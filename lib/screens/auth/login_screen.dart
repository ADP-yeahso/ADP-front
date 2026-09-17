import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/auth_session.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'family_group_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final tokens = await _authService.login(email: email, password: password);
      if (!mounted) return;
      context.read<AuthSession>().signIn(tokens);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FamilyGroupListScreen()),
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSignup() async {
    final didSignup = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
    if (!mounted || didSignup != true) return;
    _showMessage('회원가입이 완료되었습니다. 가입한 계정으로 로그인해주세요.');
  }

  @override
  Widget build(BuildContext context) {
    // 디자이너 시안 기준 해상도 (351 x 727)
    final size = MediaQuery.of(context).size;
    final double wScale = size.width / 351;
    final double hScale = size.height / 727;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0), // 배경색 (디자이너 지정 컬러)
      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const ClampingScrollPhysics(), // 콘텐츠가 화면에 다 들어올 때는 스크롤(바운스) 방지
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 세로 여백은 hScale을 적용하여 화면 높이에 비례하게 조절
              // 1. 최상단 여백 (시안 비례 계산: 약 110px)
              SizedBox(height: 110 * hScale, width: double.infinity),

              // 2. 로고 (회원님이 만족하셨던 이전 높이 140 기준으로 롤백)
              // Width 고정을 풀어서, 새 로고의 비율이 변했더라도 찌그러지지 않고 자연스럽게 축소되도록 조치했습니다.
              SvgPicture.asset(
                'assets/auth/login/logo.svg',
                height: 105 * wScale,
              ),
              // 로고와 부제 사이 간격 (시안 비례 계산: 약 16px)
              SizedBox(height: 25 * hScale),

              // 3. 부제
              SvgPicture.asset(
                'assets/auth/login/subtitle.svg',
                width: 232 * wScale,
                height: 16 * wScale,
              ),
              // 부제와 입력창 사이의 큰 여백 (시안 비례 계산: 약 110px)
              SizedBox(height: 110 * hScale),

              // 4. 아이디 입력창
              _SvgInputWidget(
                boxAsset: 'assets/auth/login/id_input_box.png',
                textAsset: 'assets/auth/login/id_input_text.png',
                textWidth: 127,
                textHeight: 13,
                wScale: wScale,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              // 입력창 사이 간격 (시안 비례 계산: 약 14px)
              SizedBox(height: 14 * hScale),

              // 5. 비밀번호 입력창
              _SvgInputWidget(
                boxAsset: 'assets/auth/login/password_input_box.png',
                textAsset: 'assets/auth/login/password_input_text.png',
                textWidth: 139,
                textHeight: 13,
                obscureText: true,
                wScale: wScale,
                controller: _passwordController,
                onSubmitted: (_) => _login(),
              ),
              // 비밀번호 창과 버튼 사이 간격 (시안 비례 계산: 약 32px)
              SizedBox(height: 32 * hScale),

              // 6. 로그인 버튼
              GestureDetector(
                onTap: _isSubmitting ? null : _login,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/auth/login/login_button.png',
                      width: 267 * wScale,
                      height: 66 * wScale,
                      fit: BoxFit.fill,
                    ),
                    if (_isSubmitting)
                      SizedBox(
                        width: 22 * wScale,
                        height: 22 * wScale,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              // 버튼과 하단 메뉴 사이 간격 (시안 비례 계산: 약 24px)
              SizedBox(height: 24 * hScale),

              // 7. 하단 메뉴
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/auth/login/find_id_text.svg',
                    width: 53 * wScale,
                    height: 11 * wScale,
                  ),
                  SizedBox(width: 14 * wScale),
                  SvgPicture.asset(
                    'assets/auth/login/line_1.svg',
                    width: 1 * wScale,
                    height: 13 * wScale,
                  ),
                  SizedBox(width: 14 * wScale),
                  SvgPicture.asset(
                    'assets/auth/login/find_password_text.svg',
                    width: 63 * wScale,
                    height: 11 * wScale,
                  ),
                  SizedBox(width: 14 * wScale),
                  SvgPicture.asset(
                    'assets/auth/login/line_2.svg',
                    width: 1 * wScale,
                    height: 13 * wScale,
                  ),
                  SizedBox(width: 14 * wScale),
                  GestureDetector(
                    onTap: _openSignup,
                    child: SvgPicture.asset(
                      'assets/auth/login/signup_text.svg',
                      width: 40 * wScale,
                      height: 11 * wScale,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40 * hScale),
            ],
          ),
        ),
      ),
    );
  }
}

class _SvgInputWidget extends StatefulWidget {
  final String boxAsset;
  final String textAsset;
  final double textWidth;
  final double textHeight;
  final bool obscureText;
  final double wScale;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _SvgInputWidget({
    required this.boxAsset,
    required this.textAsset,
    required this.textWidth,
    required this.textHeight,
    this.obscureText = false,
    required this.wScale,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
  });

  @override
  State<_SvgInputWidget> createState() => _SvgInputWidgetState();
}

class _SvgInputWidgetState extends State<_SvgInputWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 포커스 상태나 텍스트 입력 상태가 변할 때마다 화면을 다시 그립니다.
    _focusNode.addListener(_onStateChanged);
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onStateChanged);
    widget.controller.removeListener(_onStateChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 입력창이 클릭(포커스)되었거나 글씨가 한 글자라도 있으면 안내 텍스트를 숨깁니다.
    final bool showPlaceholder =
        !_focusNode.hasFocus && widget.controller.text.isEmpty;

    return SizedBox(
      width: 269 * widget.wScale,
      height: 43 * widget.wScale,
      child: Stack(
        children: [
          // 1. 디자이너 원본 박스 에셋 (PNG)
          Positioned.fill(
            child: Image.asset(
              widget.boxAsset,
              width: 269 * widget.wScale,
              height: 43 * widget.wScale,
              fit: BoxFit.fill,
            ),
          ),

          // 2. 안내 텍스트 에셋 (PNG) - 클릭되거나 텍스트가 있으면 안 보이게 처리
          if (showPlaceholder)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18 * widget.wScale,
                ), // 안내 텍스트 조절 위치 패딩값 튜닝
                child: Image.asset(
                  widget.textAsset,
                  width: widget.textWidth * widget.wScale,
                  height: widget.textHeight * widget.wScale,
                ),
              ),
            ),

          // 3. 타이핑을 위한 투명 입력창
          Positioned.fill(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.onSubmitted == null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: widget.onSubmitted,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14 * widget.wScale,
                fontWeight: FontWeight.w500, // 디자이너 시안처럼 살짝 도톰하게 (Medium)
                letterSpacing: -0.5, // 디자이너 시안처럼 자간을 살짝 좁게 (Tighter tracking)
              ),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(
                  left: 16 * widget.wScale,
                  right: 16 * widget.wScale,
                  bottom: 0 * widget.wScale,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
