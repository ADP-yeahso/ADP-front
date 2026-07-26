import 'package:flutter/material.dart';
import 'family_group_list_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  void _updateAll(bool? value) {
    setState(() {
      _agreeAll = value ?? false;
      _agreeTerms = _agreeAll;
      _agreePrivacy = _agreeAll;
      _agreeMarketing = _agreeAll;
    });
  }

  void _checkAll() {
    setState(() {
      _agreeAll = _agreeTerms && _agreePrivacy && _agreeMarketing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        title: Text('회원가입', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 24)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LabelInput(label: '아이디 (이메일)', primaryColor: primaryColor),
            const SizedBox(height: 16),
            _LabelInput(label: '비밀번호', hint: '8자 이상, 영문, 숫자, 특수문자 조합', primaryColor: primaryColor, obscureText: true, showVisibilityIcon: true),
            const SizedBox(height: 16),
            _LabelInput(label: '비밀번호 확인', primaryColor: primaryColor, obscureText: true, showVisibilityIcon: true),
            const SizedBox(height: 16),
            _LabelInput(label: '이름 (닉네임)', primaryColor: primaryColor),
            const SizedBox(height: 16),
            _LabelInput(label: '전화번호', primaryColor: primaryColor),
            
            const SizedBox(height: 32),
            _buildCheckboxRow('서비스 이용약관 동의 (필)', _agreeTerms, (v) {
              setState(() => _agreeTerms = v ?? false);
              _checkAll();
            }, primaryColor),
            _buildCheckboxRow('개인정보 수집 및 이용 동의 (필)', _agreePrivacy, (v) {
              setState(() => _agreePrivacy = v ?? false);
              _checkAll();
            }, primaryColor),
            _buildCheckboxRow('광고 및 마케팅 알림 수신 동의 (선)', _agreeMarketing, (v) {
              setState(() => _agreeMarketing = v ?? false);
              _checkAll();
            }, primaryColor),
            const SizedBox(height: 8),
            _buildCheckboxRow('모두 동의', _agreeAll, _updateAll, primaryColor, isBold: true),
            
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyGroupListScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: primaryColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('회원 가입', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to login
                },
                child: RichText(
                  text: TextSpan(
                    text: '이미 계정이 있으신가요? ',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '로그인',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String title, bool value, ValueChanged<bool?> onChanged, Color primaryColor, {bool isBold = false}) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                side: BorderSide(color: primaryColor, width: 2),
                activeColor: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelInput extends StatelessWidget {
  final String label;
  final String? hint;
  final Color primaryColor;
  final bool obscureText;
  final bool showVisibilityIcon;

  const _LabelInput({
    required this.label,
    this.hint,
    required this.primaryColor,
    this.obscureText = false,
    this.showVisibilityIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: showVisibilityIcon
                ? Icon(Icons.visibility_off, color: primaryColor)
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
