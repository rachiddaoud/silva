import 'emotion.dart';
import 'victory_card.dart';

class DayEntry {
  final DateTime date;
  final Emotion emotion;
  final String? comment;
  final List<VictoryCard> victoryCards;

  DayEntry({
    required this.date,
    required this.emotion,
    this.comment,
    required this.victoryCards,
  });

  // Sérialisation JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'emotionIndex': Emotion.emotions.indexOf(emotion),
      'comment': comment,
      'victoryCardIds': victoryCards.map((v) => v.id).toList(),
    };
  }

  // Désérialisation JSON
  factory DayEntry.fromJson(Map<String, dynamic> json) {
    final emotionIndex = json['emotionIndex'] as int;
    final emotion = emotionIndex >= 0 && emotionIndex < Emotion.emotions.length
        ? Emotion.emotions[emotionIndex]
        : Emotion.emotions[3]; // Par défaut: Bof / Neutre

    final victoryCardIds = (json['victoryCardIds'] as List<dynamic>?)
            ?.map((id) => id as int)
            .toList() ??
        [];
    
    final defaultVictories = VictoryCard.getDefaultVictories();
    final victoryCards = victoryCardIds
        .map((id) => defaultVictories.firstWhere(
              (v) => v.id == id,
              orElse: () => defaultVictories.first,
            ))
        .toList();

    return DayEntry(
      date: DateTime.parse(json['date'] as String),
      emotion: emotion,
      comment: json['comment'] as String?,
      victoryCards: victoryCards,
    );
  }
}

