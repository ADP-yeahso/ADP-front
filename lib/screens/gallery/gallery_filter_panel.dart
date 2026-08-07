import 'package:flutter/material.dart';

class GalleryFilterPanel extends StatelessWidget {
  // 선택된 기록 구분 목록
  // 여러 개를 동시에 선택하기 위해 String이 아니라 Set<String> 사용
  final Set<String> selectedRecordTypes;

  // 선택된 파일 유형 목록
  final List<String> selectedFileTypes;

  // 정렬 기준
  final String sortBy;

  // 기록 구분 선택/해제 콜백
  final void Function(String type, bool isSelected)
      onRecordTypeChanged;

  // 파일 유형 선택/해제 콜백
  final void Function(String type, bool isSelected)
      onFileTypeChanged;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '조건검색',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 8),

          // 1. 기록 구분 필터
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 70,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '기록 구분',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: const [
                    {
                      'label': '환자',
                      'value': 'patient',
                    },
                    {
                      'label': '감정',
                      'value': 'emotion',
                    },
                    {
                      'label': '직접 추가',
                      'value': 'custom',
                    },
                  ].map((type) {
                    final String value = type['value']!;
                    final String label = type['label']!;

                    final bool isSelected =
                        selectedRecordTypes.contains(value);

                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      showCheckmark: true,
                      onSelected: (selected) {
                        onRecordTypeChanged(
                          value,
                          selected,
                        );
                      },
                      selectedColor: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.2),
                      checkmarkColor:
                          Theme.of(context).primaryColor,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. 파일 유형 필터
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 70,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '파일 유형',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    {
                      'label': '사진',
                      'value': 'image',
                    },
                    {
                      'label': '동영상',
                      'value': 'video',
                    },
                    {
                      'label': '음성',
                      'value': 'audio',
                    },
                  ].map((type) {
                    final String value = type['value']!;
                    final String label = type['label']!;

                    final bool isSelected =
                        selectedFileTypes.contains(value);

                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        onFileTypeChanged(
                          value,
                          selected,
                        );
                      },
                      selectedColor: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.2),
                      checkmarkColor:
                          Theme.of(context).primaryColor,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. 정렬 및 검색 초기화
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 70,
                      child: Text(
                        '정렬',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    ChoiceChip(
                      label: const Text('최신순'),
                      selected: sortBy == 'latest',
                      onSelected: (selected) {
                        if (selected) {
                          onSortByChanged('latest');
                        }
                      },
                      selectedColor: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.2),
                      side: BorderSide(
                        color: sortBy == 'latest'
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: sortBy == 'latest'
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight: sortBy == 'latest'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),

                    const SizedBox(width: 8),

                    ChoiceChip(
                      label: const Text('오래된순'),
                      selected: sortBy == 'oldest',
                      onSelected: (selected) {
                        if (selected) {
                          onSortByChanged('oldest');
                        }
                      },
                      selectedColor: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.2),
                      side: BorderSide(
                        color: sortBy == 'oldest'
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: sortBy == 'oldest'
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                        fontWeight: sortBy == 'oldest'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                ),
                label: const Text(
                  '검색 초기화',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}