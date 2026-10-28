import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

class LocalAssetServer {
  final String assetBase;
  final int port;
  HttpServer? _server;

  Future<void>? _starting;
  Future<void>? _stopping;
  bool _stopRequested = false;

  LocalAssetServer({this.assetBase = 'assets', this.port = 0});

  String get origin {
    final server = _server;

    if (server == null) {
      throw StateError('Asset server is not running.');
    }

    return 'http://localhost:${server.port}';
  }

  Future<void> start() {
    if (_stopRequested) {
      return Future<void>.error(
        StateError('Cannot restart a stopped asset server.'),
      );
    }

    if (_server != null) {
      return Future<void>.value();
    }

    return _starting ??= _start();
  }

  Future<void> _start() async {
    final handler = const Pipeline().addHandler(_handleRequest);

    final server = await io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      port,
    );

    if (_stopRequested) {
      await server.close(force: true);
      return;
    }

    _server = server;
    debugPrint('LocalAssetServer listening on $origin');
  }

  Future<void> stop() {
    _stopRequested = true;
    return _stopping ??= _stop();
  }

  Future<void> _stop() async {
    final starting = _starting;

    if (starting != null) {
      try {
        await starting;
      } catch (_) {
        // 시작에 실패했더라도 종료 처리는 마친다.
      }
    }

    final server = _server;
    _server = null;

    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<Response> _handleRequest(Request request) async {
    final path = request.url.path;
    if (path.isEmpty || path == '/') {
      return Response.notFound('Not found');
    }

    try {
      const diagnosticsEnabled = bool.fromEnvironment(
        'GARDEN_DIAGNOSTICS',
        defaultValue: false,
      );

      const catalogDelayMs = int.fromEnvironment(
        'GARDEN_CATALOG_DELAY_MS',
        defaultValue: 0,
      );

      if (diagnosticsEnabled &&
          path == 'www/flower_catalog.json' &&
          catalogDelayMs > 0) {
        debugPrint('GARDEN_CATALOG_DELAY: ${catalogDelayMs}ms');

        await Future<void>.delayed(
          Duration(milliseconds: catalogDelayMs),
        );
      }
      // e.g. path = 'www/index.html' -> assetPath = 'assets/www/index.html'
      final assetPath = '$assetBase/$path';
      final ByteData data = await rootBundle.load(assetPath);
      final buffer = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      String contentType = 'application/octet-stream';
      if (path.endsWith('.html')) contentType = 'text/html; charset=utf-8';
      else if (path.endsWith('.js')) contentType = 'application/javascript; charset=utf-8';
      else if (path.endsWith('.css')) contentType = 'text/css; charset=utf-8';
      else if (path.endsWith('.png')) contentType = 'image/png';
      else if (path.endsWith('.glb')) contentType = 'model/gltf-binary';
      else if (path.endsWith('.gltf')) contentType = 'model/gltf+json';

      final isModel =
        path.endsWith('.glb') || path.endsWith('.gltf');

      return Response.ok(buffer, headers: {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': isModel
          ? 'public, max-age=31536000, immutable'
          : 'no-cache',
      });
    } catch (e) {
      return Response.notFound('Asset not found: $path');
    }
  }
}
