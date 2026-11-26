#!/usr/bin/env python3
"""Turns generated clay renders into asset-catalog images.

Usage
  python3 scripts/clay-art.py cutout <render.jpg> <asset-name> <folder> [--size 600] [--pad 0.04]
      Removes the background (rembg, isnet-general-use), trims to the subject, pads,
      resizes the longest side to --size px, quantizes and installs it as
      Dewy/Assets.xcassets/<folder>/<asset-name>.imageset/<asset-name>.png (@3x).

  python3 scripts/clay-art.py scene <render.jpg> <asset-name> <folder> [--width 1290]
      Full-bleed backgrounds (no cutout): resized and saved as a high quality JPEG.

  python3 scripts/clay-art.py icon <render.jpg>
      Center-crops to a square and writes the 1024 px app icon (no alpha).

  python3 scripts/clay-art.py preview <png> <out.png>
      Composites a cutout on a checker + dark strip so edges can be checked by eye.

Needs: pip install "rembg[cpu]" pillow   (and optionally pngquant on PATH)
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "Dewy", "Assets.xcassets")

_session = None


def session():
    global _session
    if _session is None:
        from rembg import new_session
        _session = new_session("isnet-general-use")
    return _session


def ensure_folder(folder):
    """Creates nested asset-catalog groups (each needs a Contents.json)."""
    path = CATALOG
    for part in [p for p in folder.split("/") if p]:
        path = os.path.join(path, part)
        os.makedirs(path, exist_ok=True)
        contents = os.path.join(path, "Contents.json")
        if not os.path.exists(contents):
            with open(contents, "w") as f:
                json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
    return path


def write_imageset(folder, name, filename):
    base = ensure_folder(folder)
    imageset = os.path.join(base, f"{name}.imageset")
    # Replace an existing set with the same name anywhere in the catalog.
    for dirpath, dirnames, _ in os.walk(CATALOG):
        for d in dirnames:
            if d == f"{name}.imageset" and os.path.join(dirpath, d) != imageset:
                shutil.rmtree(os.path.join(dirpath, d))
    if os.path.isdir(imageset):
        shutil.rmtree(imageset)
    os.makedirs(imageset)
    with open(os.path.join(imageset, "Contents.json"), "w") as f:
        json.dump({
            "images": [{"filename": os.path.basename(filename), "idiom": "universal", "scale": "3x"}],
            "info": {"author": "xcode", "version": 1},
        }, f, indent=2)
    return imageset


def quantize(path):
    if shutil.which("pngquant"):
        subprocess.run(["pngquant", "--force", "--skip-if-larger", "--quality=80-98",
                        "--speed", "1", "--output", path, path], check=False)


def cutout(args):
    from rembg import remove
    src = Image.open(args.src).convert("RGB")
    out = remove(src, session=session(), post_process_mask=True)
    alpha = out.getchannel("A")
    # Firm up the matte: kill faint haze, keep soft anti-aliased edges.
    alpha = alpha.point(lambda a: 0 if a < 18 else (255 if a > 238 else a))
    alpha = alpha.filter(ImageFilter.MedianFilter(3))
    out.putalpha(alpha)
    bbox = alpha.getbbox()
    if not bbox:
        sys.exit("cutout: empty mask")
    out = out.crop(bbox)
    w, h = out.size
    pad = int(max(w, h) * args.pad)
    canvas = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    canvas.paste(out, (pad, pad))
    scale = args.size / max(canvas.size)
    canvas = canvas.resize((max(1, round(canvas.width * scale)), max(1, round(canvas.height * scale))), Image.LANCZOS)
    imageset = write_imageset(args.folder, args.name, f"{args.name}.png")
    dst = os.path.join(imageset, f"{args.name}.png")
    canvas.save(dst, optimize=True)
    quantize(dst)
    print(f"{args.name}: {canvas.size[0]}x{canvas.size[1]} -> {os.path.relpath(dst, ROOT)} ({os.path.getsize(dst)//1024} KB)")


def scene(args):
    src = Image.open(args.src).convert("RGB")
    scale = args.width / src.width
    img = src.resize((args.width, round(src.height * scale)), Image.LANCZOS)
    imageset = write_imageset(args.folder, args.name, f"{args.name}.jpg")
    dst = os.path.join(imageset, f"{args.name}.jpg")
    img.save(dst, quality=86, optimize=True, progressive=True)
    print(f"{args.name}: {img.size[0]}x{img.size[1]} -> {os.path.relpath(dst, ROOT)} ({os.path.getsize(dst)//1024} KB)")


def icon(args):
    src = Image.open(args.src).convert("RGB")
    side = min(src.size)
    left = (src.width - side) // 2
    top = (src.height - side) // 2
    img = src.crop((left, top, left + side, top + side)).resize((1024, 1024), Image.LANCZOS)
    dst = os.path.join(CATALOG, "AppIcon.appiconset", "AppIcon.png")
    img.save(dst, optimize=True)
    print(f"app icon -> {os.path.relpath(dst, ROOT)}")


def preview(args):
    img = Image.open(args.src).convert("RGBA")
    w, h = img.size
    board = Image.new("RGBA", (w * 2, h), (255, 255, 255, 255))
    tile = 24
    for y in range(0, h, tile):
        for x in range(0, w, tile):
            if (x // tile + y // tile) % 2:
                board.paste((220, 220, 220, 255), (x, y, x + tile, y + tile))
    board.paste((30, 24, 48, 255), (w, 0, w * 2, h))
    board.alpha_composite(img, (0, 0))
    board.alpha_composite(img, (w, 0))
    board.convert("RGB").save(args.out)
    print(args.out)


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("cutout")
    c.add_argument("src"); c.add_argument("name"); c.add_argument("folder")
    c.add_argument("--size", type=int, default=600)
    c.add_argument("--pad", type=float, default=0.04)
    s = sub.add_parser("scene")
    s.add_argument("src"); s.add_argument("name"); s.add_argument("folder")
    s.add_argument("--width", type=int, default=1290)
    i = sub.add_parser("icon")
    i.add_argument("src")
    p = sub.add_parser("preview")
    p.add_argument("src"); p.add_argument("out")
    args = parser.parse_args()
    {"cutout": cutout, "scene": scene, "icon": icon, "preview": preview}[args.cmd](args)


if __name__ == "__main__":
    main()
