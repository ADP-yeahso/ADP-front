import '../screens/care_notebook/care_record_view_data.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Keeps successful writes when a later request fails, so retrying does not
/// duplicate the condition, behavior logs, or hospital visit.
class CareSaveProgress {
  int? conditionId;
  int? visitId;
  final Map<String, int> behaviorIds = {};
}

class CareNotebookService {
  CareNotebookService(this.api);
  final ApiService api;

  String _date(DateTime value) => value.toIso8601String().split('T').first;

  Future<List<CareRecordViewData>> list(
    AuthTokens tokens,
    int patientId,
  ) async {
    final care = CareApi(api);
    final conditions = await care.dailyConditions(tokens, patientId);
    final behaviors = await care.behaviorLogs(tokens, patientId);
    final visits = await care.hospitalVisits(tokens, patientId);
    bool matches(
      Map<String, dynamic> row,
      Map<String, dynamic> condition,
      String field,
    ) =>
        row['user_id'] == condition['user_id'] &&
        _date(DateTime.parse(row[field] as String).toLocal()) ==
            condition['record_date'];
    return conditions.map((row) {
      final medical = visits
          .where((visit) => matches(visit, row, 'visit_date'))
          .toList();
      final visit = medical.isEmpty ? <String, dynamic>{} : medical.first;
      return CareRecordViewData(
        date: DateTime.parse(row['record_date'] as String),
        mealStatus: row['meal_status'] as String,
        sleepStatus: row['sleep_status'] as String,
        bowelStatus: row['bowel_status'] as String,
        medicationStatus: row['medication_status'] as String,
        activityStatus: row['activity_status'] as String,
        moodStatus: row['mood_status'] as String,
        cognitiveStatus: row['cognitive_status'] as String,
        unusualChanges: behaviors
            .where((log) => matches(log, row, 'occurred_at'))
            .map((log) => log['behavior_type'] as String)
            .toList(),
        note: row['note'] as String? ?? '',
        hasMedicalUpdate: visit.isNotEmpty,
        hospitalDepartment: [
          visit['hospital_name'],
          visit['department'],
        ].whereType<String>().where((value) => value.isNotEmpty).join(' '),
        visitDetails: visit['visit_reason'] as String? ?? '',
        medicationChanges: visit['guardian_memo'] as String? ?? '',
        nextVisitDate: DateTime.tryParse('${visit['next_visit_date']}'),
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> save(
    AuthTokens tokens,
    int patientId,
    CareRecordViewData record,
    CareSaveProgress progress,
  ) async {
    final body = {
      'record_date': _date(record.date),
      'meal_status': record.mealStatus,
      'sleep_status': record.sleepStatus,
      'bowel_status': record.bowelStatus,
      'medication_status': record.medicationStatus,
      'activity_status': record.activityStatus,
      'mood_status': record.moodStatus,
      'cognitive_status': record.cognitiveStatus,
      'behavior_change': record.unusualChanges.isNotEmpty,
      'note': record.note,
    };
    if (progress.conditionId == null) {
      final saved = await CareApi(
        api,
      ).createDailyCondition(tokens, patientId, body);
      progress.conditionId = saved['id'] as int;
    } else {
      final updates = Map<String, dynamic>.from(body)..remove('record_date');
      await api.patch(
        '/care-notes/daily-conditions/${progress.conditionId}',
        tokens,
        updates,
      );
    }
    for (final type in progress.behaviorIds.keys.toList()) {
      if (!record.unusualChanges.contains(type)) {
        await api.delete(
          '/care-notes/behavior-logs/${progress.behaviorIds[type]}',
          tokens,
        );
        progress.behaviorIds.remove(type);
      }
    }
    for (final type in record.unusualChanges) {
      if (progress.behaviorIds.containsKey(type)) continue;
      final saved = await CareApi(api).createBehaviorLog(tokens, patientId, {
        'behavior_type': type,
        'occurred_at': record.date.toUtc().toIso8601String(),
      });
      progress.behaviorIds[type] = saved['id'] as int;
    }
    if (record.hasMedicalUpdate) {
      final visit = {
        'visit_date': _date(record.date),
        'hospital_name': record.hospitalDepartment,
        'visit_reason': record.visitDetails,
        'medication_changed': record.medicationChanges.isNotEmpty,
        'guardian_memo': record.medicationChanges,
        'next_visit_date': record.nextVisitDate == null
            ? null
            : _date(record.nextVisitDate!),
      };
      if (progress.visitId == null) {
        final saved = await CareApi(
          api,
        ).createHospitalVisit(tokens, patientId, visit);
        progress.visitId = saved['id'] as int;
      } else {
        await api.patch(
          '/care-notes/hospital-visits/${progress.visitId}',
          tokens,
          visit,
        );
      }
    } else if (progress.visitId != null) {
      await api.delete(
        '/care-notes/hospital-visits/${progress.visitId}',
        tokens,
      );
      progress.visitId = null;
    }
  }
}
