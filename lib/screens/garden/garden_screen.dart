import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/app_data.dart';
import '../../data/garden_range.dart';

import '../../utils/local_asset_server.dart';
import '../care_notebook/care_notebook_list_screen.dart';
import '../family/family_share_screen.dart';
import 'entry_detail_sheet.dart';
import 'garden_home_header.dart';

/// 기억의 정원 – Three.js + WebView 하이브리드 아키텍처
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key, this.assetPreview = false});

  final bool assetPreview;

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final DateTime _anchor = gardenAnchorMonth();
  int _pageIndex = gardenMonthsBack;

  late final WebViewController _webViewController;
  late final LocalAssetServer _localhostServer;

  bool _isFocusing = false;
  bool _isServerStarted = false;
  bool _isFlowerBrowsing = false;
  int _flowerIndex = 0;
  int _flowerCount = 0;
  // Read state lasts for this home session until a persistent inbox is added.
  final Set<String> _openedSharedRecordIds = {};

  DateTime get _currentMonth => gardenMonthAt(_anchor, _pageIndex);

  @override
  void initState() {
    super.initState();
    _localhostServer = LocalAssetServer(assetBase: 'assets');
    _initWebViewAndServer();
  }

  Future<void> _initWebViewAndServer() async {
    await _localhostServer.start();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final msgId = message.message;
          if (kDebugMode) {
            print('JS Message: $msgId');
          }
          _handleGardenMessage(msgId);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _reload3DScene();
          },
        ),
      );

    await _webViewController.loadRequest(
      Uri.parse(
        'http://localhost:8080/www/index.html?v=\${DateTime.now().millisecondsSinceEpoch}',
      ),
    );

    if (mounted) {
      setState(() {
        _isServerStarted = true;
      });
    }
  }

  void _handleGardenMessage(String message) {
    if (!mounted || message.startsWith('ERROR_')) return;
    if (message.startsWith('{')) {
      final event = jsonDecode(message) as Map<String, dynamic>;
      switch (event['type']) {
        case 'flowerBrowse':
          setState(() {
            _isFlowerBrowsing = true;
            _flowerIndex = event['index'] as int;
            _flowerCount = event['count'] as int;
          });
          return;
        case 'gardenOverview':
          setState(() {
            _isFlowerBrowsing = false;
            _flowerIndex = 0;
            _flowerCount = 0;
          });
          return;
        case 'openDiary':
          _handleFlowerTap(event['diaryId'] as String);
          return;
        default:
          return;
      }
    }
    if (message == 'tree') {
      _handleTreeTap();
    } else if (message.isNotEmpty) {
      _handleFlowerTap(message);
    }
  }

  void _previousGardenItem() {
    if (_isFlowerBrowsing) {
      _webViewController.runJavaScript('window.browseFlower?.(-1)');
    } else {
      _prevMonth();
    }
  }

  void _nextGardenItem() {
    if (_isFlowerBrowsing) {
      _webViewController.runJavaScript('window.browseFlower?.(1)');
    } else {
      _nextMonth();
    }
  }

  @override
  void dispose() {
    _webViewController.runJavaScript(
      'if (typeof window.disposeGarden === "function") window.disposeGarden();',
    );
    _localhostServer.stop();
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

  /// 달이 변경될 때마다 3D Scene의 데이터를 다시 주입
  void _reload3DScene() {
    if (widget.assetPreview) {
      _webViewController.runJavaScript('''
        function tryPreviewGarden() {
          if (typeof window.previewGarden === 'function') {
            window.previewGarden();
          } else {
            setTimeout(tryPreviewGarden, 100);
          }
        }
        tryPreviewGarden();
      ''');
      return;
    }
    final appData = context.read<AppData>();
    final diaries = appData.diariesForMonth(_currentMonth);

    final diariesJson = jsonEncode(
      diaries
          .map((e) => {'id': e.id, 'emotion': e.flowerType.emotionId.name})
          .toList(),
    );
    const assetVersion = 'flower-mapping-v1';
    final treeUrl =
        'http://localhost:8080/images/worldtree.glb?v=$assetVersion';

    final flowerBaseUrl = 'http://localhost:8080/images/flower';
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
    final flowerUrlsMapJson = jsonEncode(emotionToFlowers);

    _webViewController.runJavaScript('''
      function tryInitGarden() {
        if (typeof window.initGarden === 'function') {
          if (typeof window.disposeGarden === 'function') window.disposeGarden();
          window.initGarden('$treeUrl', '$flowerUrlsMapJson', '$diariesJson');
        } else {
          setTimeout(tryInitGarden, 100);
        }
      }
      tryInitGarden();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final appData = context.watch<AppData>();
    final month = _currentMonth;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. 가장 밑바탕: 3D Three.js 뷰어 (WebView) 전체 화면 ──
          if (_isServerStarted)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isFocusing,
                child: WebViewWidget(controller: _webViewController),
              ),
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
                    child: GardenHomeHeader(
                      month: month,
                      showTitleAndActions: !_isFlowerBrowsing,
                      groupName: appData.group.groupName,
                      hasUnreadRecords: _sharedRecordIds(
                        appData,
                      ).difference(_openedSharedRecordIds).isNotEmpty,
                      onOpenMailbox: _openMailbox,
                      onOpenNotebook: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CareNotebookListScreen(),
                        ),
                      ),
                    ),
                  ),

                if (_isServerStarted && !_isFocusing)
                  Positioned(
                    right: 16,
                    bottom: 72,
                    child: Tooltip(
                      message: _isFlowerBrowsing
                          ? '전체 정원으로 돌아가기'
                          : '기본 구도로 돌아가기',
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A6B8A),
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => _webViewController.runJavaScript(
                          'if(typeof window.resetCamera === "function") window.resetCamera()',
                        ),
                        icon: const Icon(Icons.center_focus_strong, size: 18),
                        label: Text(_isFlowerBrowsing ? '정원으로' : '기본 구도'),
                      ),
                    ),
                  ),

                // 꽃 감상 중에는 같은 달의 꽃을, 전체 정원에서는 달을 이동.
                if (!_isFocusing && !widget.assetPreview) ...[
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _SideMonthButton(
                        assetPath: 'assets/garden/home/month_previous.svg',
                        tooltip: _isFlowerBrowsing ? '이전 꽃' : '이전 달',
                        onTap:
                            (_isFlowerBrowsing
                                ? _flowerCount > 1
                                : _pageIndex > 0)
                            ? _previousGardenItem
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _SideMonthButton(
                        assetPath: 'assets/garden/home/month_next.svg',
                        tooltip: _isFlowerBrowsing ? '다음 꽃' : '다음 달',
                        onTap:
                            (_isFlowerBrowsing
                                ? _flowerCount > 1
                                : _pageIndex < gardenTotalPages - 1)
                            ? _nextGardenItem
                            : null,
                      ),
                    ),
                  ),
                ],
                if (_isFlowerBrowsing && !_isFocusing && !widget.assetPreview)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 20,
                    child: IgnorePointer(
                      child: Text(
                        '${_flowerIndex + 1} / $_flowerCount · 꽃을 다시 누르면 일기를 볼 수 있어요',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF386622),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFlowerTap(String diaryId) async {
    if (_isFocusing) return;
    // 더미 데이터 클릭 시 무시 (아이디가 dummy로 시작)
    if (diaryId.startsWith('dummy')) {
      _webViewController.runJavaScript(
        _isFlowerBrowsing
            ? 'window.resumeFlowerBrowse?.()'
            : 'window.resetCamera?.()',
      );
      return;
    }

    final appData = context.read<AppData>();
    final diary = appData.diaryById(int.tryParse(diaryId) ?? -1);
    if (diary == null) {
      _webViewController.runJavaScript(
        'if(typeof window.resetCamera === "function") window.resetCamera()',
      );
      return;
    }

    setState(() {
      _isFocusing = true;
    });

    await showDiaryDetailSheet(context, diary);

    if (mounted) {
      setState(() {
        _isFocusing = false;
      });
      _webViewController.runJavaScript(
        _isFlowerBrowsing
            ? 'window.resumeFlowerBrowse?.()'
            : 'window.resetCamera?.()',
      );
    }
  }

  Future<void> _handleTreeTap() async {
    if (_isFocusing) return;
    final appData = context.read<AppData>();
    final memories = appData.memoriesForMonth(_currentMonth);

    setState(() {
      _isFocusing = true;
    });

    await showMemoryListSheet(context, memories);

    if (mounted) {
      setState(() {
        _isFocusing = false;
      });
      // 나무에서 멀어질 경우 리셋 카메라(선택적)
      _webViewController.runJavaScript(
        'if(typeof window.resetCamera === "function") window.resetCamera()',
      );
    }
  }

  Set<String> _sharedRecordIds(AppData appData) => {
    for (final memory in appData.sharedMemories)
      if (!appData.isCurrentUser(memory.userId))
        'memory:${memory.id}:${memory.updatedAt.microsecondsSinceEpoch}',
    for (final diary in appData.sharedDiaries)
      if (!appData.isCurrentUser(diary.userId))
        'diary:${diary.id}:${diary.updatedAt.microsecondsSinceEpoch}',
  };

  void _openMailbox() {
    final records = _sharedRecordIds(context.read<AppData>());
    setState(() => _openedSharedRecordIds.addAll(records));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyShareScreen()),
    );
  }
}

class _SideMonthButton extends StatelessWidget {
  final String assetPath;
  final String tooltip;
  final VoidCallback? onTap;
  const _SideMonthButton({
    required this.assetPath,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: SvgPicture.asset(
          assetPath,
          width: 14,
          height: 25,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
