import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/garden_nav_controller.dart';
import 'calendar/calendar_screen.dart';
import 'garden/garden_screen.dart';
import 'profile/profile_screen.dart';
import 'record/record_choice_sheet.dart';
import 'gallery/gallery_screen.dart';

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
    GalleryScreen(),
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
      body: Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => IndexedStack(index: _index, children: _screens),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRecordChoice,
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. 홈
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: '홈',
              ),
              // 2. 기억 보기
              _buildNavItem(
                index: 1,
                icon: Icons.park_outlined,
                selectedIcon: Icons.park,
                label: '기억 보기',
              ),
              // 가운데 + 버튼을 위한 여백
              const SizedBox(width: 48),
              // 3. 갤러리
              _buildNavItem(
                index: 2,
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library,
                label: '갤러리',
              ),
              // 4. Setting
              _buildNavItem(
                index: 3,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Setting',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _index == index;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey[600];

    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

