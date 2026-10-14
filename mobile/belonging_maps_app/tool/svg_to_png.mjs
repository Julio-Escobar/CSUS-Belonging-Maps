// Dev-time tool: rasterizes every `.svg` under a directory into a sibling `.png`.
//
// The ArcGIS Maps SDK for Flutter can only load raster images
// (BMP/GIF/ICO/JPEG/PNG) as `ArcGISImage`/`PictureMarkerSymbol`, so the source
// SVG icons must be converted to PNG before they can be used on the map.
//
// Usage:
//   npm install
//   node svg_to_png.mjs ../assets/map_icons [targetLongestSide]
//
// Each SVG is rendered at its intrinsic size, then downscaled only if its
// longest side exceeds `maxLongestSide` pixels (default 128). Transparency is
// preserved and the result is written next to the source as `<name>.png`.

import { readdirSync, readFileSync, writeFileSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';
import { Resvg } from '@resvg/resvg-js';

const root = process.argv[2];
const maxLongestSide = Number(process.argv[3] ?? 128);

if (!root) {
  console.error('Usage: node svg_to_png.mjs <directory> [maxLongestSide]');
  process.exit(1);
}

let converted = 0;
let failed = 0;

function render(svg, fitTo) {
  return new Resvg(svg, {
    fitTo,
    background: 'rgba(0,0,0,0)',
  }).render();
}

function convert(file) {
  const relative = file.replace(`${root}/`, '').replace(`${root}\\`, '');
  try {
    const svg = readFileSync(file, 'utf8');
    const intrinsic = render(svg, undefined);
    const longest = Math.max(intrinsic.width, intrinsic.height);
    const image =
      longest > maxLongestSide
        ? render(svg, { mode: 'zoom', value: maxLongestSide / longest })
        : intrinsic;

    const out = `${file.slice(0, -extname(file).length)}.png`;
    writeFileSync(out, image.asPng());
    converted += 1;
    console.log(`  ok   ${relative} -> ${image.width}x${image.height}`);
  } catch (error) {
    failed += 1;
    console.error(`  FAIL ${relative}: ${error.message}`);
  }
}

function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      walk(full);
    } else if (extname(full).toLowerCase() === '.svg') {
      convert(full);
    }
  }
}

console.log(`Rasterizing SVGs under ${root} (max longest side: ${maxLongestSide}px)`);
walk(root);
console.log(`Done. ${converted} converted, ${failed} failed.`);
if (failed > 0) process.exitCode = 1;
