import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'family_group_list_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 1;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isPwVisible = false;
  bool _isPwConfirmVisible = false;
  
  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
    _pwController.addListener(_onChanged);
    _pwConfirmController.addListener(_onChanged);
    _nicknameController.addListener(_onChanged);
    _phoneController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

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

  // Regex rules
  bool get _isEmailValid {
    if (_emailController.text.isEmpty) return false;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(_emailController.text);
  }

  bool get _isPwValid {
    if (_pwController.text.isEmpty) return false;
    final regex = RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[!@#$%^&*]).{8,16}$');
    return regex.hasMatch(_pwController.text);
  }

  bool get _isPwConfirmValid {
    if (_pwConfirmController.text.isEmpty) return false;
    return _pwController.text == _pwConfirmController.text;
  }

  bool get _isStep1Valid {
    return _isEmailValid && _isPwValid && _isPwConfirmValid;
  }

  bool get _isStep2Valid {
    return _nicknameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _agreeTerms &&
        _agreePrivacy;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double wScale = screenWidth / 351;
    final double hScale = screenHeight / 727;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- [1. 상단 뒤로가기 버튼 영역] ---
              Padding(
                padding: EdgeInsets.only(left: 20 * wScale, top: 10 * hScale),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(5 * wScale),
                    child: _step == 2
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _step = 1),
                            child: SvgPicture.asset('assets/auth/signup/icon_back.svg', width: 21 * wScale, height: 31 * wScale),
                          )
                        : SizedBox(height: 31 * wScale, width: 21 * wScale),
                  ),
                ),
              ),
              
              // --- [상단 뒤로가기 버튼과 타이틀 사이의 여백] --- (조절 가능)
              SizedBox(height: 10 * hScale),

              // --- [2. 메인 타이틀 ('회원가입')] ---
              SvgPicture.asset('assets/auth/signup/text_signup.svg', width: 147 * wScale, height: 42 * wScale),
              
              // --- [타이틀과 입력 폼들 사이의 여백] --- (조절 가능)
              SizedBox(height: 60 * hScale),

              // --- [3. 입력 폼 영역 (Step 1 / Step 2)] ---
              if (_step == 1) _buildStep1(wScale, hScale),
              if (_step == 2) _buildStep2(wScale, hScale),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(double wScale, double hScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26 * wScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- [아이디 (이메일) 라벨] ---
          Padding(
            padding: EdgeInsets.only(left: 12 * wScale),
            child: SvgPicture.asset('assets/auth/signup/text_id.svg', width: 100 * wScale),
          ),
          
          // 라벨과 입력창 사이의 여백 (조절 가능)
          SizedBox(height: 2 * hScale),
          
          // --- [아이디 (이메일) 입력창] ---
          _buildInputBox(_emailController, wScale, hScale, isValid: _isEmailValid, isError: _emailController.text.isNotEmpty && !_isEmailValid),
          
          // 입력창과 하단 안내문구 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [아이디 (이메일) 안내 문구] ---
          if (_emailController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 6 * wScale),
              child: Row(
                children: [
                  SvgPicture.asset(_isEmailValid ? 'assets/auth/signup/icon_check.svg' : 'assets/auth/signup/icon_x.svg', width: 16 * wScale),
                  SizedBox(width: 4 * wScale),
                  SvgPicture.asset(_isEmailValid ? 'assets/auth/signup/text_email_available.svg' : 'assets/auth/signup/text_email_unavailable.svg', height: 12 * wScale),
                ],
              ),
            ),
          
          // 각 입력 항목 그룹들 간의 여백 (조절 가능)
          SizedBox(height: 48 * hScale),

          // --- [비밀번호 라벨] ---
          Padding(
            padding: EdgeInsets.only(left: 12 * wScale),
            child: SvgPicture.asset('assets/auth/signup/text_pw.svg', width: 62 * wScale),
          ),
          
          // 라벨과 입력창 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [비밀번호 입력창] ---
          _buildInputBox(_pwController, wScale, hScale, isPassword: true, showEyeIcon: true, isValid: _isPwValid, isError: _pwController.text.isNotEmpty && !_isPwValid, isVisible: _isPwVisible, onToggleVisibility: () => setState(() => _isPwVisible = !_isPwVisible)),
          
          // 입력창과 하단 안내문구 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [비밀번호 안내 문구들] ---
          if (_pwController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 6 * wScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(_isPwValid ? 'assets/auth/signup/icon_check.svg' : 'assets/auth/signup/icon_x.svg', width: 16 * wScale),
                      SizedBox(width: 4 * wScale),
                      SvgPicture.asset('assets/auth/signup/text_pw_rule1.svg', height: 12 * wScale),
                    ],
                  ),
                  SizedBox(height: 4 * hScale),
                  Row(
                    children: [
                      SvgPicture.asset(_isPwValid ? 'assets/auth/signup/icon_check.svg' : 'assets/auth/signup/icon_check.svg', width: 16 * wScale),
                      SizedBox(width: 4 * wScale),
                      SvgPicture.asset('assets/auth/signup/text_pw_rule2.svg', height: 12 * wScale),
                    ],
                  ),
                ],
              ),
            ),
          
          // 각 입력 항목 그룹들 간의 여백 (조절 가능)
          SizedBox(height: 48 * hScale),

          // --- [비밀번호 확인 라벨] ---
          Padding(
            padding: EdgeInsets.only(left: 12 * wScale),
            child: SvgPicture.asset('assets/auth/signup/text_pw_confirm.svg', width: 88 * wScale),
          ),
          
          // 라벨과 입력창 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [비밀번호 확인 입력창] ---
          _buildInputBox(_pwConfirmController, wScale, hScale, isPassword: true, showEyeIcon: true, isValid: _isPwConfirmValid, isError: _pwConfirmController.text.isNotEmpty && !_isPwConfirmValid, isVisible: _isPwConfirmVisible, onToggleVisibility: () => setState(() => _isPwConfirmVisible = !_isPwConfirmVisible)),
          
          // 입력창과 하단 안내문구 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [비밀번호 확인 불일치 문구] ---
          if (_pwConfirmController.text.isNotEmpty && !_isPwConfirmValid)
            Padding(
              padding: EdgeInsets.only(left: 6 * wScale),
              child: Row(
                children: [
                  SvgPicture.asset('assets/auth/signup/icon_x.svg', width: 16 * wScale),
                  SizedBox(width: 4 * wScale),
                  SvgPicture.asset('assets/auth/signup/text_pw_mismatch.svg', height: 12 * wScale),
                ],
              ),
            ),

          // --- [입력 폼과 하단 '다음' 버튼 사이의 커다란 여백] --- 
          // 버튼 위치를 올리려면 높이를 줄이고, 내리려면 높이를 키우세요.
          SizedBox(height: 80 * hScale),
          
          // --- [4. '다음' 버튼] ---
          Center(
            child: GestureDetector(
              onTap: () {
                if (_isStep1Valid) {
                  setState(() => _step = 2);
                }
              },
              child: SvgPicture.asset(
                _isStep1Valid ? 'assets/auth/signup/btn_next_green.svg' : 'assets/auth/signup/btn_next_yellow.svg',
                width: 299 * wScale,
              ),
            ),
          ),
          
          // --- [하단 여백 (화면 맨 밑바닥 여유공간)] ---
          SizedBox(height: 40 * hScale),
        ],
      ),
    );
  }

  Widget _buildStep2(double wScale, double hScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26 * wScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- [닉네임 라벨] ---
          Padding(
            padding: EdgeInsets.only(left: 12 * wScale),
            child: SvgPicture.asset('assets/auth/signup/text_nickname.svg', width: 100 * wScale),
          ),
          
          // 라벨과 입력창 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [닉네임 입력창] ---
          _buildInputBox(_nicknameController, wScale, hScale),
          
          // 입력창과 하단 안내문구 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [닉네임 안내 문구] ---
          Padding(
            padding: EdgeInsets.only(left: 6 * wScale),
            child: SvgPicture.asset('assets/auth/signup/text_nickname_rule.svg', height: 12 * wScale),
          ),
          
          // 각 입력 항목 그룹들 간의 여백 (조절 가능)
          SizedBox(height: 48 * hScale),

          // --- [전화번호 라벨] ---
          Padding(
            padding: EdgeInsets.only(left: 12 * wScale),
            child: SvgPicture.asset('assets/auth/signup/text_phone.svg', width: 62 * wScale),
          ),
          
          // 라벨과 입력창 사이의 여백 (조절 가능)
          SizedBox(height: 6 * hScale),
          
          // --- [전화번호 입력창] ---
          _buildInputBox(_phoneController, wScale, hScale),
          
          // 입력 폼들과 약관 동의 리스트 사이의 여백 (조절 가능)
          SizedBox(height: 40 * hScale),

          // --- [약관 동의 체크박스 리스트] ---
          _buildTermsRow(wScale, hScale, '서비스 이용약관 동의 (필수)', _agreeTerms, (v) {
            setState(() => _agreeTerms = v ?? false);
            _checkAll();
          }),
          
          // 체크박스 항목들 사이 여백 (조절 가능)
          SizedBox(height: 12 * hScale),
          
          _buildTermsRow(wScale, hScale, '개인정보 수집 및 이용 동의 (필수)', _agreePrivacy, (v) {
            setState(() => _agreePrivacy = v ?? false);
            _checkAll();
          }),
          
          // 체크박스 항목들 사이 여백 (조절 가능)
          SizedBox(height: 12 * hScale),
          
          _buildTermsRow(wScale, hScale, '광고 및 푸쉬성 알람 수신 동의 (선택)', _agreeMarketing, (v) {
            setState(() => _agreeMarketing = v ?? false);
            _checkAll();
          }),
          
          // 체크박스 항목들 사이 여백 (조절 가능)
          SizedBox(height: 12 * hScale),
          
          _buildTermsRow(wScale, hScale, '전체 동의', _agreeAll, _updateAll, isAll: true),

          // --- [약관 리스트와 하단 '회원가입' 버튼 사이의 커다란 여백] --- 
          // 버튼 위치를 올리려면 높이를 줄이고, 내리려면 높이를 키우세요.
          SizedBox(height: 80 * hScale),
          
          // --- [5. '회원가입' 버튼] ---
          Center(
            child: GestureDetector(
              onTap: () {
                if (_isStep2Valid) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyGroupListScreen()),
                  );
                }
              },
              child: SvgPicture.asset(
                _isStep2Valid ? 'assets/auth/signup/btn_signup_green.svg' : 'assets/auth/signup/btn_signup_yellow.svg',
                width: 299 * wScale,
              ),
            ),
          ),
          
          // --- [하단 여백 (화면 맨 밑바닥 여유공간)] ---
          SizedBox(height: 40 * hScale),
        ],
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller, double wScale, double hScale, {bool isPassword = false, bool showEyeIcon = false, bool isValid = false, bool isError = false, bool isVisible = false, VoidCallback? onToggleVisibility}) {
    String boxAsset = 'assets/auth/signup/box_empty.png';
    if (isValid) boxAsset = 'assets/auth/signup/box_normal.png';
    if (isError) boxAsset = 'assets/auth/signup/box_error.png';

    return SizedBox(
      width: 299 * wScale,
      height: 38 * wScale, // as per svg
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(boxAsset, fit: BoxFit.fill),
          ),
          Positioned.fill(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !isVisible,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15 * wScale,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(
                  left: 12 * wScale, 
                  right: showEyeIcon ? 40 * wScale : 12 * wScale,
                  top: 6 * hScale, // 커서를 아래로 내리기 위한 여백 추가
                ), 
                isDense: true,
              ),
            ),
          ),
          if (showEyeIcon)
            Positioned(
              right: 12 * wScale,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleVisibility,
                child: Center(
                  child: SvgPicture.asset(
                    isVisible ? 'assets/auth/signup/icon_eye_open.svg' : 'assets/auth/signup/icon_eye_closed.svg',
                    width: 32 * wScale,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTermsRow(double wScale, double hScale, String text, bool value, ValueChanged<bool?> onChanged, {bool isAll = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 20 * wScale,
                height: 20 * wScale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6 * wScale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: Offset(1 * wScale, 1 * wScale),
                      blurRadius: 2 * wScale,
                    ),
                  ],
                ),
              ),
              if (value)
                SvgPicture.asset('assets/auth/signup/icon_checkbox.svg', width: 14 * wScale),
            ],
          ),
          SizedBox(width: 12 * wScale),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14 * wScale,
              fontWeight: isAll ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
