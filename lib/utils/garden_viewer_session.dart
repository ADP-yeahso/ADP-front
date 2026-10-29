import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'local_asset_server.dart';

class GardenViewerSession {
  GardenViewerSession({
    required this.diagnostics,
    required this.onChanged,
    required this.onEvent,
    this.catalogProcessDelayMs = 0,
  });

  final bool diagnostics;
  final int catalogProcessDelayMs;

  final void Function(GardenViewerSession session) onChanged;
  final void Function(
    GardenViewerSession session,
    Map<String, dynamic> event,
  ) onEvent;

  final LocalAssetServer _server = LocalAssetServer(
    assetBase: 'assets',
  );

  final Completer<void> _readySignal = Completer<void>();

  WebViewController? _controller;
  Future<void>? _starting;
  Future<void>? _closingFuture;

  String? _origin;
  String? _jsSessionId;

  bool _ready = false;
  bool _closing = false;
  bool _paused = false;
  int _documentVersion = 0;

  WebViewController? get controller => _controller;
  String? get origin => _origin;
  String? get jsSessionId => _jsSessionId;
  bool get isReady => _ready && !_closing;
  bool get isClosing => _closing;
  bool get isPaused => _paused;

  Future<void> start() {
    if (_closing) {
      return Future<void>.value();
    }

    return _starting ??= _start();
  }

  Future<void> _start() async {
    await _server.start();
    if (_closing) return;

    _origin = _server.origin;

    final controller = WebViewController();
    _controller = controller;

    await controller.setJavaScriptMode(
      JavaScriptMode.unrestricted,
    );
    if (_closing) return;

    await controller.setBackgroundColor(Colors.transparent);
    if (_closing) return;

    await controller.addJavaScriptChannel(
      'FlutterChannel',
      onMessageReceived: (message) {
        _handleMessage(message.message);
      },
    );
    if (_closing) return;

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) {
          if (_closing) return;

          _documentVersion++;
          _ready = false;
          _jsSessionId = null;
          onChanged(this);
        },
        onWebResourceError: (error) {
          if (!_closing && error.isForMainFrame == true) {
            _reportError('ERROR_PAGE', error.description);
          }
        },
      ),
    );
    if (_closing) return;

    // ready를 기다리는 동안에도 플랫폼 뷰를 표시할 수 있게 한다.
    onChanged(this);

    final query = <String, String>{
      'v': 'garden-session-v1',
      if (diagnostics) 'diagnostics': '1',
      if (diagnostics && catalogProcessDelayMs > 0)
        'catalogProcessDelayMs': '$catalogProcessDelayMs',
    };

    await controller.loadRequest(
      Uri.parse('$_origin/www/index.html').replace(
        queryParameters: query,
      ),
    );
    if (_closing) return;

    await _readySignal.future.timeout(
      const Duration(seconds: 15),
    );
  }

  void _handleMessage(String message) {
    if (_closing) return;

    if (message.startsWith('GARDEN_DIAGNOSTICS:')) {
      if (diagnostics) {
        debugPrint(message);
      }
      return;
    }

    const prefix = 'GARDEN_EVENT:';
    if (!message.startsWith(prefix)) return;

    try {
      final decoded = jsonDecode(message.substring(prefix.length));
      if (decoded is! Map) return;

      final event = Map<String, dynamic>.from(decoded);

      if (event['type'] == 'ready') {
        unawaited(_acceptReady(event));
        return;
      }

      if (!isReady || event['sessionId'] != _jsSessionId) {
        return;
      }

      if (_paused &&
          const ['flower', 'tree', 'openDiary', 'flowerBrowse']
              .contains(event['type'])) {
        return;
      }

      onEvent(this, event);
    } catch (error) {
      debugPrint('Invalid garden event: $error');
    }
  }

  Future<void> _acceptReady(Map<String, dynamic> event) async {
    final controller = _controller;
    final sessionId = event['sessionId'];
    final version = _documentVersion;

    if (_closing || controller == null || sessionId is! String) {
      return;
    }

    try {
      Object? status = await controller.runJavaScriptReturningResult(
        'JSON.stringify(window.getGardenViewerStatus?.() ?? null)',
      );

      if (status is String) status = jsonDecode(status);
      if (status is String) status = jsonDecode(status);

      if (_closing ||
          version != _documentVersion ||
          !identical(controller, _controller) ||
          status is! Map ||
          status['sessionId'] != sessionId ||
          status['destroyed'] == true) {
        return;
      }

      if (_ready && _jsSessionId == sessionId) {
        return;
      }

      _jsSessionId = sessionId;
      _ready = true;
      _paused = false;

      if (!_readySignal.isCompleted) {
        _readySignal.complete();
      }

      onChanged(this);
      onEvent(this, event);
    } catch (error) {
      if (!_closing && version == _documentVersion) {
        debugPrint('Garden ready check failed: $error');
      }
    }
  }

  Future<void> runScript(String script) async {
    final controller = _controller;
    final version = _documentVersion;

    if (!isReady || _paused || controller == null) {
      return;
    }

    try {
      final expectedSessionId = _jsSessionId;

      await controller.runJavaScript('''
        if (
          window.getGardenViewerStatus?.()?.sessionId ===
          ${jsonEncode(expectedSessionId)}
        ) {
          $script
        }
      ''');
    } catch (error) {
      if (!_closing && version == _documentVersion) {
        _reportError('ERROR_JS', error);
      }
    }
  }

  Future<void> pause() async {
    if (_closing || _paused) return;

    _paused = true;

    if (!isReady) {
      await close();
      return;
    }

    try {
      await _controller!.runJavaScript(
        'window.pauseGarden();',
      ).timeout(const Duration(seconds: 2));
    } catch (error) {
      debugPrint('Garden pause failed: $error');
      await close();
    }
  }

  Future<bool> resume() async {
    final controller = _controller;
    final version = _documentVersion;

    if (!isReady || controller == null) return false;

    try {
      final result = await controller.runJavaScriptReturningResult(
        'window.resumeGarden(false)',
      ).timeout(const Duration(seconds: 2));

      if (_closing || version != _documentVersion) {
        return false;
      }

      final resumed = result == true || result.toString() == 'true';
      if (resumed) {
        _paused = false;
      }

      return resumed;
    } catch (error) {
      debugPrint('Garden resume failed: $error');
      return false;
    }
  }

  Future<void> close() {
    if (_closingFuture != null) return _closingFuture!;

    _closing = true;
    _ready = false;
    _paused = true;

    if (!_readySignal.isCompleted) {
      _readySignal.complete();
    }

    return _closingFuture = _close();
  }

  Future<void> _close() async {
    final starting = _starting;
    if (starting != null) {
      await _cleanupStep(() => starting);
    }

    final controller = _controller;

    if (controller != null) {
      // JS 종료 응답을 제한 시간 동안 기다린다.
      await _cleanupStep(() async {
        await controller.runJavaScriptReturningResult('''
          typeof window.destroyGardenViewer === 'function'
            ? window.destroyGardenViewer()
            : false
        ''');
      });

      _controller = null;
      _origin = null;
      onChanged(this);

      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );

      // 시작 중이던 문서·모듈 요청도 이전 페이지와 함께 종료한다.
      await _cleanupStep(() => controller.loadHtmlString(
        '<!doctype html><html><body></body></html>',
      ));

      await _cleanupStep(
        () => controller.removeJavaScriptChannel('FlutterChannel'),
      );

      await _cleanupStep(
        () => controller.setNavigationDelegate(NavigationDelegate()),
      );
    }

    try {
      await _server.stop();
    } catch (error) {
      debugPrint('Garden server stop failed: $error');
    }

    _origin = null;
    _jsSessionId = null;
  }

  Future<void> _cleanupStep(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 2));
    } catch (error) {
      debugPrint('Garden cleanup: $error');
    }
  }

  void _reportError(String code, Object error) {
    if (_closing) return;

    onEvent(this, {
      'type': 'error',
      'code': code,
      'message': '정원을 불러오지 못했어요.',
      'detail': error.toString(),
    });
  }
}