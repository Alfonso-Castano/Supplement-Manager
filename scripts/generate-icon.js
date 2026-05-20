// StackWise App Icon Generator
// Produces all required PNG sizes for the iOS AppIcon asset catalog.
// Run with: node scripts/generate-icon.js

'use strict';
const zlib = require('zlib');
const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function hexRgb(hex) {
  const h = hex.replace('#', '');
  return [parseInt(h.slice(0,2),16), parseInt(h.slice(2,4),16), parseInt(h.slice(4,6),16)];
}

function lerp(a, b, t) { return a + (b - a) * t; }
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

// ---------------------------------------------------------------------------
// PNG writer (pure Node.js, no dependencies)
// ---------------------------------------------------------------------------

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    t[i] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) crc = CRC_TABLE[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function chunk(type, data) {
  const tb = Buffer.from(type, 'ascii');
  const lb = Buffer.allocUnsafe(4); lb.writeUInt32BE(data.length, 0);
  const cb = Buffer.allocUnsafe(4); cb.writeUInt32BE(crc32(Buffer.concat([tb, data])), 0);
  return Buffer.concat([lb, tb, data, cb]);
}

function writePng(rgba, size, filepath) {
  const SIG  = Buffer.from([0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A]);
  const ihdr = Buffer.allocUnsafe(13);
  ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4);
  ihdr[8]=8; ihdr[9]=6; ihdr[10]=0; ihdr[11]=0; ihdr[12]=0;

  // Raw image data: 1 filter byte (None=0) + 4 bytes/pixel per row
  const stride = 1 + size * 4;
  const raw    = Buffer.allocUnsafe(size * stride);
  for (let y = 0; y < size; y++) {
    raw[y * stride] = 0;
    const rowBase = y * size * 4;
    const dstBase = y * stride + 1;
    for (let x = 0; x < size; x++) {
      const s = rowBase + x * 4;
      const d = dstBase + x * 4;
      raw[d]   = rgba[s];
      raw[d+1] = rgba[s+1];
      raw[d+2] = rgba[s+2];
      raw[d+3] = rgba[s+3];
    }
  }

  const idat = zlib.deflateSync(raw, { level: 6 });
  const png  = Buffer.concat([SIG, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);
  fs.writeFileSync(filepath, png);
}

// ---------------------------------------------------------------------------
// Icon renderer
// ---------------------------------------------------------------------------

// Simple 5×7 bitmap font glyphs
const GLYPHS = {
  S: [0b01110, 0b10001, 0b10000, 0b01110, 0b00001, 0b10001, 0b01110],
  W: [0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b01010, 0b01010],
};

function renderIcon(size) {
  const px = new Uint8Array(size * size * 4);

  // 1. Diagonal 3-stop gradient background
  const cTL = hexRgb('#0F9BBF');
  const cCC = hexRgb('#1272A8');
  const cBR = hexRgb('#0F6B48');

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const t = (x + y) / (2 * (size - 1));
      let r, g, b;
      if (t <= 0.5) {
        const s = t * 2;
        r = lerp(cTL[0], cCC[0], s); g = lerp(cTL[1], cCC[1], s); b = lerp(cTL[2], cCC[2], s);
      } else {
        const s = (t - 0.5) * 2;
        r = lerp(cCC[0], cBR[0], s); g = lerp(cCC[1], cBR[1], s); b = lerp(cCC[2], cBR[2], s);
      }
      const i = (y * size + x) * 4;
      px[i]=Math.round(r); px[i+1]=Math.round(g); px[i+2]=Math.round(b); px[i+3]=255;
    }
  }

  // 2. White radial gloss ellipse at top-left (30% opacity)
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const nx = x / size, ny = y / size;
      const d = Math.sqrt((nx / 0.78) ** 2 + (ny / 0.52) ** 2);
      if (d < 1) {
        const a = (1 - d) * 0.30;
        const i = (y * size + x) * 4;
        px[i]   = clamp(Math.round(px[i]   + (255 - px[i])   * a), 0, 255);
        px[i+1] = clamp(Math.round(px[i+1] + (255 - px[i+1]) * a), 0, 255);
        px[i+2] = clamp(Math.round(px[i+2] + (255 - px[i+2]) * a), 0, 255);
      }
    }
  }

  // 3. Pills (5 capsules, right-aligned)
  const sc = size / 120;
  const specs = [
    { w:52, l:36, ta:0.72,  ba:0.18  },
    { w:72, l:16, ta:0.635, ba:0.165 },
    { w:60, l:28, ta:0.55,  ba:0.15  },
    { w:48, l:40, ta:0.465, ba:0.135 },
    { w:64, l:24, ta:0.38,  ba:0.14  },
  ];
  const ph = 12 * sc, gap = 6 * sc;
  const totalH = specs.length * ph + (specs.length - 1) * gap;
  const regionCY = size * 0.54;
  const startY = regionCY - totalH / 2;

  for (let si = 0; si < specs.length; si++) {
    const sp = specs[si];
    const px1 = sp.l * sc, pw = sp.w * sc, px2 = px1 + pw;
    const py1 = startY + si * (ph + gap), py2 = py1 + ph;
    const r = (py2 - py1) / 2, cy = (py1 + py2) / 2;

    for (let y = Math.floor(py1); y <= Math.ceil(py2); y++) {
      if (y < 0 || y >= size) continue;
      const dy = Math.abs(y - cy);
      if (dy > r) continue;
      const xi = r - Math.sqrt(Math.max(0, r * r - dy * dy));
      const lx = Math.ceil(px1 + xi), rx = Math.floor(px2 - xi);
      const tRow = (y - py1) / Math.max(py2 - py1, 1);
      const a = lerp(sp.ta, sp.ba, clamp(tRow, 0, 1));

      for (let x = lx; x <= rx; x++) {
        if (x < 0 || x >= size) continue;
        const idx = (y * size + x) * 4;
        px[idx]   = clamp(Math.round(px[idx]   + (255 - px[idx])   * a), 0, 255);
        px[idx+1] = clamp(Math.round(px[idx+1] + (255 - px[idx+1]) * a), 0, 255);
        px[idx+2] = clamp(Math.round(px[idx+2] + (255 - px[idx+2]) * a), 0, 255);
      }
    }

    // Top-left inner highlight strip
    const hlH = Math.max(1, r * 0.28);
    for (let y = Math.floor(py1); y <= Math.floor(py1 + hlH); y++) {
      if (y < 0 || y >= size) continue;
      const dy = Math.abs(y - cy);
      if (dy > r) continue;
      const xi = r - Math.sqrt(Math.max(0, r * r - dy * dy));
      const lx = Math.ceil(px1 + xi), rx = Math.floor(px2 - xi);
      const rxHl = Math.floor(lx + (rx - lx) * 0.55);
      const tHl  = (y - py1) / Math.max(hlH, 1);
      const a    = 0.35 * (1 - tHl);
      for (let x = lx; x <= Math.min(rx, rxHl); x++) {
        if (x < 0 || x >= size) continue;
        const idx = (y * size + x) * 4;
        px[idx]   = clamp(Math.round(px[idx]   + (255 - px[idx])   * a), 0, 255);
        px[idx+1] = clamp(Math.round(px[idx+1] + (255 - px[idx+1]) * a), 0, 255);
        px[idx+2] = clamp(Math.round(px[idx+2] + (255 - px[idx+2]) * a), 0, 255);
      }
    }
  }

  // 4. "SW" on first pill (if large enough)
  const sp0 = specs[0];
  const fpx1 = sp0.l * sc, fpw = sp0.w * sc;
  const fpy1 = startY, fpy2 = startY + ph;
  const fpcy = (fpy1 + fpy2) / 2;
  const letterH = 7, letterW = 5;
  const gScale = Math.max(1, Math.floor(ph * 0.6 / letterH));
  if (gScale >= 1 && ph > 6) {
    const charGap = Math.max(1, gScale);
    const totalTW = letterW * gScale * 2 + charGap;
    const centerX = fpx1 + fpw / 2 + fpw * 0.06;
    const tx = Math.round(centerX - totalTW / 2);
    const ty = Math.round(fpcy - (letterH * gScale) / 2);
    const tA = 0.93;

    const drawGlyph = (rows, ox, oy) => {
      for (let row = 0; row < letterH; row++) {
        for (let col = 0; col < letterW; col++) {
          if (!((rows[row] >> (letterW - 1 - col)) & 1)) continue;
          for (let dy = 0; dy < gScale; dy++) {
            for (let dx = 0; dx < gScale; dx++) {
              const gx = ox + col * gScale + dx, gy = oy + row * gScale + dy;
              if (gx < 0 || gx >= size || gy < 0 || gy >= size) continue;
              const idx = (gy * size + gx) * 4;
              px[idx]   = clamp(Math.round(px[idx]   + (255 - px[idx])   * tA), 0, 255);
              px[idx+1] = clamp(Math.round(px[idx+1] + (255 - px[idx+1]) * tA), 0, 255);
              px[idx+2] = clamp(Math.round(px[idx+2] + (255 - px[idx+2]) * tA), 0, 255);
            }
          }
        }
      }
    };

    drawGlyph(GLYPHS.S, tx, ty);
    drawGlyph(GLYPHS.W, tx + letterW * gScale + charGap, ty);
  }

  return px;
}

// ---------------------------------------------------------------------------
// Resize helper (bilinear)
// ---------------------------------------------------------------------------

function resizeRgba(src, srcSize, dstSize) {
  const dst = new Uint8Array(dstSize * dstSize * 4);
  const scale = srcSize / dstSize;
  for (let dy = 0; dy < dstSize; dy++) {
    for (let dx = 0; dx < dstSize; dx++) {
      const sx = dx * scale, sy = dy * scale;
      const x0 = Math.floor(sx), y0 = Math.floor(sy);
      const x1 = Math.min(x0 + 1, srcSize - 1), y1 = Math.min(y0 + 1, srcSize - 1);
      const fx = sx - x0, fy = sy - y0;
      for (let c = 0; c < 4; c++) {
        const v = lerp(
          lerp(src[(y0 * srcSize + x0) * 4 + c], src[(y0 * srcSize + x1) * 4 + c], fx),
          lerp(src[(y1 * srcSize + x0) * 4 + c], src[(y1 * srcSize + x1) * 4 + c], fx),
          fy
        );
        dst[(dy * dstSize + dx) * 4 + c] = clamp(Math.round(v), 0, 255);
      }
    }
  }
  return dst;
}

// ---------------------------------------------------------------------------
// Main — generate all sizes
// ---------------------------------------------------------------------------

const SIZES = [1024, 512, 180, 120, 87, 80, 60, 58, 40, 29, 20];

const outDir = path.join(__dirname, '..', 'StackWise', 'Assets.xcassets', 'AppIcon.appiconset');
fs.mkdirSync(outDir, { recursive: true });

console.log('Rendering base 1024×1024 icon...');
const base1024 = renderIcon(1024);
console.log('Done. Exporting all sizes...');

for (const size of SIZES) {
  const rgba = size === 1024 ? base1024 : resizeRgba(base1024, 1024, size);
  const name = `AppIcon-${size}.png`;
  writePng(rgba, size, path.join(outDir, name));
  process.stdout.write(`  ${name}\n`);
}

// ---------------------------------------------------------------------------
// Contents.json
// ---------------------------------------------------------------------------

const images = [
  // iOS Marketing
  { filename: 'AppIcon-1024.png', idiom: 'ios-marketing', scale: '1x',  size: '1024x1024' },
  // iPhone notification
  { filename: 'AppIcon-40.png',   idiom: 'iphone',        scale: '2x',  size: '20x20'     },
  { filename: 'AppIcon-60.png',   idiom: 'iphone',        scale: '3x',  size: '20x20'     },
  // iPhone settings / Spotlight
  { filename: 'AppIcon-58.png',   idiom: 'iphone',        scale: '2x',  size: '29x29'     },
  { filename: 'AppIcon-87.png',   idiom: 'iphone',        scale: '3x',  size: '29x29'     },
  // iPhone spotlight
  { filename: 'AppIcon-80.png',   idiom: 'iphone',        scale: '2x',  size: '40x40'     },
  { filename: 'AppIcon-120.png',  idiom: 'iphone',        scale: '3x',  size: '40x40'     },
  // iPhone app icon
  { filename: 'AppIcon-120.png',  idiom: 'iphone',        scale: '2x',  size: '60x60'     },
  { filename: 'AppIcon-180.png',  idiom: 'iphone',        scale: '3x',  size: '60x60'     },
];

const contents = { images, info: { author: 'xcode', version: 1 } };
fs.writeFileSync(
  path.join(outDir, 'Contents.json'),
  JSON.stringify(contents, null, 2) + '\n'
);

console.log('\nContents.json written.');
console.log(`\nAll files in: ${outDir}`);
