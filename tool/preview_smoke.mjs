#!/usr/bin/env node
/**
 * Headless smoke test for preview/index.html.
 *
 * There is no browser in the build sandbox, so jsdom + a stub 2D context is
 * used to execute the real preview script and drive the main flows: tab
 * switching, filters, search, language switch, units, the detail sheet, the
 * 360° sweep, the "found" celebration and the range badge.
 *
 *   npm install jsdom          # once, anywhere (not committed)
 *   node tool/preview_smoke.mjs
 */

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { JSDOM, VirtualConsole } from 'jsdom';

const here = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(resolve(here, '../preview/index.html'), 'utf8');

const errors = [];
const virtualConsole = new VirtualConsole();
virtualConsole.on('jsdomError', (e) => errors.push('jsdomError: ' + (e.stack || e.message)));
virtualConsole.on('error', (...args) => errors.push('console.error: ' + args.join(' ')));

const gradient = { addColorStop() {} };
const fakeContext = (canvas) => ({
  canvas,
  setTransform() {}, clearRect() {}, save() {}, restore() {}, translate() {}, rotate() {},
  beginPath() {}, closePath() {}, moveTo() {}, lineTo() {}, arc() {}, fill() {}, stroke() {},
  fillRect() {}, strokeRect() {}, fillText() {}, measureText: () => ({ width: 42 }),
  createRadialGradient: () => gradient, createLinearGradient: () => gradient,
  globalAlpha: 1, shadowBlur: 0, shadowColor: '', font: '', textAlign: 'start',
  fillStyle: '', strokeStyle: '', lineWidth: 1, lineCap: 'butt'
});

const dom = new JSDOM(html, {
  runScripts: 'dangerously',
  pretendToBeVisual: true,
  url: 'http://localhost/preview/',
  virtualConsole,
  beforeParse(window) {
    window.HTMLCanvasElement.prototype.getContext = function () { return fakeContext(this); };
    Object.defineProperty(window.HTMLElement.prototype, 'getBoundingClientRect', {
      value() { return { x: 0, y: 0, width: 400, height: 700, top: 0, left: 0, right: 400, bottom: 700 }; }
    });
    window.AudioContext = class {
      constructor() { this.currentTime = 0; this.destination = {}; this.state = 'running'; }
      createOscillator() {
        return { type: '', frequency: { value: 0 }, connect() { return { connect() {} }; }, start() {}, stop() {} };
      }
      createGain() {
        return {
          gain: { setValueAtTime() {}, linearRampToValueAtTime() {}, exponentialRampToValueAtTime() {} },
          connect() { return { connect() {} }; }
        };
      }
      resume() {}
    };
    window.navigator.vibrate = () => true;
    window.requestAnimationFrame = (cb) => window.setTimeout(() => cb(window.performance.now()), 16);
    window.cancelAnimationFrame = (id) => window.clearTimeout(id);
  }
});

const { window } = dom;
const { document } = window;
const click = (el) => el.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
const wait = (ms) => new Promise((resolveWait) => setTimeout(resolveWait, ms));

await wait(300);

const results = [];
const check = (name, condition) => results.push([condition ? 'PASS' : 'FAIL', name]);

check('title is set', document.title.includes('Bluetooth Finder Radar'));
check('8 mock devices listed', document.querySelectorAll('#device-list .card').length === 8);
check('5 filter chips', document.querySelectorAll('#filters .filter').length === 5);
check('radar canvas exists', Boolean(document.getElementById('radar')));
check('detail sheet starts closed', !document.getElementById('detail').classList.contains('active'));

click(document.querySelector('[data-screen="devices"]'));
check('devices tab opens', document.getElementById('screen-devices').classList.contains('active'));
click(document.querySelector('[data-screen="settings"]'));
check('settings tab opens', document.getElementById('screen-settings').classList.contains('active'));

click(document.querySelector('[data-filter="tracker"]'));
check('tracker filter shows 3 devices', document.querySelectorAll('#device-list .card').length === 3);
const search = document.getElementById('search-input');
search.value = 'airtag';
search.dispatchEvent(new window.Event('input', { bubbles: true }));
check('search narrows to AirTag', document.querySelectorAll('#device-list .card').length === 1);
click(document.querySelector('[data-filter="all"]'));
search.value = '';
search.dispatchEvent(new window.Event('input', { bubbles: true }));

click(document.getElementById('lang-btn'));
check('arabic + rtl applied', document.documentElement.lang === 'ar' && document.documentElement.dir === 'rtl');
click(document.getElementById('lang-btn'));
check('english + ltr restored', document.documentElement.lang === 'en' && document.documentElement.dir === 'ltr');

click(document.querySelector('#unit-seg [data-unit="ft"]'));
check('imperial units selectable', document.querySelector('#unit-seg [data-unit="ft"]').classList.contains('on'));
click(document.querySelector('#unit-seg [data-unit="m"]'));

click(document.querySelector('#device-list .card'));
await wait(120);
check('detail sheet opens', document.getElementById('detail').classList.contains('active'));
check('distance readout populated', /\d/.test(document.getElementById('detail-distance').textContent));
check('zone label populated', document.getElementById('detail-zone').textContent.length > 0);

click(document.getElementById('btn-sweep'));
check('sweep overlay opens', document.getElementById('sweep').classList.contains('active'));
await wait(250);
check('sweep heading updates', document.getElementById('sweep-heading').textContent !== '—');
click(document.getElementById('sweep-close'));

click(document.getElementById('btn-found'));
check('found dialog visible', document.getElementById('found').classList.contains('active'));
click(document.getElementById('found-ok'));
check('found dialog dismissed', !document.getElementById('found').classList.contains('active'));

click(document.getElementById('detail-back'));
await wait(80);
check('detail sheet closes', !document.getElementById('detail').classList.contains('active'));
const rangeBefore = document.getElementById('range-pill').textContent;
click(document.getElementById('range-pill'));
check('range badge cycles', document.getElementById('range-pill').textContent !== rangeBefore);

await wait(400);

for (const [status, name] of results) console.log(`${status}  ${name}`);
const failed = results.filter(([status]) => status === 'FAIL').length;
console.log(`\n${results.length - failed}/${results.length} checks passed`);

if (errors.length) {
  console.log('\nRUNTIME ERRORS:');
  for (const error of errors) console.log(error);
}
process.exit(failed || errors.length ? 1 : 0);
