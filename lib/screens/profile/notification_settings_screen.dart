import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _familyRecord = true;
  bool _diaryReminder = true;
  bool _careRecommendation = true;
  bool _familyEmotion = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionLabel('가족 활동'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('새 가족 기록 알림'),
            subtitle: const Text('가족이 나무나 꽃을 새로 남기면 알려드려요'),
            value: _familyRecord,
            onChanged: (v) => setState(() => _familyRecord = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('가족 감정 상태 알림'),
            subtitle: const Text('가족 구성원의 감정에 어려움이 감지되면 알려드려요'),
            value: _familyEmotion,
            onChanged: (v) => setState(() => _familyEmotion = v),
          ),
          const SizedBox(height: 12),
          const _SectionLabel('나의 기록'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('일기 작성 리마인더'),
            subtitle: Text('매일 ${_reminderTime.format(context)}에 알려드려요'),
            value: _diaryReminder,
            onChanged: (v) => setState(() => _diaryReminder = v),
          ),
          if (_diaryReminder)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: TextButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('알림 시간 변경'),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('감정 케어 추천 알림'),
            subtitle: const Text('일기 분석 후 위로 문구·음악을 바로 알려드려요'),
            value: _careRecommendation,
            onChanged: (v) => setState(() => _careRecommendation = v),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black45)),
    );
  }
}
