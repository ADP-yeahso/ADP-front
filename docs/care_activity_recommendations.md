# 감정별 추천 활동

작업 브랜치는 `feature/recommend_activity`이며 Git 기준은 `front-develop`의 `68f8f83`이다. 추천 기능에 집중하기 위해 이전에 가져온 `web-deployment`의 API·인증 코드를 제거했다. API 클라이언트, 인증 세션, 가짜 토큰, 샘플 HTTP 클라이언트 및 http 직접 의존성은 이 변경에 포함하지 않는다.

## 현재 범위

- 모든 감정에서 공통 활동 2개, 확인 가능한 최종 감정에서 맞춤 활동 2개를 표시한다.
- 크림 배경·흰 패널·2×2 카드·감정별 색상·노란 홈 버튼을 유지한다.
- 맞춤 활동은 BottomSheet로 설명한다. ‘활동 완료’만 완료로 처리하며 취소·뒤로가기·닫기는 완료하지 않는다.
- 완료 상태는 화면 내부 `Set<String>`과 `setState`로 관리한다. 화면을 새로 열면 초기화된다.
- 행마다 내용에 맞춰 카드 높이를 정하고 바깥 화면을 스크롤해 긴 제목과 시스템 글자 확대를 허용한다.
- 화면 읽기 프로그램에서 활동 제목·완료 상태를 읽고 실행할 수 있다.
- 홈 버튼은 기존 `GardenNavController.requestDate`와 첫 라우트 복귀를 재사용한다.

## 감정 전달 계약

기존 `lib/models/emotions.dart`의 `Emotion`을 재사용한다. 추천 화면은 API 응답 형식이나 인증 토큰을 알 필요가 없다.

```dart
// 일기·API 담당 코드에서 이미 확보한 최종 감정을 전달한다.
DiaryResultScreen(emotion: finalEmotion);

// 결과 화면을 통하지 않는 연결도 가능하다.
DiaryCareContentScreen(emotion: finalEmotion);
```

`DiaryResultScreen`의 ‘다음’ 버튼은 전달받은 같은 `Emotion` 객체를 추천 화면으로 넘긴다. 기존 결과 화면의 꽃 카드·색상·기본 표시 방식은 유지한다.

`CareActivityCatalog`는 `Emotion.name`의 감정 코드로 활동을 조회한다. DB 숫자 ID를 1~7로 고정 가정하지 않는다. 백엔드 코드 `tenderness`와 기존 프론트 코드 `affection`은 같은 활동에 연결한다. 불안 카드의 요구 색상 `#AEAEAE`는 추천 카탈로그 내부에만 적용한다.

감정이 없거나 미지원 코드가 전달되면 실제 중립으로 추정하지 않고 공통 활동 2개와 안내를 표시한다. 기존 일기 작성 흐름은 감정을 결과 화면에 전달하지 않는 목업 상태였으므로, API 연동 담당자가 위 생성자 인자에 실제 최종 감정을 연결하기 전까지 해당 경로의 맞춤 추천은 나오지 않는다. 이 기능에서 선택 태그를 새로 분석해 최종 감정을 만들지는 않는다.

## 기존 화면과의 경계

다음 파일에 가져왔던 API 변경은 원래 상태로 복원했다.

- `lib/main.dart`, `lib/models/emotion_model.dart`, `lib/screens/profile/profile_screen.dart`
- `lib/screens/record/write/diary_situation_screen.dart`, `diary_emotion_explore_screen.dart`, `diary_emotion_select_screen.dart`, `diary_loading_screen.dart`
- `pubspec.yaml`, `pubspec.lock`

로그인 화면은 기존 가족 그룹 화면으로 이동하는 동작을 복원했다. 로그인 버튼에 접근성 레이블과 디버그 미리보기 진입만 추가했다. 실제 인증 동작을 새로 추가하지 않는다.

## 서버 없는 미리보기

1. Debug 모드로 앱을 실행하고, 이미 실행 중이면 Hot Restart 한다.
2. 로그인 버튼 아래 **추천 활동 미리보기 (디버그)**를 누른다.
3. 7개 감정 중 하나를 고르면 결과 화면이 열린다.
4. ‘다음’을 눌러 해당 감정의 활동·완료 처리·취소를 확인한다.

이 진입은 기존 화면에 샘플 `Emotion` 객체를 전달할 뿐이며 API 호출·인증 세션·일기 저장은 없다. 이전 ‘서버 없이 시작’ 버튼과 OFFLINE 세션은 제거했다. 일반 로그인 버튼으로도 기존 목업 화면을 서버 없이 둘러볼 수 있다. 미리보기 버튼과 미리보기 화면은 `kDebugMode`에서만 동작한다. 미리보기의 홈 버튼은 첫 라우트로 복귀한다.

## 공통 활동 연결

익명 편지함·치매 관리 매뉴얼 화면이 로컬에 없어 준비 중 안내를 표시한다. 기존 화면이 통합되면 다음 콜백에 라우트를 연결한다.

```dart
DiaryCareContentScreen(
  emotion: finalEmotion,
  onOpenLetter: () { /* 기존 편지 작성 화면으로 이동 */ },
  onOpenManual: () { /* 기존 매뉴얼 화면으로 이동 */ },
)
```

GitHub `feature/mailbox`의 가족 편지함을 익명 편지함의 대상으로 사용할지는 팀에서 결정해야 한다. 공통 활동은 임의로 완료 표시하지 않는다. 호흡 타이머와 서버 완료 상태 저장은 추가하지 않았다.

## 변경 파일

| 영역 | 파일 |
| --- | --- |
| 추천 데이터 | `lib/data/care_activity_catalog.dart` |
| 추천 UI | `lib/screens/record/write/diary_care_content_screen.dart` |
| 감정 전달 | `lib/screens/record/write/diary_result_screen.dart`의 화면 전환 부분 |
| 디버그 진입 | `lib/screens/auth/login_screen.dart`, `lib/screens/debug/care_activity_preview_screen.dart` |
| 테스트 | `test/care_activity_catalog_test.dart`, `diary_care_content_screen_test.dart`, `diary_recommendation_flow_test.dart`, `login_screen_test.dart`, `widget_test.dart` |

기존 시작 화면 테스트는 이미지 버튼을 일반 Text로 찾던 검사를 입력 위젯과 접근성 레이블 검사로 보완했다.

## 검증

```sh
flutter analyze --no-pub
flutter test --no-pub
```

7개 감정별 활동·색상, 공통 활동, 감정 누락, 320px 화면과 글자 2배, 완료·취소·접근성·홈 복귀, 결과 화면의 감정 전달, 디버그 진입을 검증한다. 실제 서버 응답·DB 정합성·네이티브 배포 빌드는 이 추천 UI 테스트의 범위에 포함하지 않는다.

API 제거 후 검증 결과: 전체 Flutter 테스트 51개 통과, 변경 코드·테스트 정적 분석 이슈 없음, `git diff --check` 통과. 커밋·푸시·브랜치 병합은 수행하지 않았다.
