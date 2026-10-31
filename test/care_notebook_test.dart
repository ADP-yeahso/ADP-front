import 'dart:io';
import 'dart:ui' as ui;
import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/care_notebook/care_record_view_data.dart';
import 'package:care_garden/screens/care_notebook/care_notebook_list_screen.dart';
import 'package:care_garden/screens/care_notebook/care_notebook_write_screen.dart';
import 'package:care_garden/screens/care_notebook/care_notebook_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:care_garden/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Regular': 400,
      'Medium': 500,
      'SemiBold': 600,
      'Bold': 700,
    }.entries) {
      await (FontLoader('Pretendard')..addFont(
            rootBundle.load('assets/fonts/Pretendard-${entry.key}.ttf'),
          ))
          .load();
    }
  });
  Widget app(AppData data, Widget screen) => ChangeNotifierProvider.value(
    value: data,
    child: MaterialApp(theme: AppTheme.light, home: screen),
  );
  Finder button(String label) => find.byWidgetPredicate(
    (widget) => widget is CareAssetButton && widget.label == label,
  );
  Finder medicalToggle() => find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.label == '진료 · 약 변경 내용 추가',
  );
  Finder png(String name) => find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        (switch (widget.image) {
              AssetImage(:final assetName) => assetName,
              ExactAssetImage(:final assetName) => assetName,
              _ => null,
            }) ==
            'assets/images/care_note/$name.png',
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
      await tester.tap(medicalToggle());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '신경과');
      await tester.tap(medicalToggle());
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
      expect(png('care_note_entry_frame'), findsOneWidget);
      expect(png('record_content_frame'), findsNWidgets(5));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader is SvgAssetLoader &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/images/care_note/entry_date_divider.svg',
        ),
        findsOneWidget,
      );
      expect(data.careRecords.single.mealStatus, '적음');
      expect(data.careRecords.single.unusualChanges, ['같은 질문 반복', '배회']);
      expect(data.careRecords.single.note, '오늘 산책했어요');
      expect(data.careRecords.single.hospitalDepartment, '신경과');
      expect(data.careRecords.single.hasMedicalUpdate, isTrue);
      expect(find.text('오늘 산책했어요'), findsOneWidget);
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
      for (final label in ['같은 질문 반복', '배회', '불안·초조', '기타']) {
        expect(tester.getSize(button(label)), before);
      }
      await tester.tap(button('배회'));
      await tester.tap(button('평소와 다른 점 없음'));
      await tester.pumpAndSettle();
      expect(button('배회'), findsNothing);
      await tester.tap(button('평소와 다른 점 있음'));
      await tester.pumpAndSettle();
      expect(tester.widget<CareAssetButton>(button('배회')).selected, isTrue);
      await tester.ensureVisible(medicalToggle());
      await tester.tap(medicalToggle());
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
  testWidgets('care notebook covers the home dock and restores it on return', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        AppData(),
        Scaffold(
          bottomNavigationBar: const BottomAppBar(
            key: ValueKey('home-dock'),
            child: Text('홈 하단바'),
          ),
          floatingActionButton: FloatingActionButton(
            key: const ValueKey('home-add'),
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => openCareNotebook(context),
                  child: const Text('돌봄수첩 열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('home-dock')), findsOneWidget);
    await tester.tap(find.text('돌봄수첩 열기'));
    await tester.pumpAndSettle();
    expect(find.byType(CareNotebookListScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('home-dock')), findsNothing);
    expect(find.byKey(const ValueKey('home-add')), findsNothing);
    await tester.tap(button('수첩 쓰기'));
    await tester.pumpAndSettle();
    expect(find.byType(CareNotebookWriteScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('home-dock')), findsNothing);
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.byType(CareNotebookListScreen), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-dock')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('care design previews keep header background behind the title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(394, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final previewData = AppData();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: app(previewData, const CareNotebookListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        for (final image in images) {
          await precacheImage(image.image, key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/care_previews').createSync(recursive: true);
        File(
          'build/care_previews/$name.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.endsWith('/top_bar.png'),
      ),
      findsNothing,
    );
    await capture('empty');
    await tester.tap(button('수첩 쓰기'));
    await tester.pumpAndSettle();
    await tester.tap(button('평소와 다른 점 있음'));
    await tester.pumpAndSettle();
    expect(find.text('특이사항 메모'), findsOneWidget);
    await capture('write');
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    previewData.addCareRecord(
      CareRecordViewData(
        date: DateTime(2026, 10, 31),
        mealStatus: '좋음',
        sleepStatus: '좋음',
        bowelStatus: '변화 있음',
        medicationStatus: '완료',
        unusualChanges: const ['배회'],
        note: '소중한 가족을 기록해 보아요 :)',
        hasMedicalUpdate: true,
        visitDetails: '의사선생님의 한마디',
      ),
    );
    await tester.pumpAndSettle();
    final frames = tester.widgetList<Image>(png('record_content_frame'));
    expect(frames, hasLength(5));
    for (final frame in frames) {
      expect(frame.centerSlice, const Rect.fromLTRB(16, 15, 77, 17));
      expect(tester.getSize(find.byWidget(frame)).height, 32);
    }
    expect(tester.widget<Text>(find.text('식사 좋음')).textAlign, TextAlign.center);
    expect(
      tester.widget<Text>(find.text('식사 좋음')).style!.fontWeight,
      FontWeight.w600,
    );
    await capture('record');
    expect(tester.takeException(), isNull);
  });
}
