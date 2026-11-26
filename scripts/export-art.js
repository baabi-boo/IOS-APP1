// Renders the SVG illustrations in design/ into the app's asset catalog.
// Usage: node scripts/export-art.js   (needs Node and Playwright with Chromium)
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '..');
const catalog = path.join(root, 'Dewy/Assets.xcassets');

// [source folder, asset folder, asset prefix, point size]
const groups = [
  ['design/drinks', 'Drinks', 'drink-', 64],
  ['design/art', 'Art', 'art-', null],
];

function writeImageSet(dir, name, png) {
  const set = path.join(dir, `${name}.imageset`);
  fs.mkdirSync(set, { recursive: true });
  fs.writeFileSync(path.join(set, `${name}.png`), png);
  fs.writeFileSync(path.join(set, 'Contents.json'), JSON.stringify({
    images: [{ filename: `${name}.png`, idiom: 'universal', scale: '3x' }],
    info: { author: 'xcode', version: 1 },
  }, null, 2) + '\n');
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 3 });
  for (const [source, folder, prefix, points] of groups) {
    const srcDir = path.join(root, source);
    if (!fs.existsSync(srcDir)) continue;
    const outDir = path.join(catalog, folder);
    fs.mkdirSync(outDir, { recursive: true });
    fs.writeFileSync(path.join(outDir, 'Contents.json'), JSON.stringify({ info: { author: 'xcode', version: 1 } }, null, 2) + '\n');
    for (const file of fs.readdirSync(srcDir).filter((f) => f.endsWith('.svg')).sort()) {
      const svg = fs.readFileSync(path.join(srcDir, file), 'utf8');
      const box = /viewBox="([\d.\s-]+)"/.exec(svg)[1].split(/\s+/).map(Number);
      const width = points || box[2];
      const height = points ? points * (box[3] / box[2]) : box[3];
      await page.setViewportSize({ width: Math.ceil(width), height: Math.ceil(height) });
      const sized = svg.replace(/<svg([^>]*?)\swidth="[^"]*"\s+height="[^"]*"/, '<svg$1').replace('<svg', `<svg width="${width}" height="${height}"`);
      await page.setContent(`<html><body style="margin:0;background:transparent">${sized}</body></html>`);
      const png = await page.locator('svg').first().screenshot({ omitBackground: true });
      writeImageSet(outDir, prefix + path.basename(file, '.svg'), png);
      console.log(`  ${folder}/${prefix}${path.basename(file, '.svg')}`);
    }
  }

  // App icon: 1024×1024, no transparency.
  const icon = path.join(root, 'design/app-icon.svg');
  if (fs.existsSync(icon)) {
    const iconPage = await browser.newPage({ deviceScaleFactor: 1, viewport: { width: 1024, height: 1024 } });
    await iconPage.setContent(`<html><body style="margin:0">${fs.readFileSync(icon, 'utf8')}</body></html>`);
    await iconPage.locator('svg').first().screenshot({ path: path.join(catalog, 'AppIcon.appiconset/AppIcon.png') });
    console.log('  AppIcon');
  }
  await browser.close();
})();
