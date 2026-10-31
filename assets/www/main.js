import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const diagnosticsEnabled =
  new URLSearchParams(window.location.search).get('diagnostics') === '1';

const diagnosticSessionId =
  globalThis.crypto?.randomUUID?.() ??
  `garden-${Date.now()}-${Math.random().toString(36).slice(2)}`;

function sendGardenEvent(type, payload = {}) {
  window.FlutterChannel?.postMessage(
    'GARDEN_EVENT:' + JSON.stringify({
      type,
      sessionId: diagnosticSessionId,
      ...payload,
    })
  );
}

const diagnosticState = {
  activeLoads: 0,
  peakActiveLoads: 0,
  diaryCount: 0,
  mappedDiaryCount: 0,
  skippedDiaryCount: 0,
  gardenStartedAtMs: null,
  gardenReadyAtMs: null,
  ownedEventListeners: 0,
};

let pendingDiagnosticReason = null;
const ownedEventRemovers = new Set();
const ownedGardenDelays = new Map();

function beginDiagnosticLoad() {
  if (!diagnosticsEnabled) return;

  diagnosticState.activeLoads += 1;
  diagnosticState.peakActiveLoads = Math.max(
    diagnosticState.peakActiveLoads,
    diagnosticState.activeLoads,
  );
}

function endDiagnosticLoad() {
  if (!diagnosticsEnabled) return;

  diagnosticState.activeLoads = Math.max(
    0,
    diagnosticState.activeLoads - 1,
  );
}

function addTrackedEventListener(target, type, listener, options) {
  target.addEventListener(type, listener, options);

  const remove = () => {
    if (!ownedEventRemovers.delete(remove)) {
      return;
    }

    target.removeEventListener(type, listener, options);
    diagnosticState.ownedEventListeners = ownedEventRemovers.size;
  };

  ownedEventRemovers.add(remove);
  diagnosticState.ownedEventListeners = ownedEventRemovers.size;

  return remove;
}

function removeOwnedEventListeners() {
  for (const remove of [...ownedEventRemovers]) {
    remove();
  }
}

function waitForGardenDelay(milliseconds) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      ownedGardenDelays.delete(timer);
      resolve();
    }, milliseconds);

    ownedGardenDelays.set(timer, resolve);
  });
}

function cancelGardenDelays() {
  const delays = [...ownedGardenDelays.entries()];
  ownedGardenDelays.clear();

  delays.forEach(([timer, resolve]) => {
    clearTimeout(timer);
    resolve();
  });
}

function queueDiagnosticReport(reason) {
  if (diagnosticsEnabled) {
    pendingDiagnosticReason = reason;
  }
}

function resetDiagnosticGardenCounts() {
  diagnosticState.diaryCount = 0;
  diagnosticState.mappedDiaryCount = 0;
  diagnosticState.skippedDiaryCount = 0;
  diagnosticState.gardenStartedAtMs = null;
  diagnosticState.gardenReadyAtMs = null;
}

function diagnosticGardenLoadMs() {
  if (
    diagnosticState.gardenStartedAtMs === null ||
    diagnosticState.gardenReadyAtMs === null
  ) {
    return null;
  }
  return diagnosticState.gardenReadyAtMs - diagnosticState.gardenStartedAtMs;
}

function seededUnit(seed) {
  const value = Math.sin(Number(seed) * 12.9898) * 43758.5453;
  return value - Math.floor(value);
}

let scene, camera, renderer, controls;
let raycaster, mouse;
let flowerMeshes = [];
let flowerData = [];
let worldTree;
let worldTreeUrl = null;
let treeLoadId = 0;
let treeLoadPromise = null;
let isFocusing = false;
let gardenLoadId = 0;
let isAssetPreview = false;
let flowerBrowseGroup = null;
let selectedFlowerIndex = -1;
let previewCatalogController = null;

// Preserve the original composition after its fixed polar angle was applied.
const defaultCameraPos = new THREE.Vector3().setFromSphericalCoords(
  Math.hypot(35, 50),
  Math.PI / 3.2,
  0,
);
const origin = new THREE.Vector3(0, 0, 0);
const defaultMinZoomDistance = 5;
const maxOrbitCenterRadius = 32; // Flowers are placed within 30 world units.
const zoomPointers = new Map();

let renderQueued = false;
let renderRunning = false;
let renderFrameId = null;
let viewerActive = true;
let viewerDestroyed = false;
let selectionId = 0;
let latestGardenRequest = null;
let viewerContextLost = false;
const pendingFlowerBatches = new Set();

function isGardenViewerActive() {
  return viewerActive && !viewerDestroyed && !viewerContextLost;
}

const MAX_CONCURRENT_MODEL_LOADS = 1;
const modelLoader = new GLTFLoader();
const modelLoadQueue = [];

let activeModelLoads = 0;

class StaleGardenLoadError extends Error {
  constructor() {
    super('Garden load was superseded by a newer generation.');
    this.name = 'StaleGardenLoadError';
  }
}

function queueModelLoad(
  url,
  generation,
  acceptResult,
  isCurrent = () => generation === gardenLoadId
) {
  return new Promise((resolve, reject) => {
    if (!isGardenViewerActive()) {
      reject(new StaleGardenLoadError());
      return;
    }
    modelLoadQueue.push({
      url,
      generation,
      acceptResult,
      isCurrent: () => isGardenViewerActive() && isCurrent(),
      resolve,
      reject,
    });

    drainModelLoadQueue();
  });
}

function cancelWaitingModelLoads() {
  const tasks = modelLoadQueue.splice(0);

  tasks.forEach((task) => {
    if (task.isCurrent()) {
      modelLoadQueue.push(task);
    } else {
      task.reject(new StaleGardenLoadError());
    }
  });
}

function cancelPreviewCatalogLoad() {
  const controller = previewCatalogController;
  previewCatalogController = null;
  controller?.abort();
}

function drainModelLoadQueue() {
  while (
    isGardenViewerActive() &&
    activeModelLoads < MAX_CONCURRENT_MODEL_LOADS &&
    modelLoadQueue.length > 0
  ) {
    const task = modelLoadQueue.shift();

    if (!task.isCurrent()) {
      task.reject(new StaleGardenLoadError());
      continue;
    }

    activeModelLoads += 1;
    beginDiagnosticLoad();

    let settled = false;

    const finish = (callback) => {
      if (settled) return;

      settled = true;
      activeModelLoads = Math.max(0, activeModelLoads - 1);
      endDiagnosticLoad();

      callback();
      drainModelLoadQueue();
    };

    try {
      modelLoader.load(
        task.url,
        (gltf) => {
          let acceptedResult;

          try {
            if (!task.isCurrent()) {
              throw new StaleGardenLoadError();
            }

            acceptedResult = task.acceptResult(gltf);
          } catch (error) {
            try {
              disposeObject3Ds([gltf.scene]);
            } finally {
              finish(() => {
                task.reject(error);
              });
            }

            return;
          }

          finish(() => {
            task.resolve(acceptedResult);
          });
        },
        undefined,
        (error) => {
          finish(() => {
            if (!task.isCurrent()) {
              task.reject(new StaleGardenLoadError());
              return;
            }

            task.reject(error);
          });
        },
      );
    } catch (error) {
      finish(() => {
        task.reject(error);
      });
    }
  }
}

init();
queueDiagnosticReport('viewer_initialized');
requestRender();

function init() {
  const container = document.getElementById('canvas-container');

  // Scene setup
  scene = new THREE.Scene();
  // HTML 배경 이미지 위에 나무와 꽃만 투명하게 합성한다.
  scene.background = null;

  // Camera setup
  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.copy(defaultCameraPos);

  // Renderer setup
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(
    Math.min(window.devicePixelRatio || 1, 2)
  );
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = false;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.setClearColor(0x000000, 0); // transparent
  container.appendChild(renderer.domElement);

  // Lighting (healing vibe)
  const hemiLight = new THREE.HemisphereLight(0xffffff, 0xffffff, 1.5);
  hemiLight.color.setHSL(0.6, 1, 0.6);
  hemiLight.groundColor.setHSL(0.095, 1, 0.75);
  hemiLight.position.set(0, 50, 0);
  scene.add(hemiLight);

  const dirLight = new THREE.DirectionalLight(0xffffff, 2);
  dirLight.color.setHSL(0.1, 1, 0.95);
  dirLight.position.set(-1, 1.75, 1);
  dirLight.position.multiplyScalar(30);
  dirLight.castShadow = false;
  scene.add(dirLight);

  createGardenGround();

  // OrbitControls
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.target.copy(origin);
  controls.enablePan = false; // Move the center through intentional zoom, not free panning.
  controls.zoomToCursor = true; // OrbitControls also uses the midpoint of a touch pinch.
  controls.screenSpacePanning = false; // Keep the moving orbit center on the garden plane.
  addTrackedEventListener(controls, 'change', () => {
    if (controls.enabled) constrainOrbitCenter();
    requestRender();
  });

  // 꽃 감상을 위한 근접 줌과 전체 정원까지의 축소 범위.
  controls.enableZoom = true;
  controls.minDistance = defaultMinZoomDistance;
  controls.maxDistance = 80; // 맵 밖으로 너무 멀어지지 않도록

  // 수직축 기준 45~70도: 기본 구도(56.25도)를 유지하면서 상하 탐색 허용.
  controls.minPolarAngle = THREE.MathUtils.degToRad(45);
  // Stay just above OrbitControls' 20-degree cursor-zoom horizon cutoff.
  controls.maxPolarAngle = THREE.MathUtils.degToRad(70) - 1e-6;
  controls.update();

  // Raycaster
  raycaster = new THREE.Raycaster();
  mouse = new THREE.Vector2();

  addTrackedEventListener(window, 'resize', onWindowResize);
  addTrackedEventListener(renderer.domElement, 'webglcontextlost', onGardenContextLost);
  addTrackedEventListener(renderer.domElement, 'webglcontextrestored', onGardenContextRestored);
  addTrackedEventListener(document, 'visibilitychange', onGardenVisibilityChange);
  addTrackedEventListener(window, 'pagehide', onGardenPageHide);
  // Capture before OrbitControls handles the second pointer, so zoom starts
  // with an approach limit for the flower/ground under the fingers.
  addTrackedEventListener(renderer.domElement, 'pointerdown', (event) => {
    if (event.pointerType !== 'touch' || !controls.enabled) return;
    zoomPointers.set(event.pointerId, new THREE.Vector2(event.clientX, event.clientY));
    if (zoomPointers.size === 2) {
      const [first, second] = zoomPointers.values();
      prepareZoomAt((first.x + second.x) / 2, (first.y + second.y) / 2);
    }
  }, { capture: true });
  addTrackedEventListener(renderer.domElement, 'pointermove', (event) => {
    zoomPointers.get(event.pointerId)?.set(event.clientX, event.clientY);
  }, { capture: true });
  const releaseZoomPointer = (event) => zoomPointers.delete(event.pointerId);
  addTrackedEventListener(renderer.domElement, 'pointerup', releaseZoomPointer, { capture: true });
  addTrackedEventListener(renderer.domElement, 'pointercancel', releaseZoomPointer, { capture: true });
  addTrackedEventListener(renderer.domElement, 'wheel', (event) => {
    if (controls.enabled) prepareZoomAt(event.clientX, event.clientY);
  }, { capture: true, passive: true });
  // Pointer events work in the WebView without a synthetic click. A drag or
  // multi-touch gesture must never select a flower, even if it ends at its start.
  let tap = null;
  addTrackedEventListener(renderer.domElement, 'pointerdown', (event) => {
    if (tap) {
      tap.cancelled = true;
      return;
    }
    if (isFocusing || event.button !== 0 || !event.isPrimary) return;
    tap = {
      pointerId: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      time: Date.now(),
      cancelled: false,
    };
  });
  addTrackedEventListener(renderer.domElement, 'pointermove', (event) => {
    if (!tap || event.pointerId !== tap.pointerId) return;
    if (Math.hypot(event.clientX - tap.x, event.clientY - tap.y) >= 10) {
      tap.cancelled = true;
    }
  });
  addTrackedEventListener(renderer.domElement, 'pointerup', (event) => {
    if (!tap || event.pointerId !== tap.pointerId) return;
    const isTap = !tap.cancelled && Date.now() - tap.time < 300 &&
      Math.hypot(event.clientX - tap.x, event.clientY - tap.y) < 10;
    tap = null;
    if (isTap) onClick(event);
  });
  addTrackedEventListener(renderer.domElement, 'pointercancel', () => { tap = null; });

  // Hide loading by default until data comes
  document.getElementById('loading').style.display = 'none';
}

// The near lawn lives on the same y=0 plane as the tree and flowers.
// Feather its distant edge into the PNG landscape instead of drawing a hard horizon.
function createGardenGround() {
  const makeRadialTexture = (stops, size) => {
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = size;
    const context = canvas.getContext('2d');
    const radius = size / 2;
    const gradient = context.createRadialGradient(
      radius, radius, 0, radius, radius, radius,
    );
    stops.forEach(([offset, color]) => gradient.addColorStop(offset, color));
    context.fillStyle = gradient;
    context.fillRect(0, 0, size, size);
    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    return texture;
  };

  // Exact RGB of background/floor.png; an unlit material preserves the match.
  const lawnTexture = makeRadialTexture([
    [0, 'rgba(147, 204, 107, 1)'],
    [0.67, 'rgba(147, 204, 107, 1)'],
    [0.84, 'rgba(147, 204, 107, 0.65)'],
    [1, 'rgba(147, 204, 107, 0)'],
  ], 512);
  const lawn = new THREE.Mesh(
    new THREE.PlaneGeometry(96, 96),
    new THREE.MeshBasicMaterial({
      map: lawnTexture, transparent: true, depthWrite: false,
    }),
  );
  lawn.rotation.x = -Math.PI / 2;
  lawn.position.y = -0.02;
  lawn.renderOrder = -2;
  scene.add(lawn);

  // A soft contact shadow anchors the trunk without a shadow-map render pass.
  const shadowTexture = makeRadialTexture([
    [0, 'rgba(49, 77, 30, 0.32)'],
    [0.3, 'rgba(49, 77, 30, 0.22)'],
    [0.65, 'rgba(49, 77, 30, 0.08)'],
    [1, 'rgba(49, 77, 30, 0)'],
  ], 128);
  const shadow = new THREE.Mesh(
    new THREE.PlaneGeometry(18, 14),
    new THREE.MeshBasicMaterial({
      map: shadowTexture, transparent: true, depthWrite: false,
    }),
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = -0.01;
  shadow.renderOrder = -1;
  shadow.raycast = () => {};
  scene.add(shadow);
}

function constrainOrbitCenter() {
  if (selectedFlowerIndex >= 0) return;
  const previous = controls.target.clone();
  controls.target.y = Math.max(0, controls.target.y);
  // Ignore floating point noise at the boundary so idle rendering can settle.
  if (controls.target.length() > maxOrbitCenterRadius + 1e-6) {
    controls.target.setLength(maxOrbitCenterRadius);
  }
  // Translate both together so reaching the garden edge does not tilt the view.
  camera.position.add(controls.target.clone().sub(previous));
}

function prepareZoomAt(clientX, clientY) {
  if (selectedFlowerIndex >= 0) return;
  clearOrbitMomentum();
  camera.updateMatrixWorld();
  scene.updateMatrixWorld(true);
  const rect = renderer.domElement.getBoundingClientRect();
  mouse.set(
    ((clientX - rect.left) / rect.width) * 2 - 1,
    -((clientY - rect.top) / rect.height) * 2 + 1,
  );
  raycaster.setFromCamera(mouse, camera);
  const hit = raycaster.intersectObjects(scene.children, true)[0];
  if (!hit) return; // Sky/empty space keeps the existing center and zoom limit.

  const flower = hit.object.userData.isFlower
    ? hit.object.userData.diaryMapping?.[hit.instanceId]
    : null;
  // Changing the flower under the fingers must not push an already-close
  // camera backwards just because the new flower has a larger framing limit.
  controls.minDistance = Math.min(
    flower?.minZoomDistance ?? defaultMinZoomDistance,
    controls.getDistance(),
  );
  controls.update();
}

function showGardenViewerRecovery(message) {
  if (viewerDestroyed) {
    return;
  }

  const loading = document.getElementById('loading');
  const text = document.createElement('div');
  text.textContent = message;

  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = '정원 다시 열기';
  button.style.marginTop = '8px';

  let retrying = false;

  button.onclick = (event) => {
    event.stopPropagation();

    if (viewerDestroyed || retrying) {
      return;
    }

    retrying = true;
    button.disabled = true;
    window.location.reload();
  };

  loading.replaceChildren(text, button);
  loading.style.pointerEvents = 'auto';
  loading.style.zIndex = '3';
  loading.style.textAlign = 'center';
  loading.style.display = 'block';
}

function onGardenContextLost(event) {
  if (viewerDestroyed) {
    return;
  }

  event.preventDefault();
  window.pauseGarden();
  viewerContextLost = true;

  showGardenViewerRecovery(
    '정원을 표시할 수 없어요. 다시 열어 주세요.'
  );

  emitDiagnosticReport('webgl_context_lost');
}

function onGardenContextRestored() {
  if (viewerDestroyed) {
    return;
  }

  viewerContextLost = false;

  // 자동 재시도 루프를 만들지 않고 사용자 재시도를 기다린다.
  showGardenViewerRecovery(
    '정원을 다시 열어 계속 이용해 주세요.'
  );

  emitDiagnosticReport('webgl_context_restored');
}

function onGardenVisibilityChange() {
  if (document.hidden) {
    window.pauseGarden();
  } else if (!window.FlutterChannel && !viewerDestroyed) {
    window.resumeGarden();
  }
}

function onGardenPageHide() {
  window.destroyGardenViewer();
}

function onWindowResize() {
  if (!isGardenViewerActive()) {
    return;
  }
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  if (flowerBrowseGroup) frameSelectedFlower();
  requestRender();
}

function showGardenLoadError(message, generation, retry) {
  if (
    !isGardenViewerActive() ||
    generation !== gardenLoadId
  ) {
    return;
  }

  const loading = document.getElementById('loading');

  const text = document.createElement('div');
  text.textContent = message;

  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = '다시 시도';
  button.style.marginTop = '8px';

  button.onclick = (event) => {
    event.stopPropagation();

    if (generation !== gardenLoadId) {
      return;
    }

    retry();
  };

  // 오류 UI를 눌러도 뒤쪽 나무나 꽃이 선택되지 않게 한다.
  loading.onclick = (event) => event.stopPropagation();
  loading.ontouchstart = (event) => event.stopPropagation();
  loading.ontouchend = (event) => event.stopPropagation();

  loading.replaceChildren(text, button);
  loading.style.pointerEvents = 'auto';
  loading.style.zIndex = '3';
  loading.style.textAlign = 'center';
  loading.style.display = 'block';
}

function createFlowerInstances(
  gltf,
  assignedDiaries,
  totalFlowerCount,
  assetPreview,
  modelUrl = ''
) {
  const baseFlower = gltf.scene;
  const numInstances = assignedDiaries.length;
  const modelFile = modelUrl.split('?')[0].split('/').pop();
  const flowerScale =
    modelFile === 'Gratitude_Marigold.glb' ? 0.106 : 0.2;
  const dummy = new THREE.Object3D();
  const createdMeshes = [];

  // 같은 꽃 모델의 모든 mesh 파트가 공유한다.
  const diaryMapping = [];

  try {
    baseFlower.position.set(0, 0, 0);
    baseFlower.rotation.set(0, 0, 0);
    baseFlower.scale.set(1, 1, 1);
    baseFlower.updateMatrixWorld(true);

    const baseBox = new THREE.Box3().setFromObject(baseFlower);
    const baseMinY = baseBox.min.y;
    const flowerRadius = baseBox.getBoundingSphere(new THREE.Sphere()).radius * flowerScale;
    const minZoomDistance = THREE.MathUtils.clamp(
      flowerRadius / Math.sin(THREE.MathUtils.degToRad(camera.fov / 2)) * 1.15,
      2.5,
      12,
    );

    baseFlower.traverse((child) => {
      if (!child.isMesh) {
        return;
      }

      const material = cloneMaterialOrMaterials(child.material);
      const geometry = child.geometry.clone();
      geometry.applyMatrix4(child.matrixWorld);

      const instancedMesh = new THREE.InstancedMesh(
        geometry,
        material,
        numInstances
      );

      instancedMesh.castShadow = false;
      instancedMesh.receiveShadow = false;
      instancedMesh.userData = {
        isFlower: true,
        diaryMapping,
      };

      createdMeshes.push(instancedMesh);
    });

    for (let index = 0; index < numInstances; index++) {
      const diary = assignedDiaries[index];

      const previewIndex = diary.previewIndex;
      const ringIndex =
        previewIndex < 8 ? previewIndex : previewIndex - 8;
      const ringCount =
        previewIndex < 8 ? 8 : totalFlowerCount - 8;

      const angleRandom = diagnosticsEnabled
        ? seededUnit(diary.id * 2 + 1)
        : Math.random();

      const radiusRandom = diagnosticsEnabled
        ? seededUnit(diary.id * 2 + 2)
        : Math.random();

      const angle = assetPreview
        ? (ringIndex / ringCount) * Math.PI * 2
        : angleRandom * Math.PI * 2;

      const radius = assetPreview
        ? (previewIndex < 8 ? 10 : 18)
        : 10 + radiusRandom * 20;

      dummy.position.set(
        Math.cos(angle) * radius,
        -(baseMinY * flowerScale),
        Math.sin(angle) * radius
      );
      dummy.scale.set(flowerScale, flowerScale, flowerScale);
      dummy.lookAt(origin);
      dummy.updateMatrix();

      // 위치 객체도 일기별로 한 번만 생성한다.
      diaryMapping[index] = {
        diaryId: diary.id,
        position: dummy.position.clone(),
        minZoomDistance,
        meshes: createdMeshes,
        instanceIndex: index,
        previewLabel: diary.previewLabel,
      };

      createdMeshes.forEach((instancedMesh) => {
        instancedMesh.setMatrixAt(index, dummy.matrix);
      });
    }

    createdMeshes.forEach((instancedMesh) => {
      instancedMesh.instanceMatrix.needsUpdate = true;
      instancedMesh.computeBoundingBox();
      instancedMesh.computeBoundingSphere();
    });

    // 원본 geometry/material을 정리한다.
    const sourceContext = createDisposalContext();
    disposeObject3D(baseFlower, sourceContext);

    // texture는 복제된 재질이 계속 사용하므로 해제 대상에서 제외한다.
    // 이후 꽃 인스턴스가 정리될 때 공통 해제 함수가 회수한다.
    sourceContext.textures.clear();

    finalizeDisposalContext(sourceContext);
    baseFlower.clear();

    return createdMeshes;
  } catch (error) {
    disposeObject3Ds(createdMeshes);
    throw error;
  }
}

function invalidateWorldTree() {
  treeLoadId++;
  treeLoadPromise = null;
  worldTreeUrl = null;

  const oldTree = worldTree;
  worldTree = null;

  if (oldTree) {
    disposeObject3Ds([oldTree]);
  }
}

function ensureWorldTree(treeUrl) {
  if (worldTree && worldTreeUrl === treeUrl) {
    emitDiagnosticReport('tree_reused');
    return Promise.resolve(worldTree);
  }

  if (treeLoadPromise && worldTreeUrl === treeUrl) {
    emitDiagnosticReport('tree_load_shared');
    return treeLoadPromise;
  }

  invalidateWorldTree();
  cancelWaitingModelLoads();

  worldTreeUrl = treeUrl;

  const currentTreeLoadId = treeLoadId;
  const isCurrentTree = () => (
    currentTreeLoadId === treeLoadId &&
    worldTreeUrl === treeUrl
  );

  queueDiagnosticReport('tree_load_started');
  requestRender();

  const promise = queueModelLoad(
    treeUrl,
    gardenLoadId,
    (gltf) => {
      const tree = gltf.scene;

      tree.position.set(0, 0, 0);
      tree.scale.set(1.1, 1.1, 1.1);
      tree.updateMatrixWorld(true);

      const treeBounds = new THREE.Box3().setFromObject(tree);
      tree.position.y -= treeBounds.min.y;

      tree.userData = { isTree: true };

      tree.traverse((child) => {
        if (child.isMesh) {
          child.castShadow = false;
          child.receiveShadow = false;
        }
      });

      scene.add(tree);
      worldTree = tree;
      requestRender();

      return tree;
    },
    isCurrentTree
  ).finally(() => {
    if (treeLoadPromise === promise) {
      treeLoadPromise = null;
    }
  });

  treeLoadPromise = promise;
  return promise;
}

window.initGarden = function (
  treeUrl,
  flowerUrlsMapJson,
  diariesJson,
  assetPreview = false
) {
  if (viewerDestroyed) {
    return;
  }

  latestGardenRequest = {
    kind: 'garden',
    treeUrl,
    flowerUrlsMapJson,
    diariesJson,
    assetPreview,
  };

  if (!isGardenViewerActive()) {
    return;
  }
  window.clearGardenContent();

  const currentLoadId = gardenLoadId;
  isAssetPreview = assetPreview;

  const loading = document.getElementById('loading');
  loading.textContent = '정원을 가꾸는 중...';
  loading.style.pointerEvents = 'none';
  loading.style.display = 'block';

  const retryGarden = () => {
    if (currentLoadId !== gardenLoadId) {
      return;
    }

    window.initGarden(
      treeUrl,
      flowerUrlsMapJson,
      diariesJson,
      assetPreview
    );
  };

  const loadGarden = async () => {
    const pendingFlowerMeshes = [];
    pendingFlowerBatches.add(pendingFlowerMeshes);
    let stage = 'data';

    try {
      const diaries = JSON.parse(diariesJson);
      const flowerUrlsMap = JSON.parse(flowerUrlsMapJson);

      if (
        !Array.isArray(diaries) ||
        !flowerUrlsMap ||
        typeof flowerUrlsMap !== 'object' ||
        Array.isArray(flowerUrlsMap)
      ) {
        throw new Error('Invalid garden data.');
      }

      diagnosticState.diaryCount = diaries.length;
      diagnosticState.gardenStartedAtMs = Date.now();

      stage = 'tree';
      await ensureWorldTree(treeUrl);

      if (currentLoadId !== gardenLoadId) {
        throw new StaleGardenLoadError();
      }

      if (diaries.length === 0) {
        loading.style.display = 'none';
        diagnosticState.gardenReadyAtMs = Date.now();
        queueDiagnosticReport('garden_ready_zero');
        requestRender();
        return;
      }

      stage = 'flower';

      const diariesByUrl = Object.create(null);

      diaries.forEach((diary) => {
        const emotion = typeof diary?.emotion === 'string'
          ? diary.emotion.trim().toLowerCase()
          : '';

        if (!emotion) {
          return;
        }

        const urls = flowerUrlsMap[emotion];

        if (!Array.isArray(urls) || urls.length === 0) {
          console.warn(`No flower mapping for emotion: ${emotion}`);
          return;
        }

        const url = urls[diary.id % urls.length];

        if (!diariesByUrl[url]) {
          diariesByUrl[url] = [];
        }

        diariesByUrl[url].push(diary);
      });

      diagnosticState.mappedDiaryCount = Object.values(diariesByUrl)
        .reduce((count, entries) => count + entries.length, 0);
      diagnosticState.skippedDiaryCount =
        diaries.length - diagnosticState.mappedDiaryCount;

      queueDiagnosticReport('flower_loads_started');
      requestRender();

      for (const url of Object.keys(diariesByUrl)) {
        if (currentLoadId !== gardenLoadId) {
          throw new StaleGardenLoadError();
        }

        const createdMeshes = await queueModelLoad(
          url,
          currentLoadId,
          (gltf) => createFlowerInstances(
            gltf,
            diariesByUrl[url],
            diaries.length,
            assetPreview,
            url
          )
        );

        if (currentLoadId !== gardenLoadId) {
          disposeObject3Ds(createdMeshes);
          throw new StaleGardenLoadError();
        }

        pendingFlowerMeshes.push(...createdMeshes);
        emitDiagnosticReport('flower_model_accepted');
      }

      if (currentLoadId !== gardenLoadId) {
        throw new StaleGardenLoadError();
      }

      pendingFlowerMeshes.forEach((mesh) => {
        scene.add(mesh);
      });

      flowerMeshes = pendingFlowerMeshes;
      const diaryOrder = new Map(diaries.map((diary, index) => [String(diary.id), index]));
      const mappings = new Set(pendingFlowerMeshes.map(mesh => mesh.userData.diaryMapping));
      flowerData = [...mappings].flat().filter(data => (
        assetPreview || !String(data.diaryId).startsWith('dummy')
      ));
      flowerData.sort((a, b) => diaryOrder.get(String(a.diaryId)) - diaryOrder.get(String(b.diaryId)));

      loading.style.display = 'none';
      diagnosticState.gardenReadyAtMs = Date.now();
      queueDiagnosticReport('garden_ready');
      requestRender();
    } catch (error) {
      disposeObject3Ds(pendingFlowerMeshes);

      if (
        error instanceof StaleGardenLoadError ||
        currentLoadId !== gardenLoadId
      ) {
        return;
      }

      const errors = {
        data: [
          'ERROR_GARDEN_DATA',
          '정원 데이터를 불러오지 못했어요.',
          'garden_data_error',
        ],
        tree: [
          'ERROR_TREE',
          '나무를 불러오지 못했어요.',
          'tree_load_error',
        ],
        flower: [
          'ERROR_FLOWER_BATCH',
          '꽃을 불러오지 못했어요.',
          'flower_batch_error',
        ],
      };

      const [code, message, reason] = errors[stage];
      console.error(code, error);

      sendGardenEvent('error', {
        code,
        message,
        detail: String(error),
      });

      showGardenLoadError(
        message,
        currentLoadId,
        retryGarden
      );

      queueDiagnosticReport(reason);
      requestRender();
    } finally {
      pendingFlowerBatches.delete(pendingFlowerMeshes);
    }
  };

  loadGarden();
};

function onClick(event) {
  if (!isGardenViewerActive() || isFocusing) {
    return;
  }

  mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

  raycaster.setFromCamera(mouse, camera);

  if (flowerBrowseGroup) {
    // Use the original garden instances, including tree occlusion, for taps.
    const hit = raycaster.intersectObjects(scene.children, true)[0];
    const data = hit?.object.userData.isFlower
      ? hit.object.userData.diaryMapping?.[hit.instanceId]
      : null;
    if (data === flowerData[selectedFlowerIndex] && !isAssetPreview) {
      isFocusing = true;
      stopCameraMotion();
      sendGardenEvent('openDiary', {
        diaryId: String(flowerData[selectedFlowerIndex].diaryId),
      });
    }
    return;
  }

  // We raycast against all objects
  const intersects = raycaster.intersectObjects(scene.children, true);

  for (let i = 0; i < intersects.length; i++) {
    let object = intersects[i].object;

    // Check if it's a flower InstancedMesh
    if (object.userData && object.userData.isFlower) {
      const instanceId = intersects[i].instanceId;
      if (instanceId !== undefined) {
        const data = object.userData.diaryMapping ? object.userData.diaryMapping[instanceId] : undefined;
        if (data) {
          if (data.previewLabel) {
            showPreviewSelection(data.previewLabel);
            focusOnFlower(data);
            break;
          }
          if (String(data.diaryId).startsWith('dummy')) {
            break; // Ignore dummy clicks
          }
          focusOnFlower(data);
          break; // Stop raycast loop
        }
      }
    }

    // Walk up to find if it's the tree
    let parent = object;
    while (parent && !parent.userData?.isTree && parent.parent) {
      parent = parent.parent;
    }

    if (parent && parent.userData?.isTree) {
      if (isAssetPreview) break;
      focusOnTree(parent);
      break;
    }
  }
}

function beginGardenSelection() {
  const generation = gardenLoadId;
  const token = ++selectionId;

  gsap.killTweensOf(camera.position);
  gsap.killTweensOf(controls.target);

  return () => (
    isGardenViewerActive() &&
    generation === gardenLoadId &&
    token === selectionId
  );
}

function stopCameraMotion() {
  controls.enabled = false;
  zoomPointers.clear();
  gsap.killTweensOf(camera.position);
  gsap.killTweensOf(controls.target);
  clearOrbitMomentum();
}

function clearOrbitMomentum() {
  // Flush OrbitControls' remaining inertia, then restore the visible pose.
  // Programmatic transitions own the camera and must not inherit a drag.
  const position = camera.position.clone();
  const target = controls.target.clone();
  controls.enableDamping = false;
  controls.update();
  controls.enableDamping = true;
  camera.position.copy(position);
  controls.target.copy(target);
  camera.lookAt(target);
}

function focusOnFlower(fData) {
  if (!isGardenViewerActive()) return;
  const index = flowerData.indexOf(fData);
  if (index < 0) return;
  isFocusing = true;
  stopCameraMotion();

  // This unrendered group only measures the selected instance for framing.
  // Keep the original flower, tree and surrounding garden in place and visible.
  if (flowerBrowseGroup) {
    flowerBrowseGroup.clear();
  }
  flowerBrowseGroup = new THREE.Group();
  const matrix = new THREE.Matrix4();
  fData.meshes.forEach((source) => {
    source.updateWorldMatrix(true, false);
    source.getMatrixAt(fData.instanceIndex, matrix);
    matrix.premultiply(source.matrixWorld);
    const flower = new THREE.Mesh(source.geometry, source.material);
    flower.applyMatrix4(matrix);
    flower.castShadow = true;
    flower.receiveShadow = true;
    flowerBrowseGroup.add(flower);
  });
  selectedFlowerIndex = index;
  controls.zoomToCursor = false;
  notifyFlowerBrowse();
  frameSelectedFlower();
}

function notifyFlowerBrowse() {
  sendGardenEvent('flowerBrowse', {
    diaryId: String(flowerData[selectedFlowerIndex].diaryId),
    index: selectedFlowerIndex,
    count: flowerData.length,
  });
}

function frameSelectedFlower() {
  const isCurrentSelection = beginGardenSelection();
  isFocusing = true;
  stopCameraMotion();
  const bounds = new THREE.Box3().setFromObject(flowerBrowseGroup);
  const center = bounds.getCenter(new THREE.Vector3());
  const radius = Math.max(bounds.getBoundingSphere(new THREE.Sphere()).radius, 0.1);
  const verticalHalfFov = THREE.MathUtils.degToRad(camera.fov / 2);
  const horizontalHalfFov = Math.atan(Math.tan(verticalHalfFov) * camera.aspect);
  // Keep the full flower clear of the date and navigation controls.
  const distance = radius / Math.sin(Math.min(verticalHalfFov * 0.48, horizontalHalfFov * 0.7));
  // Approach from outside the flower ring so the camera stays away from the
  // tree trunk while the tree remains in the background.
  const azimuth = Math.atan2(center.x - origin.x, center.z - origin.z);
  const offset = new THREE.Vector3().setFromSphericalCoords(distance, Math.PI / 3, azimuth);
  const targetCamPos = center.clone().add(offset);
  controls.minDistance = Math.max(radius * 1.5, 0.3);
  controls.maxDistance = distance * 2;

  gsap.to(camera.position, {
    x: targetCamPos.x,
    y: targetCamPos.y,
    z: targetCamPos.z,
    duration: 0.65,
    ease: "power3.inOut",
    onUpdate: requestRender,
  });

  gsap.to(controls.target, {
    x: center.x,
    y: center.y,
    z: center.z,
    duration: 0.65,
    ease: "power3.inOut",
    onUpdate: requestRender,
    onComplete: () => {
      if (!isCurrentSelection()) return;
      isFocusing = false;
      controls.enabled = true;
      controls.update();
      requestRender();
    }
  });
}

window.browseFlower = function (direction) {
  if (!isGardenViewerActive() || selectedFlowerIndex < 0 || flowerData.length < 2) return;
  const index = (selectedFlowerIndex + (direction < 0 ? -1 : 1) + flowerData.length) % flowerData.length;
  const data = flowerData[index];
  if (data.previewLabel) showPreviewSelection(data.previewLabel);
  focusOnFlower(data);
};

window.resumeFlowerBrowse = function () {
  if (!isGardenViewerActive() || !flowerBrowseGroup) return;
  isFocusing = false;
  controls.enabled = true;
  controls.update();
  requestRender();
};

function leaveFlowerBrowse() {
  const wasBrowsing = selectedFlowerIndex >= 0;
  if (flowerBrowseGroup) {
    // The framing proxy shares the garden's geometry and materials.
    flowerBrowseGroup.clear();
    flowerBrowseGroup = null;
  }
  selectedFlowerIndex = -1;
  if (controls) {
    controls.zoomToCursor = true;
    controls.minDistance = defaultMinZoomDistance;
    controls.maxDistance = 80;
  }
  const panel = document.getElementById('preview-selection');
  if (panel) panel.style.display = 'none';
  if (wasBrowsing) {
    sendGardenEvent('gardenOverview');
  }
  return wasBrowsing;
}

function focusOnTree(treeObj) {
  if (!isGardenViewerActive()) {
    return;
  }

  const isCurrentSelection = beginGardenSelection();
  isFocusing = true;
  stopCameraMotion();

  // Tree is at origin, just zoom in
  const targetCamPos = new THREE.Vector3(0, 10, 20);

  gsap.to(camera.position, {
    x: targetCamPos.x,
    y: targetCamPos.y,
    z: targetCamPos.z,
    duration: 1.5,
    ease: "power3.inOut",
    onUpdate: requestRender,
  });

  gsap.to(controls.target, {
    x: origin.x,
    y: origin.y,
    z: origin.z,
    duration: 1.5,
    ease: "power3.inOut",
    onUpdate: requestRender,
    onComplete: () => {
      if (!isCurrentSelection()) {
        return;
      }
      if (window.FlutterChannel) {
        sendGardenEvent('tree');
      }
    }
  });
}

window.resetCamera = function () {
  if (!isGardenViewerActive()) {
    return;
  }

  const isCurrentSelection = beginGardenSelection();
  isFocusing = true;
  stopCameraMotion();
  leaveFlowerBrowse();
  controls.minDistance = defaultMinZoomDistance;

  // Tween back to default position
  gsap.to(camera.position, {
    x: defaultCameraPos.x,
    y: defaultCameraPos.y,
    z: defaultCameraPos.z,
    duration: 1.5,
    ease: "power3.inOut",
    onUpdate: requestRender,
  });

  gsap.to(controls.target, {
    x: origin.x,
    y: origin.y,
    z: origin.z,
    duration: 1.5,
    ease: "power3.inOut",
    onUpdate: requestRender,
    onComplete: () => {
      if (!isCurrentSelection()) {
        return;
      }
      isFocusing = false;
      controls.enabled = true;
      controls.update();
      requestRender();
    }
  });
};

function cancelGardenRender() {
  if (renderFrameId !== null) {
    cancelAnimationFrame(renderFrameId);
    renderFrameId = null;
  }

  renderQueued = false;
  pendingDiagnosticReason = null;
}

function requestRender() {
  if (
    !isGardenViewerActive() ||
    !scene ||
    !camera ||
    !renderer ||
    !controls ||
    renderQueued ||
    renderRunning
  ) {
    return;
  }

  renderQueued = true;

  renderFrameId = requestAnimationFrame(() => {
    renderFrameId = null;
    renderQueued = false;

    if (!isGardenViewerActive()) {
      return;
    }

    renderRunning = true;
    let controlsChanged = false;

    try {
      // Focus/reset animations may be closer than minDistance or outside the
      // browsing angles. Look at the animated target without clamping their pose.
      if (controls.enabled) {
        const previousPosition = camera.position.clone();
        const previousRotation = camera.quaternion.clone();
        const previousTarget = controls.target.clone();
        controls.update();
        // r160 can report target changes caused only by floating point noise
        // once cursor zoom moves it off the origin. Do not render forever at rest.
        controlsChanged = previousPosition.distanceToSquared(camera.position) > 1e-6 ||
          8 * (1 - previousRotation.dot(camera.quaternion)) > 1e-6 ||
          previousTarget.distanceToSquared(controls.target) > 1e-6;
      } else {
        camera.lookAt(controls.target);
      }

      if (!isGardenViewerActive()) {
        return;
      }

      renderer.render(scene, camera);

      if (pendingDiagnosticReason !== null) {
        const reason = pendingDiagnosticReason;
        pendingDiagnosticReason = null;
        emitDiagnosticReport(reason);
      }
    } catch (error) {
      console.error('Garden render failed', error);
      window.pauseGarden?.();

      sendGardenEvent('error', {
        code: 'ERROR_RENDER',
        message: '정원을 표시하지 못했어요.',
        detail: String(error),
      });

      return;
    } finally {
      renderRunning = false;
    }

    if (controlsChanged) {
      requestRender();
    }
  });
}

function cloneMaterialOrMaterials(materialOrMaterials) {
  if (Array.isArray(materialOrMaterials)) {
    return materialOrMaterials.map((material) => (
      material?.clone() ?? new THREE.MeshStandardMaterial()
    ));
  }

  return materialOrMaterials?.clone()
    ?? new THREE.MeshStandardMaterial();
}

function forEachMaterial(materialOrMaterials, callback) {
  const materials = Array.isArray(materialOrMaterials)
    ? materialOrMaterials
    : [materialOrMaterials];

  materials.forEach((material) => {
    if (material) {
      callback(material);
    }
  });
}

function collectTextureValue(value, textures) {
  if (value?.isTexture) {
    textures.add(value);
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((item) => {
      collectTextureValue(item, textures);
    });
  }
}

function collectMaterialTextures(material, textures) {
  Object.values(material).forEach((value) => {
    collectTextureValue(value, textures);
  });

  if (!material.uniforms) return;

  Object.values(material.uniforms).forEach((uniform) => {
    collectTextureValue(uniform?.value, textures);
  });
}

function collectImageBitmapValue(value, bitmaps) {
  if (typeof ImageBitmap === 'undefined') return;

  if (value instanceof ImageBitmap) {
    bitmaps.add(value);
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((item) => {
      collectImageBitmapValue(item, bitmaps);
    });
  }
}

function collectTextureBitmaps(texture, bitmaps) {
  collectImageBitmapValue(texture?.source?.data, bitmaps);
}

function collectDiagnosticResources(roots = [scene]) {
  const seenObjects = new Set();
  const geometries = new Set();
  const materials = new Set();
  const textures = new Set();
  const bitmaps = new Set();
  const logicalFlowers = new Set();

  let meshes = 0;
  let instancedMeshes = 0;
  let instanceSlots = 0;

  const collect = (object) => {
    if (!object.isMesh || seenObjects.has(object)) return;
    seenObjects.add(object);
    meshes += 1;

    if (object.geometry) geometries.add(object.geometry);

    forEachMaterial(object.material, (material) => {
      materials.add(material);
      collectMaterialTextures(material, textures);
    });

    if (object.isInstancedMesh) {
      instancedMeshes += 1;
      instanceSlots += object.count;

      if (object.userData?.isFlower) {
        for (let index = 0; index < object.count; index++) {
          const mapping = object.userData.diaryMapping?.[index];
          if (mapping) logicalFlowers.add(mapping);
        }
      }
    }
  };

  roots.forEach((root) => root?.traverse(collect));
  textures.forEach((texture) => collectTextureBitmaps(texture, bitmaps));

  return {
    meshes,
    geometries: geometries.size,
    materials: materials.size,
    textures: textures.size,
    bitmaps: bitmaps.size,
    instancedMeshes,
    instanceSlots,
    logicalFlowers: logicalFlowers.size,
  };
}

function collectDiagnosticSnapshot() {
  const pendingRoots = [...pendingFlowerBatches].flat();
  return {
    resources: collectDiagnosticResources([scene, ...pendingRoots]),
    sceneResources: collectDiagnosticResources(),
    pendingResources: collectDiagnosticResources(pendingRoots),
  };
}

function emitDiagnosticReport(reason) {
  if (!diagnosticsEnabled || !renderer || !scene) return;

  const snapshot = collectDiagnosticSnapshot();
  const rendererMemory = renderer.info.memory;
  const rendererRender = renderer.info.render;
  let shadowCasters = 0;
  let shadowReceivers = 0;
  let shadowRenderTargets = 0;

  scene.traverse((object) => {
    if (object.castShadow) shadowCasters += 1;
    if (object.receiveShadow) shadowReceivers += 1;

    if (object.isLight) {
      if (object.shadow?.map) shadowRenderTargets += 1;
      if (object.shadow?.mapPass) shadowRenderTargets += 1;
    }
  });

  const report = {
    type: 'garden_diagnostics',
    schemaVersion: 2,
    timestampMs: Date.now(),
    reason,
    sessionId: diagnosticSessionId,
    generation: gardenLoadId,
    diaryCount: diagnosticState.diaryCount,
    mappedDiaryCount: diagnosticState.mappedDiaryCount,
    skippedDiaryCount: diagnosticState.skippedDiaryCount,
    sceneFlowerCount: snapshot.sceneResources.logicalFlowers,
    pendingFlowerCount: snapshot.pendingResources.logicalFlowers,
    gardenLoadMs: diagnosticGardenLoadMs(),
    loading: {
      active: diagnosticState.activeLoads,
      waiting: modelLoadQueue.length,
      peakActive: diagnosticState.peakActiveLoads,
    },
    ...snapshot,
    renderer: {
      geometries: rendererMemory.geometries,
      textures: rendererMemory.textures,
      programs: renderer.info.programs?.length ?? 0,
      drawCalls: rendererRender.calls,
      triangles: rendererRender.triangles,
    },
    shadows: {
      rendererEnabled: renderer.shadowMap.enabled,
      casters: shadowCasters,
      receivers: shadowReceivers,
      renderTargets: shadowRenderTargets,
    },
    activity: {
      eventListeners: diagnosticState.ownedEventListeners,
      timers:
        ownedGardenDelays.size +
        Number(window.__gardenPendingInitTimers || 0),
      rafQueued: Number(renderQueued),
      rafRunning: Number(renderRunning),
      tweens: gsap.getTweensOf([
        camera.position,
        controls.target,
      ]).length,
    },
  };

  const message = `GARDEN_DIAGNOSTICS:${JSON.stringify(report)}`;

  console.log(message);

  if (window.FlutterChannel) {
    window.FlutterChannel.postMessage(message);
  }
}

const disposedInstancedMeshes = new WeakSet();
const disposedSkeletons = new WeakSet();
const disposedGeometries = new WeakSet();
const disposedMaterials = new WeakSet();
const disposedTextures = new WeakSet();
const closedBitmaps = new WeakSet();

function createDisposalContext() {
  return {
    instancedMeshes: new Set(),
    skeletons: new Set(),
    geometries: new Set(),
    materials: new Set(),
    textures: new Set(),
    bitmaps: new Set(),
    finalized: false,
  };
}

function disposeObject3D(root, context) {
  if (!root) return;

  root.removeFromParent();

  root.traverse((child) => {
    child.userData = {};

    if (!child.isMesh) return;

    if (
      child.isInstancedMesh &&
      !context.instancedMeshes.has(child)
    ) {
      context.instancedMeshes.add(child);

      if (!disposedInstancedMeshes.has(child)) {
        child.dispose();
        disposedInstancedMeshes.add(child);
      }
    }

    if (
      child.isSkinnedMesh &&
      child.skeleton &&
      !context.skeletons.has(child.skeleton)
    ) {
      context.skeletons.add(child.skeleton);
      if (!disposedSkeletons.has(child.skeleton)) {
        child.skeleton.dispose();
        disposedSkeletons.add(child.skeleton);
      }
    }

    const geometry = child.geometry;

    if (geometry && !context.geometries.has(geometry)) {
      context.geometries.add(geometry);

      if (!disposedGeometries.has(geometry)) {
        geometry.dispose();
        disposedGeometries.add(geometry);
      }
    }

    forEachMaterial(child.material, (material) => {
      collectMaterialTextures(material, context.textures);

      if (context.materials.has(material)) return;

      context.materials.add(material);

      if (!disposedMaterials.has(material)) {
        material.dispose();
        disposedMaterials.add(material);
      }
    });
  });
}

function finalizeDisposalContext(context) {
  if (context.finalized) return;

  context.textures.forEach((texture) => {
    collectTextureBitmaps(texture, context.bitmaps);

    if (!disposedTextures.has(texture)) {
      texture.dispose();
      disposedTextures.add(texture);
    }
  });

  context.bitmaps.forEach((bitmap) => {
    if (closedBitmaps.has(bitmap)) return;

    try {
      bitmap.close();
      closedBitmaps.add(bitmap);
    } catch (error) {
      console.warn('Failed to close ImageBitmap', error);
    }
  });

  context.finalized = true;
}

function disposeObject3Ds(roots) {
  const context = createDisposalContext();

  roots.forEach((root) => {
    disposeObject3D(root, context);
  });

  finalizeDisposalContext(context);
}

window.clearGardenContent = function () {
  if (viewerDestroyed) {
    return;
  }
  gardenLoadId++;
  selectionId++;
  zoomPointers.clear();
  leaveFlowerBrowse();
  cancelWaitingModelLoads();
  cancelPreviewCatalogLoad();
  cancelGardenDelays();
  disposePendingFlowerBatches();

  const loading = document.getElementById('loading');
  loading.replaceChildren();
  loading.style.pointerEvents = 'none';
  loading.style.display = 'none';

  const panel = document.getElementById('preview-selection');
  if (panel) {
    panel.style.display = 'none';
  }

  gsap.killTweensOf(camera.position);
  gsap.killTweensOf(controls.target);

  isFocusing = false;
  controls.enabled = isGardenViewerActive();

  camera.position.copy(defaultCameraPos);
  controls.target.copy(origin);
  controls.update();

  const oldFlowers = flowerMeshes;
  flowerData = [];
  flowerMeshes = [];
  disposeObject3Ds(oldFlowers);

  resetDiagnosticGardenCounts();
  renderer.renderLists?.dispose();
  requestRender();
};

function disposePendingFlowerBatches() {
  const roots = [];

  pendingFlowerBatches.forEach((batch) => {
    roots.push(...batch);
    batch.length = 0;
  });

  pendingFlowerBatches.clear();
  disposeObject3Ds(roots);
}

window.pauseGarden = function () {
  if (viewerDestroyed || !viewerActive) {
    return;
  }

  viewerActive = false;
  zoomPointers.clear();
  gardenLoadId++;
  treeLoadId++;
  treeLoadPromise = null;
  selectionId++;

  cancelWaitingModelLoads();
  cancelPreviewCatalogLoad();
  cancelGardenDelays();
  cancelGardenRender();

  gsap.killTweensOf(camera.position);
  gsap.killTweensOf(controls.target);

  isFocusing = false;
  controls.enabled = false;

  disposePendingFlowerBatches();
  emitDiagnosticReport('garden_paused');
};

window.resumeGarden = function (reload = true) {
  if (viewerDestroyed || viewerContextLost) {
    return false;
  }

  if (viewerActive) {
    return true;
  }

  viewerActive = true;
  controls.enabled = isGardenViewerActive();
  if (!reload) {
    requestRender();
    return true;
  }

  const request = latestGardenRequest;

  if (request?.kind === 'preview') {
    window.previewGarden();
  } else if (request?.kind === 'garden') {
    window.initGarden(
      request.treeUrl,
      request.flowerUrlsMapJson,
      request.diariesJson,
      request.assetPreview
    );
  } else {
    requestRender();
  }

  return true;
};

window.destroyGardenViewer = function () {
  if (viewerDestroyed) {
    return true;
  }

  viewerDestroyed = true;
  viewerActive = false;
  zoomPointers.clear();
  gardenLoadId++;
  treeLoadId++;
  treeLoadPromise = null;
  selectionId++;
  latestGardenRequest = null;

  cancelWaitingModelLoads();
  cancelPreviewCatalogLoad();
  cancelGardenDelays();
  cancelGardenRender();

  if (camera) {
    gsap.killTweensOf(camera.position);
  }
  if (controls) {
    gsap.killTweensOf(controls.target);
  }

  leaveFlowerBrowse();
  flowerData = [];
  removeOwnedEventListeners();
  controls?.dispose();

  disposePendingFlowerBatches();

  scene?.traverse((object) => {
    object.shadow?.dispose?.();
  });

  if (scene) {
    disposeObject3Ds([scene]);
    scene.clear();
  }

  flowerMeshes = [];
  worldTree = null;
  worldTreeUrl = null;
  isFocusing = false;
  resetDiagnosticGardenCounts();

  const loading = document.getElementById('loading');
  if (loading) {
    loading.replaceChildren();
    loading.onclick = null;
    loading.ontouchstart = null;
    loading.ontouchend = null;
    loading.style.pointerEvents = 'none';
    loading.style.display = 'none';
  }

  document.getElementById('preview-selection')?.remove();

  const oldRenderer = renderer;

  oldRenderer?.renderLists?.dispose();
  oldRenderer?.dispose();

  if (oldRenderer) {
    try {
      const extension = oldRenderer.getContext()
        .getExtension('WEBGL_lose_context');

      if (extension) {
        oldRenderer.forceContextLoss();
      }
    } catch (error) {
      console.warn('Context release failed', error);
    }

    oldRenderer.domElement.remove();
  }

  emitDiagnosticReport('viewer_destroyed');
  sendGardenEvent('destroyed');

  scene = null;
  camera = null;
  controls = null;
  renderer = null;
  raycaster = null;
  mouse = null;

  return true;
};

// 기존 Flutter 종료 호출도 전체 종료로 연결한다.
window.disposeGarden = window.destroyGardenViewer;

window.cancelGardenLoadForDiagnostics = async function () {
  if (!diagnosticsEnabled || !isGardenViewerActive()) {
    return;
  }

  invalidateWorldTree();
  window.clearGardenContent();

  const cancelledGeneration = gardenLoadId;
  const deadline = performance.now() + 10000;

  while (cancelledGeneration === gardenLoadId) {
    await waitForGardenDelay(100);

    if (cancelledGeneration !== gardenLoadId) {
      return;
    }

    if (
      activeModelLoads === 0 &&
      modelLoadQueue.length === 0
    ) {
      emitDiagnosticReport('garden_cancelled_settled');
      return;
    }

    if (performance.now() >= deadline) {
      emitDiagnosticReport('garden_cancel_timeout');
      return;
    }
  }
};

function showPreviewSelection(label) {
  let panel = document.getElementById('preview-selection');
  if (!panel) {
    panel = document.createElement('div');
    panel.id = 'preview-selection';
    panel.style.cssText = 'position:fixed;bottom:60px;left:16px;right:16px;padding:12px;background:rgba(255,255,255,.95);border-radius:12px;font:14px sans-serif;color:#333;text-align:center;z-index:2';
    const text = document.createElement('div');
    text.id = 'preview-label';
    panel.appendChild(text);
    const button = document.createElement('button');
    button.textContent = '전체 정원으로 돌아가기';
    button.style.marginTop = '8px';
    addTrackedEventListener(button, 'click', (event) => {
      event.stopPropagation();
      panel.style.display = 'none';
      window.resetCamera();
    });
    panel.appendChild(button);
    // UI taps should not trigger the scene raycaster.
    addTrackedEventListener(panel, 'touchstart', event => event.stopPropagation(), { passive: true });
    addTrackedEventListener(panel, 'touchend', event => event.stopPropagation());
    addTrackedEventListener(panel, 'click', event => event.stopPropagation());
    document.body.appendChild(panel);
  }
  document.getElementById('preview-label').textContent = label;
  panel.style.display = 'block';
}

window.previewGarden = async function () {
  if (viewerDestroyed) {
    return;
  }

  latestGardenRequest = { kind: 'preview' };

  if (!isGardenViewerActive()) {
    return;
  }
  window.clearGardenContent();

  const requestGeneration = gardenLoadId;
  const controller = new AbortController();
  previewCatalogController = controller;

  const loading = document.getElementById('loading');
  loading.textContent = '꽃 목록을 불러오는 중...';
  loading.style.pointerEvents = 'none';
  loading.style.display = 'block';

  const isCurrentRequest = () => (
    isGardenViewerActive() &&
    requestGeneration === gardenLoadId &&
    previewCatalogController === controller &&
    !controller.signal.aborted
  );

  try {
    const response = await fetch('flower_catalog.json', {
      signal: controller.signal,
    });

    if (!isCurrentRequest()) {
      return;
    }

    if (!response.ok) {
      throw new Error(`Flower catalog: HTTP ${response.status}`);
    }

    const catalog = await response.json();

    if (!isCurrentRequest()) {
      return;
    }

    if (diagnosticsEnabled) {
      const delayMs = Number(
        new URLSearchParams(window.location.search)
          .get('catalogProcessDelayMs') || 0
      );

      if (Number.isFinite(delayMs) && delayMs > 0) {
        loading.textContent = '꽃 목록 처리 대기 중 · 진단';
        emitDiagnosticReport('preview_catalog_process_delayed');

        await waitForGardenDelay(Math.min(delayMs, 10000));
      }
    }

    if (!isCurrentRequest()) {
      if (diagnosticsEnabled) {
        emitDiagnosticReport('preview_catalog_stale_ignored');
      }

      return;
    }

    if (!Array.isArray(catalog)) {
      throw new Error('Flower catalog must be an array.');
    }

    const assetVersion = 'flower-mapping-v3';
    const flowerMap = {};

    const diaries = catalog.map((flower, index) => {
      const emotion = `preview_${index}`;
      flowerMap[emotion] = [`../images/flower/${flower.file}?v=${assetVersion}`,];

      return {
        id: index,
        emotion,
        previewIndex: index,
        previewLabel:
          `${flower.file} · ` +
          `${flower.triangles.toLocaleString()} 삼각형 · ` +
          `${(flower.bytes / 1024).toFixed(0)}KiB` +
          (flower.mapped ? '' : ' · 현재 미사용'),
      };
    });

    if (!isCurrentRequest()) {
      return;
    }

    // catalog 처리가 끝났으므로 모델 로딩에 넘기기 전에 참조를 정리한다.
    previewCatalogController = null;

    window.initGarden(
      `../images/worldtree.glb?v=${assetVersion}`,
      JSON.stringify(flowerMap),
      JSON.stringify(diaries),
      true
    );
  } catch (error) {
    if (!isCurrentRequest()) {
      return;
    }

    console.error('Error loading flower catalog', error);

    sendGardenEvent('error', {
      code: 'ERROR_PREVIEW_CATALOG',
      message: '꽃 목록을 불러오지 못했어요.',
      detail: String(error),
    });

    showGardenLoadError(
      '꽃 목록을 불러오지 못했어요.',
      requestGeneration,
      () => window.previewGarden()
    );

    queueDiagnosticReport('preview_catalog_error');
    requestRender();
  } finally {
    if (previewCatalogController === controller) {
      previewCatalogController = null;
    }
  }
};

window.loseGardenContextForDiagnostics = function () {
  if (
    !diagnosticsEnabled ||
    !isGardenViewerActive() ||
    !renderer
  ) {
    return false;
  }

  const extension = renderer.getContext()
    .getExtension('WEBGL_lose_context');

  if (!extension) {
    return false;
  }

  extension.loseContext();
  return true;
};

window.getGardenViewerStatus = function () {
  const snapshot = collectDiagnosticSnapshot();
  return {
    sessionId: diagnosticSessionId,
    active: isGardenViewerActive(),
    destroyed: viewerDestroyed,
    contextLost: viewerContextLost,

    loading: {
      active: activeModelLoads,
      waiting: modelLoadQueue.length,
    },

    diaryCount: diagnosticState.diaryCount,
    mappedDiaryCount: diagnosticState.mappedDiaryCount,
    skippedDiaryCount: diagnosticState.skippedDiaryCount,
    sceneFlowerCount: snapshot.sceneResources.logicalFlowers,
    pendingFlowerCount: snapshot.pendingResources.logicalFlowers,
    gardenLoadMs: diagnosticGardenLoadMs(),
    ...snapshot,

    activity: {
      eventListeners: ownedEventRemovers.size,
      timers:
        ownedGardenDelays.size +
        Number(window.__gardenPendingInitTimers || 0),
      rafQueued: Number(renderQueued),
      rafRunning: Number(renderRunning),
      tweens: camera && controls
        ? gsap.getTweensOf([
            camera.position,
            controls.target,
          ]).length
        : 0,
    },

    canvasCount: document.querySelectorAll(
      '#canvas-container canvas'
    ).length,
  };
};

window.reportGardenDiagnostics = function (reason = 'manual_status') {
  if (!diagnosticsEnabled) return null;
  emitDiagnosticReport(reason);
  return window.getGardenViewerStatus();
};

sendGardenEvent('ready');
// Opening the viewer directly in a browser uses the same complete asset preview.
if (!window.FlutterChannel) window.previewGarden();
