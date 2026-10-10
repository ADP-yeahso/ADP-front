# 1번 정원 화면 메모리 경량화 작업 지시서

작성일: 2026-10-10

검토 기준: 커밋 `8beeec9`의 코드, Three.js `0.160.0`, `webview_flutter 4.14.1`

상태: 설계 및 코드 검토 완료. 아래 구현과 실기기 측정은 미수행.

## 목표와 작업 원칙

스마트폰에서 정원 화면의 최대 메모리 사용량을 낮추고, 월 이동·탭 이동·화면 종료를 반복해도 불필요한 할당이 쌓이지 않도록 한다. 우선순위는 **실시간 그림자 해제 → 리소스 해제 누락 수정 → 동시 로딩 제한 → 화면 수명주기 연결 → 추가 할당 절감 → 실기기 검증**이다.

현재 실기기 OOM 측정 결과는 없다. “메모리가 버티지 못한다”는 우려를 검증하면서 개선한다. GLB 파일 크기만으로 실행 중 메모리나 안전성을 판단하지 않는다. Flutter, WebView의 JavaScript·디코딩 이미지, GPU 자원을 함께 확인한다.

- 아래 **01~10을 직렬로 진행**한다. 단계별 완료 조건을 확인하고 다음 단계로 넘어간다.
- 코드로 적용 가능한 기법을 모두 검토한다. 필수 수정은 구현하고, 조건부 기법은 측정 결과와 적용·보류 이유를 남긴다. 효과가 없는 변경까지 일괄 적용하지 않는다.
- 감정별 꽃 매핑, 월별 일기, 꽃·나무 탭과 상세 보기, 카메라 복귀를 유지한다. 데이터 삭제나 임의의 꽃 표시 개수 제한으로 해결하지 않는다.
- 꽃 GLB 원본 재제작은 [별도 에셋 작업](flower_asset_review.md)이다. 이 작업은 코드 개선을 먼저 완료하며, 에셋 교체를 선행 조건으로 삼지 않는다.
- 각 단계에서 변경 파일, 재현 시나리오, 전후 수치, 남은 문제를 기록한다. 측정할 수 없는 항목은 미측정으로 표시한다.

## 현재 코드에서 확인한 사항

줄 번호는 변경될 수 있으므로 파일과 함수명을 기준으로 작업한다.

| 위치 | 현재 동작 | 검토·수정할 문제 |
|---|---|---|
| `assets/www/main.js` / `init()` | AA 사용, DPR 상한 2, 실시간 그림자 활성화 | 기본 렌더 타깃과 그림자 패스 비용 절감 필요 |
| `init()` 및 `initGarden()` | 방향광, 나무, 꽃, 바닥에 그림자 설정 | 모든 생성 경로에서 그림자 해제 필요 |
| `initGarden()` | 필요한 꽃만 URL별 인스턴싱 | 기존 최적화 유지. 꽃 종류 전체를 `Promise.all`로 동시에 로딩하여 피크가 커질 수 있음 |
| `initGarden()`의 배치 로딩 | 한 건 실패하면 배치 catch로 이동 | 먼저 성공했거나 나중에 성공하는 GLTF 결과를 정리하는 실패 경로가 없음 |
| 인스턴스 생성부 | 원본 geometry·material을 clone | 정상 완료 시 원본 리소스의 명시적 소유권 정리가 없음. 원본 geometry가 GPU에 업로드됐다고 단정하지 말고 CPU 중복과 참조 잔존을 측정 |
| `disposeObject3D()` | geometry·material·일부 texture를 dispose | `InstancedMesh.dispose()` 누락, ImageBitmap 정리 없음. geometry·material 중복 해제 방지와 공유 리소스 소유권 관리 필요 |
| `disposeGarden()` | 나무·꽃 및 renderLists 정리 | 월 데이터 교체용 정리 수준. 바닥, 조명, renderer, controls, canvas, 이벤트까지 종료하는 경로가 없음 |
| `requestRender()` | 필요할 때만 RAF 예약 | 기존 방식 유지. RAF ID 저장·취소 및 비활성/종료 상태 가드 필요 |
| `lib/screens/root_shell.dart` | `IndexedStack`으로 정원 유지 | 다른 탭에서도 정원 State가 살아 있으므로 `dispose()`만으로 탭 이동 시 해제되지 않음 |
| `garden_screen.dart` | 서버 시작 후 `late` controller 할당 | 초기화 도중 종료하면 미초기화 접근 또는 늦은 서버·WebView 생성 가능 |
| `_reload3DScene()` | 준비될 때까지 100ms마다 재귀 타이머 | 요청별 타이머가 누적되거나 종료 후 실행될 수 있음 |
| Flutter `dispose()` | JS 정리와 서버 stop을 비동기로 호출 | 완료 순서를 기다리지 않음. JS 정리를 보장하는 정상 종료 경로 필요 |
| `local_asset_server.dart` | 요청마다 GLB 전체를 `rootBundle.load` | WebView 디코딩과 Dart 버퍼 할당이 겹칠 수 있음. 장기 HTTP 캐시는 살아 있는 GPU·JS 리소스 해제를 대신하지 않음 |

이미 존재하는 인스턴싱, 필요한 꽃만 로딩, 오래된 세대 결과 검사, 요청 기반 렌더링은 유지·보완한다.

## 01. 기준 측정과 진단 장치 추가

**작업 파일:** `assets/www/main.js`, `garden_screen.dart`, 새 측정 결과 문서.

- [ ] 지원 대상 중 메모리가 가장 작은 실제 iPhone·Android를 각각 선정한다. 기종/RAM/OS/WebView 버전, 빌드 모드, 커밋, 화면 크기를 기록한다. 한 플랫폼만 확보했다면 다른 플랫폼은 미검증으로 남긴다.
- [ ] 동일한 고정 데이터로 꽃 0·30·60송이를 준비한다. 모든 운영 꽃 종류가 포함되는 경우와 무거운 꽃 종류가 많이 반복되는 경우를 포함하고, 운영상 더 큰 월 데이터가 가능하면 그 규모도 추가한다. 22종 미리보기는 별도 부하 시나리오로 사용한다.
- [ ] 초기 진입, 로딩 중 최대값, 로딩 후 10초 안정값, 월 이동 30회 후 안정값, 탭 왕복 30회 후 안정값을 측정한다.
- [ ] 진단 모드에서 세션 ID/월 요청 세대, 실행·대기 로딩 수, 소유 geometry/material/texture/bitmap/instance 수, 이벤트·타이머·RAF 수를 숫자로 기록한다. 객체 자체를 콘솔에 출력하여 참조를 붙잡지 않는다.
- [ ] `renderer.info.memory`의 geometry·texture 수, program 수, draw call·triangle 수를 기록한다. 이는 전체 메모리 바이트가 아니며 인스턴스 버퍼 누락 등을 모두 검출하지 못하므로 자체 소유권 카운터와 함께 사용한다.
- [ ] Flutter DevTools로 Dart 영역을 확인하고, 플랫폼 도구로 앱 및 관련 WebView 프로세스의 메모리를 별도로 확인한다. 앱 프로세스 하나의 RSS만으로 전체 비용을 결론 내리지 않는다. 공유 페이지의 이중 합산도 피한다.

Android는 `adb shell dumpsys meminfo <패키지명 또는 PID>`와 프로파일러를 사용하고, iOS는 Xcode/Instruments 및 Web Inspector에서 접근 가능한 지표를 사용한다. 확보하지 못한 WebView/GPU 지표는 명시한다. 측정은 profile 중심으로 수행하고 최종 동작은 release에서도 확인한다. [Flutter 메모리 도구](https://docs.flutter.dev/tools/devtools/memory), [Android dumpsys](https://developer.android.com/tools/dumpsys), [Apple 메모리 조사](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use).

**완료 조건:** 동일 조건으로 재측정할 수 있는 데이터와 측정표가 있고, 02 적용 전 기준값이 기록되어 있다. 실기기를 확보하지 못해도 코드 수정은 진행하되 최종 성능 검증은 완료 처리하지 않는다.

## 02. 실시간 그림자 완전 해제

**작업 파일:** `assets/www/main.js`.

- [ ] renderer 생성 시 `renderer.shadowMap.enabled = false`로 설정한다.
- [ ] 방향광의 `castShadow`를 false로 설정한다. 그림자 mapSize·camera·필터 설정을 제거한다.
- [ ] 나무의 모든 하위 mesh, 생성한 꽃 `InstancedMesh`, 바닥의 `castShadow`와 `receiveShadow`를 false로 설정한다. GLB에 저장된 true 값도 로딩 후 덮어쓴다.
- [ ] 앱 실행 중 그림자를 켰다가 끄는 경로가 있다면 기존 shadow render target도 정리한다. `light.shadow.dispose()`와 관련 참조 정리를 확인하고, 종료 이후 자동 재할당이 일어나지 않도록 한다. 처음부터 끈 경로에서는 target이 생성되지 않는지 확인한다.
- [ ] 조명과 재질은 우선 유지한다. 꽃·나무가 식별되는지 전체 정원/확대 화면을 비교한다. 대체 그림자가 필요하면 별도 요구로 기록하고 이 단계에서 추가 텍스처나 패스를 도입하지 않는다.

`shadowMap.enabled` 변경과 이미 할당된 target 해제는 별도로 처리한다. r160의 `LightShadow.dispose()`는 shadow target을 해제하는 구현이다. [r160 LightShadow 소스](https://github.com/mrdoob/three.js/blob/r160/src/lights/LightShadow.js).

**완료 조건:** 일반 정원·미리보기·재진입 모두 실시간 그림자가 없고, 새 shadow target이 생성되지 않는다. 01과 동일 조건의 전후 메모리·draw call·화면 캡처를 기록한다.

## 03. 리소스 소유권과 공통 해제 함수 정비

**작업 파일:** `assets/www/main.js`의 로딩·생성·해제 함수.

해제 단위를 **뷰어 세션 / 월 데이터 세대 / 꽃 URL별 리소스**로 정한다. 생성·인수한 자원을 등록하고, 실패 중에도 등록된 자원을 회수할 수 있게 한다. 사용 중인 공유 자원은 마지막 소유자가 반납할 때 해제한다.

| 자원 | 기본 소유자 | 해제 시점 |
|---|---|---|
| renderer, controls, canvas, 바닥·조명 | 뷰어 세션 | 뷰어 종료 |
| 현재 나무 모델 | 뷰어 세션 | 뷰어 종료. 동일 URL이면 월 이동 때 유지 |
| 꽃 인스턴스, 꽃 선택용 매핑 | 월 데이터 세대 | 월 교체/실패/비활성화 |
| 꽃 geometry·material·texture | 해당 URL의 현재 소유자 | 마지막 사용 종료. 기본은 월 간 캐시 없음 |
| 원본 GLTF와 parser·배열 참조 | 개별 로딩 작업 | 인수 완료 또는 실패 직후 |
| ImageBitmap·공유 이미지 소스 | 이를 참조하는 모든 texture의 소유자 | 마지막 이미지 사용자 종료 |
| RAF, 타이머, 이벤트, tween | 등록한 세션/요청 | 취소·비활성화·종료 |

- [ ] geometry/material/texture뿐 아니라 `InstancedMesh.dispose()`도 호출한다. geometry 해제만으로 인스턴스 전용 버퍼 정리를 대신하지 않는다. r160은 InstancedMesh의 dispose 이벤트를 받아 instanceMatrix/instanceColor 버퍼를 제거한다. [InstancedMesh](https://github.com/mrdoob/three.js/blob/r160/src/objects/InstancedMesh.js), [WebGLObjects](https://github.com/mrdoob/three.js/blob/r160/src/renderers/webgl/WebGLObjects.js).
- [ ] 같은 해제 범위에서 geometry/material/texture/bitmap별 Set을 두어 중복 해제를 막는다. Set은 중복 방지용이며, 범위를 넘는 공유 소유권은 참조 수 또는 명시적 소유권 이전으로 해결한다.
- [ ] material 배열을 지원한다. 현재 `child.material.clone()`은 배열이면 사용할 수 없으므로 각 material을 처리한다.
- [ ] material이 실제 참조하는 texture를 수집한다. 고정 `textureKeys` 목록의 누락을 검토하고, 현재 사용하는 material 타입 및 향후 ShaderMaterial uniform을 처리할 범위를 명시한다.
- [ ] texture GPU 해제와 ImageBitmap CPU 해제를 구분한다. 마지막 사용 시 `texture.dispose()`와 소유한 bitmap의 `close()`를 처리한다. 같은 bitmap을 공유하는 다른 texture가 있으면 조기 close하지 않는다. 이미지가 HTMLImageElement인 경우에는 bitmap API를 호출하지 않는다.
- [ ] skeleton·render target·worker·object URL 등은 실제 생성 여부를 조사하고, 생성되는 자원에 한해 대응 해제를 추가한다.
- [ ] scene 연결, userData 매핑, 배열, Map, Promise 결과·클로저 참조를 제거한다. scene에서 제거하는 것만으로 해제가 끝났다고 판단하지 않는다.
- [ ] 해제 함수는 두 번 호출하거나 초기화가 일부만 끝난 상태에서 호출해도 안전하게 만든다.

Three.js는 geometry/material/texture 해제를 각각 관리하며, bitmap의 close는 앱이 소유권을 판단하여 수행해야 한다. [r160 리소스 해제 지침](https://github.com/mrdoob/three.js/blob/r160/docs/manual/en/introduction/How-to-dispose-of-objects.html).

**완료 조건:** 정상 완료·중간 실패·오래된 세대·중복 해제에 같은 소유권 규칙이 적용된다. 공유 texture 사용 중 해제로 인한 검은 꽃, 깨진 재질, 재업로드 반복이 없다.

## 04. 로딩을 제한하고 실패·취소 결과 즉시 회수

**작업 파일:** `assets/www/main.js`의 `initGarden()` 및 미리보기 로딩.

- [ ] 무제한 `uniqueUrls.map` + `Promise.all`을 대기열로 교체한다. 동시 모델 로딩·파싱 작업은 우선 **1개**로 시작하고, 실측으로 필요할 때 **2개**를 비교한다. 한 GLB 내부 이미지 디코딩은 별도 병렬 작업이 될 수 있음을 기록한다.
- [ ] 슬롯은 요청 시작부터 parse·인수/회수 완료까지 점유한다. 세대가 바뀌어도 취소되지 않은 작업의 슬롯을 곧바로 반환하지 않는다. 월 요청마다 별도 제한기를 만들어 전체 동시 작업 수가 증가하는 구조를 피한다.
- [ ] 새 월 요청이 오면 이전 대기 작업을 폐기하고 최신 월만 남긴다. 이미 진행 중인 작업은 지원 가능한 범위에서 취소하고, 취소 불가능한 결과는 도착 직후 세대 검사 후 해제한다.
- [ ] 로딩 결과를 하나씩 인스턴스로 변환하고 원본 정리를 끝낸 뒤 다음 작업을 진행한다. 모든 GLTF 원본을 결과 배열에 모아두지 않는다.
- [ ] 요청 세대는 로딩 완료, 파싱 완료, scene 인수 직전, 오류 표시 직전에 확인한다. 종료된 세션 결과는 새 세션에 추가하지 않는다.
- [ ] 한 꽃 로딩이 실패하면 해당 월 꽃 배치를 실패로 정리하는 정책을 기본으로 한다. 이미 인수한 꽃, 성공했지만 미인수인 결과, 나중에 도착한 결과를 모두 회수한다. 나무만 유지하고 재시도 가능한 오류 상태를 표시한다.
- [ ] 나무 로딩 실패, 빈 월, 잘못된 감정 값, 로딩 중 종료, 연속 월 이동에도 loading UI와 내부 상태를 정리한다. GLTF parse 자체가 중간 실패하여 결과를 반환하지 않는 경우에는 loader 내부의 이미지·부분 생성 리소스 회수 가능 범위를 별도로 조사한다. 추적할 수 없는 경로는 한계로 기록하고 필요 시 loader 보완이나 실패한 뷰어 세션 폐기를 적용한다.
- [ ] `AbortController`를 쓸 경우 실제 요청에 signal이 전달되는 경로인지 확인한다. r160 `GLTFLoader.load()`가 임의의 signal을 받는다고 가정하지 않는다. 자체 fetch + parse를 선택하면 외부 리소스·상대 URL과 parse 이후 회수도 검증한다. parse 시작 후에는 취소로 메모리가 즉시 사라진다고 가정하지 않는다. [r160 GLTFLoader 구현](https://github.com/mrdoob/three.js/blob/r160/examples/jsm/loaders/GLTFLoader.js).
- [ ] 미리보기 catalog fetch도 세션/요청 세대에 포함하여, 늦은 catalog 결과가 종료 후 정원을 다시 만들지 못하게 한다.

**완료 조건:** 연속 월 이동 30회에도 모델 작업 동시 상한을 지킨다. 404·손상 GLB·파싱 지연을 주입해도 모든 성공 결과가 인수 또는 해제로 종결된다. 이전 월이 뒤늦게 표시되지 않는다.

## 05. 원본 중복 할당 축소와 월 교체 범위 축소

**작업 파일:** `assets/www/main.js`, `garden_screen.dart`.

- [ ] 나무는 동일 뷰어·동일 URL 동안 한 번 로딩한다. 월 변경은 꽃 데이터만 교체하고, 나무 URL/버전 변경이나 뷰어 종료 때 해제한다.
- [ ] 최소 수정안은 현재의 geometry clone + 노드 변환 bake를 유지하되, 인스턴스로 인수한 직후 원본 geometry/material과 GLTF 참조를 정리한다. clone된 material과 원본 material이 texture를 공유한다는 점을 반영하여 texture 소유권을 이전한다.
- [ ] 추가 개선안으로 원본 geometry/material을 직접 인수하고, `꽃 배치 행렬 × 원본 노드의 matrixWorld`를 instance 행렬에 반영하여 clone/bake를 없앨 수 있는지 검토한다. 일반 Mesh부터 적용 가능성을 확인하고 skinned/morph·다중 material 자산은 별도 처리한다. 최종 경로 하나를 선택하고 이유를 기록한다.
- [ ] 위치·일기 ID·미리보기 label 매핑은 꽃 URL별로 한 벌만 만들고 해당 파트들이 공유한다. 현재처럼 같은 일기의 Vector3와 객체를 각 mesh 파트마다 복제하지 않는다.
- [ ] 배치가 바뀐 InstancedMesh의 bounding box/sphere를 재계산하여 culling·raycast 오류를 막는다. 인스턴싱은 계속 유지한다.
- [ ] 쓰이지 않는 `flowerData`, `diaryIds` 등은 실제 참조를 확인하고 제거한다.
- [ ] 기본은 현재 월만 보유한다. 꽃 종류 전체 preload나 모든 월 GLTF 캐시는 추가하지 않는다. 캐시가 필요하다고 판단하면 최대 보유량·퇴출·마지막 소유자 해제 규칙과 실측 이익을 먼저 제시한다.

**완료 조건:** 월 이동 때 나무 로딩·파싱이 반복되지 않는다. 원본과 clone의 동시 보유 기간이 최소화되고, 공유 재질·꽃 위치·터치 ID 매핑이 유지된다.

## 06. 월 정리·일시 중단·뷰어 종료 API 분리

**작업 파일:** `assets/www/main.js`.

기존 `disposeGarden()`의 역할을 명확하게 나눈다. 아래 이름은 설계 예시이며 실제 명칭은 통일해서 사용한다.

| API 역할 | 처리 | 이후 동작 |
|---|---|---|
| `clearGardenContent()` | 월 요청 무효화, 대기 꽃 취소, 해당 월 꽃과 선택 참조 해제 | 동일 나무·바닥·renderer로 새 월 로딩 가능 |
| `pauseGarden()` | 입력·RAF·tween 중단, 신규 모델 작업 중단, 재개용 최소 상태 저장 | 활성 복귀 시 재개 또는 최신 월 재로딩 |
| `destroyGardenViewer()` | 모든 요청 무효화, 전체 리소스·이벤트·renderer 정리 | 새 세션을 생성해야 사용 가능 |

- [ ] `requestRender()`에 활성·종료 가드를 넣고 RAF ID를 저장한다. pause/destroy에서 `cancelAnimationFrame()`하며, 취소 후 예약 플래그도 초기화한다. 렌더 도중 예외가 나도 running 플래그가 고정되지 않게 한다.
- [ ] 기존 요청 기반 렌더링과 damping 종료까지의 렌더링을 유지한다. 상시 `requestAnimationFrame` 루프로 되돌리지 않는다.
- [ ] 카메라와 controls.target의 GSAP tween을 정지하고, 오래된 onComplete가 Flutter 상세 시트를 열지 못하도록 세대·활성 상태를 검사한다. 정원 소유 tween만 정리한다.
- [ ] resize/click/touch/visibility/pagehide 핸들러를 제거 가능한 참조로 등록한다. controls의 change 리스너와 `controls.dispose()`도 처리한다.
- [ ] 전체 종료 순서는 종료 플래그·세대 무효화 → 작업·RAF·타이머·tween 중단 → 이벤트·controls 해제 → 꽃·나무·바닥·shadow target 등 해제 → renderer 정리 → canvas·진단 UI·참조 제거로 한다.
- [ ] 전체 종료에서 `renderer.dispose()`를 호출한다. 폐기한 canvas의 context 반납이 필요하면 지원 여부를 확인하여 `forceContextLoss()`를 적용한다. 월 교체에는 호출하지 않고, 폐기한 renderer를 다시 사용하지 않는다. [r160 renderer 구현](https://github.com/mrdoob/three.js/blob/r160/src/renderers/WebGLRenderer.js).
- [ ] `webglcontextlost/restored`를 처리한다. 예기치 않은 손실에는 루프 재시도를 막고 최신 데이터로 한 번 재생성할 수 있게 한다. 의도적 destroy에 따른 손실은 복구하지 않는다.
- [ ] `pagehide`는 보조 정리 경로로 연결한다. 정상 종료의 주 경로는 Flutter에서 명시적으로 호출한다.

**완료 조건:** destroy 후 새 scene 추가·렌더·상세 시트 콜백이 없다. 이벤트·RAF·타이머·소유 리소스 수가 해당 종료 기준으로 돌아오고, 새 세션 생성 후 정상 작동한다. 내부 엔진 캐시 때문에 `renderer.info`가 반드시 0이어야 한다는 조건은 두지 않는다.

## 07. Flutter 탭·앱 수명주기와 종료 순서 연결

**작업 파일:** `garden_screen.dart`, `root_shell.dart`, 필요 시 정원 전용 수명주기 controller.

메모리 절감을 우선하여 아래 정책을 기본으로 구현한다. `IndexedStack`에 남아 있는 정원은 가벼운 상태만 유지하게 한다.

| 상황 | 기본 정책 |
|---|---|
| 월 이동 | 동일 뷰어 유지, 이전 꽃 해제 후 최신 월 로딩 |
| 다른 하단 탭으로 이동 | 뷰어 전체 종료, WebViewWidget 제거·controller 참조 반납, 서버 종료. 선택 월 등 최소 상태 보존 |
| 다른 탭에서 정원 복귀 | 새 뷰어 생성, 보존한 월의 최신 데이터 주입 |
| 돌봄수첩 등 별도 route에 완전히 가려짐 | 우선 pause, 오래 유지되면 아래 백그라운드와 같은 해제 정책 적용 |
| Flutter 상세 bottom sheet 표시 | 전체 종료하지 않음. 카메라 이동 완료 후 불필요한 렌더·입력 정지, 닫힐 때 복귀 |
| 앱 inactive/hidden/paused | 즉시 pause·대기 로딩 무효화. 최초 기준 5초 후에도 비활성이면 전체 종료, 복귀하면 재생성 |
| OS 메모리 압박 | 5초 대기 없이 리소스 반납. 현재 표시 중이면 재로딩 반복을 막고 재시도 상태 제공 |
| 로그아웃·정원 영구 제거 | 전체 종료 및 서버·채널 정리 |

- [ ] RootShell의 탭 활성 여부를 정원에 명시적으로 전달한다. Offstage나 `TickerMode`만으로 WebView의 JS·GPU가 정리된다고 가정하지 않는다. route 가림은 별도 관찰한다.
- [ ] `WidgetsBindingObserver` 또는 동등한 API로 앱 수명주기와 메모리 압박을 연결한다. JS `visibilitychange`만으로 앱/탭 상태가 전달된다고 가정하지 않는다. 등록한 observer는 종료 시 해제한다. [Flutter 메모리 압박 콜백](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didHaveMemoryPressure.html).
- [ ] nullable controller/명시적 상태를 사용해 `late` 초기화 전 접근을 막는다. 서버 start, WebView 설정, loadRequest 등 각 await 후 세션 ID·mounted·활성 여부를 확인하고, 이미 종료되었으면 늦게 생성된 자원도 정리한다.
- [ ] 준비 상태는 `starting → ready → loading → active/paused → destroying → destroyed`처럼 관리한다. starting/ready 중 종료와 재진입도 처리하고 이전 세션의 종료 완료가 새 세션을 지우지 못하게 한다.
- [ ] 100ms 무한 재귀 타이머를 정원 준비 handshake와 최신 요청 한 건 보관 방식으로 교체한다. 제한 시간·실패 UI를 두고, 숨김·종료 시 예약을 취소한다.
- [ ] JS 브리지는 ready/destroyed/error/flower/tree 등 메시지 타입과 세션 ID를 구분한다. 현재처럼 모든 비어 있지 않은 문자열을 꽃 ID로 보내지 않도록 수정한다.
- [ ] 정상 탭 이동·로그아웃에서는 종료 coordinator가 JS destroy 완료 응답을 제한 시간 내 기다린 후 WebView를 제거하고 서버를 닫는다. 다른 탭 UI를 막지 않으면서 재진입 시 이전 종료와 새 초기화가 경합하지 않게 한다.
- [ ] Flutter `State.dispose()`를 async로 만들지 않는다. 강제 제거·초기화 실패에는 즉시 무효화와 best-effort 종료를 수행하고 비동기 예외를 처리한다. 이미 폐기된 WebView에 JS를 실행할 수 있다고 가정하지 않는다.
- [ ] controller 참조 반납과 플랫폼 view 제거를 검증한다. 공통 `WebViewController.dispose()`가 있다고 가정하지 말고 설치된 플러그인의 실제 API를 확인한다. `clearCache()`를 매번 호출하는 방식은 GPU·JS 해제의 대체책으로 쓰지 않는다. [WebViewController 최신 API 참고](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html). 실제 구현은 lockfile의 4.14.1 및 플랫폼 패키지 버전에서 확인한다.
- [ ] 서버 stop은 중복 호출·시작 중 종료에도 안전하게 만든다. 동일 8080 포트의 이전 서버 종료를 기다린 뒤 새 서버를 시작하거나, 세션별 포트와 동적 URL을 사용한다. 서버 수는 실제 활성 뷰어 정책과 일치해야 한다.

**완료 조건:** 느린 초기화 중 탭 이동·로그아웃·즉시 재진입에도 LateInitializationError, setState-after-dispose, 포트 충돌, 늦은 상세 시트 표시가 없다. 숨긴 정원의 WebView가 계속 유지되지 않으며 선택 월은 복원된다. OS의 네이티브 메모리 반환 지연은 별도로 측정한다.

## 08. 렌더 버퍼·합성 비용 추가 절감

**작업 파일:** `assets/www/main.js`, `garden_screen.dart`.

- [ ] 모바일 기본 DPR을 우선 **1.0**, antialias를 **false**로 바꿔 측정한다. DPR 1.5는 확대 가독성에 필요하고 메모리 여유가 확인될 때 비교한다. DPR 2 대비 DPR 1의 출력 픽셀 수는 같은 CSS 크기에서 1/4이지만 앱 전체 메모리가 1/4로 줄어든다는 뜻은 아니다.
- [ ] resize·회전·재생성에서도 같은 DPR 정책을 적용한다. 반복 이벤트를 합쳐 불필요한 render target 재할당을 줄인다.
- [ ] 현재 scene.background가 불투명한 점을 고려하여 renderer `alpha: false` 적용을 비교한다. Flutter 겹침 UI와 시각 결과를 확인하고 효과가 없거나 호환성이 떨어지면 보류한다.
- [ ] 꽃·나무 확대 시 전체 화면 `BackdropFilter`가 플랫폼 view 위에서 어떤 합성 비용과 시각 결과를 만드는지 실측한다. 비용이 확인되면 단색/반투명 overlay로 대체한다. 변경 전후 화면을 첨부한다.
- [ ] raycast 대상을 상호작용 가능한 꽃·나무로 한정하고, 탭마다 불필요한 임시 배열 할당을 줄인다. culling을 임의로 끄지 않는다.
- [ ] 재질 단순화, geometry 병합, 공간별 인스턴스 분할은 추가 후보로 평가한다. 외형, draw call, culling, 정점 메모리의 전후 이익이 확인되는 경우 적용한다. 이미 동작하는 instancing을 없애지 않는다.

**완료 조건:** 채택한 설정의 전후 수치와 확대 화면 비교가 있다. 정지·숨김 상태에서는 정원 소유 렌더가 지속되지 않는다. 조건부 항목마다 적용·보류 근거를 남긴다.

## 09. 에셋 공급·디코딩·캐시 추가 검토

**작업 파일:** `local_asset_server.dart`, 필요 시 별도 에셋 공급 계층.

- [ ] 04의 동시 로딩 제한 후에도 Dart GLB 버퍼와 WebView 디코딩이 만드는 피크가 큰지 측정한다. 미리보기뿐 아니라 실제 운영 매핑으로 확인한다.
- [ ] 요청별 `ByteData`·응답 버퍼의 수명을 점검한다. 앱에 별도 전체 GLB 메모리 캐시를 추가하지 않는다. 현재 `asUint8List`는 buffer view이므로 그것만으로 추가 전체 복사가 발생한다고 단정하지 않는다.
- [ ] 공급 비용이 크면 플랫폼 asset URL 또는 파일 기반 스트리밍을 검토한다. `rootBundle.load()`로 전체를 읽은 뒤 Stream으로 감싸는 것은 전체 버퍼 할당을 피하는 해결책이 아니다. 기존 상대 URL·CORS·MIME·캐시 버전 처리를 검증하고 실측 이익이 있는 경로를 채택한다.
- [ ] `THREE.Cache`를 무제한으로 활성화하지 않는다. 직접 만든 리소스 캐시를 포함해 모든 메모리 캐시는 소유권·최대량·퇴출·압박 시 비우기 규칙을 갖게 한다. HTTP 캐시와 디코딩 객체/GPU 캐시를 구분한다.
- [ ] 텍스처별 해상도·형식·mipmap을 조사한다. 실행 중 축소는 디코딩 피크를 먼저 발생시킬 수 있으므로 보장된 피크 해결책으로 취급하지 않는다.
- [ ] KTX2/Basis GPU 압축 텍스처, Draco/Meshopt geometry 압축은 에셋 파이프라인이 필요한 후속 후보로 구분한다. 적용 시 decoder/transcoder worker와 해제까지 포함하고, 다운로드 크기 감소를 그대로 RAM 감소로 보고하지 않는다.
- [ ] 저해상도/LOD 자산이 필요한 경우 별도 GLB 작업 목록에 요구 사항을 전달할 수 있도록 문서에 적는다. 이번 코드 작업의 완료와 에셋 작업의 완료 상태를 각각 남긴다.

**완료 조건:** 공급 경로와 캐시의 최대 보유 범위가 설명되어 있고, 추가 변경의 실측 이익 또는 보류 근거가 있다. 이 단계에서 남은 에셋 의존 사항은 후속 작업으로 명시한다.

## 10. 회귀·실기기 검증과 인계

**검증 순서:** 코드 정적 검사 → 실패 경로 자동 검증 → 실제 폰 반복 시나리오 → release 확인.

- [ ] `flutter analyze`, 기존 `flutter test`를 실행하고 기존 실패와 신규 실패를 구분한다.
- [ ] 해제 함수의 중복 호출, 공유 texture/bitmap 마지막 소유자 해제, 인스턴스 해제, 일부 로딩 실패 후 늦은 성공, 오래된 세대 폐기, 동시 작업 상한을 검증하는 자동 테스트를 추가한다. 단순히 소스에 dispose 문자열이 있는지 검사하는 테스트는 사용하지 않는다.
- [ ] 실제 WebGL/WebView에서 dispose 경로를 별도 확인한다. mock dispose 호출 횟수만으로 GPU 해제까지 검증했다고 보고하지 않는다.
- [ ] 아래 시나리오를 같은 기기·데이터·빌드 모드로 변경 전후 각 3회 수행한다. 데이터나 기기 상태가 다르면 비교표에 표시한다.

| 시나리오 | 확인할 결과 |
|---|---|
| 꽃 0·30·60송이 및 운영상 최대 규모 진입 | 로딩 피크, 안정 메모리, 표시 누락 없음 |
| 전/다음 월 빠르게 30회 이동 | 최신 월만 표시, 동시 상한 준수, 오래된 결과 회수 |
| 정원 ↔ 다른 탭 30회 왕복 | 뷰어 재생성 수명 일치, 누적 canvas·context·리스너 없음 |
| 꽃·나무 상세 보기/복귀 각 20회 | 올바른 ID, 카메라 복귀, 합성·tween 잔존 없음 |
| 로딩 중 탭 이동·로그아웃·재진입 각 10회 | 늦은 서버·WebView·scene 생성 없음, 포트 충돌 없음 |
| 백그라운드 1초 및 10초 후 복귀 각 10회 | 짧은 pause 복귀와 전체 해제 후 복원 모두 정상 |
| OS 메모리 압박 알림 또는 개발용 주입 | 해제 정책 실행, 자동 재할당 루프 없음. 주입 테스트와 실제 압박을 구분 |
| 404·손상 GLB·지연 로딩·context loss | 오류 UI, 소유 자원 회수, 통제된 재시도 |
| 22종 전체 미리보기 | 그림자 해제·대기열·탭 선택·전체 복귀 모두 정상 |

### 최종 완료 판단

1. 필수 수정 02~07이 구현되고 위 회귀 시나리오에서 신규 오류가 없다.
2. 같은 월로 돌아온 안정 상태에서 자원 소유 수가 반복 횟수에 비례해 늘지 않는다. 초기 워밍업·엔진 캐시를 구분하고, 10/20/30회 종료 시점의 추세를 확인한다.
3. 동일 시나리오의 로딩 피크와 안정 메모리가 기준 측정보다 개선되었음을 수치로 제시한다. 개선이 없거나 악화된 단계는 원인을 조사하고 채택 여부를 재검토한다.
4. 실기기 반복에서 OOM·WebView 프로세스 종료·지속적 context loss가 없다. 이 결과를 모든 스마트폰의 안전성 보장으로 확대하지 않는다.
5. 01에서 선정한 최저 사양 기기의 측정에 따라 앱·WebView 메모리 예산과 복귀 시간 목표를 정하고 충족 여부를 적는다. 기기 근거 없이 “전체 100MB 이하” 같은 공통 상한을 설정하지 않는다.
6. 08~09의 모든 후보에 적용·보류·에셋 의존 상태와 근거가 있다. 실제 폰 검증이 남으면 작업 상태를 “구현 완료 / 실기기 검증 대기”로 표시한다.

### 담당자 제출물

- 단계별 커밋 또는 검토 가능한 변경 묶음.
- 리소스 소유권과 생성·해제 API 설명.
- `docs/garden_memory_optimization_results.md`: 기기 정보, 기준·최종 커밋, 테스트 데이터, 측정표, 실패 주입 결과, 미측정·미해결 사항.
- 그림자 해제, DPR/AA, 확대 overlay 변경 전후 화면 캡처.
- 추가 에셋 요청과 코드로 해결한 항목의 완료 상태.

결과 문서의 기본 측정표:

| 기기/모드/커밋 | 데이터·시나리오 | 앱 메모리 지표·단위 | WebView 지표·단위 | 로딩 피크 | 10초 안정값 | 10/20/30회 안정값 | 자원 수 | 복귀 시간 | 판정 |
|---|---|---|---|---|---|---|---|---|---|
| 기입 | 기입 | RSS/PSS/footprint 등 구분 | 프로세스·도구 명시 | 기입 | 기입 | 기입 | 기입 | 기입 | 기입 |

각 메모리 값은 어느 프로세스의 어떤 지표인지 함께 적는다. 프로세스 종료나 GPU 자원 해제 이후에도 OS·드라이버가 페이지를 유지할 수 있으므로 “즉시 처음과 같은 RSS”만을 해제 성공 조건으로 삼지 않는다.
