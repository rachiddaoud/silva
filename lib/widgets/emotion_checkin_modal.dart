import 'package:flutter/material.dart';
import '../models/emotion.dart';

class EmotionCheckinModal extends StatefulWidget {
  final int victoriesCount;
  final Function(Emotion) onValidate;

  const EmotionCheckinModal({
    super.key,
    required this.victoriesCount,
    required this.onValidate,
  });

  @override
  State<EmotionCheckinModal> createState() => _EmotionCheckinModalState();
}

class _EmotionCheckinModalState extends State<EmotionCheckinModal> {
  Emotion? selectedEmotion;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF0F9FF),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Color(0xFFFFD4A3),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Comment vous sentez-vous *vraiment* aujourd'hui ?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A6B7A),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Color(0xFFFFD4A3),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: Emotion.emotions.map((emotion) {
                final isSelected = selectedEmotion == emotion;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedEmotion = emotion;
                    });
                  },
                  child: Container(
                    width: 80,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                emotion.moodColor,
                                emotion.moodColor.withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? emotion.moodColor.withValues(alpha: 0.6)
                            : emotion.moodColor.withValues(alpha: 0.3),
                        width: isSelected ? 2.5 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: emotion.moodColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: emotion.moodColor.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              emotion.emoji,
                              style: TextStyle(
                                fontSize: isSelected ? 32 : 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              emotion.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2C3E50),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedEmotion != null
                    ? () {
                        widget.onValidate(selectedEmotion!);
                        Navigator.of(context).pop();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF89CFF0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  disabledBackgroundColor: const Color(0xFFD0E8F5),
                  disabledForegroundColor: const Color(0xFFA8C4D6),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Valider la journée",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

