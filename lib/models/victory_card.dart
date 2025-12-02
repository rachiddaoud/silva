class VictoryCard {
  final int id;
  final String text;
  final String emoji;
  final int spriteId; // ID for sprite sheet extraction
  bool isAccomplished;
  DateTime? timestamp; // When the victory was accomplished

  VictoryCard({
    required this.id,
    required this.text,
    required this.emoji,
    required this.spriteId,
    this.isAccomplished = false,
    this.timestamp,
  });

  VictoryCard copyWith({
    int? id,
    String? text,
    String? emoji,
    int? spriteId,
    bool? isAccomplished,
    DateTime? timestamp,
  }) {
    return VictoryCard(
      id: id ?? this.id,
      text: text ?? this.text,
      emoji: emoji ?? this.emoji,
      spriteId: spriteId ?? this.spriteId,
      isAccomplished: isAccomplished ?? this.isAccomplished,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static List<VictoryCard> getDefaultVictories() {
    return [
      VictoryCard(
        id: 0,
        text: "J'ai bu un grand verre d'eau",
        emoji: "💧",
        spriteId: 0,
      ),
      VictoryCard(
        id: 1,
        text: "J'ai pris ma douche",
        emoji: "🚿",
        spriteId: 1,
      ),
      VictoryCard(
        id: 2,
        text: "J'ai demandé de l'aide",
        emoji: "🙏",
        spriteId: 2,
      ),
      VictoryCard(
        id: 3,
        text: "J'ai mangé un repas chaud",
        emoji: "🍽️",
        spriteId: 3,
      ),
      VictoryCard(
        id: 4,
        text: "J'ai respiré 1 minute",
        emoji: "🌬️",
        spriteId: 4,
      ),
      VictoryCard(
        id: 5,
        text: "J'ai posé le bébé 5 min",
        emoji: "🛋️",
        spriteId: 5,
      ),
      VictoryCard(
        id: 6,
        text: "J'ai dit \"Non\"",
        emoji: "✋",
        spriteId: 6,
      ),
      VictoryCard(
        id: 7,
        text: "J'ai souri",
        emoji: "😊",
        spriteId: 7,
      ),
      VictoryCard(
        id: 8,
        text: "J'ai vu le soleil 5 min",
        emoji: "☀️",
        spriteId: 8,
      ),
    ];
  }
}




