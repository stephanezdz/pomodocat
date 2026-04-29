Place an animated cat asset here.

Accepted file names (the app looks for them in this order):
  1. cat.mov   — HEVC with alpha channel (recommended)
  2. cat.mp4   — HEVC with alpha channel
  3. cat.gif   — animated GIF with transparency
  4. cat.png   — animated PNG (APNG) with transparency

If none are found, the app falls back to the 🐱 emoji.

How to make a HEVC + alpha .mov from a green-screen source with ffmpeg:
  ffmpeg -i source.mp4 \
    -vf "chromakey=0x00FF00:0.10:0.05,format=yuva420p" \
    -c:v hevc_videotoolbox -allow_sw 1 -alpha_quality 0.75 \
    -tag:v hvc1 cat.mov

After dropping a file here, rebuild with:
  ./build-app.sh
