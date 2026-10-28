import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/auth_session.dart';
import '../../data/app_data.dart';
import '../../services/api_service.dart';
import 'create_family_screen.dart';
import 'group_created_screen.dart';

class FamilyGroupListScreen extends StatefulWidget {
  const FamilyGroupListScreen({super.key});

  @override
  State<FamilyGroupListScreen> createState() => _FamilyGroupListScreenState();
}

class _FamilyGroupListScreenState extends State<FamilyGroupListScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  List<Map<String, dynamic>> _groups = const [];
  bool _isLoadingGroups = true;
  bool _isOpening = false;
  String? _groupLoadError;

  @override
  void initState() {
    super.initState();
    _codeFocusNode.addListener(_onStateChanged);
    _codeController.addListener(_onStateChanged);
    _loadGroups();
  }

  @override
  void dispose() {
    _codeFocusNode.removeListener(_onStateChanged);
    _codeController.removeListener(_onStateChanged);
    _codeFocusNode.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  Future<void> _loadGroups() async {
    final tokens = context.read<AuthSession>().tokens;
    if (tokens == null) {
      if (mounted) setState(() => _isLoadingGroups = false);
      return;
    }
    try {
      final groups = await GroupApi(ApiService()).list(tokens);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _groupLoadError = null;
        _isLoadingGroups = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _groupLoadError = error.message;
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _openGroup(int groupId) async {
    if (_isOpening) return;
    final tokens = context.read<AuthSession>().tokens;
    if (tokens == null) return;
    setState(() => _isOpening = true);
    try {
      await context.read<AppData>().openGroup(tokens, groupId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupCreatedScreen()),
      );
      if (mounted) await _loadGroups();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  String _groupName(Map<String, dynamic> group) =>
      (group['group_name'] ?? group['name'] ?? '가족 그룹').toString();

  Widget _buildGroupCard(Map<String, dynamic> group, double scale) {
    return GestureDetector(
      onTap: _isOpening ? null : () => _openGroup(group['id'] as int),
      child: SizedBox(
        width: 296 * scale,
        height: 101 * scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/auth/family_group/group_box_1.svg',
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              left: 22 * scale,
              right: 110 * scale,
              child: Text(
                _groupName(group),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF315646),
                ),
              ),
            ),
            Positioned(
              right: 20 * scale,
              child: Image.asset(
                'assets/auth/family_group/enter_text.png',
                width: 85 * scale,
                height: 85 * (112 / 292) * scale,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinGroup() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _isOpening) return;
    final tokens = context.read<AuthSession>().tokens;
    if (tokens == null) return;
    try {
      final group = await GroupApi(ApiService()).join(tokens, code);
      if (!mounted) return;
      _codeController.clear();
      await _openGroup(group['id'] as int);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 0번 로그인 화면과 동일하게 시안 해상도(351 x 727) 기준 스케일 계산
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double wScale = screenWidth / 351;
    final double hScale = screenHeight / 727;

    // 포커스가 없으면서 텍스트가 비어있을 때만 Placeholder SVG를 표시
    final bool showPlaceholder =
        !_codeFocusNode.hasFocus && _codeController.text.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0), // 배경색 (디자이너 지정 컬러)
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(), // 스크롤 바운스 방지
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 최상단 마진
              SizedBox(height: 20 * hScale, width: double.infinity),

              // 2. 가족 그룹 아이콘
              SvgPicture.asset(
                'assets/auth/family_group/family_group_icon.svg',
                width: 104 * wScale,
                height: 104 * wScale,
              ),
              SizedBox(height: 2 * hScale),

              // 3. 타이틀 및 부제
              SvgPicture.asset(
                'assets/auth/family_group/title_text.svg',
                width: 81 * wScale,
                height: 28 * wScale,
              ),
              SizedBox(height: 6 * hScale),
              SvgPicture.asset(
                'assets/auth/family_group/subtitle_text.svg',
                width: 181 * wScale,
                height: 14 * wScale,
              ),
              SizedBox(height: 50 * hScale),

              // 4. 현재 참여 중인 그룹 헤더
              Container(
                width: 296 * wScale,
                padding: EdgeInsets.only(left: 4 * wScale),
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  'assets/auth/family_group/joined_group_header.svg',
                  width: 100 * wScale,
                  height: 16 * wScale,
                ),
              ),
              SizedBox(height: 4 * hScale),

              if (_isLoadingGroups || _isOpening)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: CircularProgressIndicator(),
                )
              else if (_groupLoadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(_groupLoadError!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _loadGroups,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              else if (_groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text('참여 중인 가족 그룹이 없습니다.'),
                )
              else
                ..._groups.map(
                  (group) => Padding(
                    padding: EdgeInsets.only(bottom: 10 * hScale),
                    child: _buildGroupCard(group, wScale),
                  ),
                ),

              // 6. 또는 구분선
              SvgPicture.asset(
                'assets/auth/family_group/or_divider.svg',
                width: 237 * wScale,
                height: 24 * wScale,
              ),
              SizedBox(height: 20 * hScale),

              // 7. 새 그룹 생성 박스
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateFamilyScreen(),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/auth/family_group/create_new_group_box.png',
                  width: 250 * wScale,
                  height: 41 * wScale, //
                  fit: BoxFit.fill, // 크기 변경 시 꽉 차게 늘어나도록 설정
                ),
              ),
              SizedBox(height: 10 * hScale),

              // 8. 그룹 참여 박스 (입력창 포함)
              SizedBox(
                width: 250 * wScale,
                height: 94 * wScale,
                child: Stack(
                  children: [
                    // 박스 배경 (250x94)
                    Positioned.fill(
                      child: Image.asset(
                        'assets/auth/family_group/join_group_box.png',
                        fit: BoxFit.fill,
                      ),
                    ),

                    // 우측 하단 노란색 입장하기 버튼
                    Positioned(
                      right: 10 * wScale,
                      bottom: 14 * wScale,
                      child: Image.asset(
                        'assets/auth/family_group/enter_button.png',
                        width: 66 * wScale,
                        height: 35 * wScale,
                        fit: BoxFit.fill, // 크기 변경 시 꽉 차게 늘어나도록 추가!
                      ),
                    ),

                    // 입력창 Placeholder 텍스트 (SVG)
                    if (showPlaceholder)
                      Positioned(
                        left: 30 * wScale, //
                        bottom: 25 * wScale, //
                        child: SvgPicture.asset(
                          'assets/auth/family_group/enter_group_code_placeholder.svg',
                          width: 110 * wScale,
                          height: 14 * wScale,
                        ),
                      ),

                    // 실제 텍스트 입력창 (투명)
                    Positioned(
                      left: 10,
                      right: 60 * wScale, // 우측에 확인 버튼이 있다고 가정하고 여백
                      bottom: 0 * wScale,
                      height: 48 * wScale,
                      child: TextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14 * wScale,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            left: 16 * wScale,
                            bottom: 8 * wScale,
                          ),
                        ),
                      ),
                    ),

                    // 확인 버튼 터치 영역 (디자이너가 우측 하단에 버튼을 구웠다고 가정)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      width: 60 * wScale,
                      height: 48 * wScale,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _joinGroup,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20 * hScale),
            ],
          ),
        ),
      ),
    );
  }
}
