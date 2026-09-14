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
  // 0: 받은 편지, 1: 보낸 편지
  int _activeTabIndex = 0;

  // 편지 작성 화면 표시 여부
  bool _isComposing = false;

  List<MailLetter> get _receivedLetters =>
      context.watch<AppData>().receivedLetters;

  List<MailLetter> get _sentLetters => context.watch<AppData>().sentLetters;

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
    final appData = context.read<AppData>();

    final memberNames =
        appData.users
            .where((user) => user.id != appData.currentUserId)
            .map((user) => user.name)
            .toSet()
            .toList()
          ..sort();

    return ['가족 모두에게', ...memberNames];
  }

  Future<void> _showReceiverPicker() async {
    final receiverOptions = _getReceiverOptions(context);

    final selectedReceiver = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '받는 사람을 선택해 주세요',
                  style: TextStyle(
                    color: Color(0xFF25341E),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...receiverOptions.map((receiver) {
                  final isSelected = receiver == _selectedReceiver;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEAF2E4)
                            : const Color(0xFFF3F4EF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        receiver == '가족 모두에게'
                            ? Icons.groups_outlined
                            : Icons.person_outline,
                        color: const Color(0xFF426B2C),
                        size: 21,
                      ),
                    ),
                    title: Text(
                      receiver,
                      style: TextStyle(
                        color: const Color(0xFF25341E),
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF426B2C))
                        : null,
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop(receiver);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedReceiver != null && mounted) {
      setState(() {
        _selectedReceiver = selectedReceiver;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // 편지 상세 모달 열기 (읽음 처리)
  void _openLetterDetail(MailLetter letter) {
    final appData = context.read<AppData>();
    final isSentLetter = letter.isSentBy(appData.currentMailboxUserId);

    // 받은 편지를 열었을 때만 읽음 처리합니다.
    if (!isSentLetter && !letter.isRead) {
      appData.markLetterAsRead(letter.id);
    }

    final senderLabel = isSentLetter
        ? (letter.isAnonymous ? '나 · 익명으로 보냄' : '나')
        : (letter.isAnonymous ? '익명의 가족' : letter.sender);

    final receiverLabel = isSentLetter
        ? letter.receiver
        : letter.isGroupLetter
        ? '가족 모두에게'
        : '나';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF2E4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mail_outline,
                          color: Color(0xFF426B2C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isSentLetter ? '보낸 편지' : '받은 편지',
                          style: const TextStyle(
                            color: Color(0xFF25341E),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        tooltip: '닫기',
                        icon: const Icon(Icons.close, color: Color(0xFF697066)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLetterInfoRow(label: '보낸 사람', value: senderLabel),
                        const SizedBox(height: 7),
                        _buildLetterInfoRow(
                          label: '받는 사람',
                          value: receiverLabel,
                        ),
                        const SizedBox(height: 7),
                        _buildLetterInfoRow(label: '보낸 시간', value: letter.date),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
                        child: Text(
                          letter.content,
                          style: const TextStyle(
                            color: Color(0xFF35452D),
                            fontSize: 15,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF426B2C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        '닫기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLetterInfoRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF858C81), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF35452D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _closeCompose() async {
    final hasWrittenContent = _contentController.text.trim().isNotEmpty;

    if (!hasWrittenContent) {
      setState(() {
        _contentController.clear();
        _selectedReceiver = '가족 모두에게';
        _isAnonymous = false;
        _isComposing = false;
      });
      return;
    }

    final shouldDiscard =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                '편지 작성을 그만둘까요?',
                style: TextStyle(
                  color: Color(0xFF25341E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                '작성한 편지 내용이 사라져요.',
                style: TextStyle(color: Color(0xFF626A5F), fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    '계속 작성',
                    style: TextStyle(color: Color(0xFF626A5F)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    '그만두기',
                    style: TextStyle(
                      color: Color(0xFF426B2C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDiscard || !mounted) {
      return;
    }

    setState(() {
      _contentController.clear();
      _selectedReceiver = '가족 모두에게';
      _isAnonymous = false;
      _isComposing = false;
    });
  }

  // 편지 보내기 제출
  Future<void> _submitLetter() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      return;
    }

    final isGroupLetter = _selectedReceiver == '가족 모두에게';

    final shouldSend =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                isGroupLetter ? '가족 모두에게 편지를 보낼까요?' : '편지를 보낼까요?',
                style: const TextStyle(
                  color: Color(0xFF25341E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                _isAnonymous
                    ? '${isGroupLetter ? "모든 가족 구성원" : "$_selectedReceiver 님"}에게 익명으로 편지를 보냅니다.\n보낸 사람의 이름은 표시되지 않아요.'
                    : isGroupLetter
                    ? '보낸 편지는 모든 가족 구성원이 확인할 수 있어요.'
                    : '$_selectedReceiver 님에게 편지를 보냅니다.',
                style: const TextStyle(
                  color: Color(0xFF626A5F),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Color(0xFF626A5F)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    '보내기',
                    style: TextStyle(
                      color: Color(0xFF426B2C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSend || !mounted) {
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
      _isComposing = false;
      _activeTabIndex = 1;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            '마음을 담은 편지를 보냈어요.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF354F27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final unreadCount = appData.unreadMailCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        leading: _isComposing
            ? IconButton(
                onPressed: _closeCompose,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: const Text(
          '가족 편지함',
          style: TextStyle(
            color: Color(0xFF182F0D),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF182F0D)),
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          color: const Color(0xFFF7F7F2),
          child: _isComposing
              ? _buildComposeTab()
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMailboxTab(
                              title: '받은 편지',
                              index: 0,
                              unreadCount: unreadCount,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMailboxTab(title: '보낸 편지', index: 1),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildLetterList()),
                    SafeArea(
                      top: false,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        color: const Color(0xFFF7F7F2),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isComposing = true);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('편지 쓰기'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: const Color(0xFF426B2C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMailboxTab({
    required String title,
    required int index,
    int unreadCount = 0,
  }) {
    final isSelected = _activeTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _activeTabIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2E4) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF426B2C) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF182F0D)
                    : const Color(0xFF7B8177),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF426B2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 2. 받은 편지함 (Inbox Tab)
  Widget _buildLetterList() {
    final isInbox = _activeTabIndex == 0;
    final letters = isInbox ? _receivedLetters : _sentLetters;

    if (letters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isInbox
                    ? Icons.mark_email_unread_outlined
                    : Icons.send_outlined,
                size: 44,
                color: const Color(0xFFA9B5A2),
              ),
              const SizedBox(height: 14),
              Text(
                isInbox ? '아직 받은 편지가 없어요' : '아직 보낸 편지가 없어요',
                style: const TextStyle(
                  color: Color(0xFF35452D),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isInbox ? '가족이 전한 편지가 이곳에 차곡차곡 쌓여요.' : '가족에게 따뜻한 마음을 전해보세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7B8177), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: letters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final letter = letters[index];
        final showUnread = isInbox && !letter.isRead;

        return InkWell(
          onTap: () => _openLetterDetail(letter),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: showUnread ? const Color(0xFFF0F6EC) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: showUnread
                    ? const Color(0xFFB8CDAA)
                    : const Color(0xFFE2E6DF),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showUnread) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF426B2C),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        isInbox
                            ? (letter.isAnonymous ? '익명의 가족' : letter.sender)
                            : letter.receiver,
                        style: const TextStyle(
                          color: Color(0xFF25341E),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      letter.date,
                      style: const TextStyle(
                        color: Color(0xFF92988E),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  isInbox
                      ? (letter.isGroupLetter ? '가족 모두에게' : '나에게')
                      : letter.isAnonymous
                      ? '익명으로 보냄'
                      : '보낸 편지',
                  style: const TextStyle(
                    color: Color(0xFF7B8177),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  letter.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF465043),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: showUnread ? FontWeight.w600 : FontWeight.w400,
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
    final canSubmit = _contentController.text.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeCompose();
        }
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '받는 사람',
              style: TextStyle(
                color: Color(0xFF35452D),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _showReceiverPicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDE4D8)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xFF426B2C),
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedReceiver,
                          style: const TextStyle(
                            color: Color(0xFF25341E),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF7B8177),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDDE4D8)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '익명으로 보내기',
                          style: TextStyle(
                            color: Color(0xFF35452D),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '받는 사람에게 보낸 사람의 이름이 표시되지 않아요.',
                          style: TextStyle(
                            color: Color(0xFF8A9186),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _isAnonymous,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF426B2C),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFD5D9D2),
                    onChanged: (value) {
                      setState(() => _isAnonymous = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const Text(
              '편지 내용',
              style: TextStyle(
                color: Color(0xFF35452D),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _contentController,
              minLines: 7,
              maxLines: 10,
              maxLength: 500,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: Color(0xFF35452D),
                fontSize: 15,
                height: 1.55,
              ),
              decoration: InputDecoration(
                hintText: '오늘 전하고 싶었던 마음을 편지로 남겨보세요.',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB3A9),
                  fontSize: 14,
                  height: 1.5,
                ),
                counterStyle: const TextStyle(
                  color: Color(0xFF92988E),
                  fontSize: 11,
                ),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDDE4D8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF6F925B),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? _submitLetter : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF426B2C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD8DDD4),
                  disabledForegroundColor: const Color(0xFF969D92),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '편지 보내기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
