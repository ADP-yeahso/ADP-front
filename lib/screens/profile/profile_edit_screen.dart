import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/auth_session.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'settings_components.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;

  bool _initialized = false;
  late final String _initialName, _initialPassword, _initialPhone;

  bool get _hasChanges =>
      _nameController.text != _initialName ||
      _passwordController.text != _initialPassword ||
      _phoneController.text != _initialPhone;

  void _onEdited() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    final user = context.read<AppData>().me;

    _nameController = TextEditingController(text: user.name);
    _passwordController = TextEditingController(text: user.password);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _initialName = user.name;
    _initialPassword = user.password;
    _initialPhone = user.phoneNumber;
    for (final controller in [
      _nameController,
      _passwordController,
      _phoneController,
    ]) {
      controller.addListener(_onEdited);
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showPhotoMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('사진 변경 기능은 추후 추가할 예정이에요.')));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final data = context.read<AppData>();
      await data.updateCurrentUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (_passwordController.text.isNotEmpty &&
          _passwordController.text != _initialPassword) {
        await data.updateCurrentUserPassword(_passwordController.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었어요.')));
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _deleteAccount() async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final yes = await settingsConfirm(
      context,
      title: '계정 삭제',
      message: '계정과 작성한 데이터가 삭제되며 복구할 수 없습니다. 정말 삭제할까요?',
      confirmLabel: '삭제',
    );
    if (yes != true || !mounted) return;
    try {
      await context.read<AppData>().deleteCurrentUserAccount();
      if (!mounted) return;
      context.read<AuthSession>().signOut();
      rootNavigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return SettingsPage(
      title: settingsTitle('edit_profile', '프로필 수정'),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SettingsEditIdentity(
              group: 'edit_profile',
              controller: _nameController,
              onPhoto: _showPhotoMessage,
            ),
            SettingsPanel(
              group: 'edit_profile',
              asset: 'box_edit_profile',
              height: 96,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 14),
                    settingsSvg(
                      'edit_profile',
                      'text_patient_relationship',
                      height: 13,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        data.patientRelationshipLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 14),
                    settingsSvg('edit_profile', 'text_phone', height: 13),
                    const SizedBox(width: 50),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: '전화번호 입력',
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = (v ?? '')
                              .replaceAll(RegExp(r'[^0-9]'), '')
                              .length;
                          return n < 10 || n > 11 ? '전화번호를 확인해 주세요' : null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            SettingsPanel(
              group: 'edit_profile',
              asset: 'box_edit_profile',
              height: 96,
              children: [
                SettingsAction(
                  group: 'edit_profile',
                  icon: 'icon_edit',
                  text: 'text_change_password',
                  textHeight: 13,
                  label: '비밀번호 수정',
                  onTap: () async {
                    final value = await settingsEditText(
                      context,
                      '비밀번호 수정',
                      '',
                      obscure: true,
                    );
                    if (!context.mounted || value == null) return;
                    final valid =
                        value.length >= 8 &&
                        value.length <= 16 &&
                        RegExp(r'[A-Za-z]').hasMatch(value) &&
                        RegExp(r'\d').hasMatch(value) &&
                        RegExp(r'[^A-Za-z0-9]').hasMatch(value);
                    if (!valid) {
                      settingsUnavailable(
                        context,
                        '비밀번호는 8~16자의 영문, 숫자, 특수문자를 포함해 주세요.',
                      );
                      return;
                    }
                    _passwordController.text = value;
                  },
                ),
                SettingsAction(
                  group: 'edit_profile',
                  icon: 'icon_delete',
                  text: 'text_delete_account',
                  textHeight: 13,
                  label: '계정 삭제',
                  onTap: _deleteAccount,
                ),
              ],
            ),
            SettingsSave(
              group: 'edit_profile',
              onTap: _saveProfile,
              isChanged: _hasChanges,
            ),
          ],
        ),
      ),
    );
  }
}
