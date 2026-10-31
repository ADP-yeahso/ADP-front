import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/garden/garden_home_header.dart';
import 'package:care_garden/screens/mailbox/family_mailbox_screen.dart';
import 'package:care_garden/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Finder svg(String path) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == path,
);

void main() {
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
                onOpenMailbox: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FamilyMailboxScreen(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(svg('assets/garden/home/unread_badge.svg'), findsOneWidget);
    await tester.tap(find.byTooltip('편지함 · 읽지 않은 편지 또는 새 공유 기록'));
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

  testWidgets('mailbox retains sent tab and access to shared records', (
    tester,
  ) async {
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
    var openedSharedRecords = false;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: data,
        child: MaterialApp(
          theme: AppTheme.light,
          home: FamilyMailboxScreen(
            onOpenSharedRecords: () => openedSharedRecords = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(svg('assets/svg/mailbox/sent_letters_tab.svg'));
    await tester.pumpAndSettle();
    expect(find.text('보낸 편지 보존 확인'), findsOneWidget);
    await tester.tap(find.byTooltip('가족 공유 기록'));
    expect(openedSharedRecords, isTrue);
    expect(tester.takeException(), isNull);
  });
}
