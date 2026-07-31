import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';

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

  bool _obscurePassword = true;
  bool _initialized = false;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사진 변경 기능은 추후 추가할 예정이에요.'),
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AppData>().updateCurrentUserProfile(
          name: _nameController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 저장되었어요.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppData>().me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          user.color.withValues(alpha: 0.18),
                      child: Icon(
                        Icons.person,
                        size: 52,
                        color: user.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _showPhotoMessage,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('사진 변경'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '이름 또는 닉네임',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해 주세요.';
                  }

                  if (value.trim().length < 2) {
                    return '이름은 두 글자 이상 입력해 주세요.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해 주세요.';
                  }

                  if (value.length < 4) {
                    return '비밀번호는 네 글자 이상 입력해 주세요.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  hintText: '010-1234-5678',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '전화번호를 입력해 주세요.';
                  }

                  final digits =
                      value.replaceAll(RegExp(r'[^0-9]'), '');

                  if (digits.length < 10 || digits.length > 11) {
                    return '올바른 전화번호를 입력해 주세요.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}