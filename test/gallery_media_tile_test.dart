import 'dart:async';

import 'package:care_garden/models/media.dart';
import 'package:care_garden/screens/gallery/gallery_media_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>();
  final disposedPlayers = <int>[];
  int playCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;

  void initializeVideo() {
    events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 15),
        size: const Size(1080, 1920),
      ),
    );
  }

  @override
  Future<void> dispose(int playerId) async {
    disposedPlayers.add(playerId);
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> play(int playerId) async {
    playCalls++;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

Future<void> _openVideoDialog(WidgetTester tester) async {
  final date = DateTime(2026, 10, 24);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: GalleryMediaTile(
              item: Media(
                id: 1,
                memoryId: null,
                diaryId: null,
                fileUrl: '/test/gallery-video.mp4',
                fileType: 'video',
                duration: 15,
                sortOrder: 0,
                createdAt: date,
              ),
              resolvedDate: date,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(GalleryMediaTile));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late VideoPlayerPlatform originalPlatform;
  late _FakeVideoPlayerPlatform platform;

  setUp(() {
    originalPlatform = VideoPlayerPlatform.instance;
    platform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  tearDown(() async {
    await platform.events.close();
    VideoPlayerPlatform.instance = originalPlatform;
  });

  testWidgets('재생 중인 동영상 창을 닫아도 예외가 발생하지 않는다', (tester) async {
    await _openVideoDialog(tester);
    platform.initializeVideo();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pump();
    expect(platform.playCalls, 1);
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byType(Dialog, skipOffstage: false), findsNothing);
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(tester.takeException(), isNull);
    expect(platform.disposedPlayers, [1]);
  });

  testWidgets('초기화 중인 동영상 창을 닫아도 플레이어를 해제한다', (tester) async {
    await _openVideoDialog(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.pump();

    // A delayed platform event must not update the dismissed dialog.
    platform.initializeVideo();
    await tester.pump();

    expect(find.byType(Dialog, skipOffstage: false), findsNothing);
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(tester.takeException(), isNull);
    expect(platform.disposedPlayers, [1]);
  });
}
