import 'dart:async';

import 'package:care_garden/screens/record/patient_info_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestFilePicker extends FilePicker {
  final requests = <FileType>[];
  List<String>? extensions;
  bool? multiple;
  late Completer<FilePickerResult?> pending;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) {
    if (requests.isEmpty) pending = Completer<FilePickerResult?>();
    requests.add(type);
    extensions = allowedExtensions;
    multiple = allowMultiple;
    return pending.future;
  }
}

Finder _attachment(String name) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName ==
          'assets/svg/screen3_1/attach_$name.svg',
);

Future<void> _openScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MaterialApp(home: PatientInfoScreen()));
  await tester.pumpAndSettle();
}

void main() {
  late _TestFilePicker picker;

  setUp(() {
    picker = _TestFilePicker();
    FilePicker.platform = picker;
  });

  tearDown(() {
    FilePicker.platform = FilePickerIO();
  });

  testWidgets('blocks repeated and cross-media taps until selection finishes', (
    tester,
  ) async {
    await _openScreen(tester);
    await tester.tap(_attachment('audio'));
    // No rebuild between taps: the handler itself must reject reentry.
    await tester.tap(_attachment('audio'));
    await tester.tap(_attachment('photo'));
    await tester.tap(_attachment('video'));
    expect(picker.requests, [FileType.audio]);

    picker.pending.complete(null);
    await tester.pumpAndSettle();
    picker.pending = Completer<FilePickerResult?>();
    await tester.tap(_attachment('audio'));
    expect(picker.requests, [FileType.audio, FileType.audio]);
    picker.pending.complete(null);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles a busy picker without opening a fallback request', (
    tester,
  ) async {
    await _openScreen(tester);
    await tester.tap(_attachment('audio'));
    picker.pending.completeError(
      PlatformException(
        code: 'multiple_request',
        message: 'Cancelled by a second request',
      ),
    );
    await tester.pumpAndSettle();
    expect(picker.requests, [FileType.audio]);
    expect(find.text('열려 있는 파일 선택창을 먼저 닫아 주세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    picker.pending = Completer<FilePickerResult?>();
    await tester.tap(_attachment('audio'));
    picker.pending.complete(
      FilePickerResult([
        PlatformFile(name: 'recording.m4a', path: '/tmp/recording.m4a', size: 12),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('recording.m4a'), findsOneWidget);
    expect(picker.requests.length, 2);
  });

  testWidgets('ignores a selection that returns after leaving the screen', (
    tester,
  ) async {
    await _openScreen(tester);
    await tester.tap(_attachment('audio'));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    picker.pending.complete(
      FilePickerResult([
        PlatformFile(name: 'late.wav', path: '/tmp/late.wav', size: 12),
      ]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS selects audio files through the document picker', (
    tester,
  ) async {
    await _openScreen(tester);
    await tester.tap(_attachment('audio'));
    expect(picker.requests, [FileType.custom]);
    expect(picker.extensions, containsAll(['mp3', 'm4a', 'wav']));
    expect(picker.multiple, isTrue);
    picker.pending.complete(null);
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));
}
