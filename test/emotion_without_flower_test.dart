import 'dart:convert';
import 'dart:ui' as ui;

import 'package:care_garden/data/app_data.dart';
import 'package:care_garden/models/diary.dart';
import 'package:care_garden/screens/calendar/calendar_screen.dart';
import 'package:care_garden/screens/record/write/diary_result_screen.dart';
import 'package:care_garden/screens/record/write/diary_care_content_screen.dart';
import 'package:care_garden/services/api_service.dart';
import 'package:care_garden/services/auth_service.dart';
import 'package:care_garden/services/diary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

const _tokens = AuthTokens(
  accessToken: 'access',
  refreshToken: 'refresh',
  tokenType: 'bearer',
);
const _names = ['중립', '분노/답답함', '불안/초조', '슬픔/소진', '죄책감/자책', '감사/안도', '애틋함/수용'];
const _moodAssets = ['joonglib', 'b_d', 'b_ch', 's_s', 'j_j', 'g_a', 'a_s'];
const _colors = [
  0xFF88C24D,
  0xFFE36887,
  0xFFAEAEAE,
  0xFF5EA7FF,
  0xFFD09ED7,
  0xFFFFE367,
  0xFFFF9131,
];

Map<String, dynamic> _saved(int emotion, {bool secondaryMajority = false}) {
  final secondary = emotion == 0 ? 1 : 0;
  final correct = secondaryMajority ? secondary : emotion;
  return {
    'id': 91,
    'user_id': 'user-1',
    'group_id': 7,
    'status': 'draft',
    'situation_text': '기록',
    'record_date': '2026-10-27T12:00:00Z',
    'updated_at': '2026-10-28T12:00:00Z',
    'finalized_at': null,
    'final_emotion_id': emotion,
    'correct_emotion_id': correct,
    'flower_id': null,
    'flower': null,
    'emotion': {
      'id': emotion,
      'emotion': 'code-$emotion',
      'display_name': _names[emotion],
    },
    'correct_emotion': {'id': correct, 'display_name': _names[correct]},
    'ai_emotion_predictions': [
      {
        'emotion_id': emotion,
        'rank': 1,
        'tags': [
          {'id': 101},
          {'id': 102},
          {'id': 103},
        ],
      },
      {
        'emotion_id': secondary,
        'rank': 2,
        'tags': [
          {'id': 201},
          {'id': 202},
          {'id': 203},
        ],
      },
    ],
    'selected_emotion_tags': secondaryMajority
        ? [
            {'id': 101},
            {'id': 201},
            {'id': 202},
          ]
        : [
            {'id': 101},
            {'id': 102},
            {'id': 201},
          ],
    'media': [],
  };
}

http.Response _json(Object value, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  status,
  headers: {'content-type': 'application/json'},
);

Future<AppData> _load(
  Map<String, dynamic> diary, {
  bool resetOnEdit = false,
}) async {
  final data = AppData(
    api: ApiService(
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer access');
        if (request.method == 'PATCH' && resetOnEdit) {
          return _json({
            ...diary,
            'final_emotion_id': null,
            'correct_emotion_id': null,
          });
        }
        switch (request.url.path) {
          case '/api/v1/users/me':
            return _json({'id': 'user-1'});
          case '/api/v1/groups/7':
            return _json({
              'id': 7,
              'group_name': '가족',
              'invite_code': 'CODE',
              'member_count': 1,
              'members': [],
              'patient': null,
            });
          case '/api/v1/diaries':
            return _json([
              {
                'id': diary['id'],
                'status': diary['status'],
                'final_emotion_id': diary['final_emotion_id'],
                'correct_emotion_id': diary['correct_emotion_id'],
              },
            ]);
          case '/api/v1/diaries/91':
            return _json(diary);
        }
        fail('Unexpected request: ${request.method} ${request.url}');
      }),
    ),
  );
  addTearDown(data.dispose);
  await data.openGroup(_tokens, 7);
  return data;
}

void main() {
  test(
    'missing flower succeeds only after verifying the saved label and exact selected tags',
    () async {
      final requests = <String>[];
      final service = DiaryService(
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          if (request.method == 'POST') {
            expect(jsonDecode(request.body), {
              'emotion_tag_ids': [101, 102, 201],
            });
            return _json({'detail': 'Flower not found'}, 404);
          }
          return _json(_saved(6));
        }),
      );
      addTearDown(service.close);
      final result = await service.saveTagsAndFinalize(
        tokens: _tokens,
        diaryId: 91,
        tagIds: [101, 102, 201],
      );
      expect(result.emotionId, 6);
      expect(result.emotionName, '애틋함/수용');
      expect(result.hasFlower, isFalse);
      expect(result.isFinalized, isFalse);
      expect(result.flowerName, isEmpty);
      expect(
        result.recordDate,
        DateTime.parse('2026-10-28T12:00:00Z').toLocal(),
      );
      expect(requests, [
        'POST /api/v1/diaries/91/finalize',
        'GET /api/v1/diaries/91',
      ]);
    },
  );

  test(
    'unsaved tags and a different saved selection cannot appear successful',
    () async {
      for (final selected in [
        <Map<String, int>>[],
        [
          {'id': 101},
          {'id': 102},
          {'id': 202},
        ],
      ]) {
        final service = DiaryService(
          client: MockClient(
            (request) async => request.method == 'POST'
                ? _json({'detail': 'Flower not found'}, 404)
                : _json(_saved(6)..['selected_emotion_tags'] = selected),
          ),
        );
        addTearDown(service.close);
        await expectLater(
          service.saveTagsAndFinalize(
            tokens: _tokens,
            diaryId: 91,
            tagIds: [101, 102, 201],
          ),
          throwsA(isA<DiaryException>()),
        );
      }
    },
  );

  test('other errors are not swallowed as a saved label', () async {
    final service = DiaryService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        return _json({'detail': 'Diary not found'}, 404);
      }),
    );
    addTearDown(service.close);
    await expectLater(
      service.saveTagsAndFinalize(
        tokens: _tokens,
        diaryId: 91,
        tagIds: [101, 102, 201],
      ),
      throwsA(
        isA<DiaryException>().having(
          (e) => e.message,
          'message',
          'Diary not found',
        ),
      ),
    );
  });

  test('unconfirmed AI-only drafts stay out of the calendar', () async {
    final data = await _load(_saved(6)..['selected_emotion_tags'] = []);
    expect(data.diaries, isEmpty);
    expect(
      Diary.hasSavedEmotion(_saved(6)..['correct_emotion_id'] = null),
      isFalse,
    );
  });

  test('saved label survives reopening a group with no flower', () async {
    final data = await _load(_saved(6));
    expect(data.diaries.single.hasFlower, isFalse);
    expect(data.diaries.single.isFinalized, isFalse);
    expect(data.diaries.single.flowerType.emotionId.id, 6);
    data.clear();
    await data.openGroup(_tokens, 7);
    expect(data.diaries.single.flowerType.emotionId.id, 6);
  });

  test(
    'the saved final emotion ID takes priority over nested display data',
    () async {
      final saved = _saved(6);
      saved['emotion'] = {
        'id': 1,
        'emotion': 'anger',
        'display_name': '분노/답답함',
      };
      final data = await _load(saved);
      expect(data.diaries.single.flowerType.emotionId.id, 6);
      expect(data.diaries.single.flowerType.emotionId.displayName, '애틋함/수용');
    },
  );

  test('changing a pending diary removes the stale classification', () async {
    final data = await _load(_saved(6), resetOnEdit: true);
    expect(await data.updateDiaryText(91, '수정', '새 내용'), isTrue);
    expect(data.diaries, isEmpty);
  });

  testWidgets(
    'original mood shapes render visibly instead of shrinking into the SVG canvas',
    (tester) async {
      for (final asset in _moodAssets) {
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SvgPicture.asset(
                  'assets/page2/moods/$asset.svg',
                  width: 66,
                  height: 66,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await tester.runAsync(() => boundary.toImage());
        final bytes = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        var visiblePixels = 0;
        for (var i = 3; i < bytes!.lengthInBytes; i += 4) {
          if (bytes.getUint8(i) > 128) visiblePixels++;
        }
        expect(
          visiblePixels,
          greaterThan(200),
          reason: '$asset must occupy a visible area',
        );
        image!.dispose();
      }
    },
  );

  for (var id = 0; id <= 6; id++) {
    testWidgets(
      'saved label $id renders its calendar color without a flower card',
      (tester) async {
        final data = await _load(_saved(id));
        final date = data.diaries.single.recordDate;
        await tester.pumpWidget(
          ChangeNotifierProvider<AppData>.value(
            value: data,
            child: MaterialApp(home: CalendarScreen(initialMonth: date)),
          ),
        );
        await tester.pumpAndSettle();
        final marker = find.byKey(
          ValueKey('calendar-emotion-${date.year}-${date.month}-${date.day}'),
        );
        await tester.ensureVisible(marker);
        final filter = tester.widget<ColorFiltered>(marker);
        expect(
          filter.colorFilter,
          ColorFilter.mode(Color(_colors[id]), BlendMode.srcIn),
        );
        final mood = tester.widget<SvgPicture>(
          find.byKey(
            ValueKey('calendar-mood-${date.year}-${date.month}-${date.day}'),
          ),
        );
        expect(
          (mood.bytesLoader as SvgAssetLoader).assetName,
          'assets/page2/moods/${_moodAssets[id]}.svg',
        );
        expect(mood.colorFilter, isNull);
        expect(
          find.byKey(
            ValueKey(
              'calendar-label-color-${date.year}-${date.month}-${date.day}',
            ),
          ),
          findsNothing,
        );
        expect(find.bySemanticsLabel('${_names[id]} 감정'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          ChangeNotifierProvider<AppData>.value(
            value: data,
            child: const MaterialApp(
              home: CalendarScreen(key: ValueKey('year')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final yearlyMood = tester.widget<SvgPicture>(
          find.byKey(
            ValueKey(
              'calendar-year-mood-${date.year}-${date.month}-${date.day}',
            ),
          ),
        );
        expect(
          (yearlyMood.bytesLoader as SvgAssetLoader).assetName,
          'assets/page2/moods/${_moodAssets[id]}.svg',
        );
        expect(yearlyMood.colorFilter, isNull);
      },
    );
  }

  testWidgets(
    'calendar uses the saved AI primary rather than the selected majority',
    (tester) async {
      final data = await _load(_saved(6, secondaryMajority: true));
      final date = data.diaries.single.recordDate;
      expect(data.diaries.single.flowerType.emotionId.id, 6);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppData>.value(
          value: data,
          child: MaterialApp(home: CalendarScreen(initialMonth: date)),
        ),
      );
      await tester.pumpAndSettle();
      final marker = find.byKey(
        ValueKey('calendar-emotion-${date.year}-${date.month}-${date.day}'),
      );
      await tester.ensureVisible(marker);
      expect(
        tester.widget<ColorFiltered>(marker).colorFilter,
        const ColorFilter.mode(Color(0xFFFF9131), BlendMode.srcIn),
      );
    },
  );

  testWidgets(
    'record completion shows the green placeholder and Next opens follow-up activities',
    (tester) async {
      final data = await _load(_saved(6));
      final date = data.diaries.single.recordDate;
      await tester.pumpWidget(
        ChangeNotifierProvider<AppData>.value(
          value: data,
          child: MaterialApp(
            home: DiaryResultScreen(
              finalization: DiaryFinalization(
                emotionId: 6,
                emotionName: '애틋함/수용',
                flowerName: '',
                flowerSentence: '',
                hasFlower: false,
                isFinalized: false,
                recordDate: date,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('감정 기록 완료'), findsOneWidget);
      expect(find.text('꽃 카드 준비 중'), findsOneWidget);
      final card = tester.widget<Container>(
        find.byKey(const ValueKey('pending-flower-card')),
      );
      expect((card.decoration as BoxDecoration).color, const Color(0xFF8BC34A));
      expect(find.text('캘린더에서 확인'), findsNothing);
      expect(find.byType(CalendarScreen), findsNothing);
      await tester.ensureVisible(find.text('다음'));
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarScreen), findsNothing);
      expect(find.byType(DiaryCareContentScreen), findsOneWidget);
    },
  );
}
