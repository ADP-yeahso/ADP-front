// 프로젝트 루트에서 JavaScriptCore 또는 Node.js로 실행한다.
const output = typeof print === 'function' ? print : console.log;
const source = typeof readFile === 'function'
  ? readFile('assets/www/main.js')
  : require('node:fs').readFileSync('assets/www/main.js', 'utf8');

const startup =
  "\ninit();\nqueueDiagnosticReport('viewer_initialized');\nrequestRender();";

if (!source.includes(startup)) {
  throw new Error('Update the test bootstrap for main.js.');
}

const testSource = source
  .replace(/^import .*;\r?$/gm, '')
  .replace(startup, '');

function expect(condition, message) {
  if (!condition) throw new Error(message);
}

function equal(actual, expected) {
  expect(
    actual === expected,
    'Unexpected value: ' + actual + ' !== ' + expected
  );
}

function tracked(extra = {}) {
  return {
    calls: 0,
    dispose() { this.calls++; },
    ...extra,
  };
}

class Bitmap {
  constructor() { this.calls = 0; }
  close() { this.calls++; }
}

class Vector {
  constructor(x = 0, y = 0, z = 0) { this.set(x, y, z); }
  set(x, y, z) {
    Object.assign(this, { x, y, z });
    return this;
  }
  copy(v) { return this.set(v.x, v.y, v.z); }
  clone() { return new Vector(this.x, this.y, this.z); }
  add(v) { return this.set(this.x + v.x, this.y + v.y, this.z + v.z); }
  setFromSphericalCoords(radius, phi, theta) {
    return this.set(
      radius * Math.sin(phi) * Math.sin(theta),
      radius * Math.cos(phi),
      radius * Math.sin(phi) * Math.cos(theta),
    );
  }
}

function geometry() {
  return tracked({
    clone: () => geometry(),
    applyMatrix4() {},
  });
}

function material(texture) {
  return tracked({
    map: texture,
    clone: () => material(texture),
  });
}

function asset(bitmap = new Bitmap()) {
  const texture = tracked({
    isTexture: true,
    source: { data: bitmap },
  });
  const g = geometry();
  const m = material(texture);
  const children = [{
    isMesh: true,
    geometry: g,
    material: m,
    matrixWorld: {},
    userData: {},
  }];

  const root = {
    position: new Vector(),
    rotation: new Vector(),
    scale: new Vector(),
    userData: {},
    updateMatrixWorld() {},
    removeFromParent() { this.parent?.remove(this); },
    traverse(fn) {
      fn(this);
      children.forEach(fn);
    },
    clear() { children.length = 0; },
  };

  return {
    scene: root,
    geometry: g,
    material: m,
    texture,
    bitmap,
  };
}

function runtime({ diagnostics = false } = {}) {
  const pending = [];
  const started = [];
  const instances = [];
  const events = [];
  const reports = [];
  const objects = [];
  const tweens = [];

  class Mesh {
    constructor(g, m, count) {
      Object.assign(this, {
        geometry: g,
        material: m,
        count,
        isMesh: true,
        isInstancedMesh: true,
        userData: {},
        instanceMatrix: {},
        calls: 0,
      });
      instances.push(this);
    }
    dispose() { this.calls++; }
    removeFromParent() { this.parent?.remove(this); }
    traverse(fn) { fn(this); }
    setMatrixAt() {}
    computeBoundingBox() {}
    computeBoundingSphere() {}
    updateWorldMatrix() {}
    getMatrixAt() {}
    applyMatrix4() {}
  }

  class Loader {
    load(url, ok, progress, fail) {
      started.push(url);
      pending.push({ url, ok, fail });
    }
  }

  const three = {
    Vector3: Vector,
    Mesh,
    Group: class {
      constructor() { this.children = []; }
      add(mesh) { this.children.push(mesh); }
      clear() { this.children = []; }
    },
    Matrix4: class { premultiply() { return this; } },
    Sphere: class { constructor() { this.radius = 1; } },
    MathUtils: {
      degToRad: degrees => degrees * Math.PI / 180,
      clamp: (value, min, max) => Math.max(min, Math.min(max, value)),
    },
    InstancedMesh: Mesh,
    Object3D: class {
      constructor() {
        this.position = new Vector();
        this.scale = new Vector();
        this.matrix = {};
      }
      lookAt() {}
      updateMatrix() {}
    },
    Box3: class {
      constructor() { this.min = { y: 0 }; }
      setFromObject() { return this; }
      getBoundingSphere(sphere) { return sphere; }
      getCenter(vector) { return vector.set(1, 0, 1); }
    },
  };

  const window = {
    location: { search: '' },
    FlutterChannel: {
      postMessage(value) {
        if (value.startsWith('GARDEN_DIAGNOSTICS:')) {
          reports.push(JSON.parse(value.slice('GARDEN_DIAGNOSTICS:'.length)));
        } else {
          events.push(JSON.parse(value.slice('GARDEN_EVENT:'.length)));
        }
      },
    },
  };

  const loading = { style: {}, replaceChildren() {} };
  const document = {
    getElementById: id => id === 'loading' ? loading : null,
    querySelectorAll: () => [],
  };

  // 실제 main.js를 실행하되 렌더러·통신·오류 UI만 대체한다.
  const api = new Function(
    'THREE', 'GLTFLoader', 'window', 'document', 'gsap',
    'ImageBitmap', 'URLSearchParams', 'console', 'objects',
    '"use strict";\n' + testSource + `
      requestRender = () => {};
      showGardenLoadError = () => {};

      scene = {
        removeFromParent() {},
        add(object) {
          objects.push(object);
          object.parent = this;
        },
        remove(object) {
          const index = objects.indexOf(object);
          if (index >= 0) objects.splice(index, 1);
          object.parent = null;
        },
        traverse(fn) {
          [...objects].forEach(object => object.traverse(fn));
        },
        clear() { objects.length = 0; },
      };

      camera = { position: new THREE.Vector3(), fov: 45, aspect: 1, lookAt() {} };
      controls = {
        target: new THREE.Vector3(),
        update() {},
        dispose() {},
      };
      renderer = {
        info: {
          memory: { geometries: 0, textures: 0 },
          render: { calls: 0, triangles: 0 },
          programs: [],
        },
        shadowMap: { enabled: false },
        renderLists: { dispose() {} },
        dispose() {},
        getContext: () => ({ getExtension: () => null }),
        domElement: { remove() {} },
      };

      return {
        dispose: disposeObject3Ds,
        resources: collectDiagnosticResources,
        report: window.reportGardenDiagnostics,
        build: createFlowerInstances,
        queue: (url, accept = () => true) =>
          queueModelLoad(url, gardenLoadId, accept),
        advance() {
          gardenLoadId++;
          cancelWaitingModelLoads();
        },
        init: window.initGarden,
        destroy: window.destroyGardenViewer,
        pause: window.pauseGarden,
        focus: index => focusOnFlower(flowerData[index]),
        browse: window.browseFlower,
        clear: window.clearGardenContent,
        reset: window.resetCamera,
        selection: () => ({
          ids: flowerData.map(data => data.diaryId),
          selected: selectedFlowerIndex,
          focusing: isFocusing,
          enabled: controls?.enabled,
          proxy: flowerBrowseGroup,
        }),
        state: () => ({
          active: activeModelLoads,
          waiting: modelLoadQueue.length,
          flowers: flowerMeshes.length,
          pending: pendingFlowerBatches.size,
        }),
      };
    `
  )(
    three, Loader, window, document, {
      killTweensOf() {},
      getTweensOf() { return []; },
      to(target, options) { tweens.push({ target, ...options }); },
    },
    Bitmap, class {
      get(key) { return key === 'diagnostics' && diagnostics ? '1' : null; }
    },
    { log() {}, warn() {}, error() {} }, objects
  );

  return {
    ...api,
    pending,
    started,
    instances,
    events,
    reports,
    objects,
    Mesh,
    tweens,
  };
}

const outcome = promise => promise.then(
  value => ({ value }),
  error => ({ error })
);

async function until(predicate) {
  for (let i = 0; i < 50 && !predicate(); i++) {
    await Promise.resolve();
  }
  expect(predicate(), 'Asynchronous transition did not finish');
}

let passed = 0;

async function test(name, run) {
  await run();
  passed++;
  output('PASS ' + name);
}

async function main() {
  await test('중복 리소스·인스턴스·skeleton 해제 방지', () => {
    const r = runtime();
    const a = asset();
    const skeleton = tracked();
    const first = new r.Mesh(a.geometry, [a.material, a.material], 1);
    const second = new r.Mesh(a.geometry, a.material, 1);

    [first, second].forEach(mesh => Object.assign(mesh, {
      isSkinnedMesh: true,
      skeleton,
    }));

    r.dispose([first, second]);
    r.dispose([first, second]);

    [
      a.geometry, a.material, a.texture, a.bitmap,
      first, second, skeleton,
    ].forEach(value => equal(value.calls, 1));
  });

  await test('여러 texture가 공유하는 bitmap을 한 번만 해제', () => {
    const r = runtime();
    const bitmap = new Bitmap();
    const a = asset(bitmap);
    const b = asset(bitmap);

    a.material.uniforms = {
      extra: { value: [b.texture] },
    };

    r.dispose([a.scene, b.scene]);
    r.dispose([a.scene, b.scene]);

    equal(a.texture.calls, 1);
    equal(b.texture.calls, 1);
    equal(bitmap.calls, 1);
  });

  await test('원본 texture를 꽃 인스턴스에 이전하고 마지막에 해제', () => {
    const r = runtime();
    const a = asset();
    const meshes = r.build(a, [{ id: 12 }], 1, false);

    equal(meshes.length, 1);
    equal(a.geometry.calls, 1);
    equal(a.material.calls, 1);
    equal(a.texture.calls, 0);
    equal(a.bitmap.calls, 0);
    equal(meshes[0].geometry.calls, 0);
    equal(meshes[0].material.calls, 0);

    r.dispose(meshes);
    r.dispose(meshes);

    [
      meshes[0], meshes[0].geometry, meshes[0].material,
      a.texture, a.bitmap,
    ].forEach(value => equal(value.calls, 1));
  });

  await test('결과 인수 완료까지 동시 로딩 1개 유지', async () => {
    const r = runtime();

    const first = r.queue('a', () => {
      equal(r.state().active, 1);
      equal(r.started.length, 1);
      return 'accepted';
    });
    const second = r.queue('b');

    equal(r.state().active, 1);
    equal(r.state().waiting, 1);

    r.pending.shift().ok(asset());
    equal(await first, 'accepted');
    equal(r.started.join(','), 'a,b');

    r.pending.shift().ok(asset());
    await second;

    equal(r.state().active, 0);
    equal(r.state().waiting, 0);
  });

  await test('이전 대기 작업 취소·늦은 결과 해제 후 슬롯 반환', async () => {
    const r = runtime();
    const late = asset();
    let accepted = 0;

    const first = outcome(
      r.queue('old-active', () => accepted++)
    );
    const waiting = outcome(r.queue('old-waiting'));

    r.advance();
    const latest = r.queue('latest');

    equal(r.started.join(','), 'old-active');
    equal(r.state().active, 1);
    equal((await waiting).error.name, 'StaleGardenLoadError');

    r.pending.shift().ok(late);

    equal((await first).error.name, 'StaleGardenLoadError');
    equal(accepted, 0);
    equal(late.geometry.calls, 1);
    equal(late.texture.calls, 1);
    equal(late.bitmap.calls, 1);
    equal(r.started.join(','), 'old-active,latest');

    r.pending.shift().ok(asset());
    await latest;
    equal(r.state().active, 0);
  });

  await test('인수 중 예외 발생 시 원본 회수·다음 작업 진행', async () => {
    const r = runtime();
    const a = asset();
    const first = outcome(r.queue('bad', () => {
      throw new Error('accept failed');
    }));
    const second = r.queue('next');

    r.pending.shift().ok(a);

    equal((await first).error.message, 'accept failed');
    equal(a.geometry.calls, 1);
    equal(a.material.calls, 1);
    equal(a.texture.calls, 1);
    equal(a.bitmap.calls, 1);
    equal(r.started.join(','), 'bad,next');

    r.pending.shift().ok(asset());
    await second;
    equal(r.state().active, 0);
  });

  await test('로더 실패 후 슬롯 반환·다음 작업 진행', async () => {
    const r = runtime();
    const first = outcome(r.queue('missing'));
    const next = r.queue('next');

    r.pending.shift().fail(new Error('404'));

    equal((await first).error.message, '404');
    equal(r.started.join(','), 'missing,next');

    r.pending.shift().ok(asset());
    await next;
    equal(r.state().active, 0);
  });

  await test('꽃 배치 일부 실패 시 성공한 꽃 회수·나무 유지', async () => {
    const r = runtime();
    const tree = asset();
    const flower = asset();

    r.init(
      'tree',
      '{"anger":["a","b"]}',
      '[{"id":0,"emotion":"anger"},{"id":1,"emotion":"anger"}]'
    );

    r.pending.shift().ok(tree);
    await until(() => r.pending[0]?.url === 'a');
    r.pending.shift().ok(flower);
    await until(() => r.pending[0]?.url === 'b');
    r.pending.shift().fail(new Error('broken model'));

    await until(() =>
      r.events.some(event => event.code === 'ERROR_FLOWER_BATCH')
    );

    equal(r.instances[0].calls, 1);
    equal(flower.texture.calls, 1);
    equal(flower.bitmap.calls, 1);
    equal(tree.geometry.calls, 0);
    equal(r.objects.length, 1);
    equal(r.state().flowers, 0);
    equal(r.state().pending, 0);
    equal(r.state().active, 0);
  });

  await test('월 이동 시 미인수 꽃과 늦게 도착한 이전 결과 회수', async () => {
    const r = runtime();
    const tree = asset();
    const first = asset();
    const late = asset();

    r.init(
      'tree',
      '{"anger":["a","b"]}',
      '[{"id":0,"emotion":"anger"},{"id":1,"emotion":"anger"}]'
    );

    r.pending.shift().ok(tree);
    await until(() => r.pending[0]?.url === 'a');
    r.pending.shift().ok(first);
    await until(() => r.pending[0]?.url === 'b');

    r.init('tree', '{}', '[]');

    equal(r.instances[0].calls, 1);
    equal(first.bitmap.calls, 1);
    equal(r.state().active, 1);

    r.pending.shift().ok(late);
    await until(() =>
      r.state().active === 0 && r.state().pending === 0
    );

    equal(late.geometry.calls, 1);
    equal(late.bitmap.calls, 1);
    equal(tree.geometry.calls, 0);
    equal(r.objects.length, 1);
    equal(r.state().flowers, 0);

    expect(
      !r.events.some(event => event.type === 'error'),
      'Old month produced an error'
    );
  });

  await test('중복 종료 안전·종료 후 늦은 결과 회수·신규 로딩 차단', async () => {
    const r = runtime();
    const late = asset();
    let accepted = 0;

    const active = outcome(r.queue('active', () => accepted++));
    const waiting = outcome(r.queue('waiting'));

    equal(r.destroy(), true);
    equal(r.destroy(), true);
    equal((await waiting).error.name, 'StaleGardenLoadError');
    equal(r.state().active, 1);

    r.pending.shift().ok(late);

    equal((await active).error.name, 'StaleGardenLoadError');
    equal(accepted, 0);
    equal(late.geometry.calls, 1);
    equal(late.bitmap.calls, 1);
    equal(r.state().active, 0);
    equal(r.state().waiting, 0);

    equal(
      (await outcome(r.queue('after-destroy'))).error.name,
      'StaleGardenLoadError'
    );
    equal(r.started.length, 1);
  });

  await test('모델별 배치 후 일기 순서·꽃 탐색 이벤트와 월 이동 정리 유지', async () => {
    const r = runtime();
    const tree = asset();
    const flowers = [asset(), asset()];
    r.init(
      'tree',
      '{"anger":["a","b"]}',
      '[{"id":1,"emotion":"anger"},{"id":0,"emotion":"anger"},{"id":3,"emotion":"anger"}]'
    );
    r.pending.shift().ok(tree);
    await until(() => r.pending[0]?.url === 'b');
    r.pending.shift().ok(flowers[0]);
    await until(() => r.pending[0]?.url === 'a');
    r.pending.shift().ok(flowers[1]);
    await until(() => r.state().flowers === 2);

    equal(r.selection().ids.join(','), '1,0,3');
    r.focus(0);
    let event = r.events.at(-1);
    equal(event.type, 'flowerBrowse');
    equal(event.diaryId, '1');
    equal(event.count, 3);
    expect(typeof event.sessionId === 'string', 'Selection lost the viewer session ID');
    r.tweens.at(-1).onComplete();
    equal(r.selection().focusing, false);

    r.browse(1);
    equal(r.events.at(-1).diaryId, '0');
    r.reset();
    equal(r.events.at(-1).type, 'gardenOverview');
    equal(r.selection().proxy, null);
    // Framing proxies share resources; returning to overview must not dispose them.
    flowers.forEach(flower => equal(flower.texture.calls, 0));

    r.focus(2);
    r.clear();
    equal(r.selection().ids.length, 0);
    equal(r.selection().selected, -1);
    equal(r.selection().proxy, null);
    flowers.forEach(flower => equal(flower.texture.calls, 1));
    equal(tree.geometry.calls, 0);
  });

  await test('화면 중단·종료 뒤 늦은 꽃 애니메이션 완료와 탐색 차단', async () => {
    const r = runtime();
    r.init('tree', '{"anger":["a"]}', '[{"id":0,"emotion":"anger"}]');
    r.pending.shift().ok(asset());
    await until(() => r.pending[0]?.url === 'a');
    r.pending.shift().ok(asset());
    await until(() => r.state().flowers === 1);

    r.focus(0);
    const completion = r.tweens.at(-1).onComplete;
    r.pause();
    completion();
    equal(r.selection().enabled, false);
    const eventCount = r.events.length;
    r.browse(1);
    equal(r.events.length, eventCount);
    r.destroy();
    completion();
    equal(r.selection().proxy, null);
    equal(r.selection().ids.length, 0);
  });

  await test('진단: 여러 파트와 중복 루트의 꽃·공유 자원을 한 번 집계', () => {
    const r = runtime();
    const a = asset();
    const mapping = [{ diaryId: 1 }, { diaryId: 2 }];
    const first = new r.Mesh(a.geometry, a.material, 2);
    const second = new r.Mesh(a.geometry, a.material, 2);
    [first, second].forEach(mesh => {
      mesh.userData = { isFlower: true, diaryMapping: mapping };
    });
    const resources = r.resources([first, first, second]);
    equal(resources.meshes, 2);
    equal(resources.geometries, 1);
    equal(resources.textures, 1);
    equal(resources.bitmaps, 1);
    equal(resources.instanceSlots, 4);
    equal(resources.logicalFlowers, 2);
  });

  await test('진단: scene 밖에서 대기하는 꽃을 집계하고 인수 후 중복 제거', async () => {
    const r = runtime({ diagnostics: true });
    r.init('tree', '{"anger":["a","b"]}',
      '[{"id":0,"emotion":"anger"},{"id":1,"emotion":"anger"}]');
    r.pending.shift().ok(asset());
    await until(() => r.pending[0]?.url === 'a');
    r.pending.shift().ok(asset());
    await until(() => r.pending[0]?.url === 'b');
    const pending = r.reports.at(-1);
    equal(pending.reason, 'flower_model_accepted');
    equal(pending.sceneFlowerCount, 0);
    equal(pending.pendingFlowerCount, 1);
    equal(pending.resources.logicalFlowers, 1);
    equal(pending.resources.meshes, 2);
    equal(pending.mappedDiaryCount, 2);
    r.pending.shift().ok(asset());
    await until(() => r.state().flowers === 2 && r.state().pending === 0);
    const status = r.report();
    equal(status.sceneFlowerCount, 2);
    equal(status.pendingFlowerCount, 0);
    equal(status.resources.logicalFlowers, 2);
    equal(r.reports.at(-1).schemaVersion, 2);
    expect(status.gardenLoadMs >= 0, 'Ready garden has no load duration');
  });

  await test('진단: 입력 수와 매핑 누락·scene 꽃 수를 구분', async () => {
    const r = runtime({ diagnostics: true });
    r.init('tree', '{"anger":["a"]}',
      '[{"id":0,"emotion":"anger"},{"id":1,"emotion":"unknown"},{"id":2,"emotion":""}]');
    r.pending.shift().ok(asset());
    await until(() => r.pending[0]?.url === 'a');
    r.pending.shift().ok(asset());
    await until(() => r.state().flowers === 1 && r.state().pending === 0);
    const status = r.report();
    equal(status.diaryCount, 3);
    equal(status.mappedDiaryCount, 1);
    equal(status.skippedDiaryCount, 2);
    equal(status.sceneFlowerCount, 1);
    r.clear();
    const cleared = r.report();
    equal(cleared.diaryCount, 0);
    equal(cleared.mappedDiaryCount, 0);
    equal(cleared.skippedDiaryCount, 0);
    equal(cleared.sceneFlowerCount, 0);
    equal(cleared.gardenLoadMs, null);
  });

  await test('진단: 종료 스냅샷과 종료 후 상태는 소유 자원 0', async () => {
    const r = runtime({ diagnostics: true });
    r.init('tree', '{}', '[]');
    r.pending.shift().ok(asset());
    await until(() => r.state().pending === 0);
    equal(r.destroy(), true);
    const report = r.reports.at(-1);
    equal(report.reason, 'viewer_destroyed');
    equal(report.resources.meshes, 0);
    equal(report.sceneFlowerCount, 0);
    equal(report.pendingFlowerCount, 0);
    equal(report.loading.waiting, 0);
    const status = r.report();
    equal(status.destroyed, true);
    equal(status.canvasCount, 0);
    equal(status.resources.geometries, 0);
  });

  output('All ' + passed + ' garden memory tests passed.');
}

let failure;

main().catch(error => {
  failure = error;
  output('FAIL ' + String(error));
  if (typeof process === 'object') process.exitCode = 1;
});

if (typeof drainMicrotasks === 'function') {
  drainMicrotasks();
  if (failure) throw failure;
  if (passed !== 16) {
    throw new Error('The test run did not finish.');
  }
}