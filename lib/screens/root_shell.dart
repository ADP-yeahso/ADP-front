import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/garden_nav_controller.dart';
import 'calendar/calendar_screen.dart';
import 'garden/garden_screen.dart';
import 'profile/profile_screen.dart';
import 'record/record_choice_sheet.dart';
import 'gallery/gallery_screen.dart';
import '../utils/garden_route_observers.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with RouteAware {
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> _rootRouteVisible = ValueNotifier<bool>(true);

  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  final RouteObserver<PageRoute<dynamic>> _gardenInnerRouteObserver =
      RouteObserver<PageRoute<dynamic>>();

  PageRoute<dynamic>? _observedRootRoute;
  GardenNavController? _navController;

  int get _index => _tabIndex.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> &&
        !identical(route, _observedRootRoute)) {
      gardenRootRouteObserver.unsubscribe(this);
      _observedRootRoute = route;
      gardenRootRouteObserver.subscribe(this, route);
    }

    final nav = context.read<GardenNavController>();
    if (_navController != nav) {
      _navController?.removeListener(_handleNavRequest);
      _navController = nav..addListener(_handleNavRequest);
    }
  }

  @override
  void didPushNext() {
    _rootRouteVisible.value = false;
  }

  @override
  void didPopNext() {
    _rootRouteVisible.value = true;
  }

  void _selectTab(int index) {
    if (_index == index) return;

    setState(() {
      _tabIndex.value = index;
    });
  }

  void _handleNavRequest() {
    if (_navController?.pendingDate != null) {
      _selectTab(0);
    }
  }

  @override
  void dispose() {
    gardenRootRouteObserver.unsubscribe(this);
    _navController?.removeListener(_handleNavRequest);
    _tabIndex.dispose();
    _rootRouteVisible.dispose();
    super.dispose();
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
      extendBody: _index == 0,
      body: Navigator(
        key: _navigatorKey,
        observers: [_gardenInnerRouteObserver],
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => ValueListenableBuilder<int>(
            valueListenable: _tabIndex,
            builder: (context, index, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: _rootRouteVisible,
                builder: (context, routeVisible, child) {
                  return IndexedStack(
                    index: index,
                    children: [
                      GardenScreen(
                        key: const ValueKey('garden-screen'),
                        isActive: index == 0,
                        isRouteVisible: routeVisible,
                        routeObserver: _gardenInnerRouteObserver,
                      ),
                      const CalendarScreen(),
                      const GalleryScreen(),
                      const ProfileScreen(),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
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
      onTap: () {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
        _selectTab(index);
      },
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

