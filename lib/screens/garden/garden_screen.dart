import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/app_data.dart';
import '../../data/garden_range.dart';

import 'dart:async';
import '../../utils/garden_viewer_session.dart';
import '../care_notebook/care_notebook_list_screen.dart';
import 'entry_detail_sheet.dart';
import '../calendar/calendar_screen.dart';


class GardenScreen extends StatefulWidget {
  const GardenScreen({
    super.key,
    this.assetPreview = false,
    this.isActive = true,
    this.isRouteVisible = true,
    this.routeObserver,
  });

  final bool assetPreview;
  final bool isActive;
  final bool isRouteVisible;
  final RouteObserver<PageRoute<dynamic>>? routeObserver;

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with WidgetsBindingObserver, RouteAware {
  final DateTime _anchor = gardenAnchorMonth();
  int _pageIndex = gardenMonthsBack;

  static const bool _gardenDiagnosticsEnabled = bool.fromEnvironment(
    'GARDEN_DIAGNOSTICS',
    defaultValue: false,
  );

  static const String _gardenScenario = String.fromEnvironment(
    'GARDEN_SCENARIO',
    defaultValue: 'real',
  );

  static const int _catalogProcessDelayMs = int.fromEnvironment(
    'GARDEN_CATALOG_PROCESS_DELAY_MS',
    defaultValue: 0,
  );

  GardenViewerSession? _session;
  Future<void> _transition = Future<void>.value();
  Timer? _idleReleaseTimer;
  PageRoute<dynamic>? _observedRoute;

  bool _isFocusing = false;
  bool _disposed = false;
  bool _appForeground = true;
  bool _innerRouteVisible = true;
  bool _releaseRequested = false;
  bool _retryRequired = false;
  String? _viewerError;

  DateTime get _currentMonth => gardenMonthAt(_anchor, _pageIndex);

  bool get _shouldRun =>
      mounted &&
      !_disposed &&
      widget.isActive &&
      widget.isRouteVisible &&
      _innerRouteVisible &&
      _appForeground &&
      !_retryRequired;

  bool _ownsSession(GardenViewerSession session) =>
      mounted && !_disposed && identical(session, _session);

  @override
  void initState() {
    super.initState();

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;

    WidgetsBinding.instance.addObserver(this);
    _syncAvailability();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeRoute();
  }

  void _subscribeRoute() {
    final observer = widget.routeObserver;
    final route = ModalRoute.of(context);

    if (observer == null ||
        route is! PageRoute<dynamic> ||
        identical(route, _observedRoute)) {
      return;
    }

    observer.unsubscribe(this);
    _observedRoute = route;
    observer.subscribe(this, route);
  }

  @override
  void didUpdateWidget(covariant GardenScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.routeObserver, widget.routeObserver)) {
      oldWidget.routeObserver?.unsubscribe(this);
      _observedRoute = null;
      _subscribeRoute();
    }

    if (oldWidget.isActive != widget.isActive ||
        oldWidget.isRouteVisible != widget.isRouteVisible) {
      _syncAvailability();
    }
  }

  @override
  void didPushNext() {
    _innerRouteVisible = false;
    _syncAvailability();
  }

  @override
  void didPopNext() {
    _innerRouteVisible = true;
    _syncAvailability();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appForeground = state == AppLifecycleState.resumed;
    _syncAvailability();
  }

  @override
  void didHaveMemoryPressure() {
    if (_disposed) return;

    _retryRequired = true;
    _viewerError = '메모리 확보를 위해 정원을 닫았어요.';
    _syncAvailability();

    if (mounted) {
      setState(() {});
    }
  }

  void _syncAvailability() {
    if (_disposed || !mounted) return;

    final current = _session;

    if (_shouldRun) {
      _idleReleaseTimer?.cancel();
      _idleReleaseTimer = null;
      _releaseRequested = false;
    } else if (!widget.isActive || _retryRequired) {
      _idleReleaseTimer?.cancel();
      _idleReleaseTimer = null;
      _releaseRequested = true;

      if (current != null) {
        unawaited(current.close());
      }
    } else {
      if (current != null) {
        if (!current.isReady) {
          _releaseRequested = true;
          unawaited(current.close());
        } else {
          unawaited(current.pause());
        }
      }

      _idleReleaseTimer ??= Timer(const Duration(seconds: 5), () {
        _idleReleaseTimer = null;

        if (!_shouldRun) {
          _releaseRequested = true;

          final session = _session;
          if (session != null) {
            unawaited(session.close());
          }

          _queueReconcile();
        }
      });
    }

    _queueReconcile();
  }

  void _queueReconcile() {
    if (_disposed) return;

    _transition = _transition.then((_) => _reconcileViewer()).catchError(
      (Object error, StackTrace stackTrace) {
        debugPrint('Garden lifecycle failed: $error');

        if (_disposed || !mounted) return;

        _retryRequired = true;
        _releaseRequested = true;
        _viewerError = '정원을 다시 불러와 주세요.';

        final current = _session;
        if (current != null) {
          unawaited(current.close());
        }

        setState(() {});
      },
    );
  }

  Future<void> _reconcileViewer() async {
    if (_disposed) return;

    var current = _session;

    if (!_shouldRun) {
      if (current != null) {
        if (_releaseRequested || current.isClosing || !current.isReady) {
          await _dropSession(current);
        } else {
          await current.pause();
        }
      }
      return;
    }

    if (current != null && current.isClosing) {
      await _dropSession(current);
      current = null;
    }

    if (!_shouldRun) return;

    if (current == null) {
      final candidate = GardenViewerSession(
        diagnostics: _gardenDiagnosticsEnabled,
        catalogProcessDelayMs: _catalogProcessDelayMs,
        onChanged: _onSessionChanged,
        onEvent: _onSessionEvent,
      );

      _session = candidate;
      _viewerError = null;
      setState(() {});

      try {
        await candidate.start();
      } catch (error) {
        debugPrint('Garden startup failed: $error');

        if (_ownsSession(candidate) && _shouldRun) {
          _retryRequired = true;
          _viewerError = '정원을 불러오지 못했어요.';
        }

        await _dropSession(candidate);
        return;
      }

      if (candidate.isClosing || !_shouldRun) {
        await _dropSession(candidate);

        if (_shouldRun) {
          _queueReconcile();
        }
      }

      return;
    }

    if (!current.isReady || !current.isPaused) return;

    final resumed = await current.resume();

    if (!_ownsSession(current) || !_shouldRun) return;

    if (!resumed) {
      await _dropSession(current);

      if (_shouldRun) {
        _queueReconcile();
      }
      return;
    }

    _reload3DScene();
  }

  Future<void> _dropSession(GardenViewerSession session) async {
    try {
      await session.close();
    } finally {
      if (identical(session, _session)) {
        _session = null;
        _isFocusing = false;

        if (!_disposed && mounted) {
          setState(() {});
        }
      }
    }
  }

  void _onSessionChanged(GardenViewerSession session) {
    if (!_ownsSession(session)) return;

    if (!_shouldRun && !session.isClosing) {
      unawaited(session.pause());
    }

    setState(() {});
  }

  void _onSessionEvent(
    GardenViewerSession session,
    Map<String, dynamic> event,
  ) {
    if (!_ownsSession(session) || session.isClosing) return;

    switch (event['type']) {
      case 'ready':
        if (_shouldRun) {
          setState(() => _isFocusing = false);
          _reload3DScene();
        }

      case 'flower':
        final diaryId = event['diaryId'];
        if (_shouldRun && !_isFocusing && diaryId is String) {
          unawaited(_handleFlowerTap(diaryId));
        }

      case 'tree':
        if (_shouldRun && !_isFocusing) {
          unawaited(_handleTreeTap());
        }

      case 'error':
        debugPrint('GARDEN_ERROR: ${event['code']} ${event['detail']}');

        if (const [
          'ERROR_PAGE',
          'ERROR_JS',
          'ERROR_RENDER',
        ].contains(event['code'])) {
          _retryRequired = true;
          _viewerError = event['message']?.toString();
          _syncAvailability();
          setState(() {});
        }

      case 'destroyed':
        _retryRequired = true;
        _viewerError = '정원이 종료됐어요. 다시 불러와 주세요.';
        _syncAvailability();
        setState(() {});
    }
  }

  void _retryViewer() {
    if (_disposed || !mounted) return;

    _retryRequired = false;
    _viewerError = null;
    _isFocusing = false;

    final current = _session;
    if (current != null) {
      unawaited(current.close());
    }

    _syncAvailability();
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    _idleReleaseTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    widget.routeObserver?.unsubscribe(this);

    final current = _session;
    _session = null;

    if (current != null) {
      unawaited(current.close());
    }

    super.dispose();
  }

  void _prevMonth() => setState(() {
    if (_pageIndex > 0) {
      _pageIndex--;
      _reload3DScene();
    }
  });

  void _nextMonth() => setState(() {
    if (_pageIndex < gardenTotalPages - 1) {
      _pageIndex++;
      _reload3DScene();
    }
  });

  // (메모리 01-B)테스트 진단 데이터 생성 함수
  List<Map<String, Object>> _buildDiagnosticDiaries(String scenario) {
    switch (scenario) {
      case 'zero':
        return const [];

      case 'mixed-30':
        return _buildMixedDiagnosticDiaries(30);

      case 'mixed-60':
        return _buildMixedDiagnosticDiaries(60);

      case 'heavy-60':
        // affection 배열의 2번 인덱스:
        // Affection_Marigold.glb를 반복 선택하도록 ID를 구성
        return List.generate(
          60,
          (index) => {'id': index * 4 + 2, 'emotion': 'affection'},
        );
      case 'fail-tree':
        return _buildMixedDiagnosticDiaries(30);

      case 'fail-flower':
      case 'corrupt-flower':
        // 첫 번째 꽃은 성공시키고 두 번째 꽃에서 실패시켜
        // 부분 성공 자원 해제를 확인한다.
        return const [
          {'id': 0, 'emotion': 'anger'},
          {'id': 1, 'emotion': 'diagnostic-failure'},
        ];

      case 'invalid-emotion':
        return const [
          {'id': 1, 'emotion': ''},
          {'id': 2, 'emotion': 'not-mapped'},
        ];
      case 'month-switch':
        return _buildMixedDiagnosticDiaries(
          _pageIndex.isEven ? 30 : 60,
        );
      default:
        throw StateError('Unknown garden diagnostic scenario: $scenario');
    }
  }

  List<Map<String, Object>> _buildMixedDiagnosticDiaries(int count) {
    const emotions = [
      'anger',
      'anxiety',
      'guilt',
      'sadness',
      'affection',
      'gratitude',
      'neutral',
    ];

    const variantCounts = {
      'anger': 4,
      'anxiety': 4,
      'guilt': 3,
      'sadness': 3,
      'affection': 4,
      'gratitude': 1,
      'neutral': 1,
    };

    final occurrences = <String, int>{};

    return List.generate(count, (index) {
      final emotion = emotions[index % emotions.length];
      final occurrence = occurrences[emotion] ?? 0;
      occurrences[emotion] = occurrence + 1;

      final variantIndex = occurrence % variantCounts[emotion]!;

      // 12는 3과 4의 공배수이므로 현재 URL 선택식
      // diary.id % urls.length에서 원하는 variantIndex가 나옴
      final id = (index + 1) * 12 + variantIndex;

      return {'id': id, 'emotion': emotion};
    });
  }

  /// 달이 변경될 때마다 3D Scene의 데이터를 다시 주입
  void _reload3DScene() {
    final session = _session;
    final origin = session?.origin;

    if (!_shouldRun ||
        session == null ||
        !session.isReady ||
        origin == null) {
      return;
    }

    if (widget.assetPreview) {
      unawaited(session.runScript('window.previewGarden();'));
      return;
    }

    final appData = context.read<AppData>();
    final diaries = appData.diariesForMonth(_currentMonth);

    final realDiaryPayload = diaries
        .map(
          (diary) => <String, Object>{
            'id': diary.id,
            'emotion': diary.flowerType.emotionId.name,
          },
        )
        .toList();

    final diaryPayload = _gardenDiagnosticsEnabled && _gardenScenario != 'real'
        ? _buildDiagnosticDiaries(_gardenScenario)
        : realDiaryPayload;

    final diariesJson = jsonEncode(diaryPayload);

    if (_gardenDiagnosticsEnabled &&
        _gardenScenario == 'month-switch') {
      debugPrint(
        'GARDEN_EXPECTED: page=$_pageIndex, '
        'diaryCount=${diaryPayload.length}',
      );
    }

    const assetVersion = 'flower-mapping-v1';
    final treeUrl =
        _gardenDiagnosticsEnabled && _gardenScenario == 'fail-tree'
            ? '$origin/images/__missing_tree__.glb'
                '?v=$assetVersion'
            : '$origin/images/worldtree.glb'
                '?v=$assetVersion';

    final flowerBaseUrl = '$origin/images/flower';
    final placeholderFlowerUrl =
        '$flowerBaseUrl/flower.glb?v=$assetVersion'; // 감사,중립 꽃 에셋 나오면 교체하고 삭제해도 됨

    final Map<String, List<String>> emotionToFlowers = {
      'anger': [
        '$flowerBaseUrl/Anger_Phlox.glb?v=$assetVersion',
        '$flowerBaseUrl/Anger_Gerbera.glb?v=$assetVersion',
        '$flowerBaseUrl/Anger_Linaria.glb?v=$assetVersion',
        '$flowerBaseUrl/Anger_Zinnia.glb?v=$assetVersion',
      ],
      'anxiety': [
        '$flowerBaseUrl/Anxiety_Borage.glb?v=$assetVersion',
        '$flowerBaseUrl/Anxiety_Geranium.glb?v=$assetVersion',
        '$flowerBaseUrl/Anxiety_Hellebore.glb?v=$assetVersion',
        '$flowerBaseUrl/Anxiety_Stock.glb?v=$assetVersion',
      ],
      'guilt': [
        '$flowerBaseUrl/Guilt_Canna.glb?v=$assetVersion',
        '$flowerBaseUrl/Guilt_Clematis.glb?v=$assetVersion',
        '$flowerBaseUrl/Guilt_Delphinium.glb?v=$assetVersion',
      ],
      'sadness': [
        '$flowerBaseUrl/Sadness_ebw.glb?v=$assetVersion',
        '$flowerBaseUrl/Sadness_mmc.glb?v=$assetVersion',
        '$flowerBaseUrl/Sadness_ydc.glb?v=$assetVersion',
      ],
      'affection': [
        '$flowerBaseUrl/Affection_Bindweed.glb?v=$assetVersion',
        '$flowerBaseUrl/Affection_Lisianthus.glb?v=$assetVersion',
        '$flowerBaseUrl/Affection_Marigold.glb?v=$assetVersion',
        '$flowerBaseUrl/Affection_Nasturtium.glb?v=$assetVersion',
      ],

      'gratitude': [placeholderFlowerUrl], // 임시임 감사 꽃 에셋 나오면 교체해야함
      'neutral': [placeholderFlowerUrl], // 임시임 중립 꽃 에셋 나오면 교체해야함
    };
    if (_gardenDiagnosticsEnabled &&
        (_gardenScenario == 'fail-flower' ||
            _gardenScenario == 'corrupt-flower')) {
      emotionToFlowers['diagnostic-failure'] = [
        _gardenScenario == 'fail-flower'
            ? '$flowerBaseUrl/__missing_flower__.glb'
                '?v=$assetVersion'
            : '$origin/www/index.html'
                '?v=$assetVersion',
      ];
    }
    final flowerUrlsMapJson = jsonEncode(emotionToFlowers);
    unawaited(session.runScript(
      'window.initGarden('
      '${jsonEncode(treeUrl)},'
      '${jsonEncode(flowerUrlsMapJson)},'
      '${jsonEncode(diariesJson)}'
      ');',
    ));
  }

  Future<void> _runGardenDiagnosticAction(String action) async {
    if (!_gardenDiagnosticsEnabled || !mounted) {
      return;
    }

    if (action == 'reload') {
      _retryViewer();
      return;
    }

    final controller = _session?.controller;

    if (controller == null || _session?.isReady != true) {
      return;
    }

    try {
      const expressions = <String, String>{
        'status': 'true',
        'pause': '(window.pauseGarden(), true)',
        'resume': 'window.resumeGarden()',
        'destroy': 'window.destroyGardenViewer()',
        'cancel':
            '(window.cancelGardenLoadForDiagnostics()'
            '.catch(error => console.error(error)), true)',
        'context-loss': 'window.loseGardenContextForDiagnostics()',
      };

      final expression = expressions[action];
      if (expression == null) {
        return;
      }

      final result = await controller.runJavaScriptReturningResult('''
        JSON.stringify({
          result: $expression,
          status: window.getGardenViewerStatus()
        })
      ''');

      if (!mounted || !identical(controller, _session?.controller)) {
        return;
      }

      debugPrint('GARDEN_STATUS[$action]: $result');
    } catch (error) {
      debugPrint('GARDEN_DIAGNOSTIC_ERROR[$action]: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final month = _currentMonth;
    final memories = appData.memoriesForMonth(month);
    final diariesCount = appData.diariesForMonth(month).length;
    final controller = _session?.controller;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. 가장 밑바탕: 3D Three.js 뷰어 (WebView) 전체 화면 ──
          if (controller != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isFocusing || _session?.isClosing == true,
                child: WebViewWidget(
                  key: ValueKey(_session),
                  controller: controller,
                ),
              ),
            )
          else if (_retryRequired)
            Positioned.fill(
              child: Center(
                child: TextButton(
                  onPressed: _retryViewer,
                  child: Text(
                    '${_viewerError ?? '정원을 불러오지 못했어요.'}\n다시 시도',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (_shouldRun)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),

          // ── 2. 포커싱 시 배경 흐림 효과 (WebView 위를 덮음) ──
          if (_isFocusing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),

          // ── 3. UI 요소들 (SafeArea 안에서 겹침 배치) ──
          SafeArea(
            child: Stack(
              children: [
                if (_gardenDiagnosticsEnabled &&
                    (_gardenScenario == 'month-switch' || widget.assetPreview))
                  Positioned(
                    top: 100,
                    right: 16,
                    child: PopupMenuButton<String>(
                      onSelected: _runGardenDiagnosticAction,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'status',
                          child: Text('상태 확인'),
                        ),
                        PopupMenuItem(
                          value: 'pause',
                          child: Text('일시 중단'),
                        ),
                        PopupMenuItem(
                          value: 'resume',
                          child: Text('재개'),
                        ),
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text('로딩 취소'),
                        ),
                        PopupMenuItem(
                          value: 'destroy',
                          child: Text('전체 종료'),
                        ),
                        PopupMenuItem(
                          value: 'reload',
                          child: Text('뷰어 재생성'),
                        ),
                        PopupMenuItem(
                          value: 'context-loss',
                          child: Text('그래픽 손실 주입'),
                        ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('정원 진단'),
                      ),
                    ),
                  ),
                if (widget.assetPreview)
                  const Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      '꽃 에셋 22종 · 각 한 송이\n꽃을 탭하면 파일 정보와 확대 보기',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF4A6B8A)),
                    ),
                  ),
                // ── 상단 헤더 ──
                if (!widget.assetPreview)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildHeader(month),
                  ),

                // ── 양옆 달 변경 화살표 ──
                if (!_isFocusing && !widget.assetPreview) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _SideMonthButton(
                        icon: Icons.chevron_left,
                        onTap: _prevMonth,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _SideMonthButton(
                        icon: Icons.chevron_right,
                        onTap: _nextMonth,
                      ),
                    ),
                  ),

                  // ── 하단 기억/꽃 개수 안내 버튼 ──
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => showMemoryListSheet(context, memories),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            '🌳 잎 ${memories.length}개 / 🌸 꽃 $diariesCount송이',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

Future<void> _handleFlowerTap(String diaryId) async {
  final session = _session;
  final documentId = session?.jsSessionId;

  if (!_shouldRun ||
      session == null ||
      !session.isReady ||
      _isFocusing) {
    return;
  }

  final appData = context.read<AppData>();
  final diary = diaryId.startsWith('dummy')
      ? null
      : appData.diaryById(int.tryParse(diaryId) ?? -1);

  if (diary == null) {
    unawaited(session.runScript('window.resetCamera();'));
    return;
  }

  setState(() => _isFocusing = true);

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.94,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: CalendarScreen(
              initialDay: diary.recordDate,
              initialDiary: diary,
            ),
          ),
        );
      },
    );
  } finally {
    if (_ownsSession(session) &&
        _shouldRun &&
        session.jsSessionId == documentId) {
      setState(() => _isFocusing = false);
      unawaited(session.runScript('window.resetCamera();'));
    }
  }
}

  Future<void> _handleTreeTap() async {
    final session = _session;
    final documentId = session?.jsSessionId;

    if (!_shouldRun || session == null || !session.isReady || _isFocusing) {
      return;
    }

    final appData = context.read<AppData>();
    final memories = appData.memoriesForMonth(_currentMonth);

    setState(() => _isFocusing = true);

    try {
      await showMemoryListSheet(context, memories);
    } finally {
      if (_ownsSession(session) &&
          _shouldRun &&
          session.jsSessionId == documentId) {
        setState(() => _isFocusing = false);
        unawaited(session.runScript('window.resetCamera();'));
      }
    }
  }

  Widget _buildHeader(DateTime month) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 날짜 (예: 07 . 26)
              Text(
                '${month.month.toString().padLeft(2, '0')} . ${month.year.toString().substring(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A6B8A), // 스케치의 파란 펜 느낌 색상
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              // 그룹 선택 (더미)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '우리가족',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A6B8A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4A6B8A),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 12,
                      color: Color(0xFF4A6B8A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/spiral_notebook.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF4A6B8A),
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CareNotebookListScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SideMonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SideMonthButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 28, color: const Color(0xFF333333)),
      ),
    );
  }
}
