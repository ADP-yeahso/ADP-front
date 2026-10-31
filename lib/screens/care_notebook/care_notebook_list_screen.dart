import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/app_data.dart';
import 'care_notebook_write_screen.dart';
import 'care_notebook_detail_screen.dart';
import 'care_record_view_data.dart';
import 'care_notebook_widgets.dart';

Future<void> openCareNotebook(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/care-notebook'),
        builder: (_) => const CareNotebookListScreen(),
      ),
    );

class CareNotebookListScreen extends StatelessWidget {
  const CareNotebookListScreen({super.key});
  Future<void> _write(BuildContext context) async {
    final record = await Navigator.of(context).push<CareRecordViewData>(
      MaterialPageRoute(builder: (_) => const CareNotebookWriteScreen()),
    );
    if (!context.mounted || record == null) return;
    context.read<AppData>().addCareRecord(record);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('돌봄 기록이 임시 저장되었어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<AppData>().careRecords;
    return Scaffold(
      backgroundColor: careBackground,
      appBar: careAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CarePatientCard(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: records.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => Align(
                              alignment: const Alignment(0, -0.12),
                              child: SingleChildScrollView(
                                child: careAsset(
                                  'empty_state',
                                  width: 248,
                                  height: constraints.maxHeight
                                      .clamp(120, 278)
                                      .toDouble(),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _recordCard(context, records[index]),
                          ),
                  ),
                  const SizedBox(height: 16),
                  CareAssetButton(
                    asset: 'write_note_button',
                    label: '수첩 쓰기',
                    height: 48,
                    onTap: () => _write(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recordCard(
    BuildContext context,
    CareRecordViewData record,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CareNotebookDetailScreen(record: record),
        ),
      ),
      child: careFrame(
        'care_note_entry_frame',
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${DateFormat('yyyy.MM.dd').format(record.date)} ${const ['월', '화', '수', '목', '금', '토', '일'][record.date.weekday - 1]}요일',
              style: const TextStyle(fontSize: 13, color: careGreen),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: careDivider('entry_date_divider'),
            ),
            Row(
              children: [
                Expanded(child: _tag('식사 ${record.mealStatus}')),
                const SizedBox(width: 5),
                Expanded(child: _tag('수면 ${record.sleepStatus}')),
                const SizedBox(width: 5),
                Expanded(child: _tag('복약 ${record.medicationStatus}')),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(flex: 4, child: _tag('배변 ${record.bowelStatus}')),
                const SizedBox(width: 5),
                Expanded(
                  flex: 5,
                  child: _tag(
                    '평소와 다른 점 - ${record.unusualChanges.isEmpty ? '없음' : record.unusualChanges.join(', ')}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                careAsset('notes_label', width: 55, height: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.note.isEmpty ? '없음' : record.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            if (record.hasMedicalUpdate) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  careAsset('medical_record_label', width: 48, height: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [
                        record.hospitalDepartment,
                        record.visitDetails,
                        record.medicationChanges,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
  Widget _tag(String text) => SizedBox(
    height: 32,
    child: careFrame(
      'record_content_frame',
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
