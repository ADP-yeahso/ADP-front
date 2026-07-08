import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/garden_nav_controller.dart';
import 'calendar/calendar_screen.dart';
import 'family/family_share_screen.dart';
import 'garden/garden_screen.dart';
import 'profile/profile_screen.dart';
import 'record/record_choice_sheet.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    GardenScreen(),
    CalendarScreen(),
    FamilyShareScreen(),
    ProfileScreen(),
  ];

  GardenNavController? _navController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<GardenNavController>();
    if (_navController != nav) {
      _navController?.removeListener(_handleNavRequest);
      _navController = nav..addListener(_handleNavRequest);
    }
  }

  @override
  void dispose() {
    _navController?.removeListener(_handleNavRequest);
    super.dispose();
  }

  void _handleNavRequest() {
    if (_navController?.pendingDate != null && _index != 0) {
      setState(() => _index = 0);
    }
  }

  Future<void> _openRecordChoice() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecordChoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _openRecordChoice,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('기록하기'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.park_outlined), selectedIcon: Icon(Icons.park), label: '정원'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: '캘린더'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: '가족 공유'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}
