import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'game_entity.dart';
import '../components/position_component.dart';
import '../components/collision_component.dart';
import '../components/sprite_component.dart';

enum TileType {
  scaffolding,
  timber,
  bricks,
  beam,
  indestructible,
}

/// Tile states for destruction animation
enum TileState {
  intact,
  damaged,
  heavilyDamaged,
  destroying,
  destroyed,
}

/// Data class for tile properties
class TileData extends Equatable {
  final Vector2 position;
  final TileType type;
  final int durability;
  final int maxDurability;
  final bool isDestructible;

  const TileData({
    required this.position,
    required this.type,
    required this.durability,
    required this.maxDurability,
    required this.isDestructible,
  });

  TileData copyWith({
    Vector2? position,
    TileType? type,
    int? durability,
    int? maxDurability,
    bool? isDestructible,
  }) {
    return TileData(
      position: position ?? this.position,
      type: type ?? this.type,
      durability: durability ?? this.durability,
      maxDurability: maxDurability ?? this.maxDurability,
      isDestructible: isDestructible ?? this.isDestructible,
    );
  }

  @override
  List<Object?> get props => [
    position,
    type,
    durability,
    maxDurability,
    isDestructible,
  ];
}

/// Destructible tile entity with durability and destruction mechanics
class TileEntity extends GameEntity {
  late final GamePositionComponent _positionComponent;
  late final GameCollisionComponent _collisionComponent;
  late final GameSpriteComponent _spriteComponent;
  
  // Tile properties
  final TileType _type;
  int _durability;
  final int _maxDurability;
  final bool _isDestructible;
  
  // State management
  TileState _currentState = TileState.intact;
  double _stateTimer = 0.0;
  
  // Visual properties
  static const double tileSize = 32.0;
  final Map<TileState, Sprite> _stateSprites = {};
  
  // Destruction animation
  double _destructionTimer = 0.0;
  static const double destructionDuration = 0.5;
  
  // Particle effects callback
  void Function(TileEntity tile, Vector2 position)? onParticleSpawn;
  
  // Destruction callback
  void Function(TileEntity tile)? onDestroyed;

  TileEntity({
    required super.id,
    required TileType type,
    required Vector2 position,
    int? durability,
    bool? isDestructible,
    this.onParticleSpawn,
    this.onDestroyed,
  }) : _type = type,
       _isDestructible = isDestructible ?? _getDefaultDestructible(type),
       _maxDurability = durability ?? _getDefaultDurability(type),
       _durability = durability ?? _getDefaultDurability(type) {
    
    // Initialize components
    _positionComponent = GamePositionComponent(
      position: position,
      size: Vector2(tileSize, tileSize),
    );
    
    // Collision component
    _collisionComponent = GameCollisionComponent(
      hitbox: RectangleHitbox(size: Vector2(tileSize, tileSize)),
      type: GameCollisionType.tile,
      collidesWith: {
        GameCollisionType.ball,
        GameCollisionType.player,
      },
      onCollision: _handleCollision,
      position: position,
      size: Vector2(tileSize, tileSize),
    );
    
    // Sprite component
    _spriteComponent = GameSpriteComponent(
      size: Vector2(tileSize, tileSize),
      renderLayer: 0, // Render behind other entities
    );
  }

  @override
  Future<void> initializeEntity() async {
    // Add components to the entity
    addEntityComponent(_positionComponent);
    addEntityComponent(_collisionComponent);
    addEntityComponent(_spriteComponent);
    
    // Initialize sprites for different states
    await _initializeSprites();
    
    // Set initial sprite
    _updateSpriteForState(_currentState);
    
    // Position the sprite component
    _spriteComponent.position = _positionComponent.position;
  }
  
  /// Initialize sprites for different tile states
  Future<void> _initializeSprites() async {
    // Create sprites for each state based on tile type
    _stateSprites[TileState.intact] = await _createTileSprite(_type, TileState.intact);
    _stateSprites[TileState.damaged] = await _createTileSprite(_type, TileState.damaged);
    _stateSprites[TileState.heavilyDamaged] = await _createTileSprite(_type, TileState.heavilyDamaged);
    _stateSprites[TileState.destroying] = await _createTileSprite(_type, TileState.destroying);
  }
  
  /// Create a sprite for a specific tile type and state
  Future<Sprite> _createTileSprite(TileType type, TileState state) async {
    // This is a placeholder - in a real implementation, sprites would be loaded from assets
    Color baseColor;
    
    // Base colors for different tile types
    switch (type) {
      case TileType.scaffolding:
        baseColor = Colors.brown;
        break;
      case TileType.timber:
        baseColor = Colors.orange;
        break;
      case TileType.bricks:
        baseColor = Colors.red;
        break;
      case TileType.beam:
        baseColor = Colors.grey.shade700;
        break;
      case TileType.indestructible:
        baseColor = Colors.grey;
        break;
    }
    
    // Modify color based on state
    switch (state) {
      case TileState.intact:
        // Keep base color
        break;
      case TileState.damaged:
        baseColor = Color.lerp(baseColor, Colors.black, 0.2)!;
        break;
      case TileState.heavilyDamaged:
        baseColor = Color.lerp(baseColor, Colors.black, 0.4)!;
        break;
      case TileState.destroying:
        baseColor = Color.lerp(baseColor, Colors.white, 0.5)!;
        break;
      case TileState.destroyed:
        baseColor = Colors.transparent;
        break;
    }
    
    final paint = Paint()..color = baseColor;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw tile
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, tileSize, tileSize),
      paint,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, tileSize, tileSize),
      strokePaint,
    );
    
    // Add type-specific details
    _drawTileDetails(canvas, type, state);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(tileSize.toInt(), tileSize.toInt());
    return Sprite(image);
  }
  
  /// Draw type-specific details on the tile
  void _drawTileDetails(Canvas canvas, TileType type, TileState state) {
    final detailPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    
    switch (type) {
      case TileType.scaffolding:
        // Draw scaffolding pattern
        canvas.drawLine(
          const Offset(0, tileSize / 2),
          const Offset(tileSize, tileSize / 2),
          detailPaint,
        );
        canvas.drawLine(
          const Offset(tileSize / 2, 0),
          const Offset(tileSize / 2, tileSize),
          detailPaint,
        );
        break;
        
      case TileType.timber:
        // Draw wood grain lines
        for (int i = 0; i < 3; i++) {
          canvas.drawLine(
            Offset(0, (i + 1) * tileSize / 4),
            Offset(tileSize, (i + 1) * tileSize / 4),
            detailPaint,
          );
        }
        break;
        
      case TileType.bricks:
        // Draw brick pattern
        canvas.drawLine(
          const Offset(0, tileSize / 2),
          const Offset(tileSize, tileSize / 2),
          detailPaint,
        );
        canvas.drawLine(
          const Offset(tileSize / 2, 0),
          const Offset(tileSize / 2, tileSize / 2),
          detailPaint,
        );
        break;
        
      case TileType.beam:
        // Draw beam pattern (horizontal lines)
        for (int i = 0; i < 4; i++) {
          canvas.drawLine(
            Offset(0, (i + 1) * tileSize / 5),
            Offset(tileSize, (i + 1) * tileSize / 5),
            detailPaint,
          );
        }
        break;
        
      case TileType.indestructible:
        // Draw diagonal lines for indestructible
        canvas.drawLine(
          const Offset(0, 0),
          const Offset(tileSize, tileSize),
          detailPaint,
        );
        canvas.drawLine(
          const Offset(tileSize, 0),
          const Offset(0, tileSize),
          detailPaint,
        );
        break;
    }
  }

  @override
  void updateEntity(double dt) {
    _stateTimer += dt;
    
    // Update state machine
    _updateStateMachine(dt);
    
    // Update destruction animation
    if (_currentState == TileState.destroying) {
      _destructionTimer += dt;
      
      // Update sprite opacity during destruction
      final opacity = 1.0 - (_destructionTimer / destructionDuration);
      _spriteComponent.setOpacity(opacity.clamp(0.0, 1.0));
    }
  }
  
  /// Update the state machine
  void _updateStateMachine(double dt) {
    switch (_currentState) {
      case TileState.intact:
      case TileState.damaged:
      case TileState.heavilyDamaged:
        // Check if durability changed and update state accordingly
        _updateStateBasedOnDurability();
        break;
        
      case TileState.destroying:
        // Check if destruction animation is complete
        if (_destructionTimer >= destructionDuration) {
          _changeState(TileState.destroyed);
          onDestroyed?.call(this);
        }
        break;
        
      case TileState.destroyed:
        // Tile is destroyed, should be removed from game
        break;
    }
  }
  
  /// Update state based on current durability
  void _updateStateBasedOnDurability() {
    if (!_isDestructible) return;
    
    final durabilityRatio = _durability / _maxDurability;
    TileState newState;
    
    if (durabilityRatio > 0.66) {
      newState = TileState.intact;
    } else if (durabilityRatio > 0.33) {
      newState = TileState.damaged;
    } else if (durabilityRatio > 0) {
      newState = TileState.heavilyDamaged;
    } else {
      newState = TileState.destroying;
      _destructionTimer = 0.0;
      
      // Spawn particles when destruction starts
      onParticleSpawn?.call(this, _positionComponent.position + Vector2(tileSize / 2, tileSize / 2));
    }
    
    if (newState != _currentState) {
      _changeState(newState);
    }
  }
  
  /// Handle collision with other entities
  void _handleCollision(GameCollisionComponent other) {
    if (other.type == GameCollisionType.ball && _isDestructible) {
      takeDamage(1);
    }
  }
  
  /// Apply damage to the tile
  void takeDamage(int damage) {
    if (!_isDestructible || _currentState == TileState.destroying || _currentState == TileState.destroyed) {
      return;
    }
    
    _durability = (_durability - damage).clamp(0, _maxDurability);
    
    // Immediate state update
    _updateStateBasedOnDurability();
  }
  
  /// Change the tile state
  void _changeState(TileState newState) {
    if (newState != _currentState) {
      _currentState = newState;
      _stateTimer = 0.0;
      _updateSpriteForState(newState);
    }
  }
  
  /// Update sprite for the current state
  void _updateSpriteForState(TileState state) {
    final sprite = _stateSprites[state];
    if (sprite != null) {
      _spriteComponent.sprite = sprite;
    }
  }
  
  /// Get default durability for tile type
  static int _getDefaultDurability(TileType type) {
    switch (type) {
      case TileType.scaffolding:
        return 1; // One hit destruction
      case TileType.timber:
        return 2; // Two hits
      case TileType.bricks:
        return 3; // Three hits
      case TileType.beam:
        return -1; // Indestructible like beams in construction
      case TileType.indestructible:
        return -1; // Indestructible
    }
  }
  
  /// Get default destructible state for tile type
  static bool _getDefaultDestructible(TileType type) {
    return type != TileType.indestructible && type != TileType.beam;
  }
  
  // Getters for components and state
  
  /// Get the position component
  @override
  GamePositionComponent get positionComponent => _positionComponent;
  
  /// Get the collision component
  @override
  GameCollisionComponent get collisionComponent => _collisionComponent;
  
  /// Get the sprite component
  @override
  GameSpriteComponent get spriteComponent => _spriteComponent;
  
  /// Get the tile type
  TileType get type => _type;
  
  /// Get current durability
  int get durability => _durability;
  
  /// Get maximum durability
  int get maxDurability => _maxDurability;
  
  /// Check if tile is destructible
  bool get isDestructible => _isDestructible;
  
  /// Get current tile state
  TileState get currentState => _currentState;
  
  /// Get state timer
  double get stateTimer => _stateTimer;
  
  /// Check if tile is destroyed
  bool get isDestroyed => _currentState == TileState.destroyed;
  
  /// Check if tile is being destroyed
  bool get isDestroying => _currentState == TileState.destroying;
  
  /// Get durability ratio (0.0 to 1.0)
  double get durabilityRatio => _maxDurability > 0 ? _durability / _maxDurability : 0.0;
  
  /// Create tile data from this entity
  TileData toTileData() {
    return TileData(
      position: _positionComponent.position.clone(),
      type: _type,
      durability: _durability,
      maxDurability: _maxDurability,
      isDestructible: _isDestructible,
    );
  }
  
  /// Create tile entity from tile data
  static TileEntity fromTileData(TileData data, String id) {
    return TileEntity(
      id: id,
      type: data.type,
      position: data.position,
      durability: data.durability,
      isDestructible: data.isDestructible,
    );
  }
}