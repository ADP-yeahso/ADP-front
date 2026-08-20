import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/app_data.dart';
import '../../data/garden_range.dart';

import '../../utils/local_asset_server.dart';
import 'entry_detail_sheet.dart';
import '../mailbox/family_mailbox_screen.dart';

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
    await _webViewController.loadRequest(Uri.parse('http://localhost:8080/www/index.html?v=\${DateTime.now().millisecondsSinceEpoch}'));

    if (mounted) {
      setState(() {
        _isServerStarted = true;
      });
    }
  }

  @override
  void dispose() {
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
    
    final diariesJson = jsonEncode(diaries.map((e) => {'id': e.id, 'emotion': e.flowerType.emotionId.name}).toList());
    final ts = DateTime.now().millisecondsSinceEpoch;
    final treeUrl = 'http://localhost:8080/images/worldtree.glb?v=$ts';
    final flowerUrl = 'http://localhost:8080/images/flower2.glb?v=$ts';
    
    _webViewController.runJavaScript('''
      function tryInitGarden() {
        if (typeof window.initGarden === 'function') {
          window.initGarden('$treeUrl', '$flowerUrl', '$diariesJson');
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
      backgroundColor: const Color(0xFFE8F4F8),
      body: Stack(
        children: [
          // ── 3D Three.js 뷰어 (WebView - 전체 화면 배경) ──
          if (_isServerStarted)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isFocusing,
                child: WebViewWidget(controller: _webViewController),
              ),
            ),

          // ── Blur Overlay (포커싱 시 뒤쪽 배경 흐림 처리) ──
          if (_isFocusing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                ),
              ),
            ),

          // ── 상단 컨트롤 및 UI 레이어 ──
          SafeArea(
            child: Column(
              children: [
                _buildHeader(month),
                Expanded(
                  child: Stack(
                    children: [
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

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => showMemoryListSheet(context, memories),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
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
          ),
        ],
      ),
    );
  }

  Future<void> _handleFlowerTap(String diaryId) async {
    // 더미 데이터 클릭 시 무시 (아이디가 dummy로 시작)
    if (diaryId.startsWith('dummy')) return;

    final appData = context.read<AppData>();
    final diary = appData.diaryById(int.tryParse(diaryId) ?? -1);
    if (diary == null) return;

    setState(() {
      _isFocusing = true;
    });

    await showDiaryDetailSheet(context, diary);

    if (mounted) {
      setState(() {
        _isFocusing = false;
      });
      _webViewController.runJavaScript('if(typeof window.resetCamera === "function") window.resetCamera()');
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
      _webViewController.runJavaScript('if(typeof window.resetCamera === "function") window.resetCamera()');
    }
  }

  Widget _buildHeader(DateTime month) {
    final hasUnreadMail = context.watch<AppData>().hasUnreadMail;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '기억의 정원',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '우리의 소중한 시간',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              // 우측 상단 편지함 버튼
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyMailboxScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              hasUnreadMail
                                  ? Icons.mark_email_unread_outlined
                                  : Icons.mail_outline_rounded,
                              color: const Color(0xFF2C3E50),
                              size: 20,
                            ),
                            if (hasUnreadMail)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4D4F),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '편지함',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${month.year}년 ${month.month}월',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Color(0xFF9E9E9E)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
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
