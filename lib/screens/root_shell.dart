import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/garden_nav_controller.dart';
import '../utils/garden_route_observers.dart';
import 'calendar/calendar_screen.dart';
import 'gallery/gallery_screen.dart';
import 'garden/garden_screen.dart';
import 'profile/profile_screen.dart';
import 'record/record_choice_sheet.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with RouteAware {
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> _rootRouteVisible = ValueNotifier<bool>(true);
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final RouteObserver<PageRoute<dynamic>> _gardenInnerRouteObserver =
      RouteObserver<PageRoute<dynamic>>();

  late final _SettingsRouteObserver _settingsRouteObserver =
      _SettingsRouteObserver((hide) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hideSettingsNav != hide) {
        setState(() => _hideSettingsNav = hide);
      }
    });
  });
  int _previousTabIndex = 0;
  bool _hideSettingsNav = false;
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
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (_index == index) return;

    setState(() {
      _previousTabIndex = _index;
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
      extendBody: true,
      body: Navigator(
        key: _navigatorKey,
        observers: [_gardenInnerRouteObserver, _settingsRouteObserver],
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => ValueListenableBuilder<int>(
            valueListenable: _tabIndex,
            builder: (context, index, child) => ValueListenableBuilder<bool>(
              valueListenable: _rootRouteVisible,
              builder: (context, routeVisible, child) => IndexedStack(
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
                  ProfileScreen(
                    onBack: () => _selectTab(_previousTabIndex),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _index == 3 && _hideSettingsNav
          ? null
          : _buildBottomBar(),
    );
  }

  // front-develop에 적용된 SVG 하단 바를 유지.
  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / 315;
            final barHeight = 68 * scale;
            final barTop = 32 * scale;
            final plusWidth = 64 * scale;
            final plusHeight = 66 * scale;
            final iconSize = 35 * scale;

            return SizedBox(
              width: constraints.maxWidth,
              height: barTop + barHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: barTop,
                    height: barHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(
                          child: SvgPicture.asset(
                            'assets/bottom_bar/bottom_bar_frame.svg',
                            fit: BoxFit.fill,
                            excludeFromSemantics: true,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildNavItem(
                                  index: 0,
                                  assetName: 'home',
                                  label: '홈',
                                  iconSize: iconSize,
                                ),
                              ),
                              Expanded(
                                child: _buildNavItem(
                                  index: 1,
                                  assetName: 'record',
                                  label: '기억 보기',
                                  iconSize: iconSize,
                                ),
                              ),
                              SizedBox(width: plusWidth),
                              Expanded(
                                child: _buildNavItem(
                                  index: 2,
                                  assetName: 'gallery',
                                  label: '갤러리',
                                  iconSize: iconSize,
                                ),
                              ),
                              Expanded(
                                child: _buildNavItem(
                                  index: 3,
                                  assetName: 'setting',
                                  label: '설정',
                                  iconSize: iconSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: (constraints.maxWidth - plusWidth) / 2,
                    width: plusWidth,
                    height: plusHeight,
                    child: Semantics(
                      button: true,
                      label: '기록하기',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openRecordChoice,
                        child: SvgPicture.asset(
                          'assets/bottom_bar/plus_button.svg',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String assetName,
    required String label,
    required double iconSize,
  }) {
    final isSelected = _index == index;
    final state = isSelected ? 'after' : 'before';

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(index),
        child: Center(
          child: SvgPicture.asset(
            'assets/bottom_bar/${assetName}_click_$state.svg',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _SettingsRouteObserver extends NavigatorObserver {
  _SettingsRouteObserver(this.onChange);

  final ValueChanged<bool> onChange;

  @override
  void didPush(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    onChange(!route.isFirst);
  }

  @override
  void didPop(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    onChange(
      previousRoute != null && !previousRoute.isFirst,
    );
  }
}