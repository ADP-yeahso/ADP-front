# 돌봄 수첩 에셋 연결 현황

대상: `assets/images/care_note/`. 디자인 요소 68종(일반 요소 34종 + 토글 선택/비선택 34종)을 확인했다. 동일한 그림의 SVG와 PNG는 대체 형식이며 중복해서 그리지 않는다. 토글과 그림자 프레임·버튼은 PNG, 문구와 아이콘·구분선은 SVG를 사용한다. 원본 ZIP은 전달 자료이며 화면에 표시하는 에셋이 아니다.

날짜, 환자 이름, 생년월일, 상태 값, 메모, 진료 내용은 사용자 데이터이므로 텍스트로 표시한다. 프레임과 고정 문구는 아래 에셋으로 조립한다.

| 에셋 | 사용 형식 | 표시 위치 |
| --- | --- | --- |
| add_icon | SVG | 작성: 진료·약 변경 펼치기 |
| add_medical_change_text | SVG | 작성: 진료·약 변경 펼치기 |
| back_icon | SVG | 공통: 뒤로 가기 |
| bowel_label | SVG | 작성: 배변 항목 |
| care_note_entry_frame | PNG | 목록: 저장된 기록 카드 |
| care_note_icon | SVG | 정원: 돌봄 수첩 진입 버튼 |
| date_picker_frame | PNG | 작성: 날짜 선택 |
| dropdown_arrow | SVG | 작성: 날짜 선택 / 진료 영역 펼치기 |
| edit_info_button | SVG | 공통: 환자 정보 수정 |
| empty_state | SVG | 목록: 빈 기록 안내 |
| entry_date_divider | SVG | 목록: 기록 날짜 구분선 |
| meal_label | SVG | 작성: 식사 항목 |
| medical_change_divider | SVG | 목록: 진료·약 변경 내용 구분선 |
| medical_change_frame | PNG | 작성: 진료·약 변경 추가 프레임 |
| medical_record_label | SVG | 목록: 진료·약 변경 기록 라벨 |
| medication_label | SVG | 작성: 복약 항목 |
| notes_frame | PNG | 작성: 메모 입력 프레임 |
| notes_input_underline | SVG | 작성: 메모 첫 줄 밑줄 |
| notes_label | SVG | 목록: 특이사항 라벨 |
| notes_placeholder | SVG | 작성: 빈 메모 입력 안내 |
| patient_avatar_default | SVG | 공통: 환자 이미지 |
| patient_info_divider | SVG | 공통: 환자 이름 / 생년월일 구분선 |
| patient_info_frame | PNG | 공통: 환자 정보 카드 |
| record_content_frame | PNG | 목록: 생활 상태 배지 |
| record_form_frame | PNG | 작성: 기록 양식 프레임 |
| record_prompt_text | SVG | 작성: 선택형 + 짧은 메모 안내 |
| record_type_label | SVG | 작성: 의 돌봄 기록 |
| save_green_button | PNG | 작성: 저장 가능 상태 |
| save_yellow_button | PNG | 작성: 저장 전 상태 |
| sleep_label | SVG | 작성: 수면 항목 |
| title | SVG | 공통: 돌봄 수첩 제목 |
| top_bar | SVG | 공통: 상단 바 배경 |
| unusual_change_label | SVG | 작성: 평소와 다른 점 항목 |
| write_note_button | PNG | 목록: 수첩 쓰기 버튼 |

| 토글 종류 | 사용 형식 | 표시 위치 |
| --- | --- | --- |
| option_bad (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_bowel_changed (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_bowel_normal (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_good (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_low (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_medication_missed (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_medication_taken (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_normal (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_aggression (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_anxiety (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_no (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_other (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_refusing_meals (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_repeated_questions (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_sleep_change (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_wandering (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |
| option_unusual_yes (selected / unselected) | PNG | 작성: 단일 선택 / 평소와 다른 점 상세 선택 |

검증: 기록 카드의 실제 PNG 프레임·배지 5개·SVG 날짜 구분선 렌더링, 선택/비선택 전환, 메모 입력과 저장, 작은 화면과 키보드 표시 상태를 `test/care_notebook_test.dart`에서 확인한다.
