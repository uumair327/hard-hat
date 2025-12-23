import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Service for converting Godot assets to Flutter-compatible formats
class AssetConverter {
  static const String _godotAssetsPath = 'godot_Hard-Hat/assets';
  static const String _flutterAssetsPath = 'assets';

  /// Convert all Godot assets to Flutter format
  static Future<void> convertAllAssets() async {
    if (kDebugMode) {
      print('Starting asset conversion from Godot to Flutter...');
    }

    await _convertSprites();
    await _convertAudio();
    await _convertTileTextures();
    await _generateSpriteAtlases();

    if (kDebugMode) {
      print('Asset conversion completed successfully!');
    }
  }

  /// Convert sprite assets from Godot to Flutter
  static Future<void> _convertSprites() async {
    final spriteConversions = {
      // Player sprites
      'sprite/game/player/idle.png': 'images/sprites/game/player/idle.png',
      'sprite/game/player/run.png': 'images/sprites/game/player/run.png',
      'sprite/game/player/jump.png': 'images/sprites/game/player/jump.png',
      'sprite/game/player/fall.png': 'images/sprites/game/player/fall.png',
      'sprite/game/player/peak.png': 'images/sprites/game/player/peak.png',
      'sprite/game/player/aim.png': 'images/sprites/game/player/aim.png',
      'sprite/game/player/strike.png': 'images/sprites/game/player/strike.png',
      'sprite/game/player/death.png': 'images/sprites/game/player/death.png',

      // Particle sprites
      'sprite/game/particle/star_particle.svg': 'images/sprites/game/particles/star_particle.svg',
      'sprite/game/particle/step_particle.svg': 'images/sprites/game/particles/step_particle.svg',

      // UI sprites
      'sprite/main_menu/play.png': 'images/sprites/ui/play.png',
      'sprite/main_menu/play_silhouette.png': 'images/sprites/ui/play_silhouette.png',
      'sprite/main_menu/config.png': 'images/sprites/ui/config.png',
      'sprite/main_menu/config_silhouette.png': 'images/sprites/ui/config_silhouette.png',
      'sprite/main_menu/quit.png': 'images/sprites/ui/quit.png',
      'sprite/main_menu/quit_silhouette.png': 'images/sprites/ui/quit_silhouette.png',
      'sprite/pause_menu/resume.png': 'images/sprites/ui/resume.png',
      'sprite/pause_menu/restart.png': 'images/sprites/ui/restart.png',
      'sprite/pause_menu/quit.png': 'images/sprites/ui/pause_quit.png',
      'sprite/pause_menu/paused.png': 'images/sprites/ui/paused.png',

      // Game background and effects
      'sprite/game/background.png': 'images/sprites/game/background.png',
      'sprite/game/transition.png': 'images/sprites/game/transition.png',

      // HUD elements
      'sprite/game/hud/arrow.svg': 'images/sprites/game/hud/arrow.svg',
      'sprite/game/hud/ball_progress.svg': 'images/sprites/game/hud/ball_progress.svg',
      'sprite/game/hud/ball_progress_over.svg': 'images/sprites/game/hud/ball_progress_over.svg',
      'sprite/game/hud/ball_progress_under.svg': 'images/sprites/game/hud/ball_progress_under.svg',
    };

    for (final entry in spriteConversions.entries) {
      await _copyAsset(entry.key, entry.value);
    }
  }

  /// Convert audio assets from Godot to Flutter
  static Future<void> _convertAudio() async {
    final audioConversions = {
      // Music
      'audio/music/mus_title.mp3': 'audio/music/title.mp3',
      'audio/music/mus_gameplay.mp3': 'audio/music/gameplay.mp3',

      // Sound effects
      'audio/sfx/sfx_break.mp3': 'audio/sfx/break.mp3',
      'audio/sfx/sfx_hit.mp3': 'audio/sfx/hit.mp3',
      'audio/sfx/sfx_land.mp3': 'audio/sfx/land.mp3',
      'audio/sfx/sfx_strike.mp3': 'audio/sfx/strike.mp3',
      'audio/sfx/sfx_boing.mp3': 'audio/sfx/boing.mp3',
      'audio/sfx/sfx_death.mp3': 'audio/sfx/death.mp3',
      'audio/sfx/sfx_confirm.mp3': 'audio/sfx/confirm.mp3',
      'audio/sfx/sfx_ding.mp3': 'audio/sfx/ding.mp3',
      'audio/sfx/sfx_tick.mp3': 'audio/sfx/tick.mp3',
      'audio/sfx/sfx_fizzle.mp3': 'audio/sfx/fizzle.mp3',
      'audio/sfx/sfx_elevator.mp3': 'audio/sfx/elevator.mp3',
      'audio/sfx/sfx_transition_pop_in.mp3': 'audio/sfx/transition_pop_in.mp3',
      'audio/sfx/sfx_transition_pop_out.mp3': 'audio/sfx/transition_pop_out.mp3',

      // Looping audio
      'audio/loop/loop_step.mp3': 'audio/loop/step.mp3',
      'audio/loop/loop_elevator.mp3': 'audio/loop/elevator.mp3',
    };

    for (final entry in audioConversions.entries) {
      await _copyAsset(entry.key, entry.value);
    }
  }

  /// Convert tile textures from Godot mesh assets
  static Future<void> _convertTileTextures() async {
    final tileConversions = {
      'mesh/scaffolding/texture.png': 'images/sprites/tiles/scaffolding.png',
      'mesh/timber/texture.png': 'images/sprites/tiles/timber.png',
      'mesh/timber_one_hit/texture.png': 'images/sprites/tiles/timber_one_hit.png',
      'mesh/bricks/texture.png': 'images/sprites/tiles/bricks.png',
      'mesh/bricks_one_hit/texture.png': 'images/sprites/tiles/bricks_one_hit.png',
      'mesh/bricks_two_hits/texture.png': 'images/sprites/tiles/bricks_two_hits.png',
      'mesh/beam/texture.png': 'images/sprites/tiles/beam.png',
      'mesh/girder/texture.png': 'images/sprites/tiles/girder.png',
      'mesh/support/texture.png': 'images/sprites/tiles/support.png',
      'mesh/spring/texture1.png': 'images/sprites/tiles/spring.png',
      'mesh/elevator/model_0.png': 'images/sprites/tiles/elevator.png',
      'mesh/spikes/texture.png': 'images/sprites/tiles/spikes.png',
      'mesh/shutter/texture.png': 'images/sprites/tiles/shutter.png',
    };

    for (final entry in tileConversions.entries) {
      await _copyAsset(entry.key, entry.value);
    }
  }

  /// Generate optimized sprite atlases for performance
  static Future<void> _generateSpriteAtlases() async {
    // Create sprite atlas definitions for different categories
    await _createSpriteAtlasDefinition('game', [
      'images/sprites/game/player/idle.png',
      'images/sprites/game/player/run.png',
      'images/sprites/game/player/jump.png',
      'images/sprites/game/player/fall.png',
      'images/sprites/game/player/peak.png',
      'images/sprites/game/player/aim.png',
      'images/sprites/game/player/strike.png',
      'images/sprites/game/player/death.png',
    ]);

    await _createSpriteAtlasDefinition('tiles', [
      'images/sprites/tiles/scaffolding.png',
      'images/sprites/tiles/timber.png',
      'images/sprites/tiles/timber_one_hit.png',
      'images/sprites/tiles/bricks.png',
      'images/sprites/tiles/bricks_one_hit.png',
      'images/sprites/tiles/bricks_two_hits.png',
      'images/sprites/tiles/beam.png',
      'images/sprites/tiles/girder.png',
      'images/sprites/tiles/support.png',
      'images/sprites/tiles/spring.png',
      'images/sprites/tiles/elevator.png',
      'images/sprites/tiles/spikes.png',
      'images/sprites/tiles/shutter.png',
    ]);

    await _createSpriteAtlasDefinition('ui', [
      'images/sprites/ui/play.png',
      'images/sprites/ui/play_silhouette.png',
      'images/sprites/ui/config.png',
      'images/sprites/ui/config_silhouette.png',
      'images/sprites/ui/quit.png',
      'images/sprites/ui/quit_silhouette.png',
      'images/sprites/ui/resume.png',
      'images/sprites/ui/restart.png',
      'images/sprites/ui/pause_quit.png',
      'images/sprites/ui/paused.png',
    ]);

    await _createSpriteAtlasDefinition('particles', [
      'images/sprites/game/particles/star_particle.svg',
      'images/sprites/game/particles/step_particle.svg',
    ]);
  }

  /// Copy an asset from Godot to Flutter directory
  static Future<void> _copyAsset(String godotPath, String flutterPath) async {
    try {
      final sourceFile = File(path.join(_godotAssetsPath, godotPath));
      final targetFile = File(path.join(_flutterAssetsPath, flutterPath));

      // Create target directory if it doesn't exist
      await targetFile.parent.create(recursive: true);

      // Copy file if source exists
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetFile.path);
        if (kDebugMode) {
          print('Copied: $godotPath -> $flutterPath');
        }
      } else {
        if (kDebugMode) {
          print('Warning: Source file not found: $godotPath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error copying asset $godotPath: $e');
      }
    }
  }

  /// Create sprite atlas definition file
  static Future<void> _createSpriteAtlasDefinition(
    String atlasName,
    List<String> spritePaths,
  ) async {
    final atlasData = {
      'name': atlasName,
      'sprites': spritePaths.map((path) {
        final name = path.split('/').last.split('.').first;
        return {
          'name': name,
          'path': path,
          'x': 0, // Will be calculated during atlas generation
          'y': 0,
          'width': 0,
          'height': 0,
        };
      }).toList(),
    };

    final atlasFile = File('assets/data/atlases/${atlasName}.json');
    await atlasFile.parent.create(recursive: true);
    await atlasFile.writeAsString(_formatJson(atlasData));

    if (kDebugMode) {
      print('Created sprite atlas definition: ${atlasName}.json');
    }
  }

  /// Format JSON data for writing to file
  static String _formatJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('{');
    
    data.forEach((key, value) {
      buffer.write('  "$key": ');
      if (value is String) {
        buffer.writeln('"$value",');
      } else if (value is List) {
        buffer.writeln('[');
        for (int i = 0; i < value.length; i++) {
          final item = value[i];
          buffer.write('    ');
          if (item is Map) {
            buffer.write('{');
            final entries = item.entries.toList();
            for (int j = 0; j < entries.length; j++) {
              final entry = entries[j];
              buffer.write('"${entry.key}": ');
              if (entry.value is String) {
                buffer.write('"${entry.value}"');
              } else {
                buffer.write('${entry.value}');
              }
              if (j < entries.length - 1) buffer.write(', ');
            }
            buffer.write('}');
          }
          if (i < value.length - 1) buffer.write(',');
          buffer.writeln();
        }
        buffer.writeln('  ]');
      }
    });
    
    buffer.writeln('}');
    return buffer.toString();
  }
}