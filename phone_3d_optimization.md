# 모바일 환경 3D (Three.js + Flutter WebView) 최적화 가이드

하이브리드 앱(Flutter + WebView 기반 Three.js)을 모바일 환경에서 쾌적하게 구동하고, 배터리 광탈(소모) 및 발열을 막기 위한 필수 최적화 전략입니다.

## 1. On-Demand 렌더링 (필요할 때만 화면 그리기)
가장 중요한 최적화 기법입니다. 현재 코드는 `requestAnimationFrame`을 통해 화면이 정지해 있을 때도 초당 60프레임(60fps)으로 화면을 다시 그리고 있습니다.
모바일에서는 아무것도 안 할 때는 렌더링을 멈추고, 상호작용(터치, 드래그 등)이 있을 때만 화면을 갱신해야 합니다.

**적용 방법:**
- `requestAnimationFrame`의 무한 루프 렌더링 방식을 제거합니다.
- `controls.addEventListener('change', render);` 를 추가하여 화면(카메라)이 움직일 때만 `renderer.render()`가 호출되도록 합니다.
- GSAP 애니메이션(꽃으로 줌인 등)이 진행 중일 때만 임시로 루프를 돌리고, 애니메이션이 끝나면 멈춥니다.

## 2. 모바일 디바이스 픽셀 비율 제한
최신 스마트폰(특히 아이폰)은 화면의 픽셀 밀도(Device Pixel Ratio)가 3 이상인 경우가 많습니다. 이를 그대로 Three.js 렌더러에 적용하면 3배의 해상도로 3D 씬을 렌더링하므로 연산량이 기하급수적으로 늘어납니다.

**적용 방법:**
```javascript
// 기존
renderer.setPixelRatio(window.devicePixelRatio);

// 변경 (최대 픽셀 비율을 2로 제한)
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
```

## 3. 그림자(Shadow) 최적화
모든 3D 모델에 실시간 그림자(`castShadow`, `receiveShadow`)를 적용하고 `PCFSoftShadowMap`을 사용하면 GPU 부하가 큽니다.

**적용 방법:**
- **그림자 베이킹(Baking):** 가능하다면 Blender 같은 툴에서 미리 그림자가 적용된 텍스처(Bake)를 만들어 사용하고 실시간 그림자를 끕니다.
- **그림자 맵 해상도 낮추기:** 
  ```javascript
  dirLight.shadow.mapSize.width = 512; // 1024에서 하향 조정
  dirLight.shadow.mapSize.height = 512;
  ```
- 불필요한 오브젝트(예: 바닥)에는 `castShadow`를 끕니다.

## 4. 안티앨리어싱(Antialiasing) 조정
모바일 기기는 기본적으로 화면 크기 대비 해상도가 매우 높아, 안티앨리어싱(`antialias: true`)의 효과가 데스크톱만큼 극적으로 체감되지 않으면서도 성능은 많이 잡아먹습니다. 성능 문제가 심각하다면 `antialias: false`로 설정하는 것을 고려합니다.

## 5. 지오메트리 및 재질(Material) 단순화
- 나무와 꽃 3D 모델(GLTF/GLB)의 폴리곤 수(Vertices/Faces)를 최소화(Decimation)합니다.
- 너무 많은 다중 재질보다는 단일 재질 + 텍스처를 활용하는 초과 Draw Call 횟수를 줄이는 데 유리합니다.

## 6. 프로필(Profile) 및 릴리즈(Release) 빌드 활용
현재 `flutter run` 디버그 모드에서 실행하여 성능이 더 낮게 측정되었을 수 있습니다. 성능 테스트는 반드시 **프로필 모드**나 **릴리즈 모드**에서 수행해야 합니다.
```bash
# 프로필 모드 (DevTools 성능 측정 가능)
flutter run --profile

# 릴리즈 모드 (최종 배포 속도)
flutter run --release
```
