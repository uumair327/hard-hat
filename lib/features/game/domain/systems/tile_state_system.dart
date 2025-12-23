import 'package:hard_hat/features/game/domain/domain.dart';

/// System responsible for managing tile state transitions and animations
/// Separates state logic from tile entities (proper ECS pattern)
class TileStateSystem extends GameSystem {
  late EntityManager _entityManager;
  
  /// Map of tiles with pending state changes
  final Map<String, TileStateTransition> _pendingTransitions = {};
  
  @override
  int get priority => 6; // Process after damage system

  @override
  Future<void> initialize() async {
    // Will be injected
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }

  /// Queue a state transition for a tile
  void queueStateTransition(TileEntity tile, TileState newState, {double delay = 0.0}) {
    _pendingTransitions[tile.id] = TileStateTransition(
      tile: tile,
      targetState: newState,
      delay: delay,
      timer: 0.0,
    );
  }

  @override
  void update(double dt) {
    // Update all tiles with state transitions
    final completedTransitions = <String>[];
    
    for (final entry in _pendingTransitions.entries) {
      final transition = entry.value;
      transition.timer += dt;
      
      if (transition.timer >= transition.delay) {
        _executeStateTransition(transition);
        completedTransitions.add(entry.key);
      }
    }
    
    // Remove completed transitions
    for (final id in completedTransitions) {
      _pendingTransitions.remove(id);
    }
    
    // Update all tile states
    _updateTileStates(dt);
  }

  /// Execute a state transition
  void _executeStateTransition(TileStateTransition transition) {
    final tile = transition.tile;
    final oldState = tile.currentState;
    
    // Note: TileEntity manages its own state transitions internally
    // We can only trigger state changes through damage or other mechanisms
    // For now, we'll handle the effects based on the target state
    _handleStateChange(tile, oldState, transition.targetState);
  }

  /// Handle state change logic
  void _handleStateChange(TileEntity tile, TileState oldState, TileState newState) {
    switch (newState) {
      case TileState.intact:
        _handleIntactState(tile);
        break;
      case TileState.damaged:
        _handleDamagedState(tile, oldState);
        break;
      case TileState.heavilyDamaged:
        _handleHeavilyDamagedState(tile, oldState);
        break;
      case TileState.destroying:
        _handleDestroyingState(tile);
        break;
      case TileState.destroyed:
        _handleDestroyedTile(tile);
        break;
    }
  }

  /// Handle intact state
  void _handleIntactState(TileEntity tile) {
    // Reset any damage effects
    tile.resetVisualEffects();
  }

  /// Handle damaged state
  void _handleDamagedState(TileEntity tile, TileState oldState) {
    if (oldState == TileState.intact) {
      // First time damaged - start damage effects
      tile.startDamageEffects();
    }
  }

  /// Handle heavily damaged state
  void _handleHeavilyDamagedState(TileEntity tile, TileState oldState) {
    if (oldState != TileState.heavilyDamaged) {
      // Increase damage effects
      tile.intensifyDamageEffects();
    }
  }

  /// Handle destroying state
  void _handleDestroyingState(TileEntity tile) {
    // Start destruction animation
    tile.startDestructionAnimation();
    
    // Schedule removal after animation completes
    queueStateTransition(tile, TileState.destroyed, delay: tile.destructionAnimationDuration);
  }

  /// Update all tile states
  void _updateTileStates(double dt) {
    final tiles = _entityManager.getEntitiesOfType<TileEntity>();
    
    for (final tile in tiles) {
      _updateTileState(tile, dt);
    }
  }

  /// Update individual tile state
  void _updateTileState(TileEntity tile, double dt) {
    switch (tile.currentState) {
      case TileState.intact:
        // No special updates needed
        break;
      case TileState.damaged:
        _updateDamagedTile(tile, dt);
        break;
      case TileState.heavilyDamaged:
        _updateHeavilyDamagedTile(tile, dt);
        break;
      case TileState.destroying:
        _updateDestroyingTile(tile, dt);
        break;
      case TileState.destroyed:
        _handleDestroyedTile(tile);
        break;
    }
  }

  /// Update damaged tile
  void _updateDamagedTile(TileEntity tile, double dt) {
    // Update damage visual effects
    tile.updateDamageEffects(dt);
  }

  /// Update heavily damaged tile
  void _updateHeavilyDamagedTile(TileEntity tile, double dt) {
    // Update heavy damage effects (cracks, particles, etc.)
    tile.updateHeavyDamageEffects(dt);
  }

  /// Update destroying tile
  void _updateDestroyingTile(TileEntity tile, double dt) {
    // The tile handles its own destruction animation internally
    // We just monitor its state
    if (tile.currentState == TileState.destroyed) {
      _handleDestroyedTile(tile);
    }
  }

  /// Handle destroyed tile
  void _handleDestroyedTile(TileEntity tile) {
    // Mark for removal from entity manager
    _entityManager.unregisterEntity(tile.id);
  }

  /// Get tiles in a specific state
  List<TileEntity> getTilesInState(TileState state) {
    final tiles = _entityManager.getEntitiesOfType<TileEntity>();
    return tiles.where((tile) => tile.currentState == state).toList();
  }

  /// Get tiles that can be damaged
  List<TileEntity> getDestructibleTiles() {
    final tiles = _entityManager.getEntitiesOfType<TileEntity>();
    return tiles.where((tile) => tile.isDestructible && 
                                tile.currentState != TileState.destroying &&
                                tile.currentState != TileState.destroyed).toList();
  }

  /// Force all tiles to a specific state (for testing/debugging)
  void forceAllTilesToState(TileState state) {
    final tiles = _entityManager.getEntitiesOfType<TileEntity>();
    for (final tile in tiles) {
      queueStateTransition(tile, state);
    }
  }

  @override
  void dispose() {
    _pendingTransitions.clear();
    super.dispose();
  }
}

/// Represents a pending state transition
class TileStateTransition {
  final TileEntity tile;
  final TileState targetState;
  final double delay;
  double timer;

  TileStateTransition({
    required this.tile,
    required this.targetState,
    required this.delay,
    this.timer = 0.0,
  });
}

/// Extension methods for TileEntity to support state system
extension TileEntityStateExtensions on TileEntity {
  /// Reset visual effects (placeholder - tile handles this internally)
  void resetVisualEffects() {
    // The tile's internal state machine handles visual updates
  }

  /// Start damage effects (placeholder - tile handles this internally)
  void startDamageEffects() {
    // The tile's internal state machine handles damage effects
  }

  /// Intensify damage effects (placeholder - tile handles this internally)
  void intensifyDamageEffects() {
    // The tile's internal state machine handles effect intensification
  }

  /// Start destruction animation (placeholder - tile handles this internally)
  void startDestructionAnimation() {
    // The tile's internal state machine handles destruction animation
  }

  /// Update damage effects (placeholder - tile handles this internally)
  void updateDamageEffects(double dt) {
    // The tile's updateEntity method handles all visual updates
  }

  /// Update heavy damage effects (placeholder - tile handles this internally)
  void updateHeavyDamageEffects(double dt) {
    // The tile's updateEntity method handles all visual updates
  }

  /// Update destruction animation (placeholder - tile handles this internally)
  void updateDestructionAnimation(double dt) {
    // The tile's updateEntity method handles destruction animation
  }

  /// Get destruction animation duration
  double get destructionAnimationDuration => 0.5; // 500ms (matches TileEntity)

  /// Check if destruction animation is complete
  bool get isDestructionAnimationComplete {
    // Check if tile has completed destruction
    return currentState == TileState.destroyed;
  }

  /// Mark entity for removal (placeholder - handled by entity manager)
  void markForRemoval() {
    // Entity removal is handled by the entity manager
  }
}