import 'package:flutter/material.dart';
import '../../../models/emotion_model.dart';
import 'diary_loading_screen.dart';

class DiaryEmotionSelectScreen extends StatefulWidget {
  const DiaryEmotionSelectScreen({super.key});

  @override
  State<DiaryEmotionSelectScreen> createState() =>
      _DiaryEmotionSelectScreenState();
}

class _DiaryEmotionSelectScreenState extends State<DiaryEmotionSelectScreen> {
  final List<EmotionModel> _selectedEmotions = [];
  static const int _maxSelection = 3;

  final List<List<EmotionModel>> _scatteredEmotions = const [
    [
      EmotionModel(name: '죄책감', color: Color(0xFFD09ED7)),
      EmotionModel(name: '애틋함', color: Color(0xFFFFE367)),
      EmotionModel(name: '슬픔', color: Color(0xFFE36887)),
    ],
    [
      EmotionModel(name: '분노', color: Color(0xFFE36887)),
      EmotionModel(name: '고마움', color: Color(0xFFFFE367)),
      EmotionModel(name: '후회감', color: Color(0xFF5EA7FF)),
    ],
    [
      EmotionModel(name: '애정', color: Color(0xFFE36887)),
      EmotionModel(name: '자책', color: Color(0xFFD09ED7)),
      EmotionModel(name: '안도감', color: Color(0xFFFFE367)),
    ],
    [
      EmotionModel(name: '답답함', color: Color(0xFF5EA7FF)),
      EmotionModel(name: '초조함', color: Color(0xFFD09ED7)),
      EmotionModel(name: '소진', color: Color(0xFF9E9E9E)),
    ],
  ];

  void _toggleEmotion(EmotionModel emotion) {
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else {
        if (_selectedEmotions.length < _maxSelection) {
          _selectedEmotions.add(emotion);
        }
      }
    });
  }

  Widget _buildEmotionButton(EmotionModel emotion) {
    final isSelected = _selectedEmotions.contains(emotion);
    final isMaxReached = _selectedEmotions.length >= _maxSelection;
    final isDisabled = !isSelected && isMaxReached;

    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleEmotion(emotion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? emotion.color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isDisabled && !isSelected) ? Colors.grey.shade300 : emotion.color,
            width: 1.5,
          ),
        ),
        child: Text(
          emotion.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected 
                ? ((emotion.color == const Color(0xFFFFE367)) ? Colors.black87 : Colors.white)
                : ((isDisabled && !isSelected) ? Colors.grey : Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Character Image Placeholder
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '오늘 느낀 감정은\n어떤 건가요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Emotion Buttons Staggered Layout
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEmotionButton(_scatteredEmotions[0][0]),
                          const SizedBox(width: 16),
                          _buildEmotionButton(_scatteredEmotions[0][1]),
                          const SizedBox(width: 16),
                          _buildEmotionButton(_scatteredEmotions[0][2]),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEmotionButton(_scatteredEmotions[1][0]),
                            const SizedBox(width: 20),
                            _buildEmotionButton(_scatteredEmotions[1][1]),
                            const SizedBox(width: 16),
                            _buildEmotionButton(_scatteredEmotions[1][2]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEmotionButton(_scatteredEmotions[2][0]),
                            const SizedBox(width: 24),
                            _buildEmotionButton(_scatteredEmotions[2][1]),
                            const SizedBox(width: 20),
                            _buildEmotionButton(_scatteredEmotions[2][2]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEmotionButton(_scatteredEmotions[3][0]),
                            const SizedBox(width: 16),
                            _buildEmotionButton(_scatteredEmotions[3][1]),
                            const SizedBox(width: 20),
                            _buildEmotionButton(_scatteredEmotions[3][2]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Selection Counter
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedEmotions.length} / $_maxSelection',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        '이전으로',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedEmotions.length != _maxSelection
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DiaryLoadingScreen(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '다음으로',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
