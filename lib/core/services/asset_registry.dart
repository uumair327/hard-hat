import 'asset_definition.dart';

/// Registry containing all game asset definitions converted from Godot
class AssetRegistry {
  static const List<AssetDefinition> gameAssets = [
    // Player sprites (converted from Godot)
    AssetDefinition(
      id: 'player_idle',
      path: 'images/sprites/game/player/idle.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'player_run',
      path: 'images/sprites/game/player/run.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'player_jump',
      path: 'images/sprites/game/player/jump.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'player_fall',
      path: 'images/sprites/game/player/fall.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'player_peak',
      path: 'images/sprites/game/player/peak.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'player_aim',
      path: 'images/sprites/game/player/aim.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'player_strike',
      path: 'images/sprites/game/player/strike.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'player_death',
      path: 'images/sprites/game/player/death.png',
      type: AssetType.sprite,
      preload: true,
    ),

    // Tile sprites (converted from Godot mesh textures)
    AssetDefinition(
      id: 'tile_scaffolding',
      path: 'images/sprites/tiles/scaffolding.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_timber',
      path: 'images/sprites/tiles/timber.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_timber_one_hit',
      path: 'images/sprites/tiles/timber_one_hit.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_bricks',
      path: 'images/sprites/tiles/bricks.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_bricks_one_hit',
      path: 'images/sprites/tiles/bricks_one_hit.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_bricks_two_hits',
      path: 'images/sprites/tiles/bricks_two_hits.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_beam',
      path: 'images/sprites/tiles/beam.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_girder',
      path: 'images/sprites/tiles/girder.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_support',
      path: 'images/sprites/tiles/support.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_spikes',
      path: 'images/sprites/tiles/spikes.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'tile_shutter',
      path: 'images/sprites/tiles/shutter.png',
      type: AssetType.sprite,
      preload: true,
    ),

    // Interactive elements
    AssetDefinition(
      id: 'elevator',
      path: 'images/sprites/tiles/elevator.png',
      type: AssetType.sprite,
      preload: false,
    ),
    AssetDefinition(
      id: 'spring',
      path: 'images/sprites/tiles/spring.png',
      type: AssetType.sprite,
      preload: false,
    ),

    // UI sprites (converted from Godot)
    AssetDefinition(
      id: 'ui_play',
      path: 'images/sprites/ui/play.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_play_silhouette',
      path: 'images/sprites/ui/play_silhouette.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_config',
      path: 'images/sprites/ui/config.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_config_silhouette',
      path: 'images/sprites/ui/config_silhouette.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_quit',
      path: 'images/sprites/ui/quit.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_quit_silhouette',
      path: 'images/sprites/ui/quit_silhouette.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_resume',
      path: 'images/sprites/ui/resume.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_restart',
      path: 'images/sprites/ui/restart.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'ui_paused',
      path: 'images/sprites/ui/paused.png',
      type: AssetType.sprite,
      preload: true,
    ),

    // Game background and effects
    AssetDefinition(
      id: 'game_background',
      path: 'images/sprites/game/background.png',
      type: AssetType.sprite,
      preload: true,
    ),
    AssetDefinition(
      id: 'game_transition',
      path: 'images/sprites/game/transition.png',
      type: AssetType.sprite,
      preload: false,
    ),

    // Audio assets (converted from Godot with original names)
    AssetDefinition(
      id: 'music_title',
      path: 'audio/music/mus_title.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'music_gameplay',
      path: 'audio/music/mus_gameplay.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_break',
      path: 'audio/sfx/sfx_break.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_hit',
      path: 'audio/sfx/sfx_hit.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_land',
      path: 'audio/sfx/sfx_land.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_strike',
      path: 'audio/sfx/sfx_strike.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_boing',
      path: 'audio/sfx/sfx_boing.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_death',
      path: 'audio/sfx/sfx_death.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_confirm',
      path: 'audio/sfx/sfx_confirm.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_ding',
      path: 'audio/sfx/sfx_ding.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_tick',
      path: 'audio/sfx/sfx_tick.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_fizzle',
      path: 'audio/sfx/sfx_fizzle.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_elevator',
      path: 'audio/sfx/sfx_elevator.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_transition_pop_in',
      path: 'audio/sfx/sfx_transition_pop_in.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_transition_pop_out',
      path: 'audio/sfx/sfx_transition_pop_out.mp3',
      type: AssetType.audio,
      preload: false,
    ),
    AssetDefinition(
      id: 'sfx_blueprints',
      path: 'audio/sfx/sfx_blueprints.mp3',
      type: AssetType.audio,
      preload: false,
    ),

    // Level data
    AssetDefinition(
      id: 'level_1',
      path: 'data/levels/level_1.json',
      type: AssetType.data,
      preload: false,
    ),
    AssetDefinition(
      id: 'level_2',
      path: 'data/levels/level_2.json',
      type: AssetType.data,
      preload: false,
    ),
    AssetDefinition(
      id: 'levels_index',
      path: 'data/levels/levels.json',
      type: AssetType.data,
      preload: true,
    ),
  ];

  /// Get asset definition by ID
  static AssetDefinition? getAssetDefinition(String assetId) {
    try {
      return gameAssets.firstWhere((asset) => asset.id == assetId);
    } catch (e) {
      return null;
    }
  }

  /// Get all assets of a specific type
  static List<AssetDefinition> getAssetsByType(AssetType type) {
    return gameAssets.where((asset) => asset.type == type).toList();
  }

  /// Get all assets marked for preloading
  static List<AssetDefinition> getPreloadAssets() {
    return gameAssets.where((asset) => asset.preload).toList();
  }

  /// Get all sprite assets
  static List<AssetDefinition> getSpriteAssets() {
    return getAssetsByType(AssetType.sprite);
  }

  /// Get all audio assets
  static List<AssetDefinition> getAudioAssets() {
    return getAssetsByType(AssetType.audio);
  }

  /// Get all atlas assets
  static List<AssetDefinition> getAtlasAssets() {
    return getAssetsByType(AssetType.spriteAtlas);
  }

  /// Get all level data assets
  static List<AssetDefinition> getLevelAssets() {
    return gameAssets.where((asset) => asset.id.startsWith('level_')).toList();
  }
}