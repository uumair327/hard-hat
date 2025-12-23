import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/entities/tile.dart';
import 'package:hard_hat/features/game/domain/components/damage_component.dart';

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
    
    // Apply damage
    final newDurability = (tile.durability - event.damage).clamp(0, tile.maxDurability);
    tile.setDurability(newDurability);
    
    // Determine new state based on durability
    final newState = _calculateTileState(tile);
    if (newState != tile.currentState) {
      tile.setState(newState);
      
      // Trigger state change effects
      _triggerStateChangeEffects(tile, newState, event);
    }
  }

  /// Calculate tile state based on durability
  TileState _calculateTileState(TileEntity tile) {
    if (tile.durability <= 0) {
      return TileState.destroying;
    }
    
    final durabilityRatio = tile.durability / tile.maxDurability;
    
    if (durabilityRatio > 0.66) {
      return TileState.intact;
    } else if (durabilityRatio > 0.33) {
      return TileState.damaged;
    } else {
      return TileState.heavilyDamaged;
    }
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
        // No effects for intact state
        break;
    }
  }

  /// Trigger effects for initial damage
  void _triggerDamageEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn damage particles
    tile.onParticleSpawn?.call('damage_particles', tile.position);
    
    // Play damage sound
    // AudioSystem will handle this through events
  }

  /// Trigger effects for heavy damage
  void _triggerHeavyDamageEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn more particles
    tile.onParticleSpawn?.call('heavy_damage_particles', tile.position);
    
    // Play heavy damage sound
    // AudioSystem will handle this through events
  }

  /// Trigger effects for destruction
  void _triggerDestructionEffects(TileEntity tile, TileDamageEvent event) {
    // Spawn destruction particles
    tile.onParticleSpawn?.call('destruction_particles', tile.position);
    
    // Play destruction sound
    // AudioSystem will handle this through events
    
    // Trigger destruction callback
    tile.onDestroyed?.call();
    
    // Schedule tile removal (handled by entity manager)
    _scheduleTileRemoval(tile);
  }

  /// Schedule tile for removal after destruction animation
  void _scheduleTileRemoval(TileEntity tile) {
    // This would typically be handled by a separate cleanup system
    // For now, we'll just mark it for removal
    tile.markForRemoval();
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

/// Component for tracking damage over time
class DamageComponent {
  int currentDamage = 0;
  int maxDamage;
  bool isInvulnerable = false;
  double invulnerabilityDuration = 0.0;
  double invulnerabilityTimer = 0.0;

  DamageComponent({
    required this.maxDamage,
    this.currentDamage = 0,
  });

  /// Apply damage and return actual damage dealt
  int applyDamage(int damage) {
    if (isInvulnerable) return 0;
    
    final actualDamage = damage.clamp(0, maxDamage - currentDamage);
    currentDamage += actualDamage;
    
    return actualDamage;
  }

  /// Set invulnerability for a duration
  void setInvulnerable(double duration) {
    isInvulnerable = true;
    invulnerabilityDuration = duration;
    invulnerabilityTimer = 0.0;
  }

  /// Update invulnerability timer
  void updateInvulnerability(double dt) {
    if (isInvulnerable) {
      invulnerabilityTimer += dt;
      if (invulnerabilityTimer >= invulnerabilityDuration) {
        isInvulnerable = false;
        invulnerabilityTimer = 0.0;
      }
    }
  }

  /// Check if entity is destroyed
  bool get isDestroyed => currentDamage >= maxDamage;

  /// Get damage ratio (0.0 to 1.0)
  double get damageRatio => currentDamage / maxDamage;

  /// Get health ratio (1.0 to 0.0)
  double get healthRatio => 1.0 - damageRatio;
}