import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const settingsBackground = Color(0xFFFFFBF0);
const settingsGreen = Color(0xFF1E3815);

Widget settingsSvg(
  String group,
  String name, {
  double? width,
  double? height,
}) => SvgPicture.asset(
  'assets/settings/$group/$name.svg',
  width: width,
  height: height,
);

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.child,
    this.headerAsset,
  });
  final Widget title;
  final Widget child;
  final String? headerAsset;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: settingsBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              Container(
                height: 66,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE8E5DA))),
                ),
                child: Stack(
                  children: [
                    if (headerAsset != null)
                      Positioned.fill(
                        child: Image.asset(headerAsset!, fit: BoxFit.fill),
                      ),
                    Center(child: title),
                    Positioned(
                      left: 6,
                      top: 9,
                      child: IconButton(
                        tooltip: '뒤로',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: settingsSvg(
                          'my_page',
                          'icon_exit',
                          width: 12,
                          height: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.group,
    required this.asset,
    required this.height,
    required this.children,
  });
  final String group, asset;
  final double height;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaledHeight = height * constraints.maxWidth / 317;
      return SizedBox(
        height: scaledHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/settings/$group/$asset.png', fit: BoxFit.fill),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      settingsSvg(
                        'my_page',
                        'line_info_divider',
                        height: 1,
                        width: double.infinity,
                      ),
                    Expanded(child: children[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class SettingsAction extends StatelessWidget {
  const SettingsAction({
    super.key,
    required this.group,
    required this.icon,
    required this.text,
    required this.label,
    required this.onTap,
  });
  final String group, icon, text, label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            settingsSvg(group, icon, width: 17, height: 17),
            const SizedBox(width: 6),
            settingsSvg(group, text, height: 13),
          ],
        ),
      ),
    ),
  );
}

class SettingsIdentity extends StatelessWidget {
  const SettingsIdentity({
    super.key,
    required this.group,
    required this.box,
    required this.name,
    required this.subtitle,
    required this.onEdit,
    this.subtitleFirst = false,
  });
  final String group, box, name;
  final Widget subtitle;
  final VoidCallback onEdit;
  final bool subtitleFirst;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SizedBox(
      height: c.maxWidth * 89 / 319,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/settings/$group/$box.png', fit: BoxFit.fill),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/settings/my_page/illustration.png',
                  width: 58,
                  height: 58,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitleFirst) ...[
                        subtitle,
                        const SizedBox(height: 3),
                      ],
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: settingsGreen,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (!subtitleFirst) subtitle,
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 4,
            child: Semantics(
              label: '수정',
              button: true,
              child: InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: settingsSvg(
                    'my_page',
                    'text_edit',
                    width: 39,
                    height: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SettingsEditIdentity extends StatelessWidget {
  const SettingsEditIdentity({
    super.key,
    required this.group,
    required this.controller,
    required this.onPhoto,
  });
  final String group;
  final TextEditingController controller;
  final VoidCallback onPhoto;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 8),
      SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          children: [
            Image.asset(
              'assets/settings/$group/illustration.png',
              width: 130,
              height: 130,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Semantics(
                label: '사진 변경',
                button: true,
                child: InkWell(
                  onTap: onPhoto,
                  child: settingsSvg(group, 'icon_plus', width: 28, height: 28),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: 160,
        child: TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: settingsGreen,
          ),
          decoration: InputDecoration(
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            isDense: true,
            border: InputBorder.none,
            suffixIconConstraints: const BoxConstraints(maxWidth: 18),
            suffixIcon: settingsSvg(
              group,
              'icon_edit_name',
              width: 14,
              height: 14,
            ),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '이름을 입력해 주세요' : null,
        ),
      ),
      settingsSvg(group, 'line_edit_name', width: 137, height: 3),
      const SizedBox(height: 18),
    ],
  );
}

class SettingsSave extends StatelessWidget {
  const SettingsSave({
    super.key,
    required this.group,
    required this.onTap,
    this.isChanged = false,
  });
  final String group;
  final bool isChanged;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Center(
      child: Semantics(
        label: '저장하기',
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Image.asset(
            'assets/settings/$group/btn_save_${isChanged ? 'green' : 'yellow'}.png',
            width: 261,
            height: 48,
            fit: BoxFit.fill,
          ),
        ),
      ),
    ),
  );
}

Future<String?> settingsEditText(
  BuildContext context,
  String title,
  String initial, {
  bool obscure = false,
}) async {
  final controller = TextEditingController(text: initial);
  final route = DialogRoute<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: obscure,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('확인'),
        ),
      ],
    ),
  );
  final value = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  controller.dispose();
  return value;
}

void settingsUnavailable(BuildContext context, String message) =>
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
