import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/models/groups.dart';
import 'package:care_garden/screens/auth/family_group_list_screen.dart';
import 'package:care_garden/screens/auth/group_created_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Group _group(int id, String name, int members) => Group(
  id: id,
  inviteCode: 'CODE$id',
  groupName: name,
  members: members,
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _openScreen(WidgetTester tester, AppData data) async {
  tester.view.physicalSize = const Size(351, 727);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: data,
      child: const MaterialApp(home: FamilyGroupListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('그룹 응답 갱신 시 이름, 인원, 카드 개수를 함께 갱신한다', (tester) async {
    final data = AppData();
    addTearDown(data.dispose);
    data.updateJoinedGroups([
      _group(10, '가나다라', 2),
      _group(20, '성강왕강용강', 12),
      _group(30, '생성 진단용', 0),
    ]);
    await _openScreen(tester, data);

    for (final name in ['가나다라', '성강왕강용강', '생성 진단용']) {
      expect(find.text(name), findsOneWidget);
    }
    for (final count in [2, 12, 0]) {
      expect(find.text('구성원 $count명'), findsOneWidget);
    }
    expect(find.text('그룹 이름'), findsNothing);
    expect(tester.takeException(), isNull);

    data.updateJoinedGroups([_group(10, '변경된 그룹', 5)]);
    await tester.pumpAndSettle();
    expect(find.text('변경된 그룹'), findsOneWidget);
    expect(find.text('구성원 5명'), findsOneWidget);
    expect(find.text('가나다라'), findsNothing);
    expect(find.text('성강왕강용강'), findsNothing);
    expect(find.text('구성원 0명'), findsNothing);

    data.updateJoinedGroups([]);
    await tester.pumpAndSettle();
    expect(find.text('변경된 그룹'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('긴 이름은 아이콘과 버튼 사이에 표시하고 입장 화면에 전달한다', (tester) async {
    const name = '우리 가족이 함께 사용하는 아주 긴 가족 그룹 이름';
    final data = AppData();
    addTearDown(data.dispose);
    data.updateJoinedGroups([_group(20, name, 123)]);
    await _openScreen(tester, data);

    final nameRect = tester.getRect(find.text(name));
    final countRect = tester.getRect(find.text('구성원 123명'));
    final cardRect = tester.getRect(find.byKey(const ValueKey(20)));
    expect(nameRect.left, greaterThanOrEqualTo(cardRect.left + 94));
    expect(nameRect.right, lessThanOrEqualTo(cardRect.right - 113));
    expect(nameRect.bottom, lessThanOrEqualTo(countRect.top));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(find.byType(GroupCreatedScreen), findsOneWidget);
    expect(find.text(name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
