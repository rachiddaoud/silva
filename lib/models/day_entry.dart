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
      // Nouveau format : sauvegarder l'état complet
      'victoryCardsData': victoryCards.map((v) => {
        'id': v.id,
        'isAccomplished': v.isAccomplished,
        'timestamp': v.timestamp?.toIso8601String(),
      }).toList(),
      // Garder l'ancien format pour compatibilité descendante si nécessaire (optionnel)
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

    final defaultVictories = VictoryCard.getDefaultVictories();
    List<VictoryCard> victoryCards = [];

    // Essayer le nouveau format d'abord
    if (json.containsKey('victoryCardsData')) {
      final cardsData = (json['victoryCardsData'] as List<dynamic>);
      victoryCards = cardsData.map((data) {
        final map = data as Map<String, dynamic>;
        final id = map['id'] as int;
        final isAccomplished = map['isAccomplished'] as bool? ?? true;
        final timestampString = map['timestamp'] as String?;
        final timestamp = timestampString != null ? DateTime.parse(timestampString) : null;
        
        final defaultCard = defaultVictories.firstWhere(
          (v) => v.id == id,
          orElse: () => defaultVictories.first,
        );
        return defaultCard.copyWith(
          isAccomplished: isAccomplished,
          timestamp: timestamp,
        );
      }).toList();
    } 
    // Fallback sur l'ancien format (IDs seulement)
    else {
      final victoryCardIds = (json['victoryCardIds'] as List<dynamic>?)
              ?.map((id) => id as int)
              .toList() ??
          [];
      
      victoryCards = victoryCardIds.map((id) {
        final defaultCard = defaultVictories.firstWhere(
          (v) => v.id == id,
          orElse: () => defaultVictories.first,
        );
        // FIX: Si on charge depuis les IDs (ancien format), on suppose qu'elles sont accomplies
        // car l'historique ne stockait que les cartes sélectionnées/accomplies.
        return defaultCard.copyWith(isAccomplished: true);
      }).toList();
    }

    return DayEntry(
      date: DateTime.parse(json['date'] as String),
      emotion: emotion,
      comment: json['comment'] as String?,
      victoryCards: victoryCards,
    );
  }
}

