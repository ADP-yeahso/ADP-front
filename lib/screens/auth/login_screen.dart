import 'package:flutter/material.dart';
import '../../widgets/image_asset_button.dart';
import '../../widgets/image_asset_placeholder.dart';
import 'signup_screen.dart';
import 'family_group_list_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // 일러스트 플레이스홀더 (에셋이 오면 imagePath 속성 추가)
              ImageAssetPlaceholder(
                // imagePath: 'assets/images/illust_login.png',
                height: 160,
                fallbackText: '일러스트',
                fallbackColor: primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                '이름',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                '서브??',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              _OutlinedInput(hint: 'ID', primaryColor: primaryColor),
              const SizedBox(height: 16),
              _OutlinedInput(hint: 'P.W', primaryColor: primaryColor, obscureText: true),
              const SizedBox(height: 24),
              
              // 로그인 버튼 (에셋이 오면 imagePath 속성 추가)
              ImageAssetButton(
                // imagePath: 'assets/images/btn_login.png',
                fallbackText: '로그인',
                fallbackColor: primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyGroupListScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              
              // 회원가입 버튼 (에셋이 오면 imagePath 속성 추가)
              ImageAssetButton(
                // imagePath: 'assets/images/btn_signup.png',
                fallbackText: '회원가입',
                fallbackColor: primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedInput extends StatelessWidget {
  final String hint;
  final Color primaryColor;
  final bool obscureText;
  final Widget? suffixIcon;

  const _OutlinedInput({
    required this.hint,
    required this.primaryColor,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
