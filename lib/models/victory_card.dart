import 'package:flutter/foundation.dart';

/// Immutable model representing a victory card.
/// 
/// Victory cards represent small daily accomplishments that users can track.
/// Each card has a unique [id], display [text], and [imagePath] for
/// visual representation.
/// 
/// The [isAccomplished] and [timestamp] fields track the completion state.
/// Use [copyWith] to create modified copies since this class is immutable.
@immutable
class VictoryCard {
  final int id;
  final String text;
  final String imagePath;
  final bool isAccomplished;
  final DateTime? timestamp;

  const VictoryCard({
    required this.id,
    required this.text,
    required this.imagePath,
    this.isAccomplished = false,
    this.timestamp,
  });

  /// Creates a copy of this victory card with the given fields replaced.
  VictoryCard copyWith({
    int? id,
    String? text,
    String? imagePath,
    bool? isAccomplished,
    DateTime? timestamp,
    bool clearTimestamp = false,
  }) {
    return VictoryCard(
      id: id ?? this.id,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      isAccomplished: isAccomplished ?? this.isAccomplished,
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
    );
  }

  /// Creates a VictoryCard from a JSON map.
  factory VictoryCard.fromJson(Map<String, dynamic> json) {
    final timestampValue = json['timestamp'];
    DateTime? timestamp;
    
    if (timestampValue is String) {
      timestamp = DateTime.tryParse(timestampValue);
    } else if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    }

    return VictoryCard(
      id: json['id'] as int,
      text: json['text'] as String,
      imagePath: json['imagePath'] as String,
      isAccomplished: json['isAccomplished'] as bool? ?? false,
      timestamp: timestamp,
    );
  }

  /// Converts this victory card to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'imagePath': imagePath,
      'isAccomplished': isAccomplished,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  /// Creates a minimal JSON representation for storage (only state, not template data).
  /// Use this when the template data can be reconstructed from the repository.
  Map<String, dynamic> toStateJson() {
    return {
      'id': id,
      'isAccomplished': isAccomplished,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VictoryCard &&
        other.id == id &&
        other.text == text &&
        other.imagePath == imagePath &&
        other.isAccomplished == isAccomplished &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      text,
      imagePath,
      isAccomplished,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'VictoryCard(id: $id, text: $text, isAccomplished: $isAccomplished)';
  }
}
