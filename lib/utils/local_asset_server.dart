import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

class LocalAssetServer {
  final String assetBase;
  final int port;
  HttpServer? _server;

  LocalAssetServer({this.assetBase = 'assets', this.port = 8080});

  Future<void> start() async {
    final handler = const Pipeline().addHandler(_handleRequest);
    _server = await io.serve(handler, InternetAddress.loopbackIPv4, port);
    print('LocalAssetServer listening on http://localhost:\${_server!.port}');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<Response> _handleRequest(Request request) async {
    final path = request.url.path;
    if (path.isEmpty || path == '/') {
      return Response.notFound('Not found');
    }

    try {
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

      return Response.ok(buffer, headers: {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
      });
    } catch (e) {
      return Response.notFound('Asset not found: $path');
    }
  }
}
