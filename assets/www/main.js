import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

let scene, camera, renderer, controls;
let raycaster, mouse;
let flowerMeshes = [];
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
window.initGarden = function (treeUrl, flowerUrl, diariesJson) {
  document.getElementById('loading').style.display = 'block';
  let diaries = JSON.parse(diariesJson);
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

    // Load Flower
    loader.load(flowerUrl, (fgltf) => {
      document.getElementById('loading').style.display = 'none';
      const baseFlower = fgltf.scene;

      // 12개가 될 때까지 테스트용 더미 꽃 추가
      while (diaries.length < 12) {
        diaries.push({ id: 'dummy_' + diaries.length });
      }

      // Compute bounding box to debug size and offset
      const box = new THREE.Box3().setFromObject(baseFlower);
      const size = new THREE.Vector3();
      box.getSize(size);
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage('FLOWER_SIZE: ' + size.x.toFixed(4) + ', ' + size.y.toFixed(4) + ', ' + size.z.toFixed(4));
        window.FlutterChannel.postMessage('FLOWER_CENTER: ' + box.getCenter(new THREE.Vector3()).x.toFixed(4));
      }

      const numFlowers = diaries.length;

      for (let i = 0; i < numFlowers; i++) {
        const diary = diaries[i];
        const clone = baseFlower.clone();

        // Random placement on the ground (반경 10 ~ 30 사이 무작위 배치)
        const angle = Math.random() * Math.PI * 2;
        const r = 10 + Math.random() * 20;

        clone.position.x = Math.cos(angle) * r;
        clone.position.z = Math.sin(angle) * r;
        clone.position.y = 0; // 임시로 0 설정 후 BoundingBox 기반으로 바닥에 딱 맞게 자동 조정

        // 베이스 모델 크기가 무려 180이나 되므로, 0.015 수준으로 대폭 축소
        clone.scale.set(1.5, 1.5, 1.5);

        // Face the tree
        clone.lookAt(origin);

        clone.userData = { isFlower: true, diaryId: diary.id };

        clone.traverse((child) => {
          if (child.isMesh) {
            child.castShadow = true;
            child.receiveShadow = true;
            if (child.material) {
              child.material = child.material.clone();
            }
          }
        });

        // BoundingBox를 계산하여 꽃의 맨 아랫부분(줄기 끝)이 정확히 바닥(y=0)에 닿도록 보정
        clone.updateMatrixWorld(true);
        const flowerBox = new THREE.Box3().setFromObject(clone);
        clone.position.y += (0 - flowerBox.min.y);

        scene.add(clone);
        flowerMeshes.push(clone);
      }
    }, undefined, function (error) {
      if (window.FlutterChannel) window.FlutterChannel.postMessage('ERROR_FLOWER: ' + error.message);
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

  // We raycast against flower meshes
  const intersects = raycaster.intersectObjects(scene.children, true);

  for (let i = 0; i < intersects.length; i++) {
    let object = intersects[i].object;
    
    // Walk up to find the group with userData
    while (object && !object.userData.isFlower && !object.userData.isTree && object.parent) {
      object = object.parent;
    }

    if (object && object.userData.isFlower) {
      if (object.userData.diaryId && String(object.userData.diaryId).startsWith('dummy')) {
        break;
      }
      focusOnFlower(object);
      break;
    } else if (object && object.userData.isTree) {
      focusOnTree(object);
      break;
    }
  }
}

function focusOnFlower(flowerObj) {
  isFocusing = true;
  controls.enabled = false;

  // Calculate target camera position (zoom in slightly above and in front of flower)
  const offset = new THREE.Vector3(0, 5, 8);
  // Transform offset to face same direction as flower to tree
  const direction = new THREE.Vector3().subVectors(origin, flowerObj.position).normalize();

  // Just a simple heuristic: move camera closer to flower
  const targetCamPos = flowerObj.position.clone().add(new THREE.Vector3(0, 4, 0)).sub(direction.multiplyScalar(8));

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
    x: flowerObj.position.x,
    y: flowerObj.position.y,
    z: flowerObj.position.z,
    duration: 1.5,
    ease: "power3.inOut",
    onComplete: () => {
      // Notify Flutter
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(flowerObj.userData.diaryId);
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
