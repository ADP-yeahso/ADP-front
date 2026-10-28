import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const diagnosticsEnabled =
  new URLSearchParams(window.location.search).get('diagnostics') === '1';

const diagnosticSessionId = diagnosticsEnabled
  ? (globalThis.crypto?.randomUUID?.() ?? `garden-${Date.now()}`)
  : null;

const diagnosticState = {
  activeLoads: 0,
  peakActiveLoads: 0,
  diaryCount: 0,
  ownedEventListeners: 0,
};

let pendingDiagnosticReason = null;

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

  if (diagnosticsEnabled) {
    diagnosticState.ownedEventListeners += 1;
  }
}

function queueDiagnosticReport(reason) {
  if (diagnosticsEnabled) {
    pendingDiagnosticReason = reason;
  }
}

function seededUnit(seed) {
  const value = Math.sin(Number(seed) * 12.9898) * 43758.5453;
  return value - Math.floor(value);
}

let scene, camera, renderer, controls;
let raycaster, mouse;
let flowerMeshes = []; // Not used for clones anymore, but we can keep for backwards compat or remove.
let flowerData = [];
let worldTree;
let isFocusing = false;
let gardenLoadId = 0;
let isAssetPreview = false;
let previewCatalogController = null;

// Default camera position
const defaultCameraPos = new THREE.Vector3(0, 35, 50);
const origin = new THREE.Vector3(0, 0, 0);

let renderQueued = false;
let renderRunning = false;

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

function queueModelLoad(url, generation, acceptResult) {
  return new Promise((resolve, reject) => {
    modelLoadQueue.push({
      url,
      generation,
      acceptResult,
      resolve,
      reject,
    });

    drainModelLoadQueue();
  });
}

function cancelWaitingModelLoads() {
  const cancelledTasks = modelLoadQueue.splice(0);

  cancelledTasks.forEach((task) => {
    task.reject(new StaleGardenLoadError());
  });
}

function cancelPreviewCatalogLoad() {
  const controller = previewCatalogController;
  previewCatalogController = null;
  controller?.abort();
}

function drainModelLoadQueue() {
  while (
    activeModelLoads < MAX_CONCURRENT_MODEL_LOADS &&
    modelLoadQueue.length > 0
  ) {
    const task = modelLoadQueue.shift();

    if (task.generation !== gardenLoadId) {
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
            if (task.generation !== gardenLoadId) {
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
            if (task.generation !== gardenLoadId) {
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
  // 몽글몽글한 하늘색 배경 및 안개 (그라데이션 효과)
  const skyColor = 0xe8f4f8; // 부드러운 파스텔 스카이블루
  scene.background = new THREE.Color(skyColor);
  // FogExp2는 거리에 따라 기하급수적으로 뿌얘지므로 선형 안개(Fog)로 교체하여 나무가 선명하게 보이도록 함
  scene.fog = new THREE.Fog(skyColor, 50, 150);

  // Camera setup
  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.set(0, 35, 50);

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

  // 3D 바닥(Ground) 생성
  const groundGeo = new THREE.PlaneGeometry(150, 150);
  const groundMat = new THREE.MeshStandardMaterial({
    color: 0xdde6d5, // 부드러운 파스텔톤 초원 느낌
    roughness: 0.9,
    metalness: 0.1
  });
  const ground = new THREE.Mesh(groundGeo, groundMat);
  ground.rotation.x = -Math.PI / 2;
  ground.castShadow = false;
  ground.receiveShadow = false;
  scene.add(ground);

  // OrbitControls
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.target.copy(origin);
  addTrackedEventListener(controls, 'change', requestRender);

  // 핀치 줌 완벽 지원 (너무 뚫고 가거나 나가지 않게 제한)
  controls.enableZoom = true;
  controls.minDistance = 22; // 나무를 너무 뚫고 들어가지 않도록
  controls.maxDistance = 80; // 맵 밖으로 너무 멀어지지 않도록

  // 시안처럼 약간 위에서 내려다보는(Bird's-eye) 고도각 설정
  // 완전 고정할 수도 있고, 살짝 위아래로 움직이게 여유를 줄 수도 있음. 일단 시안 구도로 고정.
  controls.minPolarAngle = Math.PI / 3.2; // 약 56도 (위에서 비스듬히 내려다봄)
  controls.maxPolarAngle = Math.PI / 3.2;

  // Raycaster
  raycaster = new THREE.Raycaster();
  mouse = new THREE.Vector2();

  addTrackedEventListener(window, 'resize', onWindowResize);
  addTrackedEventListener(window, 'click', onClick);

  // ── 모바일 터치 지원 ──
  // iOS WebView에서는 click 이벤트가 제대로 발생하지 않으므로
  // touchstart/touchend로 "탭"을 감지하여 raycast를 수행합니다.
  let touchStartX = 0, touchStartY = 0;
  let touchStartTime = 0;

  addTrackedEventListener(window, 'touchstart', (e) => {
    if (e.touches.length === 1) {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
      touchStartTime = Date.now();
    }
  }, { passive: true });

  addTrackedEventListener(window, 'touchend', (e) => {
    if (e.changedTouches.length !== 1) return;
    const touch = e.changedTouches[0];
    const dx = touch.clientX - touchStartX;
    const dy = touch.clientY - touchStartY;
    const dt = Date.now() - touchStartTime;

    // 손가락 이동이 10px 이하이고 300ms 이내면 "탭"으로 간주
    if (Math.abs(dx) < 10 && Math.abs(dy) < 10 && dt < 300) {
      onClick({
        clientX: touch.clientX,
        clientY: touch.clientY,
      });
    }
  });

  // Hide loading by default until data comes
  document.getElementById('loading').style.display = 'none';
}

function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  requestRender();
}

function showGardenLoadError(message, generation, retry) {
  if (generation !== gardenLoadId) {
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
  assetPreview
) {
  const baseFlower = gltf.scene;
  const numInstances = assignedDiaries.length;
  const flowerScale = 0.2;
  const dummy = new THREE.Object3D();
  const createdMeshes = [];

  try {
    baseFlower.position.set(0, 0, 0);
    baseFlower.rotation.set(0, 0, 0);
    baseFlower.scale.set(1, 1, 1);
    baseFlower.updateMatrixWorld(true);

    const baseBox = new THREE.Box3().setFromObject(baseFlower);
    const baseMinY = baseBox.min.y;

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
        diaryIds: [],
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

      dummy.position.x = Math.cos(angle) * radius;
      dummy.position.z = Math.sin(angle) * radius;
      dummy.position.y = -(baseMinY * flowerScale);
      dummy.scale.set(flowerScale, flowerScale, flowerScale);
      dummy.lookAt(origin);
      dummy.updateMatrix();

      createdMeshes.forEach((instancedMesh) => {
        instancedMesh.setMatrixAt(index, dummy.matrix);

        if (!instancedMesh.userData.diaryMapping) {
          instancedMesh.userData.diaryMapping = [];
        }

        instancedMesh.userData.diaryMapping[index] = {
          diaryId: diary.id,
          position: dummy.position.clone(),
          previewLabel: diary.previewLabel,
        };
      });
    }

    createdMeshes.forEach((instancedMesh) => {
      instancedMesh.instanceMatrix.needsUpdate = true;
    });

    return createdMeshes;
  } catch (error) {
    disposeObject3Ds(createdMeshes);
    throw error;
  }
}

// Function called from Flutter to initialize models
window.initGarden = function (treeUrl, flowerUrlsMapJson, diariesJson, assetPreview = false) {
  const currentLoadId = ++gardenLoadId;
  cancelWaitingModelLoads();
  cancelPreviewCatalogLoad();

  isAssetPreview = assetPreview;
  const loading = document.getElementById('loading');
  loading.textContent = '정원을 가꾸는 중...';
  loading.style.pointerEvents = 'none';
  loading.style.display = 'block';

  const retryGarden = () => {
    if (currentLoadId !== gardenLoadId) {
      return;
    }

    window.disposeGarden();
    window.initGarden(
      treeUrl,
      flowerUrlsMapJson,
      diariesJson,
      assetPreview
    );
  };

  let diaries = JSON.parse(diariesJson);
  let flowerUrlsMap = JSON.parse(flowerUrlsMapJson);
  diagnosticState.diaryCount = diaries.length;

  // Load Tree
  queueDiagnosticReport('tree_load_started');
  requestRender();
  queueModelLoad(treeUrl, currentLoadId, (gltf) => {
    if (currentLoadId !== gardenLoadId) {
      disposeObject3Ds([gltf.scene]);
      return;
    }
    worldTree = gltf.scene;
    worldTree.position.set(0, 0, 0);
    // Apply soft material override for healing vibe
    worldTree.userData = { isTree: true };
    worldTree.traverse((child) => {
      if (child.isMesh) {
        child.castShadow = false;
        child.receiveShadow = false;
      }
    });
    // scale tree if needed
    worldTree.scale.set(1.5, 1.5, 1.5);
    scene.add(worldTree);
    requestRender();

    const numFlowers = diaries.length;
    if (numFlowers === 0) {
      document.getElementById('loading').style.display = 'none';
      queueDiagnosticReport('garden_ready_zero');
      requestRender();
      return;
    }

    // Determine required flower URLs and mapping for diaries
    let diariesByUrl = {};
    
    diaries.forEach(diary => {
      const emotion = typeof diary.emotion === 'string' && diary.emotion.trim() !== ''
      ? diary.emotion.toLowerCase()
      : null;

      if (!emotion) {
        return;
      }

      const urls = flowerUrlsMap[emotion];

      if (!Array.isArray(urls) || urls.length === 0) {
        console.warn(`No flower mapping for emotion: ${emotion}`);
        return;
      }
      // Stable random using diary.id
      const urlIndex = diary.id % urls.length;
      const url = urls[urlIndex];
      
      if (!diariesByUrl[url]) {
        diariesByUrl[url] = [];
      }
      diariesByUrl[url].push(diary);
    });

    // Load Flowers
    const uniqueUrls = Object.keys(diariesByUrl);
    queueDiagnosticReport('flower_loads_started');
    requestRender();

    const loadFlowersSequentially = async () => {
      const pendingFlowerMeshes = [];

      try {
        for (const url of uniqueUrls) {
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
              assetPreview
            )
          );

          if (currentLoadId !== gardenLoadId) {
            disposeObject3Ds(createdMeshes);
            throw new StaleGardenLoadError();
          }

          pendingFlowerMeshes.push(...createdMeshes);
        }

        if (currentLoadId !== gardenLoadId) {
          throw new StaleGardenLoadError();
        }

        pendingFlowerMeshes.forEach((mesh) => {
          scene.add(mesh);
        });

        flowerData = [];
        flowerMeshes = pendingFlowerMeshes;

        document.getElementById('loading').style.display = 'none';
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

        console.error('Error loading flower batch', error);

        if (window.FlutterChannel) {
          window.FlutterChannel.postMessage(
            'ERROR_FLOWER_BATCH: ' + error.message
          );
        }

        showGardenLoadError(
          '꽃을 불러오지 못했어요.',
          currentLoadId,
          retryGarden
        );

        queueDiagnosticReport('flower_batch_error');
        requestRender();
      }
    };
    loadFlowersSequentially();

  }).catch((error) => {
    if (error instanceof StaleGardenLoadError) {
      return;
    }
    if (currentLoadId !== gardenLoadId) {
      return;
    }
    if (window.FlutterChannel) {
      window.FlutterChannel.postMessage('ERROR_TREE: ' + error.message);
    }
    showGardenLoadError(
      '나무를 불러오지 못했어요.',
      currentLoadId,
      retryGarden
    );
    queueDiagnosticReport('tree_load_error');
    requestRender();
  });
}

function onClick(event) {
  if (isFocusing) return;

  mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

  raycaster.setFromCamera(mouse, camera);

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

function focusOnFlower(fData) {
  isFocusing = true;
  controls.enabled = false;

  // Transform offset to face same direction as flower to tree
  const direction = new THREE.Vector3().subVectors(origin, fData.position).normalize();

  // Just a simple heuristic: move camera closer to flower
  const targetCamPos = fData.position.clone().add(new THREE.Vector3(0, 4, 0)).sub(direction.multiplyScalar(8));

  // Tween Camera Position
  gsap.to(camera.position, {
    x: targetCamPos.x,
    y: targetCamPos.y,
    z: targetCamPos.z,
    duration: 1.5,
    ease: "power3.inOut",
    onUpdate: requestRender,
  });

  // Tween Controls Target (LookAt)
  gsap.to(controls.target, {
    x: fData.position.x,
    y: fData.position.y,
    z: fData.position.z,
    duration: 1.5,
    ease: "power3.inOut",
    onUpdate: requestRender,
    onComplete: () => {
      // Notify Flutter
      if (window.FlutterChannel && !fData.previewLabel) {
        window.FlutterChannel.postMessage(fData.diaryId);
      }
    }
  });
}

function focusOnTree(treeObj) {
  isFocusing = true;
  controls.enabled = false;

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
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage('tree');
      }
    }
  });
}

window.resetCamera = function () {
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
      isFocusing = false;
      controls.enabled = true;
    }
  });
};

function requestRender() {
  if (renderQueued || renderRunning) return;

  renderQueued = true;

  requestAnimationFrame(() => {
    renderQueued = false;
    renderRunning = true;

    const controlsChanged = controls.update();
    renderer.render(scene, camera);

    renderRunning = false;

    if (pendingDiagnosticReason !== null) {
      const reason = pendingDiagnosticReason;
      pendingDiagnosticReason = null;
      emitDiagnosticReport(reason);
    }

    // OrbitControls damping이 끝날 때까지 계속 렌더링
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

function collectDiagnosticResources() {
  const geometries = new Set();
  const materials = new Set();
  const textures = new Set();
  const bitmaps = new Set();

  let meshes = 0;
  let instancedMeshes = 0;
  let instanceSlots = 0;

  scene?.traverse((object) => {
    if (!object.isMesh) return;

    meshes += 1;

    if (object.geometry) {
      geometries.add(object.geometry);
    }

    forEachMaterial(object.material, (material) => {
      materials.add(material);
      collectMaterialTextures(material, textures);
    });

    if (object.isInstancedMesh) {
      instancedMeshes += 1;
      instanceSlots += object.count;
    }
  });

  textures.forEach((texture) => {
    collectTextureBitmaps(texture, bitmaps);
  });

  return {
    meshes,
    geometries: geometries.size,
    materials: materials.size,
    textures: textures.size,
    bitmaps: bitmaps.size,
    instancedMeshes,
    instanceSlots,
  };
}

function emitDiagnosticReport(reason) {
  if (!diagnosticsEnabled || !renderer || !scene) return;

  const resources = collectDiagnosticResources();
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
    reason,
    sessionId: diagnosticSessionId,
    generation: gardenLoadId,
    diaryCount: diagnosticState.diaryCount,
    loading: {
      active: diagnosticState.activeLoads,
      waiting: modelLoadQueue.length,
      peakActive: diagnosticState.peakActiveLoads,
    },
    resources,
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
      timers: Number(window.__gardenPendingInitTimers || 0),
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

window.disposeGarden = function() {
  gardenLoadId++;
  cancelWaitingModelLoads();
  cancelPreviewCatalogLoad();

  const loading = document.getElementById('loading');
  loading.replaceChildren();
  loading.style.pointerEvents = 'none';
  loading.style.display = 'none';

  gsap.killTweensOf(camera.position);
  gsap.killTweensOf(controls.target);

  isFocusing = false;
  controls.enabled = true;

  const roots = [];

  if (worldTree) {
    roots.push(worldTree);
    worldTree = null;
  }

  roots.push(...flowerMeshes);
  disposeObject3Ds(roots);

  flowerMeshes = [];
  flowerData = [];
  diagnosticState.diaryCount = 0;

  renderer.renderLists?.dispose();

  if (diagnosticsEnabled) {
    emitDiagnosticReport('garden_disposed');
  }

  requestRender();
};

window.cancelGardenLoadForDiagnostics = async function () {
  if (!diagnosticsEnabled) {
    return;
  }

  window.disposeGarden();

  const cancelledGeneration = gardenLoadId;
  const deadline = performance.now() + 10000;

  while (cancelledGeneration === gardenLoadId) {
    await new Promise((resolve) => setTimeout(resolve, 100));

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
  window.disposeGarden();

  const requestGeneration = gardenLoadId;
  const controller = new AbortController();
  previewCatalogController = controller;

  const loading = document.getElementById('loading');
  loading.textContent = '꽃 목록을 불러오는 중...';
  loading.style.pointerEvents = 'none';
  loading.style.display = 'block';

  const isCurrentRequest = () => (
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

        await new Promise((resolve) => {
          setTimeout(resolve, Math.min(delayMs, 10000));
        });
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

    const flowerMap = {};

    const diaries = catalog.map((flower, index) => {
      const emotion = `preview_${index}`;
      flowerMap[emotion] = [`../images/flower/${flower.file}`];

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
      '../images/worldtree.glb',
      JSON.stringify(flowerMap),
      JSON.stringify(diaries),
      true
    );
  } catch (error) {
    if (!isCurrentRequest()) {
      return;
    }

    console.error('Error loading flower catalog', error);

    if (window.FlutterChannel) {
      window.FlutterChannel.postMessage(
        'ERROR_PREVIEW_CATALOG: ' + error.message
      );
    }

    showGardenLoadError(
      '꽃 목록을 불러오지 못했어요.',
      requestGeneration,
      () => window.previewGarden()
    );

    queueDiagnosticReport('preview_catalog_error');
    requestRender();
  } finally {
    // 더 최신 요청의 controller를 지우지 않도록 확인한다.
    if (previewCatalogController === controller) {
      previewCatalogController = null;
    }
  }
};

// Opening the viewer directly in a browser uses the same complete asset preview.
if (!window.FlutterChannel) window.previewGarden();
