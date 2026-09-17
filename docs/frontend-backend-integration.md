# Flutter 프론트엔드 ↔ 백엔드 첫 연동 가이드

이 문서는 이 프로젝트에서 인증 API를 연결하며 적용한 방식과, 처음 연결할 때 자주 막히는 지점을 정리한 기록이다. 현재 실제로 연결된 범위는 **회원가입**과 **로그인**이며, 가족 그룹·정원·기록 API는 아직 화면 데이터와 연결되어 있지 않다.

## 1. 연결 구조 한눈에 보기

```text
LoginScreen / SignupScreen
        ↓
AuthService (HTTP 요청·응답·오류 변환)
        ↓
ApiConfig (실행 환경별 API_BASE_URL)
        ↓
백엔드 /api/v1/auth/signup, /api/v1/auth/login
        ↓
AuthSession (로그인 토큰을 앱 메모리에 보관)
```

화면에서 `http`를 직접 호출하지 않고 `AuthService`에 모아 두었다. 이 방식이면 요청 형식, 상태 코드 처리, 시간 제한을 한 곳에서 관리할 수 있고 다음 API도 같은 패턴으로 추가하기 쉽다.

## 2. 시작 전 확인할 것

- 백엔드가 실행 중이어야 한다.
- 프론트가 호출할 주소는 `/api/v1`까지 포함해야 한다. 예: `http://localhost:8000/api/v1`
- 실제 휴대폰에서 PC의 `localhost`는 휴대폰 자신을 뜻한다. PC IP 또는 외부에 배포된 HTTPS 주소를 써야 한다.
- Android 에뮬레이터에서 개발 PC의 `localhost`는 `10.0.2.2`로 접근한다.
- 웹 브라우저로 실행하면 백엔드 CORS 허용 출처에 프론트 주소(예: `http://localhost:5173`)를 등록해야 한다.

## 3. 서버 주소 설정

### 권장: `env.json` + `--dart-define-from-file`

프로젝트 루트의 `env.json`에 다음처럼 작성한다. 이 파일은 `.gitignore`에 포함되어 있으므로 개인/환경별 주소를 커밋하지 않는다.

```json
{
  "API_BASE_URL": "https://<backend-host>/api/v1"
}
```

실행한다.

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

VS Code에서는 [`.vscode/launch.json`](../.vscode/launch.json)에 이미 같은 인자가 설정되어 있다. Flutter 실행 설정을 이용하면 Chrome을 `localhost:5173`으로 열고 `env.json`도 함께 전달한다.

`env.json`은 Flutter가 저절로 읽는 파일이 아니다. 반드시 위처럼 `--dart-define-from-file=env.json`을 전달해야 한다. 다른 IDE나 CI에서도 같은 인자를 넣는다.

### 주소를 전달하지 않았을 때의 기본값

[`lib/config/api_config.dart`](../lib/config/api_config.dart)에서 다음 기본 주소를 사용한다.

| 실행 환경 | 기본 주소 |
| --- | --- |
| Android 에뮬레이터 | `http://10.0.2.2:8000/api/v1` |
| iOS 시뮬레이터·웹·데스크톱 | `http://localhost:8000/api/v1` |

설정값 끝의 `/`는 자동으로 제거한다. 따라서 `.../api/v1/`을 입력해도 API 경로가 `//auth/login`으로 만들어지지 않는다.

## 4. 백엔드와 합의한 인증 계약

프론트의 현재 요청/응답 기대값은 아래와 같다. 백엔드 스키마가 바뀌면 화면보다 먼저 [`lib/services/auth_service.dart`](../lib/services/auth_service.dart)를 수정하고 테스트를 갱신한다.

### 회원가입

```http
POST {API_BASE_URL}/auth/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password1!",
  "name": "사용자",
  "phone_number": "010-1234-5678"
}
```

성공은 `201 Created`이며, 다음 필드를 기대한다.

```json
{
  "id": "user-id",
  "email": "user@example.com",
  "name": "사용자"
}
```

현재 서버 구현에서 Supabase 가입 오류가 `400`으로 내려오고, API 명세에는 중복 계정이 `409`로 정의된 차이가 있었다. 그래서 프론트는 `400`과 `409`를 모두 “이미 가입된 이메일이거나 사용할 수 없는 계정 정보”로 안내한다. `422`는 입력 형식 오류로 처리한다.

### 로그인

```http
POST {API_BASE_URL}/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password1!"
}
```

성공은 `200 OK`이며, 다음 토큰 필드가 반드시 필요하다.

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "bearer"
}
```

`token_type`은 없으면 프론트에서 `bearer`로 간주한다. `401`은 이메일/비밀번호 불일치, `422`는 요청 값 형식 오류로 표시한다. 네트워크 오류와 15초 초과는 “서버에 연결할 수 없습니다”로 안내한다.

## 5. 프론트에서 수정한 부분

| 위치 | 수정 내용 | 이유 |
| --- | --- | --- |
| `pubspec.yaml` | `http` 패키지 추가 | Flutter에서 REST 요청을 보낼 클라이언트가 필요함 |
| `lib/config/api_config.dart` | `API_BASE_URL`과 플랫폼별 로컬 기본 주소 추가 | 소스 수정 없이 로컬·배포 서버를 전환 |
| `lib/services/auth_service.dart` | 회원가입/로그인 POST, JSON 변환, 상태 코드·timeout 처리 | 네트워크 로직을 화면에서 분리 |
| `lib/screens/auth/signup_screen.dart` | 실제 가입 요청, 진행 중 중복 탭 방지, 오류 SnackBar | UI 입력값을 백엔드 계약에 맞춰 전송 |
| `lib/screens/auth/login_screen.dart` | 실제 로그인 요청, 토큰 저장, 성공 시 화면 전환 | 더미 화면 전환을 실제 인증 흐름으로 교체 |
| `lib/data/auth_session.dart`, `lib/main.dart` | `AuthSession`을 Provider로 등록 | 로그인 직후 토큰을 앱 전체에서 꺼낼 기반 마련 |
| Android/iOS 설정 | 로컬 HTTP 개발을 위한 네트워크 허용 설정 | 개발 서버 접근 시 플랫폼 차단 방지 |
| `.vscode/*`, `.gitignore` | `env.json` 전달 설정 및 Git 제외 | 환경별 URL을 안전하고 편하게 관리 |

회원가입 화면의 이메일/비밀번호 검증도 백엔드 요청 직전에 유효하지 않은 값을 막도록 조정했다. 비밀번호 규칙은 영문·숫자·특수문자를 포함한 8~16자다.

## 6. 플랫폼별 시행착오와 해결법

### `localhost`가 연결되지 않을 때

가장 흔한 원인이다. 실행 주체별 `localhost`가 다르다.

| 실행 위치 | 백엔드가 내 개발 PC에 있을 때 사용할 주소 |
| --- | --- |
| Chrome 웹 | `http://localhost:8000/api/v1` |
| Android 에뮬레이터 | `http://10.0.2.2:8000/api/v1` |
| iOS 시뮬레이터 | 보통 `http://localhost:8000/api/v1` |
| 실제 Android/iPhone | `http://<개발-PC-LAN-IP>:8000/api/v1` 또는 HTTPS 배포 주소 |

### HTTP가 플랫폼에서 막힐 때

개발용 로컬 서버가 HTTP라면 Android 9 이상에서는 cleartext 트래픽이 막힐 수 있다. 이 프로젝트는 [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)의 `android:usesCleartextTraffic="true"`로 로컬 개발을 허용했다. iOS는 [`ios/Runner/Info.plist`](../ios/Runner/Info.plist)의 `NSAllowsLocalNetworking`을 추가했다.

운영에서는 HTTP 허용을 넓게 유지하지 말고 HTTPS API를 사용한다. 배포된 백엔드 주소가 HTTPS라면 이 설정에 의존하지 않는다.

### 웹에서만 CORS 오류가 날 때

Flutter 코드 문제가 아니라 브라우저 보안 정책일 가능성이 높다. 백엔드 CORS 설정에 프론트 origin을 추가한다. 개발 중 VS Code 설정은 `http://localhost:5173`을 사용하므로, 예를 들면 FastAPI에서는 해당 origin을 `allow_origins`에 등록한다. `*` 허용은 인증 쿠키 등 자격 증명 설정과 함께 사용할 수 없고 운영에선 지양한다.

### 주소는 맞는데 “서버에 연결할 수 없습니다”가 나올 때

`AuthService`는 DNS 실패, 연결 거절, 인증서 오류, timeout 등을 같은 사용자 메시지로 바꾼다. 원인을 확인할 때는 다음 순서가 빠르다.

1. 브라우저/Postman/curl로 `API_BASE_URL`의 서버가 실제 실행 중인지 확인한다.
2. 앱 실행 명령에 `--dart-define-from-file=env.json`이 포함되었는지 확인한다.
3. 에뮬레이터/실기기라면 위 표의 주소 규칙과 방화벽을 확인한다.
4. 백엔드 로그에서 요청이 도착했는지, 상태 코드와 응답 본문은 무엇인지 확인한다.

## 7. 새 API를 연결하는 표준 절차

1. 백엔드 담당자와 경로, HTTP 메서드, 요청 JSON, 성공 상태 코드/본문, 실패 상태 코드를 먼저 합의한다.
2. 기능별 서비스(예: `DiaryService`)에 `http.Client`를 주입 가능하게 만들고, `ApiConfig.baseUrl`을 사용한다.
3. 요청에는 `Content-Type: application/json`, 본문에는 `jsonEncode`를 사용한다.
4. 응답 JSON은 파싱 실패에도 앱이 죽지 않게 처리하고, 화면에 보여 줄 오류 메시지로 상태 코드를 변환한다.
5. 로그인 뒤 필요한 API에는 아래처럼 access token을 넣는다.

```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer ${context.read<AuthSession>().tokens!.accessToken}',
}
```

서비스 계층에서는 `BuildContext`에 직접 의존하지 않는 편이 좋다. 호출하는 화면/Repository가 토큰을 전달하거나, 별도 인증 HTTP 클라이언트를 만들어 헤더를 일괄 주입한다.

6. 성공·대표 오류·요청 JSON을 검증하는 단위 테스트를 추가한다.
7. 웹, Android 에뮬레이터, 필요하면 실기기에서 각각 URL/CORS/HTTP 정책을 확인한다.

## 8. 현재 남은 작업과 주의점

- `AuthSession`은 **메모리**에만 토큰을 저장한다. 앱을 재시작하면 로그인 상태가 사라진다. 자동 로그인에는 `flutter_secure_storage` 같은 안전한 저장소와 refresh-token 갱신 API가 필요하다.
- 로그인 토큰을 후속 API의 `Authorization` 헤더에 자동으로 넣는 공통 클라이언트는 아직 없다.
- 로그아웃 시 `AuthSession.signOut()` 호출과 로그인 화면으로의 라우팅을 연결해야 한다.
- 토큰, 비밀번호, 실제 운영 주소가 담긴 `env.json`은 절대 커밋하지 않는다. 팀 공유가 필요하면 `env.example.json`에는 값 없이 키 이름만 둔다.
- 응답의 `id` 타입이 UUID 문자열이 아닌 숫자 등으로 바뀌면 `SignupResult` 파싱도 함께 변경해야 한다.

## 9. 검증 방법

현재 회원가입 요청 규격은 [`test/auth_service_test.dart`](../test/auth_service_test.dart)에서 검증한다.

```bash
flutter test test/auth_service_test.dart
```

테스트는 `POST /api/v1/auth/signup`, JSON 키(`name`, `phone_number` 포함), `201` 성공 응답, `400` 가입 오류 변환을 확인한다. 실제 백엔드 연결 여부는 별도로 앱을 실행해 테스트 계정으로 회원가입과 로그인을 수행하고, 백엔드 로그까지 함께 확인한다.
