import 'package:flutter/material.dart';

class GalleryFilterPanel extends StatelessWidget {
  final String selectedRecordType;
  final List<String> selectedFileTypes;
  final String sortBy;
  final ValueChanged<String> onRecordTypeChanged;
  final Function(String, bool) onFileTypeChanged;
  final ValueChanged<String> onSortByChanged;
  final VoidCallback onReset;

  const GalleryFilterPanel({
    super.key,
    required this.selectedRecordType,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '조건검색',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          
          // 1. 기록 구분 필터 로우
          Row(
            children: [
              const SizedBox(
                width: 70,
                child: Text('기록 구분', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: ['전체', '환자', '감정'].map((type) {
                    final isSelected = selectedRecordType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) onRecordTypeChanged(type);
                      },
                      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. 파일 유형 필터 로우
          Row(
            children: [
              const SizedBox(
                width: 70,
                child: Text('파일 유형', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    {'label': '사진', 'value': 'image'},
                    {'label': '동영상', 'value': 'video'},
                    {'label': '음성', 'value': 'audio'},
                  ].map((type) {
                    final isSelected = selectedFileTypes.contains(type['value']);
                    return FilterChip(
                      label: Text(type['label']!),
                      selected: isSelected,
                      onSelected: (val) {
                        onFileTypeChanged(type['value']!, val);
                      },
                      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. 정렬 및 초기화 로우
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 70,
                    child: Text('정렬', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ),
                  ChoiceChip(
                    label: const Text('최신순'),
                    selected: sortBy == 'latest',
                    onSelected: (val) {
                      if (val) onSortByChanged('latest');
                    },
                    selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: sortBy == 'latest' ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: sortBy == 'latest' ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('오래된순'),
                    selected: sortBy == 'oldest',
                    onSelected: (val) {
                      if (val) onSortByChanged('oldest');
                    },
                    selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: sortBy == 'oldest' ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: sortBy == 'oldest' ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('검색 초기화', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
