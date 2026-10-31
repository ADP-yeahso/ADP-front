import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/screens/profile/profile_screen.dart';
import 'package:care_garden/screens/profile/profile_edit_screen.dart';
import 'package:care_garden/screens/profile/patient_info_screen.dart';
import 'package:care_garden/screens/profile/patient_info_edit_screen.dart';
import 'package:care_garden/screens/profile/family_management_screen.dart';
import 'package:care_garden/screens/profile/settings_components.dart';
import 'package:care_garden/theme/app_theme.dart';

void main() {
  for (final patient in [false, true]) {
    testWidgets(
      '${patient ? 'patient' : 'profile'} save button changes color without changing size',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = AppData();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: data,
            child: MaterialApp(
              theme: AppTheme.light,
              home: patient
                  ? const PatientInfoEditScreen()
                  : const ProfileEditScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.byType(SettingsSave);
        final image = find.descendant(of: button, matching: find.byType(Image));
        final originalSize = tester.getSize(image);
        expect(originalSize, const Size(261, 48));
        expect(tester.widget<SettingsSave>(button).isChanged, isFalse);
        final nameField = find.byType(TextFormField).first;
        final originalName = patient ? data.patient.patientName : data.me.name;
        await tester.enterText(nameField, '수정한 이름');
        await tester.pumpAndSettle();
        expect(tester.widget<SettingsSave>(button).isChanged, isTrue);
        expect(
          (tester.widget<Image>(image).image as AssetImage).assetName,
          endsWith('btn_save_green.png'),
        );
        expect(tester.getSize(image), originalSize);
        await tester.enterText(nameField, originalName);
        await tester.pumpAndSettle();
        expect(tester.widget<SettingsSave>(button).isChanged, isFalse);
        expect(
          (tester.widget<Image>(image).image as AssetImage).assetName,
          endsWith('btn_save_yellow.png'),
        );
        expect(tester.getSize(image), originalSize);
        if (!patient) {
          await tester.enterText(
            find.byType(TextFormField).last,
            '010-1234-5678',
          );
          await tester.pumpAndSettle();
          expect(tester.widget<SettingsSave>(button).isChanged, isTrue);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  final screens = <String, Widget>{
    'my_page': const ProfileScreen(),
    'edit_profile': const ProfileEditScreen(),
    'patient_info': const PatientInfoScreen(),
    'edit_patient': const PatientInfoEditScreen(),
    'group_info': const FamilyManagementScreen(),
  };
  for (final width in [320.0, 351.0, 430.0]) {
    for (final screen in screens.entries) {
      testWidgets('${screen.key} renders at $width without overflow', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final font = FontLoader('Pretendard')
          ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.ttf'));
        await font.load();
        final nameFont = FontLoader('OwnglyphMeetme')
          ..addFont(rootBundle.load('assets/fonts/OwnglyphMeetme-Regular.ttf'));
        await nameFont.load();
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AppData(),
            child: MaterialApp(
              theme: AppTheme.light,
              home: RepaintBoundary(key: boundary, child: screen.value),
            ),
          ),
        );
        final imageContext = tester.element(find.byType(SettingsPage));
        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        await tester.runAsync(() async {
          for (final image in images) {
            await precacheImage(image.image, imageContext);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (width == 351) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final directory = Directory('build/settings_previews')
              ..createSync(recursive: true);
            File(
              '${directory.path}/${screen.key}.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }

  testWidgets('patient name and clinical information save back to AppData', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = AppData();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: data,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientInfoEditScreen(),
                  ),
                ),
                child: const Text('수정'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '새 환자 이름');
    final dementia = find.byKey(const ValueKey('patient_field_0'));
    await tester.tap(dementia);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '알츠하이머');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SettingsSave>(find.byType(SettingsSave)).isChanged,
      isTrue,
    );
    await tester.ensureVisible(find.byType(SettingsSave));
    await tester.tap(find.byType(SettingsSave));
    await tester.pumpAndSettle();
    expect(data.patient.patientName, '새 환자 이름');
    expect(data.patient.dementiaType, '알츠하이머');
    expect(find.text('수정'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
