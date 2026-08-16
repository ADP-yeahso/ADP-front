import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GalleryFilterPanel extends StatelessWidget {
  // 선택된 기록 구분 목록
  // 여러 개를 동시에 선택하기 위해 String이 아니라 Set<String> 사용
  final Set<String> selectedRecordTypes;

  // 선택된 파일 유형 목록
  final List<String> selectedFileTypes;

  // 정렬 기준
  final String sortBy;

  // 기록 구분 선택/해제 콜백
  final void Function(String type, bool isSelected) onRecordTypeChanged;

  // 파일 유형 선택/해제 콜백
  final void Function(String type, bool isSelected) onFileTypeChanged;

  // 정렬 기준 변경 콜백
  final ValueChanged<String> onSortByChanged;

  // 검색 초기화 콜백
  final VoidCallback onReset;

  const GalleryFilterPanel({
    super.key,
    required this.selectedRecordTypes,
    required this.selectedFileTypes,
    required this.sortBy,
    required this.onRecordTypeChanged,
    required this.onFileTypeChanged,
    required this.onSortByChanged,
    required this.onReset,
  });
  Widget _svgButton({required String assetPath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    const basePath = 'assets/gallery/screen4/';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AspectRatio(
        aspectRatio: 317 / 166,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 조건 검색 박스
            SvgPicture.asset(
              '${basePath}4_condition_search_box.svg',
              fit: BoxFit.fill,
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 조건검색 제목
                    SvgPicture.asset(
                      '${basePath}4_condition_search.svg',
                      width: 72,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 8),

                    // 기록 구분
                    Row(
                      children: [
                        SizedBox(
                          width: 58,
                          child: SvgPicture.asset(
                            '${basePath}4_condition_search_record_classification.svg',
                            width: 45,
                            alignment: Alignment.centerLeft,
                          ),
                        ),

                        _svgButton(
                          assetPath:
                              '${basePath}${selectedRecordTypes.contains('patient') ? '4_after_click_record_classification_patient.svg' : '4_before_click_record_classification_patient.svg'}',
                          onTap: () {
                            onRecordTypeChanged(
                              'patient',
                              !selectedRecordTypes.contains('patient'),
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        _svgButton(
                          assetPath:
                              '${basePath}${selectedRecordTypes.contains('emotion') ? '4_after_click_record_classification_emotion.svg' : '4_before_click_record_classification_emotion.svg'}',
                          onTap: () {
                            onRecordTypeChanged(
                              'emotion',
                              !selectedRecordTypes.contains('emotion'),
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        _svgButton(
                          assetPath:
                              '${basePath}${selectedRecordTypes.contains('custom') ? '4_after_click_record_classification_direct_add.svg' : '4_before_click_record_classification_direct_add.svg'}',
                          onTap: () {
                            onRecordTypeChanged(
                              'custom',
                              !selectedRecordTypes.contains('custom'),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // 파일 유형
                    Row(
                      children: [
                        SizedBox(
                          width: 58,
                          child: SvgPicture.asset(
                            '${basePath}4_condition_search_file_type.svg',
                            width: 45,
                            alignment: Alignment.centerLeft,
                          ),
                        ),

                        _svgButton(
                          assetPath:
                              '${basePath}${selectedFileTypes.contains('image') ? '4_after_click_file_type_photo.svg' : '4_before_click_file_type_photo.svg'}',
                          onTap: () {
                            onFileTypeChanged(
                              'image',
                              !selectedFileTypes.contains('image'),
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        _svgButton(
                          assetPath:
                              '${basePath}${selectedFileTypes.contains('video') ? '4_after_click_file_type_video.svg' : '4_before_click_file_type_video.svg'}',
                          onTap: () {
                            onFileTypeChanged(
                              'video',
                              !selectedFileTypes.contains('video'),
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        _svgButton(
                          assetPath:
                              '${basePath}${selectedFileTypes.contains('audio') ? '4_after_click_file_type_audio.svg' : '4_before_click_file_type_audio.svg'}',
                          onTap: () {
                            onFileTypeChanged(
                              'audio',
                              !selectedFileTypes.contains('audio'),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // 정렬
                    Row(
                      children: [
                        SizedBox(
                          width: 58,
                          child: SvgPicture.asset(
                            '${basePath}4_condition_search_sort.svg',
                            width: 24,
                            alignment: Alignment.centerLeft,
                          ),
                        ),

                        _svgButton(
                          assetPath:
                              '${basePath}${sortBy == 'latest' ? '4_after_click_sort_latest.svg' : '4_before_click_sort_latest.svg'}',
                          onTap: () {
                            onSortByChanged('latest');
                          },
                        ),

                        const SizedBox(width: 4),

                        _svgButton(
                          assetPath:
                              '${basePath}${sortBy == 'oldest' ? '4_after_click_sort_oldest.svg' : '4_before_click_sort_oldest.svg'}',
                          onTap: () {
                            onSortByChanged('oldest');
                          },
                        ),

                        const Spacer(),

                        GestureDetector(
                          onTap: onReset,
                          behavior: HitTestBehavior.opaque,
                          child: SvgPicture.asset(
                            '${basePath}4_search_reset.svg',
                            width: 65,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
