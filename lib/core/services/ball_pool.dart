import 'package:flame/components.dart';
import '../../features/game/domain/entities/ball_entity.dart';
import 'object_pool.dart';

/// Specialized object pool for ball entities
class BallPool extends GenericObjectPool<BallEntity> {
  BallPool({
    int initialSize = 5,
    int maxSize = 20,
    this.onBallRecycled,
    this.onTileDestroyed,
  }) : super(
    factory: () => _createBall(onBallRecycled, onTileDestroyed),
    reset: _resetBall,
    initialSize: initialSize,
    maxSize: maxSize,
    autoExpand: true,
  );
  
  /// Callback for when a ball is recycled
  final void Function(BallEntity ball)? onBallRecycled;
  
  /// Callback for when a ball destroys a tile
  final void Function(BallEntity ball, String tileId)? onTileDestroyed;
  
  /// Factory method to create new ball entities
  static BallEntity _createBall(
    void Function(BallEntity ball)? onRecycled,
    void Function(BallEntity ball, String tileId)? onTileDestroyed,
  ) {
    return BallEntity(
      id: 'ball_${DateTime.now().millisecondsSinceEpoch}_${_ballCounter++}',
      onRecycle: onRecycled,
      onTileDestroyed: onTileDestroyed,
    );
  }
  
  /// Reset method to prepare ball for reuse
  static void _resetBall(BallEntity ball) {
    ball.reset();
  }
  
  static int _ballCounter = 0;
  
  /// Acquire a ball and position it at the specified location
  BallEntity acquireBall({Vector2? position}) {
    final ball = acquire();
    if (position != null) {
      ball.reset(position: position);
    }
    return ball;
  }
  
  /// Launch a ball from the pool
  BallEntity launchBall({
    required Vector2 position,
    required Vector2 direction,
    double? speed,
  }) {
    final ball = acquireBall(position: position);
    ball.launch(direction, speed: speed);
    return ball;
  }
  
  /// Update all active balls and automatically recycle finished ones
  void updateActiveBalls(double dt) {
    final ballsToRecycle = <BallEntity>[];
    
    for (final ball in activeObjects) {
      ball.updateEntity(dt);
      
      // Check if ball should be recycled
      if (ball.shouldRecycle) {
        ballsToRecycle.add(ball);
      }
    }
    
    // Recycle finished balls
    releaseAll(ballsToRecycle);
  }
  
  /// Force recycle all active balls
  void recycleAllBalls() {
    final activeBalls = List<BallEntity>.from(activeObjects);
    for (final ball in activeBalls) {
      ball.forceRecycle();
    }
    releaseAll(activeBalls);
  }
  
  /// Get all active balls
  List<BallEntity> get activeBalls => List<BallEntity>.from(activeObjects);
  
  /// Get count of active balls
  int get activeBallCount => activeObjects.length;
}

/// Global ball pool manager
class GlobalBallPoolManager {
  static final GlobalBallPoolManager _instance = GlobalBallPoolManager._internal();
  factory GlobalBallPoolManager() => _instance;
  GlobalBallPoolManager._internal();
  
  BallPool? _ballPool;
  
  /// Initialize the global ball pool
  void initialize({
    int initialSize = 5,
    int maxSize = 20,
    void Function(BallEntity ball)? onBallRecycled,
    void Function(BallEntity ball, String tileId)? onTileDestroyed,
  }) {
    _ballPool?.dispose();
    _ballPool = BallPool(
      initialSize: initialSize,
      maxSize: maxSize,
      onBallRecycled: onBallRecycled,
      onTileDestroyed: onTileDestroyed,
    );
  }
  
  /// Get the ball pool
  BallPool get ballPool {
    if (_ballPool == null) {
      throw StateError('BallPool not initialized. Call initialize() first.');
    }
    return _ballPool!;
  }
  
  /// Check if pool is initialized
  bool get isInitialized => _ballPool != null;
  
  /// Update all active balls
  void update(double dt) {
    _ballPool?.updateActiveBalls(dt);
  }
  
  /// Get pool statistics
  PoolStats? get stats => _ballPool?.stats;
  
  /// Clear all balls
  void clear() {
    _ballPool?.clear();
  }
  
  /// Dispose of the pool
  void dispose() {
    _ballPool?.dispose();
    _ballPool = null;
  }
}