import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/mail_letter.dart';

/// 가족 편지함 스크린 (그레이박스 와이어프레임 스타일)
class FamilyMailboxScreen extends StatefulWidget {
  const FamilyMailboxScreen({super.key});

  @override
  State<FamilyMailboxScreen> createState() => _FamilyMailboxScreenState();
}

class _FamilyMailboxScreenState extends State<FamilyMailboxScreen> {
  // 1. 탭 상태 (0: 받은 편지함, 1: 편지 쓰기)
  int _activeTabIndex = 0;

  List<MailLetter> get _letters => context.watch<AppData>().letters;

  // 3. 편지 쓰기 폼 컨트롤러 및 상태
  final TextEditingController _contentController = TextEditingController();
  String _selectedReceiver = '가족 모두에게';
  bool _isAnonymous = false;

  String _getDisplayReceiver(String receiver) {
    if (receiver == '가족 모두에게') {
      return '가족 모두에게';
    }
    return '나';
  }

  List<String> _getReceiverOptions(BuildContext context) {
    final appData = context.watch<AppData>();
    // 현재 등록된 그룹 멤버들의 이름을 중복 없이 추출 후 가나다 순으로 정렬
    final memberNames = appData.users.map((u) => u.name).toSet().toList()
      ..sort();
    return ['가족 모두에게', ...memberNames];
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // 편지 상세 모달 열기 (읽음 처리)
  void _openLetterDetail(MailLetter letter) {
    context.read<AppData>().markLetterAsRead(letter.id);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 정보
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '발신: ${letter.isAnonymous ? "[익명]" : letter.sender}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '수신: ${_getDisplayReceiver(letter.receiver)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        letter.date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 편지 본문
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Text(
                    letter.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 닫기 버튼
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Text(
                        '닫기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 편지 보내기 제출
  void _submitLetter() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('편지 내용을 입력해 주세요.'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    context.read<AppData>().addLetter(
      receiver: _selectedReceiver,
      content: content,
      isAnonymous: _isAnonymous,
    );

    setState(() {
      _contentController.clear();
      _isAnonymous = false;
      _selectedReceiver = '가족 모두에게';
      _activeTabIndex = 0; // 받은 편지함 탭으로 전환
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _letters.where((l) => !l.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          '가족 편지함',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Colors.black, height: 2.0),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          color: Colors.white,
          child: Column(
            children: [
              // 1. 상단 탭 네비게이션 ('받은 편지함' & '편지 쓰기')
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: Row(
                  children: [
                    // 받은 편지함 탭
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _activeTabIndex == 0
                                ? Colors.white
                                : const Color(0xFFF3F4F6),
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTabIndex == 0
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 4.0,
                              ),
                              right: const BorderSide(
                                color: Colors.black,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '받은 편지함 (${_letters.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _activeTabIndex == 0
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  color: Colors.black,
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 편지 쓰기 탭
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _activeTabIndex == 1
                                ? Colors.white
                                : const Color(0xFFF3F4F6),
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTabIndex == 1
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 4.0,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '편지 쓰기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _activeTabIndex == 1
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 탭 본문 영역
              Expanded(
                child: _activeTabIndex == 0
                    ? _buildInboxTab()
                    : _buildComposeTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. 받은 편지함 (Inbox Tab)
  Widget _buildInboxTab() {
    if (_letters.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF9CA3AF)),
          ),
          child: const Text(
            '받은 편지가 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _letters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final letter = _letters[index];
        return InkWell(
          onTap: () => _openLetterDetail(letter),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: letter.isRead ? Colors.white : const Color(0xFFF3F4F6),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 Row (발신자 / 수신자 / 안읽음 표시 / 날짜)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (!letter.isRead) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            color: Colors.black,
                            child: const Text(
                              '[안 읽음]',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        Text(
                          letter.isAnonymous ? '[익명]' : letter.sender,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: letter.isRead
                                ? Colors.black87
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '➜ ${_getDisplayReceiver(letter.receiver)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      letter.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFD1D5DB)),
                const SizedBox(height: 8),

                // 내용 미리보기
                Text(
                  letter.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: letter.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. 편지 쓰기 (Compose Tab)
  Widget _buildComposeTab() {
    final receiverOptions = _getReceiverOptions(context);
    final currentReceiver = receiverOptions.contains(_selectedReceiver)
        ? _selectedReceiver
        : receiverOptions.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수신자 선택 (Select)
          const Text(
            '수신자 선택',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: currentReceiver,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.black, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.black, width: 2.0),
              ),
            ),
            items: receiverOptions.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedReceiver = newValue);
              }
            },
          ),
          const SizedBox(height: 16),

          // 익명 옵션 (Checkbox)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  activeColor: Colors.black,
                  checkColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  onChanged: (bool? value) {
                    setState(() => _isAnonymous = value ?? false);
                  },
                ),
                GestureDetector(
                  onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                  child: const Text(
                    '익명으로 보내기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 내용 작성 (Textarea)
          const Text(
            '편지 내용',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _contentController,
            maxLines: 6,
            style: const TextStyle(fontSize: 13, color: Colors.black),
            decoration: const InputDecoration(
              hintText: '가족에게 마음을 전하는 따뜻한 이야기를 적어주세요...',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              contentPadding: EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.black, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.black, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 전송 버튼
          InkWell(
            onTap: _submitLetter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  '편지 보내기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
