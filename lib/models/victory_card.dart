class VictoryCard {
  final int id;
  final String text;
  final String emoji;
  bool isAccomplished;

  VictoryCard({
    required this.id,
    required this.text,
    required this.emoji,
    this.isAccomplished = false,
  });

  VictoryCard copyWith({
    int? id,
    String? text,
    String? emoji,
    bool? isAccomplished,
  }) {
    return VictoryCard(
      id: id ?? this.id,
      text: text ?? this.text,
      emoji: emoji ?? this.emoji,
      isAccomplished: isAccomplished ?? this.isAccomplished,
    );
  }

  static List<VictoryCard> getDefaultVictories() {
    return [
      VictoryCard(id: 0, text: "J'ai bu un grand verre d'eau", emoji: "💧"),
      VictoryCard(id: 1, text: "J'ai pris ma douche", emoji: "🚿"),
      VictoryCard(id: 2, text: "J'ai demandé de l'aide", emoji: "🙏"),
      VictoryCard(id: 3, text: "J'ai mangé un repas chaud", emoji: "🍽️"),
      VictoryCard(id: 4, text: "J'ai respiré 1 minute", emoji: "🌬️"),
      VictoryCard(id: 5, text: "J'ai posé le bébé 5 min", emoji: "🛋️"),
      VictoryCard(id: 6, text: "J'ai dit \"Non\"", emoji: "✋"),
      VictoryCard(id: 7, text: "J'ai souri", emoji: "😊"),
      VictoryCard(id: 8, text: "J'ai vu le soleil 5 min", emoji: "☀️"),
    ];
  }
}




