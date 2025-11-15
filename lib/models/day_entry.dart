import 'emotion.dart';
import 'victory_card.dart';

class DayEntry {
  final DateTime date;
  final Emotion? emotion; // Nullable pour les jours non remplis
  final String? comment;
  final List<VictoryCard> victoryCards;

  DayEntry({
    required this.date,
    this.emotion,
    this.comment,
    this.victoryCards = const [],
  });

  // Vérifier si l'entrée est vide (jour non rempli)
  bool get isEmpty => emotion == null;

  // Sérialisation JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'emotionIndex': emotion != null ? Emotion.emotions.indexOf(emotion!) : null,
      'comment': comment,
      'victoryCardIds': victoryCards.map((v) => v.id).toList(),
    };
  }

  // Désérialisation JSON
  factory DayEntry.fromJson(Map<String, dynamic> json) {
    final emotionIndex = json['emotionIndex'] as int?;
    Emotion? emotion;
    if (emotionIndex != null && 
        emotionIndex >= 0 && 
        emotionIndex < Emotion.emotions.length) {
      emotion = Emotion.emotions[emotionIndex];
    }

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

