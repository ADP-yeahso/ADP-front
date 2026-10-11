# 꽃 GLB 경량화 요청 목록

측정일: 2026-10-02. GLB 최종 삼각형 기준. 원본 에셋은 수정하지 않음.

제작 목표: 꽃 한 송이 전체 5,000~8,000 삼각형 / GLB 텍스처 포함 500KiB 이하. 검토 상한: 10,000 삼각형 / 1MiB. 이는 30~60송이 동시 표시를 가정한 초기 기준이며 실기기 성능 보장은 아님.

## 현재 정원에 사용되는 재작업 대상 17종

| 파일 | 삼각형 | GLB 크기(MiB) |
|---|---:|---:|
| `Affection_Marigold.glb` | 60,144 | 1.856 |
| `Anger_Linaria.glb` | 58,856 | 1.056 |
| `Anxiety_Geranium.glb` | 30,016 | 2.007 |
| `Affection_Lisianthus.glb` | 27,312 | 0.527 |
| `Guilt_Clematis.glb` | 27,056 | 1.861 |
| `Guilt_Delphinium.glb` | 25,216 | 0.484 |
| `Anxiety_Stock.glb` | 21,968 | 0.792 |
| `Anger_Zinnia.glb` | 20,496 | 1.357 |
| `Sadness_ebw.glb` | 18,812 | 0.652 |
| `Anxiety_Hellebore.glb` | 18,052 | 1.073 |
| `Anger_Gerbera.glb` | 17,008 | 0.322 |
| `Anger_Phlox.glb` | 16,368 | 1.201 |
| `Sadness_ydc.glb` | 14,288 | 0.957 |
| `Anxiety_Borage.glb` | 13,536 | 0.485 |
| `Sadness_mmc.glb` | 11,840 | 0.349 |
| `flower.glb` | 11,772 | 1.130 |
| `Guilt_Canna.glb` | 11,666 | 0.792 |

메리골드와 리나리아를 우선 샘플 수정한 뒤, 전체 정원과 확대 화면의 외형을 확인하고 나머지에 적용한다.

## 제외 및 미사용 파일

- `Affection_Bindweed.glb`: 7,552 삼각형 / 0.354MiB. 현재 목표 충족. 렌더링 파트 5개는 별도 개선 여지.
- `Affection_Nasturtium.glb`: 10,032 삼각형 / 0.290MiB. 상한 근접 예외로 재작업 제외.
- `Affection_lisian_low.glb`: 8,510 삼각형 / 0.425MiB. 현재 미사용. 삼각형 상한 이내이나 렌더링 파트 10개.
- `Affection_lisian_mid.glb`: 82,974 삼각형 / 5.082MiB. 현재 미사용. 향후 사용할 경우 경량화 필요.
- `flower2.glb`: 11,772 삼각형 / 1.130MiB. 현재 미사용. 향후 사용할 경우 경량화 필요.

## 시뮬레이터에서 전체 에셋 미리보기

```sh
flutter run -d 13C1B47D-A82F-4790-8EF6-56B9141BFB24 -t lib/main_garden_preview.dart
```

폴더 내 꽃 GLB 22개를 각 한 송이씩 배치한다. 감사·중립이 공유하는 flower.glb는 한 번 표시한다. 파일별 low/mid 및 flower2는 비교용으로 각각 표시한다. 실제 일기는 수정하지 않는다. 꽃을 탭하면 파일명과 삼각형 수를 확인하고 확대할 수 있다. 돌아가기 버튼으로 전체 정원을 다시 본다.
