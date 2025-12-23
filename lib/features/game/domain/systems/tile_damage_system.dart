import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// System responsible for processing tile damage
/// Separates damage logic from tile entities (proper ECS pattern)
class TileDamageSystem extends GameSystem {
  /// List of damage events to process
  final List<TileDamageEvent> _damageEvents = [];
  
  @override
  int get priority => 5; // Process after collision detection

  @override
  Future<void> initialize() async {
    // Initialize damage processing
  }

  /// Queue a damage event for processing
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
    tile.onParticleSpawn?.call(tile, tilePosition);
    
    // Play damage sound
    // AudioSystem will handle this through events
  }

  /// Trigger effects for heavy damage
  void _triggerHeavyDamageEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn more particles
    final tilePosition = tile.positionComponent.position + Vector2(16, 16); // Center of tile
    tile.onParticleSpawn?.call(tile, tilePosition);
    
    // Play heavy damage sound
    // AudioSystem will handle this through events
  }

  /// Trigger effects for destruction
  void _triggerDestructionEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn destruction particles
    final tilePosition = tile.positionComponent.position + Vector2(16, 16); // Center of tile
    tile.onParticleSpawn?.call(tile, tilePosition);
    
    // Play destruction sound
    // AudioSystem will handle this through events
    
    // Trigger destruction callback
    tile.onDestroyed?.call(tile);
    
    // Note: Tile removal is handled by the tile's own state machine
    // No need to manually mark for removal here
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