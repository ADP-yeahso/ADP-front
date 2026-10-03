import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/auth_session.dart';
import '../../services/group_service.dart';
import '../root_shell.dart';
import 'create_family_screen.dart';

class FamilyGroupListScreen extends StatefulWidget {
  const FamilyGroupListScreen({super.key});

  @override
  State<FamilyGroupListScreen> createState() => _FamilyGroupListScreenState();
}

class _FamilyGroupListScreenState extends State<FamilyGroupListScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  final GroupService _groupService = GroupService();
  List<GroupSummary> _groups = const [];
  bool _isLoading = true;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _codeFocusNode.addListener(_refresh);
    _codeController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroups());
  }

  @override
  void dispose() {
    _codeFocusNode.removeListener(_refresh);
    _codeController.removeListener(_refresh);
    _codeFocusNode.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadGroups() async {
    final tokens = context.read<AuthSession>().tokens;
    if (tokens == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final groups = await _groupService.listGroups(tokens);
      if (mounted) setState(() => _groups = groups);
    } on GroupException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup() async {
    final inviteCode = _codeController.text.trim();
    if (inviteCode.isEmpty || _isJoining) return;
    final tokens = context.read<AuthSession>().tokens;
    if (tokens == null) {
      _showMessage('로그인 정보가 없습니다. 다시 로그인해주세요.');
      return;
    }
    setState(() => _isJoining = true);
    try {
      final group = await _groupService.joinGroup(
        tokens: tokens,
        inviteCode: inviteCode,
      );
      if (!mounted) return;
      _showMessage('${group.name}에 참여했습니다.');
      _enterApp();
    } on GroupException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _enterApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wScale = size.width / 351;
    final hScale = size.height / 727;
    final showPlaceholder =
        !_codeFocusNode.hasFocus && _codeController.text.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 20 * hScale, width: double.infinity),
              SvgPicture.asset(
                'assets/auth/family_group/family_group_icon.svg',
                width: 104 * wScale,
                height: 104 * wScale,
              ),
              SizedBox(height: 2 * hScale),
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
              if (_isLoading)
                SizedBox(
                  width: 296 * wScale,
                  height: 101 * wScale,
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_groups.isEmpty)
                SizedBox(
                  width: 296 * wScale,
                  height: 101 * wScale,
                  child: const Center(child: Text('참여 중인 그룹이 없어요.')),
                )
              else
                ..._groups.map(
                  (group) => Padding(
                    padding: EdgeInsets.only(bottom: 10 * hScale),
                    child: _GroupCard(
                      group: group,
                      wScale: wScale,
                      onTap: _enterApp,
                    ),
                  ),
                ),
              SizedBox(height: 10 * hScale),
              SvgPicture.asset(
                'assets/auth/family_group/or_divider.svg',
                width: 237 * wScale,
                height: 24 * wScale,
              ),
              SizedBox(height: 20 * hScale),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateFamilyScreen()),
                ),
                child: Image.asset(
                  'assets/auth/family_group/create_new_group_box.png',
                  width: 250 * wScale,
                  height: 41 * wScale,
                  fit: BoxFit.fill,
                ),
              ),
              SizedBox(height: 10 * hScale),
              SizedBox(
                width: 250 * wScale,
                height: 94 * wScale,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/auth/family_group/join_group_box.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      right: 10 * wScale,
                      bottom: 14 * wScale,
                      child: _isJoining
                          ? SizedBox(
                              width: 35 * wScale,
                              height: 35 * wScale,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Image.asset(
                              'assets/auth/family_group/enter_button.png',
                              width: 66 * wScale,
                              height: 35 * wScale,
                              fit: BoxFit.fill,
                            ),
                    ),
                    if (showPlaceholder)
                      Positioned(
                        left: 30 * wScale,
                        bottom: 25 * wScale,
                        child: SvgPicture.asset(
                          'assets/auth/family_group/enter_group_code_placeholder.svg',
                          width: 110 * wScale,
                          height: 14 * wScale,
                        ),
                      ),
                    Positioned(
                      left: 10,
                      right: 60 * wScale,
                      bottom: 0,
                      height: 48 * wScale,
                      child: TextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        enabled: !_isJoining,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _joinGroup(),
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.wScale,
    required this.onTap,
  });

  final GroupSummary group;
  final double wScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 296 * wScale,
        height: 101 * wScale,
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
              left: 28 * wScale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 17 * wScale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5 * wScale),
                  Text(
                    '${group.memberCount}명 참여 중',
                    style: TextStyle(fontSize: 12 * wScale),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20 * wScale,
              child: Image.asset(
                'assets/auth/family_group/enter_text.png',
                width: 85 * wScale,
                height: 85 * (112 / 292) * wScale,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
