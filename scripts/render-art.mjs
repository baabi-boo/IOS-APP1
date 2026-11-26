#!/usr/bin/env node
/**
 * Dewy Storybook Art Pipeline — Zero-Dependency Headless Chrome CDP Renderer.
 *
 * Converts hand-crafted gouache SVGs (with full SVG <filter> paper grain,
 * Gaussian blur, gradients, and masks) into crisp transparent @3x PNG assets
 * for Xcode Assets.xcassets, plus editorial inspection contact sheets.
 *
 * Usage:
 *   node scripts/render-art.mjs --svg in.svg --out out.png --width 360 --height 360 [--opaque] [--imageset]
 *   node scripts/render-art.mjs --dir design/drinks --xcassets Dewy/Assets.xcassets/Drinks --width 360 --height 360 [--sheet out.png] [--title "Drinks"]
 *   node scripts/render-art.mjs --batch manifest.json
 *   node scripts/render-art.mjs --sheet spec.json --out contact-sheet.png
 *   node scripts/render-art.mjs --self-test
 */

import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import zlib from 'node:zlib';
import { pathToFileURL } from 'node:url';

const CHROME_PATH = process.env.CHROME_PATH || '/usr/bin/google-chrome';

// MARK: - Minimal CDP Client over Node 22 Built-in WebSocket

class CDPClient {
  constructor(ws) {
    this.ws = ws;
    this.nextId = 1;
    this.pending = new Map();

    ws.addEventListener('message', (event) => {
      const msg = JSON.parse(typeof event.data === 'string' ? event.data : Buffer.from(event.data).toString('utf8'));
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) {
          reject(new Error(`CDP error (${msg.error.code}): ${msg.error.message}`));
        } else {
          resolve(msg.result);
        }
      }
    });

    ws.addEventListener('close', () => {
      for (const { reject } of this.pending.values()) {
        reject(new Error('CDP WebSocket closed unexpectedly'));
      }
      this.pending.clear();
    });
  }

  send(method, params = {}, timeoutMs = 20000) {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`CDP timeout after ${timeoutMs}ms: ${method}`));
        }
      }, timeoutMs);

      this.pending.set(id, {
        resolve: (val) => {
          clearTimeout(timer);
          resolve(val);
        },
        reject: (err) => {
          clearTimeout(timer);
          reject(err);
        }
      });

      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    try {
      this.ws.close();
    } catch {
      // Ignore close races.
    }
  }
}

// MARK: - Headless Chrome Session Manager

export class ChromeRenderer {
  constructor() {
    this.proc = null;
    this.cdp = null;
    this.frameId = null;
    this.tmpDir = null;
  }

  async launch() {
    this.tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'dewy-art-chrome-'));
    const args = [
      '--headless=new',
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-gpu',
      '--disable-dev-shm-usage',
      '--disable-extensions',
      '--disable-background-networking',
      '--disable-default-apps',
      '--disable-sync',
      '--hide-scrollbars',
      '--mute-audio',
      '--no-first-run',
      '--remote-debugging-port=0',
      `--user-data-dir=${this.tmpDir}`,
      'about:blank'
    ];

    this.proc = spawn(CHROME_PATH, args, { stdio: ['ignore', 'pipe', 'pipe'] });

    const port = await new Promise((resolve, reject) => {
      let stderrBuf = '';
      const timer = setTimeout(() => {
        reject(new Error(`Timed out waiting for Chrome DevTools endpoint. stderr:\n${stderrBuf}`));
      }, 15000);

      const onData = (chunk) => {
        stderrBuf += chunk.toString('utf8');
        const match = stderrBuf.match(/DevTools listening on ws:\/\/127\.0\.0\.1:(\d+)\//);
        if (match) {
          clearTimeout(timer);
          this.proc.stderr.off('data', onData);
          resolve(Number(match[1]));
        }
      };

      this.proc.stderr.on('data', onData);
      this.proc.once('exit', (code) => {
        clearTimeout(timer);
        reject(new Error(`Chrome exited prematurely with code ${code}. stderr:\n${stderrBuf}`));
      });
    });

    const pageWsUrl = await this.#findPageWebSocket(port);
    const ws = await new Promise((resolve, reject) => {
      const socket = new WebSocket(pageWsUrl);
      const timer = setTimeout(() => reject(new Error('Timed out connecting to Chrome page WebSocket')), 10000);
      socket.addEventListener('open', () => {
        clearTimeout(timer);
        resolve(socket);
      }, { once: true });
      socket.addEventListener('error', (err) => {
        clearTimeout(timer);
        reject(new Error(`WebSocket connection failed: ${err?.message || 'unknown error'}`));
      }, { once: true });
    });

    this.cdp = new CDPClient(ws);
    await this.cdp.send('Page.enable');
    await this.cdp.send('Runtime.enable');
    const { frameTree } = await this.cdp.send('Page.getFrameTree');
    this.frameId = frameTree.frame.id;
  }

  async #findPageWebSocket(port) {
    const base = `http://127.0.0.1:${port}`;
    for (let attempt = 0; attempt < 20; attempt++) {
      try {
        const res = await fetch(`${base}/json/list`);
        const targets = await res.json();
        const page = targets.find((t) => t.type === 'page' && t.webSocketDebuggerUrl);
        if (page) return page.webSocketDebuggerUrl;
      } catch {
        // Retry briefly while Chrome initializes targets.
      }
      await new Promise((r) => setTimeout(r, 100));
    }
    const created = await fetch(`${base}/json/new?about:blank`, { method: 'PUT' });
    const target = await created.json();
    if (!target.webSocketDebuggerUrl) {
      throw new Error('Could not find or create a Chrome page target');
    }
    return target.webSocketDebuggerUrl;
  }

  /**
   * Renders an SVG file or markup string to an exact-dimension PNG buffer.
   */
  async renderSvg({ svgPath, svgMarkup, width, height, opaque = false }) {
    const rawSvg = svgMarkup ?? (await fs.readFile(svgPath, 'utf8'));
    const html = `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body {
    width: ${width}px;
    height: ${height}px;
    overflow: hidden;
    background: ${opaque ? '#FFF8F0' : 'transparent'};
  }
  #stage {
    width: ${width}px;
    height: ${height}px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  #stage > svg {
    width: ${width}px;
    height: ${height}px;
    display: block;
    shape-rendering: geometricPrecision;
  }
</style>
</head>
<body><div id="stage">${rawSvg}</div></body>
</html>`;

    await this.cdp.send('Emulation.setDeviceMetricsOverride', {
      width,
      height,
      deviceScaleFactor: 1,
      mobile: false
    });

    if (opaque) {
      await this.cdp.send('Emulation.setDefaultBackgroundColorOverride', {});
    } else {
      await this.cdp.send('Emulation.setDefaultBackgroundColorOverride', {
        color: { r: 0, g: 0, b: 0, a: 0 }
      });
    }

    await this.cdp.send('Page.setDocumentContent', {
      frameId: this.frameId,
      html
    });

    await this.cdp.send('Runtime.evaluate', {
      expression: 'new Promise(r => document.fonts.ready.then(() => requestAnimationFrame(() => requestAnimationFrame(() => r(true)))))',
      awaitPromise: true
    });

    const { data } = await this.cdp.send('Page.captureScreenshot', {
      format: 'png',
      fromSurface: true,
      clip: { x: 0, y: 0, width, height, scale: 1 }
    });

    return Buffer.from(data, 'base64');
  }

  /**
   * Renders an editorial HTML contact sheet showing rendered PNGs on both cream parchment
   * and twilight indigo swatches for visual QA.
   */
  async renderContactSheet({ title = 'Dewy Storybook Contact Sheet', subtitle = '', items = [], columns = 4, outPath }) {
    const cardHtml = [];
    for (const item of items) {
      const buf = await fs.readFile(item.pngPath);
      const dims = readPngHeader(buf);
      const dataUri = `data:image/png;base64,${buf.toString('base64')}`;
      const label = escapeHtml(item.label || path.basename(item.pngPath, '.png'));
      const sub = escapeHtml(item.sublabel || `${dims.width}×${dims.height}px`);
      cardHtml.push(`
        <div class="card">
          <div class="preview-pair">
            <div class="swatch swatch-cream"><img src="${dataUri}" alt="${label}"></div>
            <div class="swatch swatch-night"><img src="${dataUri}" alt="${label}"></div>
          </div>
          <div class="meta">
            <span class="label">${label}</span>
            <span class="sub">${sub}</span>
          </div>
        </div>
      `);
    }

    const sheetWidth = Math.max(960, columns * 310 + 96);
    const html = `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body {
    width: ${sheetWidth}px;
    background: #F7EFE4;
    color: #251E2B;
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Rounded", "Segoe UI", system-ui, sans-serif;
  }
  .wrap { padding: 36px 40px 44px; }
  header {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 24px;
    padding-bottom: 16px;
    border-bottom: 2px solid rgba(37, 30, 43, 0.12);
  }
  h1 { font-size: 26px; font-weight: 700; letter-spacing: -0.02em; }
  .subtitle { font-size: 14px; color: #6B5C73; font-weight: 500; }
  .grid {
    display: grid;
    grid-template-columns: repeat(${columns}, 1fr);
    gap: 18px;
  }
  .card {
    background: #FFFDFA;
    border: 1.5px solid rgba(37, 30, 43, 0.10);
    border-radius: 18px;
    overflow: hidden;
    box-shadow: 0 4px 14px rgba(85, 62, 52, 0.08);
  }
  .preview-pair {
    display: grid;
    grid-template-columns: 1.45fr 1fr;
    height: 164px;
    border-bottom: 1px solid rgba(37, 30, 43, 0.08);
  }
  .swatch {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 14px;
  }
  .swatch-cream {
    background-color: #FFF8F0;
    background-image:
      linear-gradient(45deg, rgba(37,30,43,0.03) 25%, transparent 25%),
      linear-gradient(-45deg, rgba(37,30,43,0.03) 25%, transparent 25%),
      linear-gradient(45deg, transparent 75%, rgba(37,30,43,0.03) 75%),
      linear-gradient(-45deg, transparent 75%, rgba(37,30,43,0.03) 75%);
    background-size: 16px 16px;
    background-position: 0 0, 0 8px, 8px -8px, -8px 0;
  }
  .swatch-night {
    background: linear-gradient(160deg, #32367A 0%, #4C4E9E 100%);
  }
  .swatch img {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
    display: block;
  }
  .meta {
    padding: 11px 14px;
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 8px;
  }
  .label { font-size: 14px; font-weight: 700; color: #251E2B; }
  .sub { font-size: 11.5px; font-weight: 600; color: #8A7A91; }
</style>
</head>
<body>
  <div class="wrap">
    <header>
      <h1>${escapeHtml(title)}</h1>
      <div class="subtitle">${escapeHtml(subtitle || `${items.length} assets · cream & twilight check`)}</div>
    </header>
    <div class="grid">${cardHtml.join('\n')}</div>
  </div>
</body>
</html>`;

    await this.cdp.send('Emulation.setDefaultBackgroundColorOverride', {});
    await this.cdp.send('Emulation.setDeviceMetricsOverride', {
      width: sheetWidth,
      height: 800,
      deviceScaleFactor: 1,
      mobile: false
    });
    await this.cdp.send('Page.setDocumentContent', { frameId: this.frameId, html });
    await this.cdp.send('Runtime.evaluate', {
      expression: 'new Promise(r => Promise.all(Array.from(document.images).map(i => i.complete ? null : new Promise(res => { i.onload = res; i.onerror = res; }))).then(() => requestAnimationFrame(() => requestAnimationFrame(() => r(true)))))',
      awaitPromise: true
    });

    const evalRes = await this.cdp.send('Runtime.evaluate', {
      expression: 'Math.ceil(document.querySelector(".wrap").getBoundingClientRect().height)',
      returnByValue: true
    });
    const sheetHeight = Math.max(200, Number(evalRes?.result?.value || 800));

    await this.cdp.send('Emulation.setDeviceMetricsOverride', {
      width: sheetWidth,
      height: sheetHeight,
      deviceScaleFactor: 1,
      mobile: false
    });
    await this.cdp.send('Runtime.evaluate', {
      expression: 'new Promise(r => requestAnimationFrame(() => requestAnimationFrame(() => r(true))))',
      awaitPromise: true
    });

    const { data } = await this.cdp.send('Page.captureScreenshot', {
      format: 'png',
      fromSurface: true,
      clip: { x: 0, y: 0, width: sheetWidth, height: sheetHeight, scale: 1 }
    });

    const png = Buffer.from(data, 'base64');
    await fs.mkdir(path.dirname(outPath), { recursive: true });
    await fs.writeFile(outPath, png);
    return { width: sheetWidth, height: sheetHeight, bytes: png.length };
  }

  async close() {
    if (this.cdp) {
      this.cdp.close();
      this.cdp = null;
    }
    if (this.proc && !this.proc.killed) {
      this.proc.kill('SIGTERM');
      await new Promise((r) => setTimeout(r, 120));
      if (!this.proc.killed) this.proc.kill('SIGKILL');
      this.proc = null;
    }
    if (this.tmpDir) {
      await fs.rm(this.tmpDir, { recursive: true, force: true }).catch(() => {});
      this.tmpDir = null;
    }
  }
}

// MARK: - Xcode Asset Catalog Helpers

async function writeImagesetContents(pngPath) {
  const dir = path.dirname(pngPath);
  const filename = path.basename(pngPath);
  const isAppIcon = dir.endsWith('.appiconset');
  const contents = isAppIcon
    ? {
        images: [{ filename, idiom: 'universal', platform: 'ios', size: '1024x1024' }],
        info: { author: 'xcode', version: 1 }
      }
    : {
        images: [{ filename, idiom: 'universal', scale: '3x' }],
        info: { author: 'xcode', version: 1 }
      };
  await fs.writeFile(path.join(dir, 'Contents.json'), `${JSON.stringify(contents, null, 2)}\n`, 'utf8');
}

function escapeHtml(str) {
  return String(str)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

// MARK: - Lightweight PNG Inspector (for self-test & QA verification)

function readPngHeader(buf) {
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (buf.length < 33 || !buf.subarray(0, 8).equals(sig)) {
    throw new Error('Invalid PNG signature');
  }
  const width = buf.readUInt32BE(16);
  const height = buf.readUInt32BE(20);
  const bitDepth = buf[24];
  const colorType = buf[25];
  return { width, height, bitDepth, colorType };
}

/**
 * Decodes RGBA pixel values at requested (x, y) coordinates from an 8-bit RGBA PNG.
 * Supports all 5 PNG scanline filters (None, Sub, Up, Average, Paeth).
 */
function samplePngPixels(buf, coords) {
  const { width, height, bitDepth, colorType } = readPngHeader(buf);
  if (bitDepth !== 8 || (colorType !== 6 && colorType !== 2)) {
    throw new Error(`Unsupported PNG format for pixel check: bitDepth=${bitDepth}, colorType=${colorType}`);
  }
  const bpp = colorType === 6 ? 4 : 3;
  const idatChunks = [];
  let offset = 8;
  while (offset + 8 <= buf.length) {
    const len = buf.readUInt32BE(offset);
    const type = buf.subarray(offset + 4, offset + 8).toString('ascii');
    if (type === 'IDAT') {
      idatChunks.push(buf.subarray(offset + 8, offset + 8 + len));
    } else if (type === 'IEND') {
      break;
    }
    offset += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idatChunks));
  const stride = width * bpp;
  const decoded = Buffer.alloc(height * stride);

  const paeth = (a, b, c) => {
    const p = a + b - c;
    const pa = Math.abs(p - a);
    const pb = Math.abs(p - b);
    const pc = Math.abs(p - c);
    return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
  };

  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const rowIn = y * (stride + 1) + 1;
    const rowOut = y * stride;
    for (let i = 0; i < stride; i++) {
      const x = raw[rowIn + i];
      const a = i >= bpp ? decoded[rowOut + i - bpp] : 0;
      const b = y > 0 ? decoded[rowOut - stride + i] : 0;
      const c = y > 0 && i >= bpp ? decoded[rowOut - stride + i - bpp] : 0;
      let val = x;
      if (filter === 1) val = (x + a) & 0xff;
      else if (filter === 2) val = (x + b) & 0xff;
      else if (filter === 3) val = (x + ((a + b) >> 1)) & 0xff;
      else if (filter === 4) val = (x + paeth(a, b, c)) & 0xff;
      decoded[rowOut + i] = val;
    }
  }

  return coords.map(([px, py]) => {
    const idx = py * stride + px * bpp;
    return {
      x: px,
      y: py,
      r: decoded[idx],
      g: decoded[idx + 1],
      b: decoded[idx + 2],
      a: bpp === 4 ? decoded[idx + 3] : 255
    };
  });
}

// MARK: - CLI Argument Parsing & Execution

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const key = token.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      args[key] = true;
    } else {
      args[key] = next;
      i++;
    }
  }
  return args;
}

async function runSelfTest(renderer) {
  const sampleSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240">
  <defs>
    <radialGradient id="gouache" cx="42%" cy="36%" r="60%">
      <stop offset="0%" stop-color="#F6FBFB"/>
      <stop offset="55%" stop-color="#9BE2E6"/>
      <stop offset="100%" stop-color="#4AAEC4"/>
    </radialGradient>
    <filter id="paperGrain" x="-10%" y="-10%" width="120%" height="120%">
      <feTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="3" result="noise"/>
      <feColorMatrix type="matrix" values="0 0 0 0 0.2  0 0 0 0 0.16  0 0 0 0 0.24  0 0 0 0.07 0" in="noise" result="grain"/>
      <feComposite in="grain" in2="SourceGraphic" operator="atop"/>
    </filter>
  </defs>
  <g filter="url(#paperGrain)">
    <path d="M108 42 C112 22 128 12 140 16 C133 24 130 34 134 45 C158 68 182 96 184 136 C186 180 156 208 120 208 C84 208 54 180 56 136 C58 96 86 68 108 42 Z"
          fill="url(#gouache)" stroke="#251E2B" stroke-width="5" stroke-linejoin="round"/>
    <path d="M84 128 C85 104 98 84 114 70" fill="none" stroke="#FFFDF7" stroke-width="9" stroke-linecap="round" opacity="0.88"/>
    <circle cx="96" cy="142" r="7.5" fill="#251E2B"/>
    <circle cx="93.5" cy="139.5" r="2.4" fill="#FFFDF7"/>
    <circle cx="144" cy="142" r="7.5" fill="#251E2B"/>
    <circle cx="141.5" cy="139.5" r="2.4" fill="#FFFDF7"/>
    <path d="M111 154 Q120 164 129 154" fill="none" stroke="#251E2B" stroke-width="4.5" stroke-linecap="round"/>
  </g>
</svg>`;

  const tmpOutDir = await fs.mkdtemp(path.join(os.tmpdir(), 'dewy-art-selftest-'));
  const pngPath = path.join(tmpOutDir, 'selftest-drop.png');
  const sheetPath = path.join(tmpOutDir, 'selftest-sheet.png');

  try {
    const png = await renderer.renderSvg({ svgMarkup: sampleSvg, width: 360, height: 360, opaque: false });
    await fs.writeFile(pngPath, png);

    const header = readPngHeader(png);
    if (header.width !== 360 || header.height !== 360) {
      throw new Error(`Expected 360x360, got ${header.width}x${header.height}`);
    }

    const samples = samplePngPixels(png, [
      [4, 4],
      [355, 4],
      [4, 355],
      [355, 355],
      [180, 180]
    ]);
    const corners = samples.slice(0, 4);
    const center = samples[4];
    for (const c of corners) {
      if (c.a !== 0) {
        throw new Error(`Corner (${c.x},${c.y}) expected alpha=0, got alpha=${c.a}`);
      }
    }
    if (center.a < 240) {
      throw new Error(`Center (180,180) expected opaque alpha>=240, got alpha=${center.a}`);
    }

    const sheet = await renderer.renderContactSheet({
      title: 'Dewy Art Pipeline Self-Test',
      subtitle: 'SVG filter grain + alpha transparency check',
      columns: 2,
      items: [
        { label: 'selftest-drop', sublabel: '360×360 RGBA', pngPath },
        { label: 'selftest-drop (verify)', sublabel: 'filter + ink', pngPath }
      ],
      outPath: sheetPath
    });

    console.log(
      JSON.stringify(
        {
          ok: true,
          rendered: { width: header.width, height: header.height, bytes: png.length, colorType: header.colorType },
          cornersAlpha: corners.map((c) => c.a),
          centerRgba: [center.r, center.g, center.b, center.a],
          contactSheet: sheet
        },
        null,
        2
      )
    );
  } finally {
    await fs.rm(tmpOutDir, { recursive: true, force: true }).catch(() => {});
  }
}

async function runCli() {
  const args = parseArgs(process.argv.slice(2));
  const renderer = new ChromeRenderer();

  try {
    await renderer.launch();

    if (args['self-test']) {
      await runSelfTest(renderer);
      return;
    }

    if (args.svg) {
      const width = Number(args.width || 360);
      const height = Number(args.height || width);
      const outPath = path.resolve(args.out || args.svg.replace(/\.svg$/i, '.png'));
      const png = await renderer.renderSvg({
        svgPath: path.resolve(args.svg),
        width,
        height,
        opaque: Boolean(args.opaque)
      });
      await fs.mkdir(path.dirname(outPath), { recursive: true });
      await fs.writeFile(outPath, png);
      if (args.imageset || path.dirname(outPath).endsWith('.imageset') || path.dirname(outPath).endsWith('.appiconset')) {
        await writeImagesetContents(outPath);
      }
      console.log(`Rendered ${outPath} (${width}x${height}, ${png.length} bytes)`);
      return;
    }

    if (args.dir) {
      const srcDir = path.resolve(args.dir);
      const width = Number(args.width || 360);
      const height = Number(args.height || width);
      const prefix = args.prefix || '';
      const entries = (await fs.readdir(srcDir)).filter((f) => f.endsWith('.svg')).sort();
      const renderedItems = [];

      for (const file of entries) {
        const stem = path.basename(file, '.svg');
        const assetName = stem.startsWith(prefix) ? stem : `${prefix}${stem}`;
        const outPath = args.xcassets
          ? path.resolve(args.xcassets, `${assetName}.imageset`, `${assetName}.png`)
          : path.resolve(args.outDir || srcDir, `${assetName}.png`);
        const png = await renderer.renderSvg({
          svgPath: path.join(srcDir, file),
          width,
          height,
          opaque: Boolean(args.opaque)
        });
        await fs.mkdir(path.dirname(outPath), { recursive: true });
        await fs.writeFile(outPath, png);
        if (args.xcassets) {
          await writeImagesetContents(outPath);
        }
        renderedItems.push({ label: assetName, sublabel: `${width}×${height}px`, pngPath: outPath });
        console.log(`  ✓ ${assetName} (${png.length} bytes)`);
      }

      if (args.sheet) {
        const sheet = await renderer.renderContactSheet({
          title: args.title || path.basename(srcDir),
          items: renderedItems,
          columns: Number(args.columns || 4),
          outPath: path.resolve(args.sheet)
        });
        console.log(`  ✓ Contact sheet ${args.sheet} (${sheet.width}x${sheet.height})`);
      }
      return;
    }

    if (args.batch) {
      const manifest = JSON.parse(await fs.readFile(path.resolve(args.batch), 'utf8'));
      for (const job of manifest.jobs || []) {
        const width = Number(job.width || 360);
        const height = Number(job.height || width);
        const outPath = path.resolve(job.out);
        const png = await renderer.renderSvg({
          svgPath: path.resolve(job.svg),
          width,
          height,
          opaque: Boolean(job.opaque)
        });
        await fs.mkdir(path.dirname(outPath), { recursive: true });
        await fs.writeFile(outPath, png);
        if (job.imageset || path.dirname(outPath).endsWith('.imageset') || path.dirname(outPath).endsWith('.appiconset')) {
          await writeImagesetContents(outPath);
        }
        console.log(`  ✓ ${path.basename(outPath)} (${width}x${height}, ${png.length} bytes)`);
      }
      for (const sheet of manifest.sheets || []) {
        const result = await renderer.renderContactSheet({
          title: sheet.title,
          subtitle: sheet.subtitle,
          columns: sheet.columns || 4,
          items: sheet.items.map((item) => ({ ...item, pngPath: path.resolve(item.pngPath) })),
          outPath: path.resolve(sheet.out)
        });
        console.log(`  ✓ Sheet ${sheet.out} (${result.width}x${result.height})`);
      }
      return;
    }

    if (args.sheet) {
      const spec = JSON.parse(await fs.readFile(path.resolve(args.sheet), 'utf8'));
      const outPath = path.resolve(args.out || spec.out);
      const result = await renderer.renderContactSheet({
        title: spec.title,
        subtitle: spec.subtitle,
        columns: spec.columns || 4,
        items: spec.items.map((item) => ({ ...item, pngPath: path.resolve(item.pngPath) })),
        outPath
      });
      console.log(`Rendered contact sheet ${outPath} (${result.width}x${result.height}, ${result.bytes} bytes)`);
      return;
    }

    console.error('Usage: node scripts/render-art.mjs --self-test | --svg ... | --dir ... | --batch ... | --sheet ...');
    process.exitCode = 1;
  } finally {
    await renderer.close();
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  runCli().catch((err) => {
    console.error(err);
    process.exitCode = 1;
  });
}
