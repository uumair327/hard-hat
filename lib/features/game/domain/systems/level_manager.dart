import 'dart:async';
import 'package:flame/components.dart';

import '../../../../core/errors/failures.dart';
import '../entities/level.dart';
import '../entities/tile.dart';
import '../entities/player_entity.dart';
import '../repositories/level_repository.dart';
import '../interfaces/entity_manager_interface.dart';
import 'game_system.dart';
import 'entity_manager.dart';

/// System responsible for managing level loading, tile instantiation, and objective detection
class LevelManager extends GameSystem {
  final LevelRepository _levelRepository;
  final EntityManager _entityManager;
  
  /// Currently loaded level
  Level? _currentLevel;
  
  /// Map of instantiated tile entities by their grid position
  final Map<String, TileEntity> _levelTiles = {};
  
  /// Level completion callback
  void Function(Level level)? onLevelComplete;
  
  /// Level loading callback
  void Function(Level level)? onLevelLoaded;
  
  /// Level loading error callback
  void Function(Failure failure)? onLevelLoadError;
  
  /// Objective detection settings
  static const double objectiveDetectionRadius = 16.0;
  
  /// Timer for objective detection checks
  double _objectiveCheckTimer = 0.0;
  static const double objectiveCheckInterval = 0.1; // Check every 100ms

  LevelManager({
    required LevelRepository levelRepository,
    required IEntityManager entityManager,
  }) : _levelRepository = levelRepository,
       _entityManager = entityManager as EntityManager;

  @override
  int get priority => -500; // Execute after entity manager but before other systems

  @override
  Future<void> initialize() async {
    // Level manager is ready to load levels
  }

  /// Load a level by ID
  Future<void> loadLevel(int levelId) async {
    try {
      // Clear current level first
      await _clearCurrentLevel();
      
      // Load level data from repository
      final result = await _levelRepository.getLevel(levelId);
      
      result.fold(
        (failure) {
          onLevelLoadError?.call(failure);
        },
        (level) async {
          _currentLevel = level;
          await _instantiateLevel(level);
          onLevelLoaded?.call(level);
        },
      );
    } catch (e) {
      onLevelLoadError?.call(LevelLoadFailure('Unexpected error loading level $levelId: $e'));
    }
  }

  /// Instantiate all tiles and elements for the loaded level
  Future<void> _instantiateLevel(Level level) async {
    // Instantiate tiles
    await _instantiateTiles(level.tiles);
    
    // Instantiate interactive elements
    await _instantiateInteractiveElements(level.elements);
    
    // Position player at spawn point
    _positionPlayerAtSpawn(level.playerSpawn);
  }

  /// Instantiate tiles from level data
  Future<void> _instantiateTiles(List<TileData> tiles) async {
    for (int i = 0; i < tiles.length; i++) {
      final tileData = tiles[i];
      final tileId = 'tile_${_currentLevel!.id}_$i';
      
      // Create tile entity
      final tileEntity = TileEntity.fromTileData(tileData, tileId);
      
      // Set up tile callbacks
      tileEntity.onDestroyed = _onTileDestroyed;
      tileEntity.onParticleSpawn = _onTileParticleSpawn;
      
      // Initialize the tile entity
      await tileEntity.initializeEntity();
      
      // Register with entity manager
      _entityManager.registerEntity(tileEntity);
      
      // Store in level tiles map
      final gridKey = _getGridKey(tileData.position);
      _levelTiles[gridKey] = tileEntity;
    }
  }

  /// Instantiate interactive elements from level data
  Future<void> _instantiateInteractiveElements(List<InteractiveElement> elements) async {
    // TODO: Implement interactive element instantiation
    // This would create entities for elevators, springs, etc.
    // For now, we'll leave this as a placeholder
    for (final element in elements) {
      // Create appropriate entity based on element type
      switch (element.type) {
        case 'elevator':
          // Create elevator entity
          break;
        case 'spring':
          // Create spring entity
          break;
        case 'target':
          // Create target entity
          break;
        default:
          // Unknown element type
          break;
      }
    }
  }

  /// Position the player at the level spawn point
  void _positionPlayerAtSpawn(Vector2 spawnPoint) {
    final player = _entityManager.getEntitiesOfType<PlayerEntity>().firstOrNull;
    if (player != null) {
      player.positionComponent.position = spawnPoint.clone();
    }
  }

  /// Handle tile destruction
  void _onTileDestroyed(TileEntity tile) {
    // Remove from level tiles map
    final gridKey = _getGridKey(tile.positionComponent.position);
    _levelTiles.remove(gridKey);
    
    // Unregister from entity manager
    _entityManager.unregisterEntity(tile.id);
  }

  /// Handle tile particle spawning
  void _onTileParticleSpawn(TileEntity tile, Vector2 position) {
    // TODO: Integrate with particle system
    // This would spawn appropriate particles based on tile type
  }

  /// Generate grid key for tile position
  String _getGridKey(Vector2 position) {
    final gridX = (position.x / TileEntity.tileSize).round();
    final gridY = (position.y / TileEntity.tileSize).round();
    return '${gridX}_$gridY';
  }

  /// Clear the current level and all its entities
  Future<void> _clearCurrentLevel() async {
    if (_currentLevel == null) return;
    
    // Remove all level tiles
    final tileIds = _levelTiles.values.map((tile) => tile.id).toList();
    for (final tileId in tileIds) {
      _entityManager.unregisterEntity(tileId);
    }
    _levelTiles.clear();
    
    // TODO: Remove interactive elements
    
    _currentLevel = null;
  }

  @override
  void updateSystem(double dt) {
    if (_currentLevel == null) return;
    
    // Update objective detection timer
    _objectiveCheckTimer += dt;
    
    // Check for level completion periodically
    if (_objectiveCheckTimer >= objectiveCheckInterval) {
      _objectiveCheckTimer = 0.0;
      _checkLevelObjectives();
    }
  }

  /// Check if level objectives have been completed
  void _checkLevelObjectives() {
    if (_currentLevel == null) return;
    
    final player = _entityManager.getEntitiesOfType<PlayerEntity>().firstOrNull;
    if (player == null) return;
    
    // For now, we'll implement a simple objective: destroy all destructible tiles
    // In a more complex game, this could check for specific objectives
    final hasDestructibleTiles = _levelTiles.values.any((tile) => 
      tile.isDestructible && !tile.isDestroyed && !tile.isDestroying
    );
    
    if (!hasDestructibleTiles) {
      // All destructible tiles are destroyed - level complete!
      _completeLevelObjective();
    }
  }

  /// Handle level objective completion
  void _completeLevelObjective() {
    if (_currentLevel == null) return;
    
    onLevelComplete?.call(_currentLevel!);
  }

  /// Get the currently loaded level
  Level? get currentLevel => _currentLevel;
  
  /// Get all level tiles
  Map<String, TileEntity> get levelTiles => Map.unmodifiable(_levelTiles);
  
  /// Get tile at specific grid position
  TileEntity? getTileAtPosition(Vector2 position) {
    final gridKey = _getGridKey(position);
    return _levelTiles[gridKey];
  }
  
  /// Get tiles in a rectangular area
  List<TileEntity> getTilesInArea(Vector2 topLeft, Vector2 bottomRight) {
    final tiles = <TileEntity>[];
    
    final startX = (topLeft.x / TileEntity.tileSize).floor();
    final startY = (topLeft.y / TileEntity.tileSize).floor();
    final endX = (bottomRight.x / TileEntity.tileSize).ceil();
    final endY = (bottomRight.y / TileEntity.tileSize).ceil();
    
    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final gridKey = '${x}_$y';
        final tile = _levelTiles[gridKey];
        if (tile != null) {
          tiles.add(tile);
        }
      }
    }
    
    return tiles;
  }
  
  /// Check if a position is blocked by a tile
  bool isPositionBlocked(Vector2 position) {
    final tile = getTileAtPosition(position);
    return tile != null && !tile.isDestroyed && !tile.isDestroying;
  }
  
  /// Get level bounds
  Vector2? get levelSize => _currentLevel?.size;
  
  /// Get camera bounds
  Vector2? get cameraMin => _currentLevel?.cameraMin;
  Vector2? get cameraMax => _currentLevel?.cameraMax;
  
  /// Get player spawn point
  Vector2? get playerSpawn => _currentLevel?.playerSpawn;
  
  /// Check if level is loaded
  bool get isLevelLoaded => _currentLevel != null;
  
  /// Get level ID
  int? get currentLevelId => _currentLevel?.id;
  
  /// Get level name
  String? get currentLevelName => _currentLevel?.name;

  @override
  void dispose() {
    _clearCurrentLevel();
    super.dispose();
  }
}