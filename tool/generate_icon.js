const fs = require('fs');
const zlib = require('zlib');

const SIZE = 1024;

// Generate pixel data
const rawPixels = Buffer.alloc(SIZE * SIZE * 4);

// Colors
const purple = { r: 199, g: 125, b: 255 }; // #C77DFF
const pink = { r: 255, g: 107, b: 157 };   // #FF6B9D

for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    const idx = (y * SIZE + x) * 4;

    // Gradient from purple to pink
    const gt = (x / SIZE + y / SIZE) / 2;
    let r = Math.round(purple.r + (pink.r - purple.r) * gt);
    let g = Math.round(purple.g + (pink.g - purple.g) * gt);
    let b = Math.round(purple.b + (pink.b - purple.b) * gt);
    let a = 255;

    // Center coordinates
    const cx = x - SIZE / 2;
    const cy = y - SIZE / 2;
    const iconSize = SIZE * 0.3;

    let isIcon = false;

    // Draw insight chart bars
    const barWidth = iconSize * 0.2;
    const barGap = iconSize * 0.1;
    const heights = [0.45, 0.75, 0.55, 1.0];
    const baseY = iconSize * 0.45;

    for (let i = 0; i < 4; i++) {
      const barX = -iconSize * 0.45 + i * (barWidth + barGap);
      const barH = iconSize * heights[i];
      const barTop = baseY - barH;

      // Rounded top
      const cornerR = barWidth * 0.3;
      if (cx >= barX && cx <= barX + barWidth && cy >= barTop + cornerR && cy <= baseY) {
        isIcon = true;
      }
      // Round top-left corner
      if (cx >= barX && cx < barX + cornerR && cy >= barTop && cy < barTop + cornerR) {
        const dx = cx - (barX + cornerR);
        const dy = cy - (barTop + cornerR);
        if (dx * dx + dy * dy <= cornerR * cornerR) isIcon = true;
      }
      // Round top-right corner
      if (cx > barX + barWidth - cornerR && cx <= barX + barWidth && cy >= barTop && cy < barTop + cornerR) {
        const dx = cx - (barX + barWidth - cornerR);
        const dy = cy - (barTop + cornerR);
        if (dx * dx + dy * dy <= cornerR * cornerR) isIcon = true;
      }
      // Top flat between corners
      if (cx >= barX + cornerR && cx <= barX + barWidth - cornerR && cy >= barTop && cy < barTop + cornerR) {
        isIcon = true;
      }
    }

    // Trend line going up-right
    const lineStartX = -iconSize * 0.45;
    const lineEndX = iconSize * 0.5;
    const lineStartY = iconSize * 0.1;
    const lineEndY = -iconSize * 0.45;

    if (cx >= lineStartX && cx <= lineEndX) {
      const t = (cx - lineStartX) / (lineEndX - lineStartX);
      // Curved line
      const lineY = lineStartY + (lineEndY - lineStartY) * (t * t);
      const thickness = iconSize * 0.04;
      if (Math.abs(cy - lineY) < thickness) {
        isIcon = true;
      }

      // Arrow at end
      if (t > 0.85) {
        const arrowT = (t - 0.85) / 0.15;
        const arrowSpread = iconSize * 0.1 * (1 - arrowT);
        if (Math.abs(cy - lineY) < arrowSpread) {
          isIcon = true;
        }
      }

      // Dot at peak
      if (t > 0.95) {
        const dotCx = lineEndX;
        const dotCy = lineEndY;
        const dotR = iconSize * 0.06;
        const dx = cx - dotCx;
        const dy = cy - dotCy;
        if (dx * dx + dy * dy <= dotR * dotR) isIcon = true;
      }
    }

    if (isIcon) {
      rawPixels[idx] = 255;
      rawPixels[idx + 1] = 255;
      rawPixels[idx + 2] = 255;
      rawPixels[idx + 3] = 240;
    } else {
      rawPixels[idx] = r;
      rawPixels[idx + 1] = g;
      rawPixels[idx + 2] = b;
      rawPixels[idx + 3] = a;
    }
  }
}

// Create PNG
function createPNG(width, height, pixels) {
  // PNG signature
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR chunk
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 6;  // color type (RGBA)
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace

  // Create raw data with filter bytes
  const rawData = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) {
    rawData[y * (1 + width * 4)] = 0; // no filter
    pixels.copy(rawData, y * (1 + width * 4) + 1, y * width * 4, (y + 1) * width * 4);
  }

  // Compress
  const compressed = zlib.deflateSync(rawData, { level: 6 });

  // Build chunks
  function makeChunk(type, data) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length, 0);
    const typeB = Buffer.from(type);
    const crcData = Buffer.concat([typeB, data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(crcData) >>> 0, 0);
    return Buffer.concat([len, typeB, data, crc]);
  }

  // CRC32
  function crc32(buf) {
    let c = 0xFFFFFFFF;
    for (let i = 0; i < buf.length; i++) {
      c ^= buf[i];
      for (let j = 0; j < 8; j++) {
        c = (c >>> 1) ^ (c & 1 ? 0xEDB88320 : 0);
      }
    }
    return c ^ 0xFFFFFFFF;
  }

  const ihdrChunk = makeChunk('IHDR', ihdr);
  const idatChunk = makeChunk('IDAT', compressed);
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

const png = createPNG(SIZE, SIZE, rawPixels);
fs.writeFileSync('assets/icon/app_icon.png', png);
console.log(`Generated ${SIZE}x${SIZE} PNG icon at assets/icon/app_icon.png`);

// Also create foreground-only version for adaptive icons
const fgPixels = Buffer.alloc(SIZE * SIZE * 4);
rawPixels.copy(fgPixels);
for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    const idx = (y * SIZE + x) * 4;
    // If it's not the white icon part, make transparent
    if (fgPixels[idx] !== 255 || fgPixels[idx + 1] !== 255 || fgPixels[idx + 2] !== 255) {
      fgPixels[idx] = 0;
      fgPixels[idx + 1] = 0;
      fgPixels[idx + 2] = 0;
      fgPixels[idx + 3] = 0;
    }
  }
}

const fgPng = createPNG(SIZE, SIZE, fgPixels);
fs.writeFileSync('assets/icon/app_icon_foreground.png', fgPng);
console.log(`Generated ${SIZE}x${SIZE} foreground PNG at assets/icon/app_icon_foreground.png`);
