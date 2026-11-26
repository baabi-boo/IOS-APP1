#!/usr/bin/env bash
# Turns the CI simulator recording into the README demo GIF.
# Usage: bash scripts/make-gif.sh   (needs ffmpeg)
set -euo pipefail
cd "$(dirname "$0")/.."
# Skip the launch (blank frames) and keep the pour, the goal and the celebration.
ffmpeg -y -v error -ss 14.5 -t 16.5 -i docs/raw/celebrate.mp4 \
  -vf "fps=14,scale=300:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=160:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
  -loop 0 docs/demo.gif
ls -la docs/demo.gif
