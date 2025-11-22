import 'package:flutter/material.dart';
import 'package:ma_bulle/models/tree_model.dart';
import 'package:ma_bulle/services/preferences_service.dart';
import 'package:ma_bulle/services/tree_service.dart';
import 'package:ma_bulle/widgets/procedural_tree_widget.dart' hide TreeParameters;
import 'package:ma_bulle/models/emotion.dart';
import 'package:ma_bulle/models/day_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ma_bulle/services/database_service.dart';

class HomeTreeWidget extends StatefulWidget {
  const HomeTreeWidget({super.key});

  @override
  State<HomeTreeWidget> createState() => _HomeTreeWidgetState();
}

class _HomeTreeWidgetState extends State<HomeTreeWidget> {
  late TreeParameters _treeParameters;
  final TreeController _treeController = TreeController();
  bool _isLoading = true;
  List<String> _simulationLogs = [];

  @override
  void initState() {
    super.initState();
    _treeParameters = const TreeParameters(seed: 12345); 
    _loadTreeData();
  }

  Future<void> _loadTreeData() async {
    setState(() {
      _isLoading = true;
      _simulationLogs.clear();
      _simulationLogs.add("Chargement de l'arbre...");
    });

    try {
      // 1. Charger l'arbre existant
      Tree? tree = await PreferencesService.getTreeState();
      
      // 2. Si pas d'arbre, en créer un nouveau
      if (tree == null) {
        _simulationLogs.add("Aucun arbre sauvegardé, création d'un nouvel arbre.");
        tree = TreeGenerator.generateTreeStructure(
          growthLevel: 0.2, // Niveau initial
          treeSize: 250,
          parameters: _treeParameters,
        );
      } else {
        _simulationLogs.add("Arbre chargé (âge: ${tree.age}).");
      }
      
      // 3. Mettre à jour le contrôleur
      _treeController.setTree(tree);
      
      // 4. Simuler les jours manquants
      final lastUpdate = await PreferencesService.getLastTreeUpdateDate();
      final now = DateTime.now();
      
      _simulationLogs.add("Dernière mise à jour: ${lastUpdate?.toIso8601String() ?? 'Jamais'}");
      
      // Si c'est la première fois ou si on a changé de jour
      if (lastUpdate == null || !_isSameDay(lastUpdate, now)) {
        // FIX: Utiliser la même source de données que l'historique (Firestore si connecté)
        List<DayEntry> history = [];
        final user = FirebaseAuth.instance.currentUser;
        
        if (user != null) {
          _simulationLogs.add("Utilisateur connecté: ${user.uid}");
          try {
            history = await DatabaseService().getHistory(user.uid);
            _simulationLogs.add("Historique chargé depuis Firestore (${history.length} entrées)");
          } catch (e) {
            _simulationLogs.add("Erreur chargement Firestore: $e");
            // Fallback local si erreur
            history = await PreferencesService.getHistory();
            _simulationLogs.add("Fallback sur historique local (${history.length} entrées)");
          }
        } else {
          _simulationLogs.add("Utilisateur non connecté -> Historique local");
          history = await PreferencesService.getHistory();
        }
        
        // Déterminer la date de début de simulation
        DateTime startDate;
        if (lastUpdate != null) {
          startDate = lastUpdate.add(const Duration(days: 1));
        } else {
          // Si jamais update -> commencer au début de l'historique
          if (history.isNotEmpty) {
            // Trouver la date la plus ancienne dans l'historique
            startDate = history.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
          } else {
            startDate = now.subtract(const Duration(days: 30)); // Fallback si historique vide
          }
        }
        
        _simulationLogs.add("Début simulation depuis: ${startDate.toIso8601String().split('T')[0]}");
        _simulationLogs.add("Historique contient ${history.length} entrées:");
        for (var h in history) {
           _simulationLogs.add(" - ${h.date.toString()} (V:${h.victoryCards.length}, E:${h.emotion?.name})");
        }
        
        // Itérer jour par jour jusqu'à hier (exclu aujourd'hui)
        int daysSimulated = 0;
        // Calculer le nombre de jours à simuler
        final daysToSimulate = now.difference(startDate).inDays;
        
        for (int i = 0; i <= daysToSimulate; i++) { 
          final date = startDate.add(Duration(days: i));
          if (date.isAfter(now.subtract(const Duration(days: 1)))) break; // Stop si on dépasse hier
          
          final dateStr = date.toIso8601String().split('T')[0];
          
          // Debug: chercher manuellement pour voir
          final foundEntry = history.where((e) => _isSameDay(e.date, date)).toList();
          if (foundEntry.isNotEmpty) {
             _simulationLogs.add("MATCH pour $dateStr: ${foundEntry.length} entrée(s)");
          }
          
          final entry = history.firstWhere(
            (e) => _isSameDay(e.date, date),
            orElse: () => DayEntry(date: date, victoryCards: []), // Entrée vide
          );
          
          // Simuler la journée
          final bool isEmptyEntry = entry.victoryCards.isEmpty && entry.emotion == null;
          
          if (isEmptyEntry) {
             _simulationLogs.add("[$dateStr] Journée vide -> Croissance naturelle");
             _treeController.simulateDay(null);
          } else {
             final victories = entry.victoryCards.where((v) => v.isAccomplished).length;
             final emotion = entry.emotion?.name ?? 'Aucune';
             
             final stats = _treeController.simulateDay(entry);
             
             _simulationLogs.add("[$dateStr] V:$victories, E:$emotion");
             _simulationLogs.add("  -> +${stats['leavesAdded']} feuilles, +${stats['flowersAdded']} fleurs, +${stats['deadLeavesAdded']} mortes");
          }
          
          daysSimulated++;
        }
        
        _simulationLogs.add("Simulation terminée ($daysSimulated jours simulés).");
        
        // Sauvegarder l'état mis à jour si on a simulé des choses
        if (daysSimulated > 0 || lastUpdate == null) {
          if (_treeController.tree != null) {
            await PreferencesService.saveTreeState(_treeController.tree!);
            await PreferencesService.setLastTreeUpdateDate(now); // Marqué comme à jour aujourd'hui
            _simulationLogs.add("État sauvegardé.");
          }
        }
      } else {
        _simulationLogs.add("Arbre déjà à jour aujourd'hui.");
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données de l\'arbre: $e');
      _simulationLogs.add("ERREUR: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  Future<void> _resetTree() async {
    Navigator.pop(context); // Fermer le dialog
    
    setState(() {
      _isLoading = true;
    });
    
    // Effacer l'état sauvegardé
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tree_state');
    await prefs.remove('last_tree_update_date');
    
    // Recharger (ce qui va recréer l'arbre et resimuler)
    await _loadTreeData();
  }

  void _showTreeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de votre arbre'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Votre arbre grandit avec vous ! 🌱\n\n'
                  '• Chaque victoire ajoute une feuille 🍃\n'
                  '• Les jours positifs font fleurir l\'arbre 🌸\n'
                  '• Les jours difficiles peuvent causer des feuilles mortes 🍂\n'
                  '• L\'arbre vieillit et grandit chaque jour 🌳',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Journal de croissance (Debug):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetTree,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  height: 200, // Hauteur fixe pour scroller
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _simulationLogs.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 250, // Hauteur fixe pour l'arbre
      width: double.infinity,
      child: Stack(
        children: [
          Center(
            child: ProceduralTreeWidget(
              size: 250,
              growthLevel: _treeController.tree?.getGrowthLevel() ?? 0.0,
              parameters: _treeParameters,
              controller: _treeController,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  onPressed: _showTreeInfo,
                  tooltip: 'Infos arbre',
                ),
                // Debug controls
                _DebugButton(
                  emoji: '🍃', 
                  onTap: () {
                    _treeController.addRandomLeaves();
                    setState(() {}); // Force rebuild to show changes
                  },
                  tooltip: 'Ajouter feuille',
                ),
                _DebugButton(
                  emoji: '🌸', 
                  onTap: () {
                    _treeController.addRandomFlower();
                    setState(() {});
                  },
                  tooltip: 'Ajouter fleur',
                ),
                _DebugButton(
                  emoji: '🍂', 
                  onTap: () {
                    _treeController.advanceLeafDeath();
                    setState(() {});
                  },
                  tooltip: 'Tuer feuille',
                ),
                _DebugButton(
                  emoji: '☀️', 
                  onTap: () {
                    _treeController.growLeaves();
                    setState(() {});
                  },
                  tooltip: '+1 Jour',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  final String tooltip;

  const _DebugButton({
    required this.emoji,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
          ),
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
