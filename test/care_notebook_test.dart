import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/care_notebook/care_notebook_list_screen.dart';
import 'package:care_garden/screens/care_notebook/care_notebook_write_screen.dart';
import 'package:care_garden/screens/care_notebook/care_notebook_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget app(AppData data, Widget screen) => ChangeNotifierProvider.value(
    value: data,
    child: MaterialApp(home: screen),
  );
  Finder button(String label) => find.byWidgetPredicate(
    (widget) => widget is CareAssetButton && widget.label == label,
  );
  bool hasPngBackground(Container container, String assetName) {
    final decoration = container.decoration;
    return decoration is BoxDecoration &&
        decoration.image?.image is AssetImage &&
        (decoration.image!.image as AssetImage).assetName == assetName;
  }

  testWidgets(
    'empty state, single and multiple selections, memo and save round trip',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = AppData();
      await tester.pumpWidget(app(data, const CareNotebookListScreen()));
      expect(data.careRecords, isEmpty);
      await tester.tap(button('수첩 쓰기'));
      await tester.pumpAndSettle();
      for (final label in [
        '식사 좋음',
        '식사 적음',
        '수면 보통',
        '배변 정상',
        '복약 완료',
        '평소와 다른 점 있음',
        '같은 질문 반복',
        '배회',
      ]) {
        await tester.ensureVisible(button(label));
        await tester.tap(button(label));
        await tester.pumpAndSettle();
      }
      expect(tester.widget<CareAssetButton>(button('식사 좋음')).selected, isFalse);
      expect(tester.widget<CareAssetButton>(button('식사 적음')).selected, isTrue);
      expect(
        tester.widget<CareAssetButton>(button('같은 질문 반복')).selected,
        isTrue,
      );
      expect(tester.widget<CareAssetButton>(button('배회')).selected, isTrue);
      await tester.enterText(find.byType(TextField).first, '오늘 산책했어요');
      await tester.tap(find.text('진료 · 약 변경 내용 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '신경과');
      await tester.tap(find.text('진료 · 약 변경 내용 추가'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        button('저장하기'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<CareAssetButton>(button('저장하기')).asset,
        'save_green_button',
      );
      await tester.tap(button('저장하기'));
      await tester.pumpAndSettle();
      expect(find.byType(CareNotebookWriteScreen), findsNothing);
      expect(data.careRecords.single.mealStatus, '적음');
      expect(data.careRecords.single.unusualChanges, ['같은 질문 반복', '배회']);
      expect(data.careRecords.single.note, '오늘 산책했어요');
      expect(data.careRecords.single.hospitalDepartment, '신경과');
      expect(data.careRecords.single.hasMedicalUpdate, isTrue);
      expect(find.textContaining('특이사항: 오늘 산책했어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('small screen expands and opens date picker without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(AppData(), const CareNotebookWriteScreen()));
    final containers = tester.widgetList<Container>(find.byType(Container));
    expect(
      containers.where(
        (container) => hasPngBackground(
          container,
          'assets/images/care_note/record_form_frame.png',
        ),
      ),
      hasLength(1),
    );
    expect(
      containers.where(
        (container) => hasPngBackground(
          container,
          'assets/images/care_note/date_picker_frame.png',
        ),
      ),
      hasLength(1),
    );
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(button('평소와 다른 점 있음'));
    await tester.tap(button('평소와 다른 점 있음'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      button('저장하기'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'expanded form clears shared dock and keyboard; selections stay crisp and stable',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        app(
          AppData(),
          Scaffold(
            body: const CareNotebookWriteScreen(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: const BottomAppBar(
              child: SizedBox(height: 60),
            ),
          ),
        ),
      );
      final before = tester.getSize(button('식사 좋음'));
      final beforeImage = tester.getSize(
        find.descendant(of: button('식사 좋음'), matching: find.byType(Image)),
      );
      await tester.tap(button('식사 좋음'));
      await tester.pumpAndSettle();
      expect(tester.getSize(button('식사 좋음')), before);
      expect(
        tester.getSize(
          find.descendant(of: button('식사 좋음'), matching: find.byType(Image)),
        ),
        beforeImage,
      );
      final selectedOption = tester.widget<Image>(
        find.descendant(of: button('식사 좋음'), matching: find.byType(Image)),
      );
      expect(
        selectedOption.image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          'assets/images/care_note/option_good_selected.png',
        ),
      );
      await tester.tap(button('평소와 다른 점 있음'));
      await tester.pumpAndSettle();
      expect(button('배회'), findsOneWidget);
      await tester.tap(button('배회'));
      await tester.tap(button('평소와 다른 점 없음'));
      await tester.pumpAndSettle();
      expect(button('배회'), findsNothing);
      await tester.tap(button('평소와 다른 점 있음'));
      await tester.pumpAndSettle();
      expect(tester.widget<CareAssetButton>(button('배회')).selected, isTrue);
      await tester.ensureVisible(find.text('진료 · 약 변경 내용 추가'));
      await tester.tap(find.text('진료 · 약 변경 내용 추가'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      final field = find.byType(TextField).at(2);
      await tester.ensureVisible(field);
      await tester.enterText(field, '변경 내용 유지');
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('care-write-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(button('저장하기'), 160, scrollable: scroll);
      final position = tester.state<ScrollableState>(scroll).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      final save = tester.getRect(button('저장하기'));
      final dock = tester.getRect(find.byType(FloatingActionButton));
      expect(save.bottom, lessThan(dock.top));
      expect(save.top, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('save turns green only when required selections are complete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(AppData(), const CareNotebookWriteScreen()));
    void expectSave(bool ready) {
      final save = button('저장하기');
      expect(
        tester.widget<CareAssetButton>(save).asset,
        ready ? 'save_green_button' : 'save_yellow_button',
      );
      final image = tester.widget<Image>(
        find.descendant(of: save, matching: find.byType(Image)),
      );
      expect(
        image.image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          ready
              ? 'assets/images/care_note/save_green_button.png'
              : 'assets/images/care_note/save_yellow_button.png',
        ),
      );
    }

    expectSave(false);
    for (final label in ['식사 좋음', '수면 보통', '배변 정상']) {
      await tester.tap(button(label));
      await tester.pumpAndSettle();
      expectSave(false);
    }
    await tester.tap(button('복약 완료'));
    await tester.pumpAndSettle();
    expectSave(true);
    final size = tester.getSize(button('저장하기'));
    await tester.tap(button('평소와 다른 점 있음'));
    await tester.pumpAndSettle();
    expectSave(false);
    await tester.tap(button('배회'));
    await tester.pumpAndSettle();
    expectSave(true);
    await tester.tap(button('배회'));
    await tester.pumpAndSettle();
    expectSave(false);
    await tester.tap(button('평소와 다른 점 없음'));
    await tester.pumpAndSettle();
    expectSave(true);
    expect(tester.getSize(button('저장하기')), size);
  });
}
