import 'app_category.dart';
import 'victory_card.dart';

/// Doodle image paths for victories.
abstract class VictoryImages {
  VictoryImages._();

  static const String drink = 'assets/doodles/drink-removebg-preview.png';
  static const String shower = 'assets/doodles/shower-removebg-preview.png';
  static const String help = 'assets/doodles/help-removebg-preview.png';
  static const String eat = 'assets/doodles/eat-removebg-preview.png';
  static const String breath = 'assets/doodles/breath-removebg-preview.png';
  static const String sleep = 'assets/doodles/sleep-removebg-preview.png';
  static const String stop = 'assets/doodles/stop-removebg-preview.png';
  static const String smile = 'assets/doodles/smile-removebg-preview.png';
  static const String walk = 'assets/doodles/walk-removebg-preview.png';
  static const String deepBreath = 'assets/doodles/deep_breath.png';
  static const String resting = 'assets/doodles/resting.png';
  static const String snack = 'assets/doodles/snack.png';
  static const String tidy = 'assets/doodles/tidy.png';

  // New images
  static const String breakTime = 'assets/doodles/break.png';
  static const String calling = 'assets/doodles/calling.png';
  static const String deconnecting = 'assets/doodles/deconnecting.png';
  static const String deepBreathing = 'assets/doodles/deep_breathing.png';
  static const String exercice = 'assets/doodles/exercice.png';
  static const String hydrating = 'assets/doodles/pregenant_hydrating.png';
  static const String pregnantDrinking = 'assets/doodles/pregenant_drinking.png';
  static const String pregnantWalking = 'assets/doodles/pregenant_walking.png';
  static const String readingBook = 'assets/doodles/reading_book.png';
  static const String resting1 = 'assets/doodles/resting_1.png';
  static const String talkingBaby = 'assets/doodles/pregenant_talking_baby.png';
  static const String tidy2 = 'assets/doodles/tidy_2.png';
  static const String vitamine = 'assets/doodles/pregenant_vitamine.png';
}

/// Victory ID ranges by category:
/// - futureMaman:           100-199
/// - nouvelleMaman:         200-299
/// - sereniteQuotidienne:   300-399
///
/// Repository providing victory card templates organized by category.
/// 
/// This class separates the static victory definitions from the VictoryCard model,
/// following the Single Responsibility Principle.
/// 
/// Usage:
/// ```dart
/// // Get victories for a specific category
/// final victories = VictoryRepository.getVictoriesForCategory(AppCategory.futureMaman);
/// 
/// // Get default victories (for nouvelleMaman category)
/// final defaults = VictoryRepository.defaultVictories;
/// 
/// // Reconstruct a victory from stored state
/// final victory = VictoryRepository.fromState(id: 200, isAccomplished: true, timestamp: DateTime.now());
/// ```
abstract class VictoryRepository {
  VictoryRepository._();

  /// Victory templates for future mothers (pregnancy). IDs: 100-199
  static const List<VictoryCard> _futureMamanVictories = [
    VictoryCard(id: 100, text: "J'ai pris mes vitamines", imagePath: VictoryImages.vitamine),
    VictoryCard(id: 101, text: "J'ai bu 2L d'eau", imagePath: VictoryImages.pregnantDrinking),
    VictoryCard(id: 102, text: "J'ai surélevé mes jambes", imagePath: VictoryImages.resting1),
    VictoryCard(id: 103, text: "J'ai hydraté mon ventre", imagePath: VictoryImages.hydrating),
    VictoryCard(id: 104, text: "J'ai parlé au bébé", imagePath: VictoryImages.talkingBaby),
    VictoryCard(id: 105, text: "Petite marche (15 min)", imagePath: VictoryImages.pregnantWalking),
    VictoryCard(id: 106, text: "J'ai préparé une collation saine", imagePath: VictoryImages.snack),
    VictoryCard(id: 107, text: "Je me suis reposé", imagePath: VictoryImages.resting1),
    VictoryCard(id: 108, text: "J'ai respiré profondément", imagePath: VictoryImages.deepBreathing),
  ];

  /// Victory templates for new mothers (postpartum). IDs: 200-299
  static const List<VictoryCard> _nouvelleMamanVictories = [
    VictoryCard(id: 200, text: "J'ai bu un grand verre d'eau", imagePath: VictoryImages.drink),
    VictoryCard(id: 201, text: "J'ai pris ma douche", imagePath: VictoryImages.shower),
    VictoryCard(id: 202, text: "J'ai demandé de l'aide", imagePath: VictoryImages.help),
    VictoryCard(id: 203, text: "J'ai mangé un repas chaud", imagePath: VictoryImages.eat),
    VictoryCard(id: 204, text: "J'ai respiré 1 minute", imagePath: VictoryImages.deepBreathing),
    VictoryCard(id: 205, text: "J'ai posé le bébé 5 min", imagePath: VictoryImages.breakTime),
    VictoryCard(id: 206, text: "J'ai dit \"Non\"", imagePath: VictoryImages.stop),
    VictoryCard(id: 207, text: "J'ai souri", imagePath: VictoryImages.smile),
    //VictoryCard(id: 208, text: "J'ai vu le soleil 5 min", imagePath: VictoryImages.walk),
    VictoryCard(id: 210, text: "J'ai fait une sieste", imagePath: VictoryImages.resting1),
  ];

  /// Victory templates for daily serenity (general wellness). IDs: 300-399
  static const List<VictoryCard> _sereniteQuotidienneVictories = [
    VictoryCard(id: 300, text: "J'ai bu de l'eau", imagePath: VictoryImages.drink),
    VictoryCard(id: 301, text: "Déconnexion écrans (1h)", imagePath: VictoryImages.deconnecting),
    VictoryCard(id: 302, text: "J'ai lu 10 pages", imagePath: VictoryImages.readingBook),
    VictoryCard(id: 303, text: "J'ai rangé un petit espace", imagePath: VictoryImages.tidy2),
    VictoryCard(id: 304, text: "J'ai médité", imagePath: VictoryImages.deepBreathing),
    VictoryCard(id: 305, text: "J'ai appelé un(e) ami(e)", imagePath: VictoryImages.calling),
    VictoryCard(id: 306, text: "J'ai fait une pause", imagePath: VictoryImages.breakTime),
    VictoryCard(id: 307, text: "J'ai fait de l'exercice", imagePath: VictoryImages.exercice),
    VictoryCard(id: 308, text: "J'ai pris un moment pour moi", imagePath: VictoryImages.resting1),
  ];

  /// All victory templates indexed by ID for quick lookup.
  static final Map<int, VictoryCard> _allVictoriesById = _buildVictoryIndex();

  static Map<int, VictoryCard> _buildVictoryIndex() {
    final map = <int, VictoryCard>{};
    for (final victory in _futureMamanVictories) {
      map[victory.id] = victory;
    }
    for (final victory in _nouvelleMamanVictories) {
      map[victory.id] = victory;
    }
    for (final victory in _sereniteQuotidienneVictories) {
      map[victory.id] = victory;
    }
    return map;
  }

  /// Returns fresh victory cards for the specified category.
  /// 
  /// The returned cards are new instances with [isAccomplished] set to false.
  static List<VictoryCard> getVictoriesForCategory(AppCategory category) {
    switch (category) {
      case AppCategory.futureMaman:
        return List.unmodifiable(_futureMamanVictories);
      case AppCategory.nouvelleMaman:
        return List.unmodifiable(_nouvelleMamanVictories);
      case AppCategory.sereniteQuotidienne:
        return List.unmodifiable(_sereniteQuotidienneVictories);
    }
  }

  /// Returns the default victories (nouvelleMaman category).
  static List<VictoryCard> get defaultVictories {
    return List.unmodifiable(_nouvelleMamanVictories);
  }

  /// Looks up a victory template by its ID.
  /// 
  /// Returns null if no victory with the given ID exists.
  static VictoryCard? getById(int id) {
    return _allVictoriesById[id];
  }

  /// Reconstructs a VictoryCard from stored state data.
  /// 
  /// This combines the template data (text, imagePath) from the repository
  /// with the stored state (isAccomplished, timestamp).
  /// 
  /// Returns null if no victory template with the given ID exists.
  static VictoryCard? fromState({
    required int id,
    required bool isAccomplished,
    DateTime? timestamp,
  }) {
    final template = _allVictoriesById[id];
    if (template == null) return null;

    return template.copyWith(
      isAccomplished: isAccomplished,
      timestamp: timestamp,
    );
  }

  /// Reconstructs a VictoryCard from a state JSON map.
  /// 
  /// The JSON should contain 'id', 'isAccomplished', and optionally 'timestamp'.
  /// Returns null if no victory template with the given ID exists.
  static VictoryCard? fromStateJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    if (id == null) return null;

    final isAccomplished = json['isAccomplished'] as bool? ?? false;
    
    DateTime? timestamp;
    final timestampValue = json['timestamp'];
    if (timestampValue is String) {
      timestamp = DateTime.tryParse(timestampValue);
    } else if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    }

    return fromState(
      id: id,
      isAccomplished: isAccomplished,
      timestamp: timestamp,
    );
  }

  /// Reconstructs multiple victory cards from a list of state JSON maps.
  /// 
  /// Invalid entries (with missing or unknown IDs) are filtered out.
  static List<VictoryCard> fromStateJsonList(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map((json) => fromStateJson(json))
        .whereType<VictoryCard>()
        .toList();
  }

  /// Returns all available victory IDs for the given category.
  static Set<int> getIdsForCategory(AppCategory category) {
    return getVictoriesForCategory(category).map((v) => v.id).toSet();
  }
}
