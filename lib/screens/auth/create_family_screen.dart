import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'group_created_screen.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final FocusNode _relationFocusNode = FocusNode();
  bool _isCustomRelation = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onStateChanged);
    _birthController.addListener(_onStateChanged);
    _relationController.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onStateChanged);
    _birthController.removeListener(_onStateChanged);
    _relationController.removeListener(_onStateChanged);
    _nameController.dispose();
    _birthController.dispose();
    _relationController.dispose();
    _relationFocusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  bool get _isAllFilled =>
      _nameController.text.isNotEmpty &&
      _birthController.text.isNotEmpty &&
      _relationController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // 0번 로그인 화면과 동일하게 시안 해상도(351 x 727) 기준 스케일 계산
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double wScale = screenWidth / 351;
    final double hScale = screenHeight / 727;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0), // 배경색
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 뒤로가기 버튼
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.only(left: 20 * wScale, top: 10 * hScale, right: 20 * wScale, bottom: 10 * hScale),
                    child: SvgPicture.asset('assets/auth/create_family/icon_back.svg', width: 21 * wScale, height: 31 * wScale),
                  ),
                ),
              ),
              
              SizedBox(height: 10 * hScale),
              
              // 2. 가족 그룹 아이콘 + 플러스 아이콘
              SizedBox(
                width: 102 * wScale,
                height: 102 * wScale,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: SvgPicture.asset('assets/auth/create_family/icon_new_family.svg', width: 98 * wScale, height: 98 * wScale),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SvgPicture.asset('assets/auth/create_family/icon_plus.svg', width: 28 * wScale, height: 28 * wScale),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24 * hScale),
              
              // 3. 타이틀 및 부제
              SvgPicture.asset('assets/auth/create_family/text_title.svg', width: 166 * wScale, height: 28 * wScale),
              SizedBox(height: 10 * hScale),
              SvgPicture.asset('assets/auth/create_family/text_subtitle.svg', width: 147 * wScale, height: 28 * wScale),
              
              SizedBox(height: 50 * hScale),
              
              // 4. 환자 정보 입력 폼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 라벨 이미지
                  Padding(
                    padding: EdgeInsets.only(top: 20 * hScale),
                    child: SvgPicture.asset('assets/auth/create_family/label_patient_info.svg', width: 59 * wScale, height: 133 * wScale),
                  ),
                  SizedBox(width: 16 * wScale),
                  // 오른쪽 텍스트 필드들
                  SizedBox(
                    width: 196 * wScale,
                    height: 145 * hScale, // 라벨과 높이를 비슷하게 맞춤
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInputField(_nameController, wScale, hScale),
                        _buildInputField(
                          _birthController, 
                          wScale, 
                          hScale,
                          readOnly: true,
                          onTap: () => _showDatePicker(context),
                        ),
                        _buildInputField(
                          _relationController, 
                          wScale, 
                          hScale,
                          readOnly: !_isCustomRelation,
                          onTap: _isCustomRelation ? null : () => _showRelationPicker(context),
                          focusNode: _relationFocusNode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 130 * hScale),//
              
              // 5. 만들기 버튼
              GestureDetector(
                onTap: () {
                  if (_isAllFilled) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreatedScreen()));
                  }
                },
                child: Image.asset(
                  _isAllFilled 
                      ? 'assets/auth/create_family/btn_create_active.png'
                      : 'assets/auth/create_family/btn_create_inactive.png',
                  width: 261 * wScale,
                  height: 48 * wScale,
                  fit: BoxFit.fill,
                ),
              ),
              
              SizedBox(height: 40 * hScale),
            ],
          ),
        ),
      ),
    );
  }

  void _showRelationPicker(BuildContext context) {
    final List<String> relations = ['아버지', '어머니', '남편', '아내', '할아버지', '할머니', '기타'];
    String tempSelected = _isCustomRelation ? '기타' : _relationController.text;
    if (tempSelected.isEmpty || !relations.contains(tempSelected)) {
       tempSelected = _isCustomRelation ? '기타' : ''; 
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 40),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '환자를 부르는 호칭',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '설정 화면과 기록 문구에 사용되는 호칭이에요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: relations.length,
                      itemBuilder: (context, index) {
                        final rel = relations[index];
                        final isSelected = tempSelected == rel;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setModalState(() {
                              tempSelected = rel;
                            });
                            Future.delayed(const Duration(milliseconds: 150), () {
                              if (!mounted) return;
                              setState(() {
                                if (rel == '기타') {
                                  _isCustomRelation = true;
                                  _relationController.clear();
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) _relationFocusNode.requestFocus();
                                  });
                                } else {
                                  _isCustomRelation = false;
                                  _relationController.text = rel;
                                }
                              });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? const Color(0xFF2A5948) : const Color(0xFFDDDDDD),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  rel,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDatePicker(BuildContext context) {
    DateTime tempDate = DateTime.now();
    
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: const Color(0xFFFFFBF0),
        child: Column(
          children: [
            Container(
              height: 50,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _birthController.text = "${tempDate.year}.${tempDate.month.toString().padLeft(2, '0')}.${tempDate.day.toString().padLeft(2, '0')}";
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  '완료',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: DateTime.now(),
                mode: CupertinoDatePickerMode.date,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  tempDate = newDate;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, double wScale, double hScale, {bool readOnly = false, VoidCallback? onTap, FocusNode? focusNode}) {
    return SizedBox(
      width: 196 * wScale,
      height: 40 * hScale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 밑줄
          SvgPicture.asset(
            'assets/auth/create_family/line_underline.svg',
            width: 196 * wScale,
            height: 4 * hScale,
            fit: BoxFit.fill,
          ),
          // 입력창
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // 밑줄과 텍스트 필드의 바닥을 맞춤
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              onTap: onTap,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15 * wScale,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.2, // 폰트 자체의 행간을 줄여 커서 크기를 텍스트와 맞춤
              ),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                // 밑줄 두께(4) + 여백(4) = 8
                contentPadding: EdgeInsets.only(bottom: 5 * hScale),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
