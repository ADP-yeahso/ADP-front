import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/mail_letter.dart';

/// 가족 편지함 스크린 (디자인 에셋 적용 완결 버전)
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

  // 편지 쓰기 폼 컨트롤러 및 상태
  final TextEditingController _contentController = TextEditingController();
  String _selectedReceiver = '가족 모두에게';
  bool _isAnonymous = false;

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

  // 5. 수신자 선택 바텀시트 모달 (디자인 가이드 기반)
  Future<void> _showReceiverPicker() async {
    final receiverOptions = _getReceiverOptions(context);

    final selectedReceiver = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFFFFDF0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드래그 핸들
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5C2AA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 헤더 Row (타이틀 + X 닫기 버튼)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '받는 사람을 선택해 주세요',
                      style: TextStyle(
                        color: Color(0xFF1F2E1B),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(bottomSheetContext).pop(),
                      child: SvgPicture.asset(
                        'assets/svg/mailbox/close_icon.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF526B43),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 수신자 옵션 리스트
                ...receiverOptions.map((receiver) {
                  final isSelected = receiver == _selectedReceiver;
                  final isGroup = receiver == '가족 모두에게';

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop(receiver);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA1D17A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            isGroup
                                ? 'assets/svg/mailbox/family_icon.svg'
                                : 'assets/svg/mailbox/personal_icon.svg',
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              isSelected
                                  ? const Color(0xFF1F2E1B)
                                  : const Color(0xFF35452D),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            receiver,
                            style: TextStyle(
                              color: const Color(0xFF1F2E1B),
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  // 2. 편지 상세 모달 팝업 (디자인 가이드 - 편지 박스)
  void _openLetterDetail(MailLetter letter) {
    final appData = context.read<AppData>();
    final isSentLetter = letter.isSentBy(appData.currentMailboxUserId);

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
          backgroundColor: const Color(0xFFFFFBE8),
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF6E8E59), width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 Header: To. {receiver} 및 X 닫기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'To. ${isSentLetter ? receiverLabel : "나"}',
                        style: const TextStyle(
                          color: Color(0xFF1F2E1B),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: SvgPicture.asset(
                          'assets/svg/mailbox/close_icon.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF5B7E46),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 본문 내용 (편지지 느낌)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          letter.content,
                          style: const TextStyle(
                            color: Color(0xFF2C3E26),
                            fontSize: 15,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 구분선
                  Container(
                    height: 1,
                    color: const Color(0xFF7E9F67).withAlpha(100),
                  ),
                  const SizedBox(height: 12),

                  // 하단 Right: From. {sender} 및 보낸 날짜
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'From. $senderLabel',
                          style: const TextStyle(
                            color: Color(0xFF1F2E1B),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          letter.date,
                          style: const TextStyle(
                            color: Color(0xFF738E64),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
              backgroundColor: const Color(0xFFFFFDF0),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFF6E8E59), width: 1.5),
              ),
              title: const Text(
                '편지 작성을 그만둘까요?',
                style: TextStyle(
                  color: Color(0xFF1F2E1B),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: const Text(
                '작성한 편지 내용이 사라져요.',
                style: TextStyle(color: Color(0xFF55694A), fontSize: 14),
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
                      fontWeight: FontWeight.w800,
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

  // 편지 보내기 제출 (디자인 가이드 - 편지 봉투 팝업 모달)
  Future<void> _submitLetter() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      return;
    }

    final messageText = _selectedReceiver == '가족 모두에게'
        ? '가족 모두에게 편지를 보냅니다.'
        : '$_selectedReceiver 님에게 편지를 보냅니다.';

    final shouldSend =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: 279,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. 봉투 프레임 PNG 에셋 (send_dialog_frame.png)
                    Image.asset(
                      'assets/images/mailbox/send_dialog_frame.png',
                      width: 279,
                      height: 148,
                      fit: BoxFit.contain,
                    ),

                    // 2. 메시지 문구 (노란 꽃 아래 여백 배치)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 72,
                      child: Text(
                        messageText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF182F0D),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // 3. 하단 우측 버튼 영역 (cancel_button.svg | action_divider_line.svg | send_button.svg)
                    Positioned(
                      right: 20,
                      bottom: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 취소 버튼 (cancel_button.svg)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(dialogContext).pop(false),
                            child: SvgPicture.asset(
                              'assets/svg/mailbox/cancel_button.svg',
                              width: 27,
                              height: 14,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 구분선 (action_divider_line.svg)
                          SvgPicture.asset(
                            'assets/svg/mailbox/action_divider_line.svg',
                            width: 1,
                            height: 12,
                          ),
                          const SizedBox(width: 8),

                          // 보내기 버튼 (send_button.svg)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(dialogContext).pop(true),
                            child: SvgPicture.asset(
                              'assets/svg/mailbox/send_button.svg',
                              width: 39,
                              height: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
          backgroundColor: const Color(0xFF5B7E46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF0),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: const Color(0xFFFFFDF0),
            child: Column(
              children: [
                // 1. 상단 모아온 편지 에셋 헤더 (top_bar.svg)
                _buildTopBar(context),
                const SizedBox(height: 6),

                // 2. 메인 콘텐츠 (편지 작성 모드 vs 편지 목록)
                Expanded(
                  child: _isComposing
                      ? _buildComposeTab()
                      : Column(
                          children: [
                            // 탭 선택바 (letter_tab_bar.svg + selected_item.svg + received_letters_tab.svg / sent_letters_tab.svg)
                            _buildPillTabBarRow(),
                            const SizedBox(height: 16),

                            Expanded(child: _buildLetterList()),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 상단 top_bar.svg 헤더 (원본 359:73 비율 보존하여 세로 변형 방지)
  Widget _buildTopBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width.clamp(0.0, 480.0);
    final topBarHeight = screenWidth * (73.0 / 359.0);

    return SizedBox(
      width: double.infinity,
      height: topBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/svg/mailbox/top_bar.svg',
              fit: BoxFit.contain,
            ),
          ),
          // 좌측 뒤로가기 화살표 탭 히트박스 영역
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 70,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_isComposing) {
                  _closeCompose();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  // 탭 선택바 (selected_item.svg, received_letters_tab.svg, sent_letters_tab.svg 사용)
  Widget _buildPillTabBarRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: 162,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 바깥 탭 바 프레임 (letter_tab_bar.png)
                Image.asset(
                  'assets/images/mailbox/letter_tab_bar.png',
                  width: 162,
                  height: 42,
                  fit: BoxFit.contain,
                ),

                // 탭 버튼 및 선택 영역 (selected_item.svg 에셋)
                Positioned.fill(
                  child: Row(
                    children: [
                      // 받은 편지 탭
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _activeTabIndex = 0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_activeTabIndex == 0)
                                SvgPicture.asset(
                                  'assets/svg/mailbox/selected_item.svg',
                                  width: 77,
                                  height: 37,
                                  fit: BoxFit.contain,
                                ),
                              SvgPicture.asset(
                                'assets/svg/mailbox/received_letters_tab.svg',
                                width: 47,
                                height: 16,
                                colorFilter: ColorFilter.mode(
                                  _activeTabIndex == 0
                                      ? Colors.black
                                      : const Color(0xFF6B7A63),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 보낸 편지 탭
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _activeTabIndex = 1),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_activeTabIndex == 1)
                                SvgPicture.asset(
                                  'assets/svg/mailbox/selected_item.svg',
                                  width: 77,
                                  height: 37,
                                  fit: BoxFit.contain,
                                ),
                              SvgPicture.asset(
                                'assets/svg/mailbox/sent_letters_tab.svg',
                                width: 45,
                                height: 12,
                                colorFilter: ColorFilter.mode(
                                  _activeTabIndex == 1
                                      ? Colors.black
                                      : const Color(0xFF6B7A63),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // 우측 편지쓰기 아이콘 버튼
          GestureDetector(
            onTap: () {
              setState(() => _isComposing = true);
            },
            child: SvgPicture.asset(
              'assets/svg/mailbox/write_letter_icon.svg',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }


  // 1 & 3. 받은/보낸 편지함 리스트 (빈 상태 및 카드리스트)
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
              // 중앙 나무 일러스트 에셋 (6_그림.svg)
              SvgPicture.asset(
                'assets/svg/mailbox/letter_illustration.svg',
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 24),

              Text(
                isInbox ? '아직 받은 편지가 없어요' : '아직 보낸 편지가 없어요',
                style: const TextStyle(
                  color: Color(0xFF1F2E1B),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                '소중한 가족에게\n따뜻한 마음을 전해 보아요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF738E64),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: letters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final letter = letters[index];

        final prefix = isInbox ? 'From. ' : 'To. ';
        final personName = isInbox
            ? (letter.isAnonymous ? '익명의 가족' : letter.sender)
            : letter.receiver;

        return GestureDetector(
          onTap: () => _openLetterDetail(letter),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7E9F67), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: From. {name} or To. {name}
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF1F2E1B),
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: prefix,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: personName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Content preview
                Text(
                  letter.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3B4D34),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // 날짜 구분선
                Container(
                  height: 1,
                  color: const Color(0xFF7E9F67).withAlpha(100),
                ),
                const SizedBox(height: 10),

                // 날짜 표시 (20XX.XX.XX 월요일)
                Text(
                  letter.date,
                  style: const TextStyle(
                    color: Color(0xFF6B8756),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. 편지 쓰기 화면 (수신자 선택 + 익명 체크박스 + 편지 작성 + 편지 보내기 버튼)
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 수신자 선택 라벨
            const Text(
              '수신자 선택',
              style: TextStyle(
                color: Color(0xFF1F2E1B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            // To. 수신자 선택 카드
            GestureDetector(
              onTap: _showReceiverPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBE8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7E9F67), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Text(
                      'To. ',
                      style: TextStyle(
                        color: Color(0xFF1F2E1B),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _selectedReceiver,
                        style: const TextStyle(
                          color: Color(0xFF1F2E1B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 익명으로 보내기 체크박스 Row
            GestureDetector(
              onTap: () {
                setState(() => _isAnonymous = !_isAnonymous);
              },
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _isAnonymous
                          ? const Color(0xFF90B978)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF90B978),
                        width: 1.5,
                      ),
                    ),
                    child: _isAnonymous
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '익명으로 보내기',
                    style: TextStyle(
                      color: Color(0xFF3B4D34),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 편지 쓰기 라벨
            const Text(
              '편지 쓰기',
              style: TextStyle(
                color: Color(0xFF1F2E1B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            // 편지 작성 텍스트 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBE8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7E9F67), width: 1.2),
              ),
              child: TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: 10,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: Color(0xFF2C3E26),
                  fontSize: 15,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  hintText: '가족에게 마음을 전하는 따뜻한 이야기를 적어주세요.',
                  hintStyle: TextStyle(
                    color: Color(0xFF91A883),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterStyle: TextStyle(
                    color: Color(0xFF738E64),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 편지 보내기 버튼 (작성 전: send_letter_yellow.png, 작성 후: send_letter_green.png)
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: canSubmit ? _submitLetter : null,
                child: Image.asset(
                  canSubmit
                      ? 'assets/images/mailbox/send_letter_green.png'
                      : 'assets/images/mailbox/send_letter_yellow.png',
                  width: 270,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
