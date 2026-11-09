// Run with @resvg/resvg-js available through an external NODE_PATH.
// The approved SVG is the only geometry source. No Flutter dependency is added.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { Resvg } = require('@resvg/resvg-js');
const root = path.resolve(__dirname, '../../..');
const symbol = fs.readFileSync(path.join(__dirname, 'daira-people-circle.svg'), 'utf8');
const group = symbol.match(/<g fill="#356DF3"[\s\S]*<\/g>/)[0];
const svg = background => `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">${background}${group}</svg>`;
const opaque = svg('<rect width="512" height="512" fill="#FFFFFF"/>');
const render = (source, size) => new Resvg(source, { fitTo: { mode: 'width', value: size } }).render();

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const value of buffer) {
    crc ^= value;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const name = Buffer.from(type);
  const length = Buffer.alloc(4); length.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([name, data])));
  return Buffer.concat([length, name, data, crc]);
}
function rgbPng(image) {
  // App Store icons must have no alpha channel, including an unused opaque one.
  const { width, height, pixels } = image;
  const bytes = Buffer.alloc(height * (1 + width * 3));
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const input = (y * width + x) * 4, output = y * (1 + width * 3) + 1 + x * 3;
    if (pixels[input + 3] !== 255) throw new Error('Unexpected transparent iOS pixel');
    pixels.copy(bytes, output, input, input + 3);
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0); header.writeUInt32BE(height, 4);
  header[8] = 8; header[9] = 2; // RGB, 8 bits; no alpha channel.
  return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(bytes)), chunk('IEND', Buffer.alloc(0))]);
}

const resources = path.join(root, 'android/app/src/main/res');
for (const [density, size] of Object.entries({ mdpi:48, hdpi:72, xhdpi:96, xxhdpi:144, xxxhdpi:192 })) {
  const directory = path.join(resources, `mipmap-${density}`);
  fs.writeFileSync(path.join(directory, 'ic_launcher.png'), render(svg('<rect width="512" height="512" rx="112" fill="#FFFFFF"/>'), size).asPng());
  fs.writeFileSync(path.join(directory, 'ic_launcher_round.png'), render(svg('<circle cx="256" cy="256" r="256" fill="#FFFFFF"/>'), size).asPng());
}
const body = symbol.match(/<path d="([^"]+)"/)[1];
const head = 'M 286.5 71 A 30.5 30.5 0 1 1 225.5 71 A 30.5 30.5 0 1 1 286.5 71 Z';
function vector(color) {
  return `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="512" android:viewportHeight="512">
  <group android:pivotX="256" android:pivotY="256" android:scaleX="0.65" android:scaleY="0.65">
    <group android:translateY="37.75">
      <path android:fillColor="${color}" android:fillType="evenOdd" android:pathData="${body}"/>
${[0,120,240].map(angle => `      <group android:rotation="${angle}" android:pivotX="256" android:pivotY="256"><path android:fillColor="${color}" android:pathData="${head}"/></group>`).join('\n')}
    </group>
  </group>
</vector>\n`;
}
fs.writeFileSync(path.join(resources, 'drawable/ic_launcher_foreground.xml'), vector('#FF356DF3'));
fs.writeFileSync(path.join(resources, 'drawable/ic_launcher_monochrome.xml'), vector('#FF000000'));
fs.writeFileSync(path.join(resources, 'values/ic_launcher_colors.xml'), '<?xml version="1.0" encoding="utf-8"?>\n<resources><color name="ic_launcher_background">#FFFFFF</color></resources>\n');
const appIcons = path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset');
const contents = JSON.parse(fs.readFileSync(path.join(appIcons, 'Contents.json'), 'utf8'));
const sizes = new Map();
for (const item of contents.images) {
  if (!item.filename) continue;
  const size = Number(item.size.split('x')[0]) * Number(item.scale.replace('x', ''));
  if (!Number.isInteger(size)) throw new Error('Invalid AppIcon size');
  sizes.set(item.filename, size);
}
for (const [filename, size] of sizes) fs.writeFileSync(path.join(appIcons, filename), rgbPng(render(opaque, size)));
fs.writeFileSync(path.join(root, 'assets/brand/daira_icon.svg'), fs.readFileSync(path.join(__dirname, 'daira-app-icon.svg')));
const backend = process.argv.find(argument => argument.startsWith('--odoo-module='));
if (backend) fs.writeFileSync(path.join(backend.slice('--odoo-module='.length), 'static/description/icon.png'), rgbPng(render(opaque, 128)));
console.log(`Exported 10 Android bitmaps, adaptive/monochrome vectors and ${sizes.size} RGB iOS icons from the approved SVG.`);
