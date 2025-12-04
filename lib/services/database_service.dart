import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/day_entry.dart';
import '../models/emotion.dart';
import '../models/victory_card.dart';
import '../models/victory_repository.dart';
import '../models/tree/tree_state.dart';
import '../models/app_category.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference _usersCollection() => _firestore.collection('users');

  DocumentReference _userDoc(String uid) => _usersCollection().doc(uid);

  CollectionReference _daysCollection(String uid) =>
      _userDoc(uid).collection('days');

  // Category
  Future<void> updateUserCategory(String uid, AppCategory category) async {
    try {
      await _userDoc(uid).set({
        'category': category.index,
        'categoryName': category.name, // Readable name for debugging
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user category: $e');
      rethrow;
    }
  }

  Future<AppCategory?> getUserCategory(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('category')) {
          final index = data['category'] as int;
          if (index >= 0 && index < AppCategory.values.length) {
            return AppCategory.values[index];
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user category: $e');
      return null;
    }
  }

  // Save or update a day entry
  Future<void> saveDayEntry(String uid, DayEntry entry) async {
    try {
      // Use date as document ID (YYYY-MM-DD) to ensure uniqueness per day
      final docId = _dateToDocId(entry.date);
      await _daysCollection(uid).doc(docId).set(entry.toJson());
    } catch (e) {
      debugPrint('Error saving day entry: $e');
      rethrow;
    }
  }

  // Get history as a stream
  Stream<List<DayEntry>> getHistoryStream(String uid) {
    return _daysCollection(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DayEntry.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
  
  // Get history as a Future (one-time fetch)
  Future<List<DayEntry>> getHistory(String uid) async {
    try {
      final snapshot = await _daysCollection(uid)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return DayEntry.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error getting history: $e');
      return [];
    }
  }

  // Check if yesterday exists, if not create empty
  Future<void> ensureYesterdayExists(String uid) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final docId = _dateToDocId(yesterday);

    final doc = await _daysCollection(uid).doc(docId).get();

    if (!doc.exists) {
      debugPrint('📝 Creating empty entry for yesterday: $docId');
      // Create empty entry for yesterday
      final emptyEntry = DayEntry(
        date: yesterday,
        emotion: null,
        comment: null,
        victoryCards: [],
      );
      await _daysCollection(uid).doc(docId).set(emptyEntry.toJson());
      debugPrint('✅ Empty entry created for yesterday');
    } else {
      debugPrint('✓ Yesterday entry already exists: $docId');
    }
  }

  // Create fake history for new users
  Future<void> createFakeHistory(String uid) async {
    final now = DateTime.now();
    final defaultVictories = VictoryRepository.defaultVictories;
    final random = Random();

    // Check if user already has data to avoid overwriting
    final snapshot = await _daysCollection(uid).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();

    // List of possible comments
    final possibleComments = [
      'Très belle journée, je me sens vraiment bien !',
      'Journée tranquille, quelques moments de repos.',
      'Journée difficile mais j\'ai tenu bon.',
      'Belle énergie aujourd\'hui !',
      'Petit à petit, jour après jour.',
      'J\'ai fait de mon mieux aujourd\'hui.',
      'Quelques moments difficiles mais j\'ai réussi à tenir.',
      'Journée calme et reposante.',
      'Je suis fière de mes petits pas.',
      'Chaque victoire compte, même les plus petites.',
      'J\'ai pris soin de moi aujourd\'hui.',
      'Journée chargée mais j\'ai géré.',
      null,
      null,
    ];

    // Generate data for past 7 days
    // Ensure at least 4 days are filled, one is empty
    final filledDaysCount = random.nextInt(4) + 4; // 4 to 7 filled
    final filledDaysIndices = <int>{};

    while (filledDaysIndices.length < filledDaysCount) {
      filledDaysIndices.add(random.nextInt(7));
    }
    
    // Ensure at least one empty day if we rolled 7 filled days (though requirement says "only one empty day", let's stick to "mostly filled")
    // Requirement: "fake data for the past 7 days with only one empty day and others filled"
    // Let's be precise: 6 filled, 1 empty.
    
    filledDaysIndices.clear();
    final emptyDayIndex = random.nextInt(7); // 0 to 6
    for (int i = 0; i < 7; i++) {
      if (i != emptyDayIndex) {
        filledDaysIndices.add(i);
      }
    }

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i + 1));
      final isFilled = filledDaysIndices.contains(i);
      final docId = _dateToDocId(date);
      final docRef = _daysCollection(uid).doc(docId);

      if (isFilled) {
        final emotionIndex = random.nextInt(Emotion.emotions.length);
        final emotion = Emotion.emotions[emotionIndex];

        final commentIndex = random.nextInt(possibleComments.length);
        final comment = possibleComments[commentIndex];

        final numVictories = random.nextInt(6) + 2;
        final shuffledVictories = List<VictoryCard>.from(defaultVictories);
        shuffledVictories.shuffle(random);
        final selectedVictories = shuffledVictories.take(numVictories).toList();
        // Mark them as accomplished for the history
        final accomplishedVictories = selectedVictories.map((v) => v.copyWith(isAccomplished: true)).toList();

        final entry = DayEntry(
          date: date,
          emotion: emotion,
          comment: comment,
          victoryCards: accomplishedVictories,
        );
        batch.set(docRef, entry.toJson());
      } else {
        final entry = DayEntry(
          date: date,
          emotion: null,
          comment: null,
          victoryCards: [],
        );
        batch.set(docRef, entry.toJson());
      }
    }

    await batch.commit();
  }

  String _dateToDocId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Update victories for today - create or update entry
  Future<void> updateTodayVictories(String uid, List<VictoryCard> victories) async {
    final now = DateTime.now();
    final docId = _dateToDocId(now);
    final docRef = _daysCollection(uid).doc(docId);

    final doc = await docRef.get();
    final accomplishedVictories = victories.where((v) => v.isAccomplished).toList();
    
    if (doc.exists) {
      // Entry exists - update it while preserving emotion and comment
      final existingEntry = DayEntry.fromJson(doc.data() as Map<String, dynamic>);
      final updatedEntry = DayEntry(
        date: now,
        emotion: existingEntry.emotion, // Preserve existing emotion
        comment: existingEntry.comment, // Preserve existing comment
        victoryCards: accomplishedVictories,
      );
      await docRef.set(updatedEntry.toJson());
    } else {
      // Entry doesn't exist - create new entry with victories but no emotion yet
      final newEntry = DayEntry(
        date: now,
        emotion: null, // No emotion until day is completed
        comment: null,
        victoryCards: accomplishedVictories,
      );
      await docRef.set(newEntry.toJson());
      debugPrint('📝 Created new today entry with ${accomplishedVictories.length} victories');
    }
  }

  // Check if today's entry exists
  Future<DayEntry?> getTodayDayEntry(String uid) async {
    try {
      final now = DateTime.now();
      final docId = _dateToDocId(now);
      final doc = await _daysCollection(uid).doc(docId).get();
      
      if (doc.exists) {
        return DayEntry.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking today entry: $e');
      return null;
    }
  }

  // Check if yesterday's entry exists
  Future<DayEntry?> getYesterdayDayEntry(String uid) async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final docId = _dateToDocId(yesterday);
      final doc = await _daysCollection(uid).doc(docId).get();
      
      if (doc.exists) {
        return DayEntry.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking yesterday entry: $e');
      return null;
    }
  }

  // Delete a specific victory from a day entry (hard delete)
  Future<void> deleteVictoryFromEntry(String uid, DateTime date, int victoryId) async {
    try {
      final docId = _dateToDocId(date);
      final docRef = _daysCollection(uid).doc(docId);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final entry = DayEntry.fromJson(doc.data() as Map<String, dynamic>);
        // Remove the victory with the specified ID
        final updatedVictories = entry.victoryCards.where((v) => v.id != victoryId).toList();
        
        if (updatedVictories.isEmpty) {
          // If no victories left, delete the entire day entry
          await docRef.delete();
          debugPrint('🗑️ Deleted entire day entry for $docId (no victories left)');
        } else {
          // Update the entry with remaining victories
          final updatedEntry = DayEntry(
            date: entry.date,
            emotion: entry.emotion,
            comment: entry.comment,
            victoryCards: updatedVictories,
          );
          await docRef.set(updatedEntry.toJson());
          debugPrint('🗑️ Deleted victory $victoryId from $docId');
        }
      }
    } catch (e) {
      debugPrint('Error deleting victory from entry: $e');
      rethrow;
    }
  }

  // Delete an entire day entry (hard delete)
  Future<void> deleteDayEntry(String uid, DateTime date) async {
    try {
      final docId = _dateToDocId(date);
      await _daysCollection(uid).doc(docId).delete();
      debugPrint('🗑️ Deleted day entry for $docId');
    } catch (e) {
      debugPrint('Error deleting day entry: $e');
      rethrow;
    }
  }

  // Tree Persistence
  Future<void> saveTreeState(String uid, TreeState tree) async {
    try {
      await _userDoc(uid).collection('tree').doc('current').set(tree.toJson());
    } catch (e) {
      debugPrint('Error saving tree state: $e');
      rethrow;
    }
  }

  Future<TreeState?> getTreeState(String uid) async {
    try {
      final doc = await _userDoc(uid).collection('tree').doc('current').get();
      if (doc.exists && doc.data() != null) {
        return TreeState.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting tree state: $e');
      return null;
    }
  }
}
