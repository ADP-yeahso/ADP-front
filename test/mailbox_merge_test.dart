import 'dart:io';
import 'dart:ui' as ui;
import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/models/mail_letter.dart';
import 'package:care_garden/screens/garden/garden_home_header.dart';
import 'package:care_garden/screens/mailbox/family_mailbox_screen.dart';
import 'package:care_garden/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Finder svg(String path) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == path,
);

Finder png(String path) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      (switch (widget.image) {
            AssetImage(:final assetName) => assetName,
            ExactAssetImage(:final assetName) => assetName,
            _ => null,
          }) ==
          path,
);
void main() {
  void expectSelectionFits(WidgetTester tester, {required bool received}) {
    final track = tester.getRect(
      find.byKey(const ValueKey('mailbox-tab-track')),
    );
    final selected = tester.getRect(
      png('assets/images/mailbox/selected_item.png'),
    );
    expect(selected.left, greaterThanOrEqualTo(track.left - 0.01));
    expect(selected.right, lessThanOrEqualTo(track.right + 0.01));
    expect(selected.top, greaterThanOrEqualTo(track.top - 0.01));
    expect(selected.bottom, lessThanOrEqualTo(track.bottom + 0.01));
    if (received) {
      expect(selected.right, lessThanOrEqualTo(track.center.dx + 0.01));
    } else {
      expect(selected.left, greaterThanOrEqualTo(track.center.dx - 0.01));
    }
    final label = svg(
      'assets/svg/mailbox/${received ? 'received_letters_tab' : 'sent_letters_tab'}.svg',
    );
    expect(tester.getRect(label).center.dx, closeTo(selected.center.dx, 0.01));
    expect(tester.getRect(label).center.dy, closeTo(selected.center.dy, 0.01));
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Pretendard');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.ttf'));
    }
    await font.load();
  });
  test('mailbox keeps received/sent filtering and unread state', () {
    final data = AppData();
    final unread = data.receivedLetters
        .where((letter) => !letter.isRead)
        .toList();
    expect(unread, isNotEmpty);
    expect(data.hasUnreadMail, isTrue);
    for (final letter in unread) {
      data.markLetterAsRead(letter.id);
    }
    expect(data.hasUnreadMail, isFalse);
    expect(data.unreadMailCount, 0);

    data.addLetter(
      receiver: '가족 모두에게',
      content: '머지 후 가족 편지',
      isAnonymous: true,
    );
    final sent = data.sentLetters.single;
    expect(sent.content, '머지 후 가족 편지');
    expect(sent.isAnonymous, isTrue);
    expect(sent.isGroupLetter, isTrue);
    expect(data.receivedLetters, isNot(contains(sent)));
    expect(data.hasUnreadMail, isFalse);
    data.dispose();
  });

  testWidgets('latest home header keeps mailbox navigation and unread badge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = AppData();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: data,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Consumer<AppData>(
              builder: (context, value, _) => GardenHomeHeader(
                month: DateTime(2026, 11),
                groupName: value.group.groupName,
                hasUnreadRecords: value.hasUnreadMail,
                onOpenNotebook: () {},
                onOpenMailbox: () => openFamilyMailbox(context),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(svg('assets/garden/home/unread_badge.svg'), findsOneWidget);
    await tester.tap(find.byTooltip('편지함 · 읽지 않은 편지'));
    await tester.pumpAndSettle();
    expect(find.byType(FamilyMailboxScreen), findsOneWidget);
    final first = data.receivedLetters.firstWhere((letter) => !letter.isRead);
    await tester.tap(find.text(first.content));
    await tester.pumpAndSettle();
    expect(first.isRead, isTrue);
    Navigator.of(tester.element(find.byType(FamilyMailboxScreen))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(FamilyMailboxScreen))).pop();
    await tester.pumpAndSettle();
    for (final letter in data.receivedLetters.toList()) {
      data.markLetterAsRead(letter.id);
    }
    await tester.pumpAndSettle();
    expect(svg('assets/garden/home/unread_badge.svg'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mailbox uses original PNG selection and hides the removed action',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = AppData();
      data.addLetter(
        receiver: '가족 모두에게',
        content: '보낸 편지 보존 확인',
        isAnonymous: false,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: data,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const FamilyMailboxScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.groups_outlined), findsNothing);
      expect(png('assets/images/mailbox/top_bar.png'), findsOneWidget);
      expect(svg('assets/svg/mailbox/top_bar.svg'), findsNothing);
      expect(svg('assets/svg/mailbox/selected_item.svg'), findsNothing);
      final selection = png('assets/images/mailbox/selected_item.png');
      expect(selection, findsOneWidget);
      final before = tester.getRect(selection);
      expectSelectionFits(tester, received: true);
      expect(
        tester
            .widget<SvgPicture>(
              svg('assets/svg/mailbox/received_letters_tab.svg'),
            )
            .colorFilter,
        isNull,
      );
      expect(
        tester
            .widget<SvgPicture>(svg('assets/svg/mailbox/sent_letters_tab.svg'))
            .colorFilter,
        isNull,
      );
      await tester.tap(svg('assets/svg/mailbox/sent_letters_tab.svg'));
      await tester.pumpAndSettle();
      expect(find.text('보낸 편지 보존 확인'), findsOneWidget);
      expectSelectionFits(tester, received: false);
      expect(tester.getRect(selection).width, closeTo(before.width, 0.01));
      expect(tester.getRect(selection).height, closeTo(before.height, 0.01));
      expect(
        tester.getRect(selection).center.dx,
        greaterThan(before.center.dx),
      );
      final frame = tester.widget<Image>(
        png('assets/images/mailbox/letter_list_frame.png'),
      );
      expect(frame.centerSlice, const Rect.fromLTRB(12, 12, 303, 92));
      expect(svg('assets/svg/mailbox/date_divider_line.svg'), findsOneWidget);
      expect(svg('assets/svg/mailbox/to_label.svg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mailbox design previews render both tabs without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(351, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = AppData();
    data.letters.add(
      MailLetter(
        id: 'preview-sent',
        groupId: data.group.id,
        senderUserId: data.currentMailboxUserId,
        receiverUserId: '2',
        sender: data.me.name,
        receiver: '재은',
        content: '가나다라마바사아자차카타파하',
        isAnonymous: false,
        isGroupLetter: false,
        createdAt: DateTime(2026, 10, 31),
      ),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ChangeNotifierProvider.value(
          value: data,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const FamilyMailboxScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      await tester.runAsync(() async {
        for (final image in images) {
          await precacheImage(image.image, key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      final render =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final frame = tester.widget<Image>(
        png('assets/images/mailbox/letter_tab_bar.png'),
      );
      final frameRect = tester
          .getRect(png('assets/images/mailbox/letter_tab_bar.png'))
          .shift(-render.localToGlobal(Offset.zero));
      final fitted = applyBoxFit(
        frame.fit ?? BoxFit.scaleDown,
        const Size(162, 42),
        frameRect.size,
      );
      final paintedFrame = Alignment.center.inscribe(
        fitted.destination,
        frameRect,
      );
      final frameBody = paintedFrame.deflate(paintedFrame.width / 162);
      final capsule = RRect.fromRectAndRadius(
        frameBody,
        Radius.circular(frameBody.height / 2),
      );
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var greenPixels = 0;
        var outsideFrame = 0;
        for (
          var y = (frameRect.top * 2).floor();
          y < (frameRect.bottom * 2).ceil();
          y++
        ) {
          for (
            var x = (frameRect.left * 2).floor();
            x < (frameRect.right * 2).ceil();
            x++
          ) {
            final offset = (y * image.width + x) * 4;
            final r = pixels.getUint8(offset);
            final g = pixels.getUint8(offset + 1);
            final b = pixels.getUint8(offset + 2);
            if (g > r + 8 && g > b + 8 && r > 40 && g < 235) {
              greenPixels++;
              if (!capsule.contains(Offset((x + 0.5) / 2, (y + 0.5) / 2))) {
                outsideFrame++;
              }
            }
          }
        }
        expect(
          greenPixels,
          greaterThan(50),
          reason: 'The selected PNG must be visible.',
        );
        expect(
          outsideFrame,
          0,
          reason:
              '$name: green pixels must remain inside the frame actually painted on screen.',
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/mailbox_previews').createSync(recursive: true);
        File(
          'build/mailbox_previews/$name.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
        final crop = frameRect.inflate(4);
        final source = Rect.fromLTRB(
          crop.left * 2,
          crop.top * 2,
          crop.right * 2,
          crop.bottom * 2,
        );
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawImageRect(
          image,
          source,
          Rect.fromLTWH(0, 0, source.width, source.height),
          Paint(),
        );
        final picture = recorder.endRecording();
        final toggle = await picture.toImage(
          source.width.ceil(),
          source.height.ceil(),
        );
        final togglePng = await toggle.toByteData(
          format: ui.ImageByteFormat.png,
        );
        File(
          'build/mailbox_previews/$name-toggle.png',
        ).writeAsBytesSync(togglePng!.buffer.asUint8List());
        toggle.dispose();
        picture.dispose();
        image.dispose();
      });
    }

    await capture('received');
    await tester.tap(svg('assets/svg/mailbox/sent_letters_tab.svg'));
    await tester.pumpAndSettle();
    await capture('sent');
    expect(tester.takeException(), isNull);
    for (final width in [320.0, 394.0, 430.0]) {
      tester.view.physicalSize = Size(width, 740);
      await tester.pumpAndSettle();
      expectSelectionFits(tester, received: false);
      await capture('sent_${width.toInt()}');
      await tester.tap(svg('assets/svg/mailbox/received_letters_tab.svg'));
      await tester.pumpAndSettle();
      expectSelectionFits(tester, received: true);
      await capture('received_${width.toInt()}');
      await tester.tap(svg('assets/svg/mailbox/sent_letters_tab.svg'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'mailbox and compose hide the home bar and restore it on return',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = AppData();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: data,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              bottomNavigationBar: SizedBox(
                key: const ValueKey('home-bottom-bar'),
                height: 96,
                child: Center(
                  child: IconButton(
                    key: const ValueKey('home-add'),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),
              body: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (context) => Center(
                    child: TextButton(
                      onPressed: () => openFamilyMailbox(context),
                      child: const Text('편지함 열기'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('home-bottom-bar')), findsOneWidget);
      await tester.tap(find.text('편지함 열기'));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyMailboxScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('home-bottom-bar')), findsNothing);
      expect(find.byKey(const ValueKey('home-add')), findsNothing);
      await tester.tap(svg('assets/svg/mailbox/write_letter_icon.svg'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('home-bottom-bar')), findsNothing);
      final back = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '뒤로 가기',
      );
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(FamilyMailboxScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('home-bottom-bar')), findsNothing);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-bottom-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-add')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
