#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const { execFileSync } = require("child_process");

const rootDir = path.resolve(__dirname, "..");
const assetsDir = path.join(rootDir, "Assets");
const iconsetDir = path.join(assetsDir, "AppIcon.iconset");
const previewPath = path.join(assetsDir, "AppIcon-1024.png");
const icnsPath = path.join(assetsDir, "AppIcon.icns");
const size = 1024;
const bytesPerPixel = 4;

fs.mkdirSync(assetsDir, { recursive: true });
fs.mkdirSync(iconsetDir, { recursive: true });

const pixels = new Uint8Array(size * size * bytesPerPixel);

function clamp01(value) {
  return Math.max(0, Math.min(1, value));
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function mixColor(colorA, colorB, t) {
  return [
    lerp(colorA[0], colorB[0], t),
    lerp(colorA[1], colorB[1], t),
    lerp(colorA[2], colorB[2], t),
  ];
}

function alphaComposite(index, color, alpha) {
  if (alpha <= 0) {
    return;
  }

  const srcA = clamp01(alpha);
  const dstA = pixels[index + 3] / 255;
  const outA = srcA + dstA * (1 - srcA);

  if (outA <= 0) {
    return;
  }

  const dstR = pixels[index] / 255;
  const dstG = pixels[index + 1] / 255;
  const dstB = pixels[index + 2] / 255;

  const srcR = color[0] / 255;
  const srcG = color[1] / 255;
  const srcB = color[2] / 255;

  const outR = (srcR * srcA + dstR * dstA * (1 - srcA)) / outA;
  const outG = (srcG * srcA + dstG * dstA * (1 - srcA)) / outA;
  const outB = (srcB * srcA + dstB * dstA * (1 - srcA)) / outA;

  pixels[index] = Math.round(outR * 255);
  pixels[index + 1] = Math.round(outG * 255);
  pixels[index + 2] = Math.round(outB * 255);
  pixels[index + 3] = Math.round(outA * 255);
}

function setPixel(x, y, color, alpha = 1) {
  if (x < 0 || y < 0 || x >= size || y >= size) {
    return;
  }

  const index = (y * size + x) * bytesPerPixel;
  alphaComposite(index, color, alpha);
}

function sdRoundedRect(px, py, cx, cy, width, height, radius) {
  const qx = Math.abs(px - cx) - width / 2 + radius;
  const qy = Math.abs(py - cy) - height / 2 + radius;
  const ax = Math.max(qx, 0);
  const ay = Math.max(qy, 0);
  return Math.hypot(ax, ay) + Math.min(Math.max(qx, qy), 0) - radius;
}

function sdCircle(px, py, cx, cy, radius) {
  return Math.hypot(px - cx, py - cy) - radius;
}

function sdSegment(px, py, x1, y1, x2, y2) {
  const vx = px - x1;
  const vy = py - y1;
  const sx = x2 - x1;
  const sy = y2 - y1;
  const dot = vx * sx + vy * sy;
  const lenSq = sx * sx + sy * sy || 1;
  const t = Math.max(0, Math.min(1, dot / lenSq));
  const dx = vx - sx * t;
  const dy = vy - sy * t;
  return Math.hypot(dx, dy);
}

function sdPolygon(px, py, points) {
  let inside = false;
  let minDistance = Infinity;

  for (let i = 0; i < points.length; i += 1) {
    const a = points[i];
    const b = points[(i + 1) % points.length];

    const intersects =
      (a[1] > py) !== (b[1] > py) &&
      px < ((b[0] - a[0]) * (py - a[1])) / (b[1] - a[1]) + a[0];

    if (intersects) {
      inside = !inside;
    }

    minDistance = Math.min(minDistance, sdSegment(px, py, a[0], a[1], b[0], b[1]));
  }

  return inside ? -minDistance : minDistance;
}

function drawDistanceShape(bounds, distanceFn, colorFn, alphaMultiplier = 1) {
  const minX = Math.max(0, Math.floor(bounds.minX));
  const minY = Math.max(0, Math.floor(bounds.minY));
  const maxX = Math.min(size - 1, Math.ceil(bounds.maxX));
  const maxY = Math.min(size - 1, Math.ceil(bounds.maxY));
  const samples = [
    [0.25, 0.25],
    [0.75, 0.25],
    [0.25, 0.75],
    [0.75, 0.75],
  ];

  for (let y = minY; y <= maxY; y += 1) {
    for (let x = minX; x <= maxX; x += 1) {
      let coverage = 0;

      for (const [sx, sy] of samples) {
        const px = x + sx;
        const py = y + sy;
        if (distanceFn(px, py) <= 0) {
          coverage += 0.25;
        }
      }

      if (coverage <= 0) {
        continue;
      }

      setPixel(x, y, colorFn(x + 0.5, y + 0.5), coverage * alphaMultiplier);
    }
  }
}

function drawTile() {
  const tileBounds = { minX: 80, minY: 80, maxX: 944, maxY: 944 };
  const tileCenterX = 512;
  const tileCenterY = 512;
  const topColor = [20, 34, 47];
  const bottomColor = [37, 60, 78];

  drawDistanceShape(
    tileBounds,
    (px, py) => sdRoundedRect(px, py, tileCenterX, tileCenterY, 864, 864, 208),
    (px, py) => {
      const vertical = clamp01((py - 80) / 864);
      const horizontalGlow = 1 - clamp01(Math.hypot(px - 760, py - 210) / 700);
      const vignette = 1 - clamp01(Math.hypot(px - 512, py - 540) / 720);
      let color = mixColor(topColor, bottomColor, vertical);
      color = mixColor(color, [74, 98, 120], horizontalGlow * 0.18);
      color = mixColor([8, 14, 20], color, 0.75 + vignette * 0.25);
      return color;
    }
  );

  drawDistanceShape(
    { minX: 130, minY: 110, maxX: 894, maxY: 420 },
    (px, py) => sdRoundedRect(px, py, 512, 256, 700, 160, 120),
    () => [255, 255, 255],
    0.08
  );

  drawDistanceShape(
    { minX: 250, minY: 180, maxX: 880, maxY: 800 },
    (px, py) => sdCircle(px, py, 620, 430, 255),
    (px, py) => {
      const dist = clamp01(Math.hypot(px - 620, py - 430) / 255);
      return mixColor([251, 191, 36], [245, 158, 11], dist);
    },
    0.92
  );

  drawDistanceShape(
    { minX: 190, minY: 260, maxX: 720, maxY: 950 },
    (px, py) => sdCircle(px, py, 390, 640, 250),
    (px, py) => {
      const dist = clamp01(Math.hypot(px - 390, py - 640) / 250);
      return mixColor([16, 185, 129], [5, 150, 105], dist);
    },
    0.18
  );
}

function drawBottle() {
  const bottleColor = [243, 244, 246];
  const bottleShadow = [5, 10, 16];
  const liquidTop = [251, 191, 36];
  const liquidBottom = [217, 119, 6];

  drawDistanceShape(
    { minX: 250, minY: 280, maxX: 774, maxY: 920 },
    (px, py) => sdRoundedRect(px, py, 514, 730, 410, 110, 55),
    () => bottleShadow,
    0.22
  );

  drawDistanceShape(
    { minX: 325, minY: 210, maxX: 700, maxY: 770 },
    (px, py) => sdRoundedRect(px, py, 512, 486, 190, 420, 96),
    (px, py) => {
      const shade = clamp01((py - 230) / 420);
      return mixColor([255, 255, 255], [231, 236, 241], shade);
    }
  );

  drawDistanceShape(
    { minX: 412, minY: 128, maxX: 612, maxY: 360 },
    (px, py) => sdRoundedRect(px, py, 512, 242, 104, 176, 36),
    (px, py) => {
      const shade = clamp01((py - 128) / 176);
      return mixColor([250, 250, 251], [226, 231, 235], shade);
    }
  );

  drawDistanceShape(
    { minX: 392, minY: 104, maxX: 632, maxY: 190 },
    (px, py) => sdRoundedRect(px, py, 512, 146, 152, 60, 22),
    (px, py) => {
      const shade = clamp01((py - 104) / 60);
      return mixColor([249, 176, 64], [214, 104, 25], shade);
    }
  );

  drawDistanceShape(
    { minX: 350, minY: 420, maxX: 674, maxY: 772 },
    (px, py) => {
      const body = sdRoundedRect(px, py, 512, 486, 190, 420, 96);
      const liquidLine = 470 - py;
      return Math.max(body, liquidLine);
    },
    (px, py) => {
      const shade = clamp01((py - 470) / 230);
      return mixColor(liquidTop, liquidBottom, shade);
    },
    0.95
  );

  drawDistanceShape(
    { minX: 446, minY: 164, maxX: 520, maxY: 650 },
    (px, py) => sdRoundedRect(px, py, 480, 406, 42, 430, 22),
    () => [255, 255, 255],
    0.24
  );
}

function drawLabel() {
  drawDistanceShape(
    { minX: 362, minY: 456, maxX: 662, maxY: 684 },
    (px, py) => sdRoundedRect(px, py, 512, 570, 248, 184, 50),
    (px, py) => {
      const shade = clamp01((py - 478) / 184);
      return mixColor([28, 41, 55], [16, 24, 32], shade);
    }
  );

  drawDistanceShape(
    { minX: 384, minY: 478, maxX: 640, maxY: 662 },
    (px, py) => sdRoundedRect(px, py, 512, 570, 208, 144, 38),
    (px, py) => {
      const glow = 1 - clamp01(Math.hypot(px - 512, py - 540) / 220);
      return mixColor([35, 50, 67], [49, 69, 89], glow * 0.5);
    },
    0.85
  );

  const leftFace = [
    [442, 600],
    [478, 624],
    [478, 560],
    [442, 536],
  ];
  const rightFace = [
    [478, 624],
    [582, 624],
    [582, 560],
    [478, 560],
  ];
  const topFace = [
    [442, 536],
    [478, 560],
    [582, 560],
    [546, 536],
  ];

  for (const [points, color, alpha] of [
    [leftFace, [251, 191, 36], 0.92],
    [rightFace, [245, 158, 11], 0.98],
    [topFace, [253, 224, 71], 0.98],
  ]) {
    drawDistanceShape(
      { minX: 432, minY: 526, maxX: 592, maxY: 634 },
      (px, py) => sdPolygon(px, py, points),
      () => color,
      alpha
    );
  }

  const strokes = [
    [442, 536, 478, 560],
    [478, 560, 582, 560],
    [546, 536, 582, 560],
    [442, 536, 442, 600],
    [478, 560, 478, 624],
    [582, 560, 582, 624],
    [442, 600, 478, 624],
    [478, 624, 582, 624],
  ];

  for (const [x1, y1, x2, y2] of strokes) {
    drawDistanceShape(
      { minX: Math.min(x1, x2) - 8, minY: Math.min(y1, y2) - 8, maxX: Math.max(x1, x2) + 8, maxY: Math.max(y1, y2) + 8 },
      (px, py) => sdSegment(px, py, x1, y1, x2, y2) - 3.2,
      () => [255, 248, 235],
      0.7
    );
  }
}

function drawSpark() {
  const segments = [
    [664, 288, 664, 364, 11],
    [626, 326, 702, 326, 11],
    [638, 298, 690, 354, 9],
    [690, 298, 638, 354, 9],
  ];

  for (const [x1, y1, x2, y2, thickness] of segments) {
    drawDistanceShape(
      { minX: Math.min(x1, x2) - 18, minY: Math.min(y1, y2) - 18, maxX: Math.max(x1, x2) + 18, maxY: Math.max(y1, y2) + 18 },
      (px, py) => sdSegment(px, py, x1, y1, x2, y2) - thickness / 2,
      () => [255, 247, 220],
      0.85
    );
  }
}

function crc32(buffer) {
  let crc = 0xffffffff;

  for (let i = 0; i < buffer.length; i += 1) {
    crc ^= buffer[i];
    for (let bit = 0; bit < 8; bit += 1) {
      const mask = -(crc & 1);
      crc = (crc >>> 1) ^ (0xedb88320 & mask);
    }
  }

  return (crc ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const typeBuffer = Buffer.from(type, "ascii");
  const lengthBuffer = Buffer.alloc(4);
  lengthBuffer.writeUInt32BE(data.length, 0);

  const crcBuffer = Buffer.alloc(4);
  crcBuffer.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), 0);

  return Buffer.concat([lengthBuffer, typeBuffer, data, crcBuffer]);
}

function writePNG(filePath, width, height, rgba) {
  const stride = width * 4;
  const rows = [];

  for (let y = 0; y < height; y += 1) {
    const row = Buffer.alloc(1 + stride);
    row[0] = 0;
    Buffer.from(rgba.buffer, rgba.byteOffset + y * stride, stride).copy(row, 1);
    rows.push(row);
  }

  const raw = Buffer.concat(rows);
  const compressed = zlib.deflateSync(raw, { level: 9 });
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  const png = Buffer.concat([
    signature,
    pngChunk("IHDR", ihdr),
    pngChunk("IDAT", compressed),
    pngChunk("IEND", Buffer.alloc(0)),
  ]);

  fs.writeFileSync(filePath, png);
}

function resizeWithSips(inputPath, outputPath, targetSize) {
  execFileSync("sips", ["-z", String(targetSize), String(targetSize), inputPath, "--out", outputPath], {
    stdio: "ignore",
  });
}

function writeIcns() {
  const iconEntries = [
    ["icp4", path.join(iconsetDir, "icon_16x16.png")],
    ["icp5", path.join(iconsetDir, "icon_32x32.png")],
    ["icp6", path.join(iconsetDir, "icon_32x32@2x.png")],
    ["ic07", path.join(iconsetDir, "icon_128x128.png")],
    ["ic08", path.join(iconsetDir, "icon_256x256.png")],
    ["ic09", path.join(iconsetDir, "icon_512x512.png")],
    ["ic10", path.join(iconsetDir, "icon_512x512@2x.png")],
  ];

  const chunks = iconEntries.map(([type, filePath]) => {
    const data = fs.readFileSync(filePath);
    const header = Buffer.alloc(8);
    header.write(type, 0, 4, "ascii");
    header.writeUInt32BE(data.length + 8, 4);
    return Buffer.concat([header, data]);
  });

  const totalLength = 8 + chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const fileHeader = Buffer.alloc(8);
  fileHeader.write("icns", 0, 4, "ascii");
  fileHeader.writeUInt32BE(totalLength, 4);

  fs.writeFileSync(icnsPath, Buffer.concat([fileHeader, ...chunks]));
}

function generateIconset() {
  const iconFiles = [
    ["icon_16x16.png", 16],
    ["icon_16x16@2x.png", 32],
    ["icon_32x32.png", 32],
    ["icon_32x32@2x.png", 64],
    ["icon_128x128.png", 128],
    ["icon_128x128@2x.png", 256],
    ["icon_256x256.png", 256],
    ["icon_256x256@2x.png", 512],
    ["icon_512x512.png", 512],
    ["icon_512x512@2x.png", 1024],
  ];

  for (const [fileName, targetSize] of iconFiles) {
    resizeWithSips(previewPath, path.join(iconsetDir, fileName), targetSize);
  }

  writeIcns();
  console.log(`Generated ${icnsPath}`);
}

drawTile();
drawBottle();
drawLabel();
drawSpark();
writePNG(previewPath, size, size, pixels);
generateIconset();

console.log(`Generated ${previewPath}`);
