import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/auth_session.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import '../record/write/diary_start_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSubmitting = false;

  Future<void> _login() async {
    setState(() => _isSubmitting = true);
    
    try {
      // 데이터 수집용 자동 로그인 처리
      final tokens = await AuthService().login(
        email: 'test@example.com',
        password: 'abc1234!',
      );
      if (!mounted) return;
      
      // 세션에 토큰 저장 (이후 다이어리 작성 시 사용됨)
      context.read<AuthSession>().signIn(tokens);
      
      // 시작 화면(DiaryStartScreen)으로 바로 넘어가기
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DiaryStartScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('자동 로그인 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 로고
                SvgPicture.asset(
                  'assets/auth/login/logo.svg',
                  height: 105 * wScale,
                ),
                // 로고와 부제 사이 간격
                SizedBox(height: 25 * hScale),

                // 2. 부제
                SvgPicture.asset(
                  'assets/auth/login/subtitle.svg',
                  width: 232 * wScale,
                  height: 16 * wScale,
                ),
                // 부제와 하단 버튼 사이 간격 (적당히 가까운 위치로 조정)
                SizedBox(height: 60 * hScale),

                // 3. 로그인(다음) 버튼
                GestureDetector(
                  onTap: _isSubmitting ? null : _login,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/auth/signup/btn_next_green.svg',
                        width: 259 * wScale,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

