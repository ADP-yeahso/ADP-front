# 프론트엔드 API 연결

2026-10-28 배포 서버의 OpenAPI와 `ADP-back/backend/app` 구현을 대조해 연결했습니다.

`connecting-api`에서 기존 미커밋 작업을 `2d193e5`로 보존하고, `origin/front-develop`의 `6a03c0e`까지 병합했습니다. 최신 달력·상세·기록 작성 화면과 에셋을 유지하며 API 흐름을 연결했습니다.

## 실행

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

`env.json`에는 `/api/v1`을 포함한 주소를 넣습니다.

```json
{
  "API_BASE_URL": "https://adp-back-production.up.railway.app/api/v1"
}
```

VS Code의 Android, 기본 기기, Chrome 실행 설정 모두 이 파일을 사용합니다. 값을 전달하지 않으면 `ApiConfig.productionBaseUrl`의 배포 주소를 사용합니다. Android에서 로컬 서버를 사용할 때는 `http://10.0.2.2:8000/api/v1`, 실제 휴대폰에서는 개발 PC의 LAN IP를 지정합니다. 브라우저에서는 백엔드 CORS에 프론트 origin을 허용해야 합니다.

## 연결 범위

| 화면 | 사용 API / 동작 |
| --- | --- |
| 회원가입·로그인 | `POST /auth/signup`, `POST /auth/login` |
| 가족 목록·참여 | `GET /groups`, `POST /groups/join` |
| 가족 생성 | `POST /groups` → `POST /groups/{id}/patients` → `PATCH /groups/{id}/members/me` |
| 그룹 입장·가족 관리 | `GET /users/me`, `GET /groups/{id}`의 실제 이름·멤버·초대 코드 사용 |
| 환자 정보 | `PATCH /patients/{id}`, 환자가 없는 그룹은 `POST /groups/{id}/patients` |
| 프로필 편집 | `PUT /users/me`로 이름·전화번호 저장 |
| 환자 기록 | `POST /patients/{id}/memory-records`, 응답의 실제 ID로 화면 캐시 갱신 |
| 환자 기록 편집·삭제 | `PATCH /memory-records/{id}`, `DELETE /memory-records/{id}` 성공 후 캐시 반영 |
| 감정 일기 | 선택 그룹으로 초안 생성 → 질문 → 답변 → 추천 태그 선택 → 태그를 포함한 `POST /diaries/{id}/finalize` |
| 꽃 기록 편집·삭제 | `PATCH /diaries/{id}`, `DELETE /diaries/{id}`; 확정 일기 편집은 아래 서버 제한 참조 |
| 일기 첨부 | `POST /diaries/{id}/media`, 인증된 multipart 요청·파일 MIME 포함 |
| 정원·달력·감정 분석 | 선택 그룹의 기억과 확정 일기를 페이지 끝까지 조회해 사용 |
| 갤러리 | 일기에 연결된 미디어를 `GET /diaries/{id}/media`의 서명 URL로 표시 |
| 돌봄수첩 | `/care-notes/daily-conditions`, `/behavior-logs`, `/hospital-visits` 저장·조회 |

`AuthSession`은 토큰을 메모리에 보관합니다. 자동 로그인·토큰 갱신은 포함하지 않습니다. 사용자 ID는 Supabase UUID 문자열을 그대로 유지합니다. 로그인과 로그아웃 때 이전 사용자의 화면 데이터를 지웁니다. 로그아웃 API는 배포 서버에 없어 로컬 세션만 종료합니다.

`AppData`는 시작 시 임시 데이터를 만들지 않습니다. 그룹 입장 시 프로필·그룹·환자·기록을 불러오고, API 오류는 재시도 안내로 표시합니다. 뒤늦게 도착한 이전 세션 응답은 반영하지 않습니다. 정원은 캐시가 바뀌면 꽃 데이터를 다시 주입합니다.

달력·정원·갤러리·감정 분석에는 `status=completed`인 일기만 포함합니다. 감정 추천을 받은 초안에도 `final_emotion_id`가 있으므로 ID 유무만으로 완료를 판단하지 않습니다. 중립 감정 ID `0`과 기존 ID `7`을 모두 표시하며, 감정 분포·추이는 본문의 키워드를 재분석하지 않고 서버의 확정 감정을 집계합니다. 추천 태그의 색상은 서버의 부모 감정 ID에 맞춥니다.

새 기록 작성 화면의 로딩은 실제 API 응답이 완료되면 다음 화면으로 이동합니다. 오류가 나면 재시도·돌아가기 버튼을 표시합니다. 최종 저장은 선택 태그를 finalize 요청에 함께 보내므로 이미 완료된 요청을 재시도할 때 태그 저장 단계의 409 오류로 막히지 않습니다. 사진·영상·음성은 각 파일 유형에 맞는 선택창으로 연결됩니다.

일기 초안 생성 이후 질문 생성·첨부 업로드가 실패하면 같은 화면에서 재시도 시 생성된 초안과 업로드 완료 파일을 재사용합니다. 돌봄수첩도 성공한 상태·행동·진료 기록의 ID를 유지해 후속 요청 실패 뒤 재시도가 중복 기록을 만들지 않게 합니다. 서버가 처리한 뒤 응답 자체가 유실된 경우의 완전한 중복 방지는 서버의 idempotency 지원이 필요합니다.

## 필수 백엔드 보완: 그룹에 속한 환자 조회

현재 배포된 `GET /groups/{group_id}`는 환자 ID나 환자 정보를 반환하지 않고, 그룹별 환자 조회 API도 없습니다. 그룹 ID와 환자 ID는 서로 다르므로 같은 값으로 가정할 수 없습니다.

[backend-group-patient.patch](backend-group-patient.patch)는 기존 그룹 상세 응답에 `patient: PatientResponse | null`을 추가합니다. 그룹 멤버 권한 확인 후 환자를 조회합니다. 데이터베이스 변경은 없습니다. 프론트는 이 필드를 읽도록 구현되어 있습니다.

```bash
# ADP-back 저장소에서 실행
git apply /path/to/ADP-front/docs/backend-group-patient.patch
```

인접한 로컬 `ADP-back` 저장소에는 이 패치가 적용되어 있습니다. 다른 체크아웃에 적용할 때만 위 명령을 사용합니다. 2026-10-28 확인한 배포 서버의 `GroupDetail`에는 아직 `patient` 필드가 없습니다.

변경한 백엔드를 배포해야 **기존 그룹의 환자 정보·환자 기록·돌봄수첩 조회**가 정상 동작합니다. 보완 전에도 같은 앱 세션에서 새로 생성한 환자는 생성 응답으로 연결되지만, 재로그인 이후 조회는 보완된 서버가 필요합니다. 환자 정보가 응답에 없으면 임의 ID나 다른 그룹의 데이터로 대체하지 않습니다.

## 배포 API에 아직 없는 기능

아래 항목은 프론트만으로 서버 저장을 구현할 수 없습니다. 저장된 것처럼 로컬 상태를 바꾸는 처리는 제거했습니다.

- 확정 꽃 일기 편집: PATCH 경로는 있으나 백엔드 `update_diary`가 완료된 일기에 409를 반환합니다. 프론트는 서버에 요청하고 거절되면 원본을 유지하며 한국어로 이유를 안내합니다. 환자 기록 편집과 두 종류 기록의 삭제는 지원합니다.

- 환자 기록 첨부: `/media/presign`, 기억 기록 미디어 업로드·등록 API가 없습니다. 첨부가 있는 경우 서버에 글부터 중복 생성하지 않고 저장을 막고 안내합니다.
- 갤러리 직접 추가: 그룹 갤러리 등록·목록 API가 없습니다. 일기 첨부 파일 조회는 동작합니다.
- 댓글·북마크·공개 범위 변경: 대응 API가 없습니다. 공개 범위 스위치는 비활성화하고 댓글 저장은 준비 중 안내를 표시합니다. 환자 기록은 그룹 멤버가, 감정 일기는 작성자가 조회합니다.
- 비밀번호 변경·프로필 사진 업로드: 대응 API가 없어 프로필 저장 항목에서 비밀번호 입력을 제외했습니다.

서버에 없는 `/groups/{id}/calendar`, `/gardens`, `/patients/{id}/daily-conditions` 등 예전 명세의 경로를 화면에서 호출하지 않습니다. 달력은 실제 기억 기록과 확정 일기 캐시를 사용합니다.

## 검증

```bash
flutter test --no-pub
flutter analyze --no-pub
```

테스트는 HTTP mock으로 배포 API 계약을 확인합니다. 실제 운영 계정으로 로그인하거나 운영 데이터를 생성하지 않았습니다. 검증 항목은 UUID·선택 그룹 유지, 서버 기록 ID·제목, 미디어 서명 URL, 페이지네이션, 로그아웃 후 늦은 응답 무시, 프로필 PUT, multipart 첨부, 부분 실패 후 저장 재시도입니다. 달력 화면 이동·탭 전환, API 응답에 따른 로딩·재시도, 초안 제외·중립 ID 0, 서버 감정 집계, 수정·삭제 성공/실패 및 삭제 후 오래된 조회 응답 무시도 회귀 테스트합니다. 백엔드 패치에는 환자 유무와 비멤버 조회 거부 테스트가 포함되어 있습니다.
