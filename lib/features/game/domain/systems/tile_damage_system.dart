import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_system_interfaces.dart';

/// System responsible for processing tile damage
/// Separates damage logic from tile entities (proper ECS pattern)
class TileDamageSystem extends GameSystem implements ITileDamageSystem {
  /// List of damage events to process
  final List<TileDamageEvent> _damageEvents = [];
  
  /// Reference to particle system for spawning destruction effects
  IParticleSystem? _particleSystem;
  
  /// Reference to audio system for playing destruction sounds
  IAudioSystem? _audioSystem;
  
  @override
  int get priority => 5; // Process after collision detection

  @override
  Future<void> initialize() async {
    // Initialize damage processing
  }
  
  /// Set particle system for integration
  void setParticleSystem(IParticleSystem particleSystem) {
    _particleSystem = particleSystem;
  }
  
  /// Set audio system for integration
  void setAudioSystem(IAudioSystem audioSystem) {
    _audioSystem = audioSystem;
  }

  /// Queue a damage event for processing
  @override
  void queueDamage(TileEntity tile, int damage, {String? source}) {
    _damageEvents.add(TileDamageEvent(
      tile: tile,
      damage: damage,
      source: source,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void update(double dt) {
    // Process all queued damage events
    for (final event in _damageEvents) {
      _processDamageEvent(event);
    }
    _damageEvents.clear();
  }

  /// Process a single damage event
  void _processDamageEvent(TileDamageEvent event) {
    final tile = event.tile;
    
    // Check if tile can take damage
    if (!tile.isDestructible || tile.currentState == TileState.destroying) {
      return;
    }
    
    // Apply damage using the tile's takeDamage method
    tile.takeDamage(event.damage);
    
    // Trigger effects based on the tile's current state after damage
    _triggerStateChangeEffects(tile, tile.currentState, event);
  }

  /// Trigger effects when tile state changes
  void _triggerStateChangeEffects(TileEntity tile, TileState newState, TileDamageEvent event) {
    switch (newState) {
      case TileState.damaged:
        _triggerDamageEffects(tile, event);
        break;
      case TileState.heavilyDamaged:
        _triggerHeavyDamageEffects(tile, event);
        break;
      case TileState.destroying:
        _triggerDestructionEffects(tile, event);
        break;
      case TileState.intact:
      case TileState.destroyed:
        // No effects for intact or destroyed state
        break;
    }
  }

  /// Trigger effects for initial damage
  void _triggerDamageEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn damage particles using the tile's position
    final tilePosition = tile.positionComponent.position + Vector2(16, 16); // Center of tile
    
    if (_particleSystem != null) {
      if (_particleSystem is ParticleSystem) {
        final particleSystem = _particleSystem as ParticleSystem;
        
        // Spawn lighter particles for damage (not destruction)
        particleSystem.spawnMaterialParticles(
          tilePosition,
          tile.type,
          tile.currentState,
          count: _getParticleCountForTile(tile.type) ~/ 3, // Fewer particles for damage
        );
      } else {
        _particleSystem!.spawnParticles('dust', tilePosition);
      }
    }
    
    // Trigger tile's particle spawn callback for backward compatibility
    tile.onParticleSpawn?.call(tile, tilePosition);
    
    // Play damage sound
    // AudioSystem will handle this through events
  }

  /// Trigger effects for heavy damage
  void _triggerHeavyDamageEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn more particles
    final tilePosition = tile.positionComponent.position + Vector2(16, 16); // Center of tile
    
    if (_particleSystem != null) {
      if (_particleSystem is ParticleSystem) {
        final particleSystem = _particleSystem as ParticleSystem;
        
        // Spawn moderate particles for heavy damage
        particleSystem.spawnMaterialParticles(
          tilePosition,
          tile.type,
          tile.currentState,
          count: (_getParticleCountForTile(tile.type) * 0.6).round(), // More particles than light damage
        );
      } else {
        _particleSystem!.spawnParticles('destruction', tilePosition);
      }
    }
    
    // Trigger tile's particle spawn callback for backward compatibility
    tile.onParticleSpawn?.call(tile, tilePosition);
    
    // Play heavy damage sound
    // AudioSystem will handle this through events
  }

  /// Trigger effects for destruction
  void _triggerDestructionEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn destruction particles based on tile type
    final tilePosition = tile.positionComponent.position + Vector2(16, 16); // Center of tile
    
    if (_particleSystem != null) {
      // Use the enhanced particle system methods for better integration
      if (_particleSystem is ParticleSystem) {
        final particleSystem = _particleSystem as ParticleSystem;
        
        // Spawn material-specific destruction particles
        particleSystem.spawnMaterialParticles(
          tilePosition,
          tile.type,
          tile.currentState,
          count: _getParticleCountForTile(tile.type),
        );
        
        // Spawn synchronized particles with audio
        particleSystem.spawnSynchronizedParticles(
          tilePosition,
          'destruction',
          _getDestructionSoundForTile(tile.type),
          count: _getParticleCountForTile(tile.type),
          audioSystem: _audioSystem,
        );
      } else {
        // Fallback to basic particle spawning
        switch (tile.type) {
          case TileType.scaffolding:
            _particleSystem!.spawnParticles('metal_sparks', tilePosition);
            break;
          case TileType.timber:
            _particleSystem!.spawnParticles('wood_chips', tilePosition);
            break;
          case TileType.bricks:
            _particleSystem!.spawnParticles('brick_dust', tilePosition);
            break;
          default:
            _particleSystem!.spawnParticles('destruction', tilePosition);
        }
      }
    }
    
    // Play destruction sound based on tile type
    if (_audioSystem != null) {
      if (_audioSystem is AudioSystem) {
        switch (tile.type) {
          case TileType.scaffolding:
          case TileType.timber:
          case TileType.bricks:
            (_audioSystem as AudioSystem).playBreakSound(tilePosition);
            break;
          default:
            (_audioSystem as AudioSystem).playBreakSound(tilePosition);
        }
      } else {
        final soundName = _getDestructionSoundForTile(tile.type);
        _audioSystem!.playSound(soundName);
      }
    }
    
    // Trigger destruction callback
    tile.onDestroyed?.call(tile);
    
    // Note: Tile removal is handled by the tile's own state machine
    // No need to manually mark for removal here
  }
  
  /// Get particle count based on tile type
  int _getParticleCountForTile(TileType tileType) {
    switch (tileType) {
      case TileType.scaffolding:
        return 15; // Metal scaffolding - moderate particles
      case TileType.timber:
        return 20; // Wood - more particles (chips and splinters)
      case TileType.bricks:
        return 25; // Bricks - most particles (dust and chunks)
      default:
        return 15;
    }
  }
  
  /// Get destruction sound name for tile type
  String _getDestructionSoundForTile(TileType tileType) {
    switch (tileType) {
      case TileType.scaffolding:
        return 'scaffolding_break';
      case TileType.timber:
        return 'timber_break';
      case TileType.bricks:
        return 'brick_break';
      default:
        return 'tile_break';
    }
  }

  @override
  void processDamageEvents(double dt) {
    update(dt);
  }

  @override
  void dispose() {
    _damageEvents.clear();
    super.dispose();
  }
}

/// Event representing damage to a tile
class TileDamageEvent {
  final TileEntity tile;
  final int damage;
  final String? source;
  final DateTime timestamp;

  TileDamageEvent({
    required this.tile,
    required this.damage,
    this.source,
    required this.timestamp,
  });
}