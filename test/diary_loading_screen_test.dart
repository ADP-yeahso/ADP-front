import 'dart:async';

import 'package:care_garden/screens/record/write/diary_loading_screen.dart';
import 'package:care_garden/services/diary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openLoading(
  WidgetTester tester,
  Future<Widget> Function() load,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DiaryLoadingScreen(loadNext: load),
              ),
            ),
            child: const Text('시작'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('시작'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('waits for the API response instead of a fixed timer', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    await _openLoading(tester, () => pending.future);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Scaffold(body: Text('완료')));
    await tester.pumpAndSettle();
    expect(find.text('완료'), findsOneWidget);
    expect(find.byType(DiaryLoadingScreen), findsNothing);
  });

  testWidgets('shows API errors and retries the same operation', (
    tester,
  ) async {
    var attempts = 0;
    await _openLoading(tester, () async {
      if (++attempts == 1) throw const DiaryException('서버가 응답하지 않아요.');
      return const Scaffold(body: Text('완료'));
    });
    await tester.pumpAndSettle();
    expect(find.text('서버가 응답하지 않아요.'), findsOneWidget);
    expect(find.text('완료'), findsNothing);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets('ignores a response after the loading screen is disposed', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    await _openLoading(tester, () => pending.future);
    await tester.pumpWidget(
      const MaterialApp(key: ValueKey('new-session'), home: Text('다른 화면')),
    );
    pending.complete(const Scaffold(body: Text('늦은 응답')));
    await tester.pumpAndSettle();
    expect(find.text('다른 화면'), findsOneWidget);
    expect(find.text('늦은 응답'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
