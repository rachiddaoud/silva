import 'emotion.dart';
import 'victory_card.dart';
import 'victory_repository.dart';

/// Represents a single day's journal entry.
/// 
/// Contains the user's emotion, optional comment, and completed victories
/// for a specific date.
class DayEntry {
  final DateTime date;
  final Emotion? emotion;
  final String? comment;
  final List<VictoryCard> victoryCards;

  const DayEntry({
    required this.date,
    this.emotion,
    this.comment,
    this.victoryCards = const [],
  });

  /// Returns true if this entry has no emotion recorded.
  bool get isEmpty => emotion == null;

  /// Returns the count of accomplished victories.
  int get accomplishedCount => victoryCards.where((v) => v.isAccomplished).length;

  /// Creates a copy of this entry with the given fields replaced.
  DayEntry copyWith({
    DateTime? date,
    Emotion? emotion,
    String? comment,
    List<VictoryCard>? victoryCards,
    bool clearEmotion = false,
    bool clearComment = false,
  }) {
    return DayEntry(
      date: date ?? this.date,
      emotion: clearEmotion ? null : (emotion ?? this.emotion),
      comment: clearComment ? null : (comment ?? this.comment),
      victoryCards: victoryCards ?? this.victoryCards,
    );
  }

  /// Converts this entry to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'emotionIndex': emotion != null ? Emotion.emotions.indexOf(emotion!) : null,
      'comment': comment,
      // Store full victory data for complete reconstruction
      'victoryCardsData': victoryCards.map((v) => v.toStateJson()).toList(),
      // Keep legacy format for backwards compatibility
      'victoryCardIds': victoryCards.map((v) => v.id).toList(),
    };
  }

  /// Creates a DayEntry from a JSON map.
  factory DayEntry.fromJson(Map<String, dynamic> json) {
    // Parse emotion
    final emotionIndex = json['emotionIndex'] as int?;
    Emotion? emotion;
    if (emotionIndex != null && 
        emotionIndex >= 0 && 
        emotionIndex < Emotion.emotions.length) {
      emotion = Emotion.emotions[emotionIndex];
    }

    // Parse victory cards
    List<VictoryCard> victoryCards = [];

    // Try new format first (full state data)
    if (json.containsKey('victoryCardsData')) {
      final cardsData = json['victoryCardsData'] as List<dynamic>? ?? [];
      victoryCards = VictoryRepository.fromStateJsonList(cardsData);
    } 
    // Fallback to legacy format (IDs only)
    else if (json.containsKey('victoryCardIds')) {
      final victoryCardIds = (json['victoryCardIds'] as List<dynamic>?)
          ?.map((id) => id as int)
          .toList() ?? [];
      
      victoryCards = victoryCardIds
          .map((id) => VictoryRepository.fromState(
                id: id,
                isAccomplished: true, // Legacy format implies accomplished
              ))
          .whereType<VictoryCard>()
          .toList();
    }

    return DayEntry(
      date: DateTime.parse(json['date'] as String),
      emotion: emotion,
      comment: json['comment'] as String?,
      victoryCards: victoryCards,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DayEntry) return false;
    
    return other.date == date &&
        other.emotion == emotion &&
        other.comment == comment &&
        _listEquals(other.victoryCards, victoryCards);
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        date,
        emotion,
        comment,
        Object.hashAll(victoryCards),
      );

  @override
  String toString() {
    return 'DayEntry(date: ${date.toIso8601String().substring(0, 10)}, '
        'emotion: ${emotion?.name ?? "none"}, '
        'victories: ${victoryCards.length})';
  }
}
