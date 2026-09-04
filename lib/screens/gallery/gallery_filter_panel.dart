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
  Widget _filterButton({
    required bool isSelected,
    required String textAssetPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 77,
        height: 29,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                isSelected
                    ? 'assets/gallery/screen4_png/4_filter_button_green.png'
                    : 'assets/gallery/screen4_png/4_filter_button_white.png',
                fit: BoxFit.fill,
              ),
            ),
            Center(child: SvgPicture.asset(textAssetPath, fit: BoxFit.contain)),
          ],
        ),
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
                      top: 9,
                      child: SvgPicture.asset(
                        '${basePathSvg}4_condition_search.svg',
                        width: 88,
                        height: 21,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // ─────────────────────
                    // 기록 구분
                    // ─────────────────────

                    // 기록 구분 글자
                    Positioned(
                      left: 12,
                      top: 38,
                      width: 58,
                      height: 29,
                      child: Center(
                        child: SvgPicture.asset(
                          '${basePathSvg}4_condition_search_record_classification.svg',
                          width: 43,
                          height: 11,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // 환자
                    Positioned(
                      left: 70,
                      top: 38,
                      child: _filterButton(
                        isSelected: selectedRecordTypes.contains('patient'),
                        textAssetPath: selectedRecordTypes.contains('patient')
                            ? '${basePathSvg}4_after_record_patient.svg'
                            : '${basePathSvg}4_before_record_patient.svg',
                        onTap: () {
                          onRecordTypeChanged(
                            'patient',
                            !selectedRecordTypes.contains('patient'),
                          );
                        },
                      ),
                    ),

                    // 감정
                    Positioned(
                      left: 149,
                      top: 38,
                      child: _filterButton(
                        isSelected: selectedRecordTypes.contains('emotion'),
                        textAssetPath: selectedRecordTypes.contains('emotion')
                            ? '${basePathSvg}4_after_record_emotion.svg'
                            : '${basePathSvg}4_before_record_emotion.svg',
                        onTap: () {
                          onRecordTypeChanged(
                            'emotion',
                            !selectedRecordTypes.contains('emotion'),
                          );
                        },
                      ),
                    ),

                    // 직접추가
                    Positioned(
                      left: 228,
                      top: 38,
                      child: _filterButton(
                        isSelected: selectedRecordTypes.contains('custom'),
                        textAssetPath: selectedRecordTypes.contains('custom')
                            ? '${basePathSvg}4_after_record_direct_add.svg'
                            : '${basePathSvg}4_before_record_direct_add.svg',
                        onTap: () {
                          onRecordTypeChanged(
                            'custom',
                            !selectedRecordTypes.contains('custom'),
                          );
                        },
                      ),
                    ),

                    // ─────────────────────
                    // 파일 유형
                    // ─────────────────────

                    // 파일 유형 글자
                    Positioned(
                      left: 12,
                      top: 69,
                      width: 58,
                      height: 29,
                      child: Center(
                        child: SvgPicture.asset(
                          '${basePathSvg}4_condition_search_file_type.svg',
                          width: 42,
                          height: 11,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // 사진
                    Positioned(
                      left: 70,
                      top: 69,
                      child: _filterButton(
                        isSelected: selectedFileTypes.contains('image'),
                        textAssetPath: selectedFileTypes.contains('image')
                            ? '${basePathSvg}4_after_file_photo.svg'
                            : '${basePathSvg}4_before_file_photo.svg',
                        onTap: () {
                          onFileTypeChanged(
                            'image',
                            !selectedFileTypes.contains('image'),
                          );
                        },
                      ),
                    ),

                    // 동영상
                    Positioned(
                      left: 149,
                      top: 69,
                      child: _filterButton(
                        isSelected: selectedFileTypes.contains('video'),
                        textAssetPath: selectedFileTypes.contains('video')
                            ? '${basePathSvg}4_after_file_video.svg'
                            : '${basePathSvg}4_before_file_video.svg',
                        onTap: () {
                          onFileTypeChanged(
                            'video',
                            !selectedFileTypes.contains('video'),
                          );
                        },
                      ),
                    ),

                    // 음성
                    Positioned(
                      left: 228,
                      top: 69,
                      child: _filterButton(
                        isSelected: selectedFileTypes.contains('audio'),
                        textAssetPath: selectedFileTypes.contains('audio')
                            ? '${basePathSvg}4_after_file_audio.svg'
                            : '${basePathSvg}4_before_file_audio.svg',
                        onTap: () {
                          onFileTypeChanged(
                            'audio',
                            !selectedFileTypes.contains('audio'),
                          );
                        },
                      ),
                    ),
                    // ─────────────────────
                    // 정렬
                    // ─────────────────────

                    // 정렬 글자
                    Positioned(
                      left: 12,
                      top: 100,
                      width: 58,
                      height: 29,
                      child: Center(
                        child: SvgPicture.asset(
                          '${basePathSvg}4_condition_search_sort.svg',
                          width: 20,
                          height: 11,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // 최신순
                    Positioned(
                      left: 70,
                      top: 100,
                      child: _filterButton(
                        isSelected: sortBy == 'latest',
                        textAssetPath: sortBy == 'latest'
                            ? '${basePathSvg}4_after_sort_latest.svg'
                            : '${basePathSvg}4_before_sort_latest.svg',
                        onTap: () {
                          onSortByChanged('latest');
                        },
                      ),
                    ),

                    // 오래된 순
                    Positioned(
                      left: 149,
                      top: 100,
                      child: _filterButton(
                        isSelected: sortBy == 'oldest',
                        textAssetPath: sortBy == 'oldest'
                            ? '${basePathSvg}4_after_sort_oldest.svg'
                            : '${basePathSvg}4_before_sort_oldest.svg',
                        onTap: () {
                          onSortByChanged('oldest');
                        },
                      ),
                    ),

                    // 검색 초기화
                    Positioned(
                      right: 14,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: onReset,
                        behavior: HitTestBehavior.opaque,
                        child: SvgPicture.asset(
                          '${basePathSvg}4_search_reset.svg',
                          width: 86,
                          height: 24,
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
