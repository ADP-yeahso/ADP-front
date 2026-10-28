import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../models/groups.dart';
import '../root_shell.dart';

class GroupCreatedScreen extends StatelessWidget {
  const GroupCreatedScreen({super.key, this.group});

  final Group? group;

  @override
  Widget build(BuildContext context) {
    final groupName =
        group?.groupName ?? context.watch<AppData>().group.groupName;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: SvgPicture.asset(
                  'assets/auth/group_created/icon_family_group.svg',
                  width: 220,
                  height: 220,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  groupName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A5948),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: SvgPicture.asset(
                  'assets/auth/group_created/text_subtitle.svg',
                  height: 18,
                ),
              ),
              const Spacer(flex: 3),
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RootShell()),
                    (route) => false,
                  );
                },
                child: SizedBox(
                  height: 72,
                  child: Image.asset(
                    'assets/auth/group_created/btn_enter_garden.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
