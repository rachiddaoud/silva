import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';

/// Service for managing audio playback throughout the app
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio players pool for concurrent playback
  final Map<String, AudioPlayer> _players = {};
  bool _initialized = false;
  
  // Sound effect types
  static const String tap = 'tap';
  static const String victorySelect = 'victory_select';
  static const String success = 'success';
  static const String emotionSelect = 'emotion_select';
  static const String pageTurn = 'page_turn';

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Pre-create players for common sounds
      _players[tap] = AudioPlayer();
      _players[victorySelect] = AudioPlayer();
      _players[success] = AudioPlayer();
      _players[emotionSelect] = AudioPlayer();
      _players[pageTurn] = AudioPlayer();
      
      // Set to low latency mode to allow overlapping sounds (e.g., rapid taps)
      for (var player in _players.values) {
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
      }
      
      _initialized = true;
      debugPrint('✓ Audio service initialized');
    } catch (e) {
      debugPrint('⚠ Failed to initialize audio service: $e');
    }
  }

  /// Play a sound effect
  Future<void> play(String soundType, {double volume = 0.7}) async {
    if (!_initialized) {
      await initialize();
    }

    // Check if sounds are enabled in preferences
    final soundEnabled = await PreferencesService.getSoundEnabled();
    if (!soundEnabled) return;

    final userVolume = await PreferencesService.getSoundVolume();
    final finalVolume = volume * userVolume;

    try {
      final player = _players[soundType];
      if (player == null) {
        debugPrint('⚠ No player found for sound: $soundType');
        return;
      }

      // Stop any current playback and reset to allow replay
      await player.stop();
      await player.setVolume(finalVolume);
      await player.play(AssetSource('sounds/$soundType.mp3'));
      
      debugPrint('🔊 Playing sound: $soundType (volume: ${(finalVolume * 100).toInt()}%)');
    } catch (e) {
      debugPrint('⚠ Failed to play sound $soundType: $e');
    }
  }

  /// Play tap sound (light UI interaction)
  Future<void> playTap() => play(tap, volume: 0.5);

  /// Play victory selection sound
  Future<void> playVictorySelect() => play(victorySelect, volume: 0.6);

  /// Play success sound (day completion, etc.)
  Future<void> playSuccess() => play(success, volume: 0.8);

  /// Play emotion selection sound
  Future<void> playEmotionSelect() => play(emotionSelect, volume: 0.6);

  /// Play page turn sound
  Future<void> playPageTurn() => play(pageTurn, volume: 0.5);

  /// Dispose of all audio players
  void dispose() {
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _initialized = false;
  }
}
