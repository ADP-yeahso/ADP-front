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
import 'entry_detail_sheet.dart';

/// 기억의 정원 – Three.js + WebView 하이브리드 아키텍처
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

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
          if (msgId == 'tree') {
            _handleTreeTap();
          } else if (msgId.isNotEmpty) {
            _handleFlowerTap(msgId);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _reload3DScene();
          },
        ),
      );

    await _webViewController.clearCache();
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
    final appData = context.read<AppData>();
    final diaries = appData.diariesForMonth(_currentMonth);

    final diariesJson = jsonEncode(
      diaries
          .map((e) => {'id': e.id, 'emotion': e.flowerType.emotionId.name})
          .toList(),
    );
    final ts = DateTime.now().millisecondsSinceEpoch;
    final treeUrl = 'http://localhost:8080/images/worldtree.glb?v=$ts';

    final flowerBaseUrl = 'http://localhost:8080/images/flower';
    final placeholderFlowerUrl =
        '$flowerBaseUrl/flower.glb?v=$ts'; // 감사,중립 꽃 에셋 나오면 교체하고 삭제해도 됨

    final Map<String, List<String>> emotionToFlowers = {
      'anger': [
        '$flowerBaseUrl/Anger_Phlox.glb?v=$ts',
        '$flowerBaseUrl/Anger_Gerbera.glb?v=$ts',
        '$flowerBaseUrl/Anger_Linaria.glb?v=$ts',
        '$flowerBaseUrl/Anger_Zinnia.glb?v=$ts',
      ],
      'anxiety': [
        '$flowerBaseUrl/Anxiety_Borage.glb?v=$ts',
        '$flowerBaseUrl/Anxiety_Geranium.glb?v=$ts',
        '$flowerBaseUrl/Anxiety_Hellebore.glb?v=$ts',
        '$flowerBaseUrl/Anxiety_Stock.glb?v=$ts',
      ],
      'guilt': [
        '$flowerBaseUrl/Guilt_Canna.glb?v=$ts',
        '$flowerBaseUrl/Guilt_Clematis.glb?v=$ts',
        '$flowerBaseUrl/Guilt_Delphinium.glb?v=$ts',
      ],
      'sadness': [
        '$flowerBaseUrl/Sadness_ebw.glb?v=$ts',
        '$flowerBaseUrl/Sadness_mmc.glb?v=$ts',
        '$flowerBaseUrl/Sadness_ydc.glb?v=$ts',
      ],
      'affection': [
        '$flowerBaseUrl/Affection_Bindweed.glb?v=$ts',
        '$flowerBaseUrl/Affection_Lisianthus.glb?v=$ts',
        '$flowerBaseUrl/Affection_Marigold.glb?v=$ts',
        '$flowerBaseUrl/Affection_Nasturtium.glb?v=$ts',
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
    final memories = appData.memoriesForMonth(month);
    final diariesCount = appData.diariesForMonth(month).length;

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
                // ── 상단 헤더 ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(month),
                ),

                // ── 양옆 달 변경 화살표 ──
                if (!_isFocusing) ...[
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
    // 더미 데이터 클릭 시 무시 (아이디가 dummy로 시작)
    if (diaryId.startsWith('dummy')) {
      _webViewController.runJavaScript(
        'if(typeof window.resetCamera === "function") window.resetCamera()',
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
        'if(typeof window.resetCamera === "function") window.resetCamera()',
      );
    }
  }

  Future<void> _handleTreeTap() async {
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
