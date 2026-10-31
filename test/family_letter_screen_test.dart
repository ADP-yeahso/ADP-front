import 'dart:convert';

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/data/auth_session.dart';
import 'package:care_garden/models/groups.dart';
import 'package:care_garden/screens/letters/family_letter_screen.dart';
import 'package:care_garden/services/api_service.dart';
import 'package:care_garden/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('sending a letter waits for the compose sheet to detach', (
    tester,
  ) async {
    var sent = false;
    final api = ApiService(
      client: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/letters')) {
          sent = true;
          return _json({'id': 1, 'content': '마음을 전해요'});
        }
        if (request.method == 'GET' && request.url.path.endsWith('/letters')) {
          return _json(
            sent
                ? [
                    {
                      'id': 1,
                      'content': '마음을 전해요',
                      'sender_user_id': 'user-1',
                      'receiver_user_id': null,
                      'is_read': true,
                    },
                  ]
                : [],
          );
        }
        fail('Unexpected request: ${request.method} ${request.url}');
      }),
    );
    addTearDown(api.close);
    final data = AppData()
      ..group = Group(
        id: 7,
        groupName: '가족',
        inviteCode: 'INVITE',
        members: 1,
        createdAt: DateTime(2026),
      )
      ..currentUserId = 'user-1';
    addTearDown(data.dispose);
    final session = AuthSession()
      ..signIn(
        const AuthTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
          tokenType: 'bearer',
        ),
      );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: data),
          ChangeNotifierProvider.value(value: session),
        ],
        child: MaterialApp(home: FamilyLetterScreen(api: api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('편지 쓰기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '마음을 전해요');
    await tester.tap(find.text('편지 보내기'));
    await tester.pumpAndSettle();

    expect(sent, isTrue);
    expect(find.text('보낸 편지'), findsOneWidget);
    expect(find.text('마음을 전해요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

http.Response _json(Object? body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json'},
);
