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
  Widget _pngButton({required String assetPath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 77,
        height: 29,
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const basePathSvg = 'assets/gallery/screen4/';
    const basePathPng = 'assets/gallery/screen4_png/';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = constraints.maxWidth;
          final panelHeight = panelWidth * (166 / 317);

          return SizedBox(
            width: panelWidth,
            height: panelHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 317,
                height: 166,
                child: Stack(
                  children: [
                    // 조건검색 흰 박스
                    Positioned.fill(
                      child: Image.asset(
                        '${basePathPng}4_condition_search_box.png',
                        fit: BoxFit.fill,
                      ),
                    ),

                    // 조건검색 제목
                    Positioned(
                      left: 12,
                      top: 10,
                      child: SvgPicture.asset(
                        '${basePathSvg}4_condition_search.svg',
                        width: 80,
                        height: 19,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // ─────────────────────
                    // 기록 구분
                    // ─────────────────────
                    Positioned(
                      left: 12,
                      top: 38,
                      child: SizedBox(
                        width: 293,
                        height: 29,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              height: 29,
                              child: Align(
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  '${basePathSvg}4_condition_search_record_classification.svg',
                                  width: 43,
                                  height: 11,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${selectedRecordTypes.contains('patient') ? '4_after_click_record_classification_patient.png' : '4_before_click_record_classification_patient.png'}',
                              onTap: () {
                                onRecordTypeChanged(
                                  'patient',
                                  !selectedRecordTypes.contains('patient'),
                                );
                              },
                            ),

                            const SizedBox(width: 2),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${selectedRecordTypes.contains('emotion') ? '4_after_click_record_classification_emotion.png' : '4_before_click_record_classification_emotion.png'}',
                              onTap: () {
                                onRecordTypeChanged(
                                  'emotion',
                                  !selectedRecordTypes.contains('emotion'),
                                );
                              },
                            ),

                            const SizedBox(width: 2),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${selectedRecordTypes.contains('custom') ? '4_after_click_record_classification_direct_add.png' : '4_before_click_record_classification_direct_add.png'}',
                              onTap: () {
                                onRecordTypeChanged(
                                  'custom',
                                  !selectedRecordTypes.contains('custom'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─────────────────────
                    // 파일 유형
                    // ─────────────────────
                    Positioned(
                      left: 12,
                      top: 69,
                      child: SizedBox(
                        width: 293,
                        height: 29,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              height: 29,
                              child: Align(
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  '${basePathSvg}4_condition_search_file_type.svg',
                                  width: 42,
                                  height: 11,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${selectedFileTypes.contains('image') ? '4_after_click_file_type_photo.png' : '4_before_click_file_type_photo.png'}',
                              onTap: () {
                                onFileTypeChanged(
                                  'image',
                                  !selectedFileTypes.contains('image'),
                                );
                              },
                            ),

                            const SizedBox(width: 2),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${selectedFileTypes.contains('video') ? '4_after_click_file_type_video.png' : '4_before_click_file_type_video.png'}',
                              onTap: () {
                                onFileTypeChanged(
                                  'video',
                                  !selectedFileTypes.contains('video'),
                                );
                              },
                            ),

                            const SizedBox(width: 2),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${selectedFileTypes.contains('audio') ? '4_after_click_file_type_audio.png' : '4_before_click_file_type_audio.png'}',
                              onTap: () {
                                onFileTypeChanged(
                                  'audio',
                                  !selectedFileTypes.contains('audio'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─────────────────────
                    // 정렬
                    // ─────────────────────
                    Positioned(
                      left: 12,
                      top: 100,
                      child: SizedBox(
                        width: 216,
                        height: 29,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              height: 29,
                              child: Align(
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  '${basePathSvg}4_condition_search_sort.svg',
                                  width: 20,
                                  height: 11,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${sortBy == 'latest' ? '4_after_click_sort_latest.png' : '4_before_click_sort_latest.png'}',
                              onTap: () {
                                onSortByChanged('latest');
                              },
                            ),

                            const SizedBox(width: 2),

                            _pngButton(
                              assetPath:
                                  '${basePathPng}${sortBy == 'oldest' ? '4_after_click_sort_oldest.png' : '4_before_click_sort_oldest.png'}',
                              onTap: () {
                                onSortByChanged('oldest');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 검색 초기화
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: GestureDetector(
                        onTap: onReset,
                        behavior: HitTestBehavior.opaque,
                        child: SvgPicture.asset(
                          '${basePathSvg}4_search_reset.svg',
                          width: 71,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
