// Unit tests for the pet's movement and sprite data. Run with:  node --test tests/
// (Arrays made inside the extracted code are compared as joined strings, since they come from a separate JS context.)
// index.html stays a single file, so these tests pull the marked "#region" blocks out of it and run them on their own.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
/** @param {string} name @returns {string} the code between `// #region name` and `// #endregion name` */
function region(name) {
  const m = html.match(new RegExp(`// #region ${name}\\n([\\s\\S]*?)// #endregion ${name}`));
  assert.ok(m, `index.html is missing the "${name}" region`);
  return m[1];
}
const lib = vm.runInNewContext(`${region('sprites')}\n${region('pet-motion')}
;({ TL_SPRITES, MOTION, WANDER, SEAFLOOR, restSpot, newMotion, pickTarget, motionStep })`);
const { TL_SPRITES, MOTION, WANDER, SEAFLOOR, restSpot, newMotion, pickTarget, motionStep } = lib;
const HATCHED = ['Hatchling', 'Inkling', 'Tidecaller', 'Deepwarden', 'Kraken'];
const THREE_FRAME = ['Inkling', 'Tidecaller', 'Deepwarden', 'Kraken'];

/** Small seeded random number generator so every run is repeatable. @param {number} seed @returns {() => number} */
function seeded(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
/** Run a mood for a while and record every tick.
 * @param {string} mood @param {string} stage @param {number} ticks @param {number} seed
 * @returns {Array<{x: number, y: number, face: string, key: string, hop: boolean, now: number, smiling: boolean}>} */
function simulate(mood, stage, ticks, seed = 1) {
  const rand = seeded(seed);
  const m = newMotion(...restSpot(mood));
  pickTarget(m, rand);
  const out = [];
  let now = 0;
  for (let i = 0; i < ticks; i++) {
    const smiling = m.smile.length > 0;
    const r = motionStep(m, mood, TL_SPRITES[stage], now, rand);
    out.push({ x: m.x, y: m.y, face: m.face, key: r.key, hop: r.hop, now, smiling: smiling || r.key === 'h' });
    now += r.delay;
  }
  return out;
}

test('every sprite frame is a 16×16 grid of . and #', () => {
  for (const [stage, frames] of Object.entries(TL_SPRITES)) {
    for (const [key, rows] of Object.entries(frames)) {
      assert.equal(rows.length, 16, `${stage}.${key} rows`);
      for (const row of rows) assert.match(row, /^[.#]{16}$/, `${stage}.${key}`);
    }
  }
});

test('every hatched stage has a happy face that differs from its neutral face', () => {
  for (const stage of HATCHED) {
    assert.ok(TL_SPRITES[stage].h, `${stage} has no happy face`);
    assert.notEqual(TL_SPRITES[stage].h.join('/'), TL_SPRITES[stage].a.join('/'), stage);
  }
});

test('the third side frame keeps frame L\'s eyes but uses different arms', () => {
  for (const stage of THREE_FRAME) {
    const { l, lc } = TL_SPRITES[stage];
    assert.ok(lc, `${stage} has no third side frame`);
    assert.equal(lc.slice(0, 11).join('/'), l.slice(0, 11).join('/'), `${stage}: head should match frame L`);
    assert.notEqual(lc.join('/'), l.join('/'), `${stage}: arms should move`);
  }
});

test('wandering pets stay on screen and move at most one pixel, up/down or sideways, per tick', () => {
  for (const mood of Object.keys(WANDER)) {
    const ticks = simulate(mood, 'Inkling', 5000, 7);
    let prev = { x: restSpot(mood)[0], y: restSpot(mood)[1] };
    for (const t of ticks) {
      assert.ok(t.x >= 0 && t.x <= MOTION.maxX && t.y >= 0 && t.y <= MOTION.maxY, `${mood} left the screen`);
      assert.ok(Math.abs(t.x - prev.x) + Math.abs(t.y - prev.y) <= 1, `${mood} jumped`);
      prev = t;
    }
  }
});

test('the path varies: two runs cover different ground and the whole screen gets visited', () => {
  const a = simulate('content', 'Inkling', 400, 1).map(t => `${t.x},${t.y}`).join(' ');
  const b = simulate('content', 'Inkling', 400, 2).map(t => `${t.x},${t.y}`).join(' ');
  assert.notEqual(a, b);
  const seen = new Set(simulate('content', 'Inkling', 6000, 3).map(t => `${t.x},${t.y}`));
  assert.ok(seen.size > 0.9 * (MOTION.maxX + 1) * (MOTION.maxY + 1), `only visited ${seen.size} spots`);
});

test('side views face the way the pet is moving', () => {
  const ticks = simulate('content', 'Kraken', 3000, 4);
  for (let i = 1; i < ticks.length; i++) {
    const dx = ticks[i].x - ticks[i - 1].x;
    if (ticks[i].face === 'l') assert.ok(dx <= 0, 'faced left while moving right');
    if (ticks[i].face === 'r') assert.ok(dx >= 0, 'faced right while moving left');
  }
});

test('side and front eyes change at most every fourth tick for three-frame creatures', () => {
  for (const stage of THREE_FRAME) {
    const ticks = simulate('content', stage, 4000, 5);
    const lastEyeChange = { f: -9, l: -9, r: -9 };
    for (let i = 0; i < ticks.length; i++) {
      const { key, face } = ticks[i];
      if (ticks[i].smiling) continue;
      if (i > 0 && ticks[i - 1].face !== face) for (const f of Object.keys(lastEyeChange)) lastEyeChange[f] = -9;
      if (key === 'b' || key === 'l2' || key === 'r2') {
        assert.ok(i - lastEyeChange[face] >= 4, `${stage} changed expression too often facing ${face}`);
        lastEyeChange[face] = i;
      }
    }
  }
});

test('happy pets flash the happy face at most once a minute, 2–3 times, holding still', () => {
  const ticks = simulate('happy', 'Inkling', 6000, 6); // 40 minutes at 0.4s a tick
  const bursts = [];
  for (let i = 0; i < ticks.length; i++) {
    if (ticks[i].key !== 'h' || (i > 0 && ['h', 'a'].includes(ticks[i - 1].key) && ticks[i - 1].smiling)) continue;
    let j = i, flashes = 0;
    while (j < ticks.length && ticks[j].smiling && (ticks[j].key === 'h' || ticks[j].key === 'a')) {
      if (ticks[j].key === 'h') flashes++;
      assert.equal(ticks[j].x, ticks[i].x); assert.equal(ticks[j].y, ticks[i].y);
      j++;
    }
    bursts.push({ at: ticks[i].now, flashes });
  }
  assert.ok(bursts.length > 5, 'the happy face should still show up');
  for (const b of bursts) assert.ok(b.flashes >= 2 && b.flashes <= 3, `flashed ${b.flashes} times`);
  for (let i = 1; i < bursts.length; i++) assert.ok(bursts[i].at - bursts[i - 1].at >= MOTION.smileCooldown, 'smiled twice within a minute');
});

test('only happy pets smile or hop, and happy hops stay occasional', () => {
  for (const mood of ['content', 'worried']) {
    const ticks = simulate(mood, 'Inkling', 3000, 8);
    assert.ok(!ticks.some(t => t.key === 'h'), `${mood} smiled`);
    assert.ok(!ticks.some(t => t.hop), `${mood} hopped`);
  }
  const happy = simulate('happy', 'Inkling', 3000, 9); // 20 minutes
  const hops = happy.filter(t => t.hop).length;
  assert.ok(hops > 0 && hops / 20 < 20, `${hops} hops in 20 minutes`);
});

test('low moods sink to the seafloor, then follow the same lap every time', () => {
  const rand = seeded(10);
  const m = newMotion(12, 1);
  let steps = 0;
  while (!m.onRoute) { motionStep(m, 'sad', TL_SPRITES.Inkling, 0, rand); assert.ok(++steps < 40, 'never reached the seafloor'); }
  assert.deepEqual([m.x, m.y], [SEAFLOOR[0][0], SEAFLOOR[0][1]]);
  for (let lap = 0; lap < 2; lap++) {
    for (let i = 1; i <= SEAFLOOR.length; i++) {
      const r = motionStep(m, 'hungry', TL_SPRITES.Inkling, 0, rand);
      const [x, y, face] = SEAFLOOR[i % SEAFLOOR.length];
      assert.deepEqual([m.x, m.y, m.face], [x, y, face]);
      assert.equal(r.delay, MOTION.routeTick);
    }
  }
  assert.equal(SEAFLOOR.length * MOTION.routeTick, 24000, 'one lap should take 24 seconds');
});
