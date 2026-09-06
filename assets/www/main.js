import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

let scene, camera, renderer, controls;
let raycaster, mouse;
let flowerMeshes = []; // Not used for clones anymore, but we can keep for backwards compat or remove.
let flowerData = [];
let worldTree;
let isFocusing = false;

// Default camera position
const defaultCameraPos = new THREE.Vector3(0, 35, 50);
const origin = new THREE.Vector3(0, 0, 0);

init();
animate();

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
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
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
  dirLight.castShadow = true;
  dirLight.shadow.mapSize.width = 1024;
  dirLight.shadow.mapSize.height = 1024;
  dirLight.shadow.camera.left = -20;
  dirLight.shadow.camera.right = 20;
  dirLight.shadow.camera.top = 20;
  dirLight.shadow.camera.bottom = -20;
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
  ground.receiveShadow = true;
  scene.add(ground);

  // OrbitControls
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.target.copy(origin);

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

  window.addEventListener('resize', onWindowResize);
  window.addEventListener('click', onClick);

  // ── 모바일 터치 지원 ──
  // iOS WebView에서는 click 이벤트가 제대로 발생하지 않으므로
  // touchstart/touchend로 "탭"을 감지하여 raycast를 수행합니다.
  let touchStartX = 0, touchStartY = 0;
  let touchStartTime = 0;

  window.addEventListener('touchstart', (e) => {
    if (e.touches.length === 1) {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
      touchStartTime = Date.now();
    }
  }, { passive: true });

  window.addEventListener('touchend', (e) => {
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
}

// Function called from Flutter to initialize models
window.initGarden = function (treeUrl, flowerUrlsMapJson, diariesJson) {
  document.getElementById('loading').style.display = 'block';
  let diaries = JSON.parse(diariesJson);
  let flowerUrlsMap = JSON.parse(flowerUrlsMapJson);
  const loader = new GLTFLoader();

  // Load Tree
  loader.load(treeUrl, (gltf) => {
    worldTree = gltf.scene;
    worldTree.position.set(0, 0, 0);
    // Apply soft material override for healing vibe
    worldTree.userData = { isTree: true };
    worldTree.traverse((child) => {
      if (child.isMesh) {
        child.castShadow = true;
        child.receiveShadow = true;
      }
    });
    // scale tree if needed
    worldTree.scale.set(1.5, 1.5, 1.5);
    scene.add(worldTree);

    const numFlowers = diaries.length;
    if (numFlowers === 0) {
      document.getElementById('loading').style.display = 'none';
      return;
    }

    // Determine required flower URLs and mapping for diaries
    let diariesByUrl = {};
    
    diaries.forEach(diary => {
      let emotion = diary.emotion ? diary.emotion.toLowerCase() : 'joy';
      let urls = flowerUrlsMap[emotion];
      if (!urls || urls.length === 0) {
        urls = flowerUrlsMap['joy']; // fallback
      }
      // Stable random using diary.id
      let urlIndex = diary.id % urls.length;
      let url = urls[urlIndex];
      
      if (!diariesByUrl[url]) {
        diariesByUrl[url] = [];
      }
      diariesByUrl[url].push(diary);
    });

    let uniqueUrls = Object.keys(diariesByUrl);
    
    // Load all required flowers in parallel
    let loadPromises = uniqueUrls.map(url => {
      return new Promise((resolve, reject) => {
        loader.load(url, (fgltf) => {
           resolve({ url: url, gltf: fgltf });
        }, undefined, (error) => {
           console.error("Error loading flower: " + url, error);
           reject(error);
        });
      });
    });

    Promise.all(loadPromises).then(results => {
      document.getElementById('loading').style.display = 'none';
      
      flowerData = [];
      flowerMeshes = []; // array of InstancedMeshes
      
      const flowerScale = 0.2;
      const dummy = new THREE.Object3D();

      results.forEach(result => {
        const url = result.url;
        const baseFlower = result.gltf.scene;
        const assignedDiaries = diariesByUrl[url];
        const numInstances = assignedDiaries.length;

        baseFlower.position.set(0, 0, 0);
        baseFlower.rotation.set(0, 0, 0);
        baseFlower.scale.set(1, 1, 1);
        baseFlower.updateMatrixWorld(true);

        const baseBox = new THREE.Box3().setFromObject(baseFlower);
        const baseMinY = baseBox.min.y;

        const typeInstancedMeshes = [];
        baseFlower.traverse((child) => {
          if (child.isMesh) {
            const material = child.material ? child.material.clone() : new THREE.MeshStandardMaterial();
            const geometry = child.geometry.clone();
            geometry.applyMatrix4(child.matrixWorld);

            const imesh = new THREE.InstancedMesh(geometry, material, numInstances);
            imesh.castShadow = true;
            imesh.receiveShadow = true;
            imesh.userData = { isFlower: true, diaryIds: [] };
            
            // Add instance id to diary id mapping inside userData if we needed specific raycasting index mapping
            // But raycasting logic uses instanceId, so flowerData array mapping must align with instanceId
            typeInstancedMeshes.push(imesh);
            flowerMeshes.push(imesh);
            scene.add(imesh);
          }
        });

        for (let i = 0; i < numInstances; i++) {
          const diary = assignedDiaries[i];
          const angle = Math.random() * Math.PI * 2;
          const r = 10 + Math.random() * 20;

          dummy.position.x = Math.cos(angle) * r;
          dummy.position.z = Math.sin(angle) * r;
          dummy.scale.set(flowerScale, flowerScale, flowerScale);
          dummy.position.y = -(baseMinY * flowerScale);
          dummy.lookAt(origin);
          dummy.updateMatrix();

          typeInstancedMeshes.forEach(imesh => {
            imesh.setMatrixAt(i, dummy.matrix);
            // Since raycaster hits a specific InstancedMesh, we need to map imesh + instanceId -> diary.
            // Currently flowerData is a flat array, but raycaster uses instanceId (0 to numInstances-1).
            // To fix raycasting with multiple InstancedMeshes, we must store a mapping per imesh!
            if (!imesh.userData.diaryMapping) imesh.userData.diaryMapping = [];
            imesh.userData.diaryMapping[i] = { diaryId: diary.id, position: dummy.position.clone() };
          });
        }

        typeInstancedMeshes.forEach(imesh => {
          imesh.instanceMatrix.needsUpdate = true;
        });
      });
    }).catch(error => {
      if (window.FlutterChannel) window.FlutterChannel.postMessage('ERROR_FLOWER_BATCH: ' + error.message);
      document.getElementById('loading').style.display = 'none';
    });

  }, undefined, function (error) {
    if (window.FlutterChannel) window.FlutterChannel.postMessage('ERROR_TREE: ' + error.message);
    document.getElementById('loading').style.display = 'none';
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
    onUpdate: () => {
      // Ensure controls target updates smoothly
      controls.update();
    }
  });

  // Tween Controls Target (LookAt)
  gsap.to(controls.target, {
    x: fData.position.x,
    y: fData.position.y,
    z: fData.position.z,
    duration: 1.5,
    ease: "power3.inOut",
    onComplete: () => {
      // Notify Flutter
      if (window.FlutterChannel) {
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
    onUpdate: () => {
      controls.update();
    }
  });

  gsap.to(controls.target, {
    x: origin.x,
    y: origin.y,
    z: origin.z,
    duration: 1.5,
    ease: "power3.inOut",
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
    ease: "power3.inOut"
  });

  gsap.to(controls.target, {
    x: origin.x,
    y: origin.y,
    z: origin.z,
    duration: 1.5,
    ease: "power3.inOut",
    onComplete: () => {
      isFocusing = false;
      controls.enabled = true;
    }
  });
}

function animate() {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}

window.disposeGarden = function() {
  if (worldTree) {
    scene.remove(worldTree);
    worldTree.traverse((child) => {
      if (child.isMesh) {
        if (child.geometry) child.geometry.dispose();
        if (child.material) {
          if (Array.isArray(child.material)) {
            child.material.forEach(m => {
               if(m.map) m.map.dispose();
               m.dispose();
            });
          } else {
            if(child.material.map) child.material.map.dispose();
            child.material.dispose();
          }
        }
      }
    });
    worldTree = null;
  }

  if (flowerMeshes && flowerMeshes.length > 0) {
    flowerMeshes.forEach(imesh => {
      scene.remove(imesh);
      if (imesh.geometry) imesh.geometry.dispose();
      if (imesh.material) {
          if (Array.isArray(imesh.material)) {
            imesh.material.forEach(m => {
               if(m.map) m.map.dispose();
               m.dispose();
            });
          } else {
            if(imesh.material.map) imesh.material.map.dispose();
            imesh.material.dispose();
          }
      }
    });
    flowerMeshes = [];
    flowerData = [];
  }
}

// --- Local Simulator Test Code ---
// Flutter 환경이 아닐 경우(웹 브라우저에서 직접 실행 시) mid 꽃 파일로 시뮬레이터를 자동 실행합니다.
setTimeout(() => {
  if (!window.FlutterChannel) {
    console.log("Running in local simulator. Initializing with mid flower...");
    const dummyDiaries = JSON.stringify([
      { id: "1", emotion: "joy" }, 
      { id: "2", emotion: "guilt" }, 
      { id: "3", emotion: "anger" }, 
      { id: "4", emotion: "sadness" }, 
      { id: "5", emotion: "guilt" }
    ]);
    const dummyMap = JSON.stringify({
      "joy": ["../images/flower/Affection_lisian_low.glb"],
      "guilt": ["../images/flower/Guilt_Canna.glb", "../images/flower/Guilt_Clematis.glb"],
      "anger": ["../images/flower/Anger_Phlox.glb"],
      "sadness": ["../images/flower/Sadness_ebw.glb"]
    });
    window.initGarden(
      '../images/worldtree.glb',
      dummyMap,
      dummyDiaries
    );
  }
}, 500);
