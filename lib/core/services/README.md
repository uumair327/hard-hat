# Object Pooling and Performance Monitoring Services

This directory contains the object pooling and performance monitoring systems for the Hard Hat Flutter game.

## Object Pooling System

The object pooling system helps reduce garbage collection pressure by reusing frequently created objects like balls, particles, and audio players.

### Key Components

1. **ObjectPool** - Generic object pool interface and implementation
2. **BallPool** - Specialized pool for ball entities
3. **AudioPlayerPool** - Pool for audio players and components
4. **ParticlePool** - Pool for particle effects (in game domain)
5. **GamePoolManager** - Centralized manager for all pools

### Usage Example

```dart
// Initialize the pool manager
final poolManager = GamePoolManager();
poolManager.initialize(
  config: PoolConfiguration(
    ballPoolSize: 20,
    particlePoolSize: 500,
    audioPlayerPoolSize: 30,
  ),
);

// Launch a ball using the pool
final ball = poolManager.launchBall(
  position: Vector2(100, 100),
  direction: Vector2(1, 0),
  speed: 300,
);

// Play spatial audio using the pool
await poolManager.playSpatialAudio(
  soundId: 'ball_bounce.mp3',
  position: Vector2(200, 150),
  volume: 0.8,
);

// Update pools in game loop
poolManager.update(deltaTime);

// Get pool statistics
final stats = poolManager.getAllStats();
print('Pool stats: $stats');
```

## Performance Monitoring System

The performance monitoring system tracks frame rate, memory usage, and other performance metrics.

### Key Components

1. **PerformanceMonitor** - Tracks FPS, frame time, memory, and CPU usage
2. **MemoryProfiler** - Monitors memory usage and detects potential leaks
3. **PerformanceOptimizer** - Automatically applies optimizations based on performance data

### Usage Example

```dart
// Initialize performance monitoring
final optimizer = PerformanceOptimizer();
optimizer.initialize(
  targetFrameRate: 60.0,
  minAcceptableFrameRate: 45.0,
  autoOptimizationEnabled: true,
);

// Start monitoring
optimizer.start();

// In your game loop
final monitor = PerformanceMonitor();
monitor.startFrame();

// ... game update logic ...

monitor.endFrame();

// Get performance status
final status = optimizer.getPerformanceStatus();
print('Performance: ${status['performance']}');
print('Memory: ${status['memory']}');
```

## Integration with Game Systems

### In Game Initialization

```dart
void initializeGame() {
  // Initialize pools first
  GamePoolManager().initialize();
  
  // Initialize performance monitoring
  PerformanceOptimizer().initialize(autoOptimizationEnabled: true);
  PerformanceOptimizer().start();
}
```

### In Game Loop

```dart
void gameUpdate(double dt) {
  // Start performance tracking
  PerformanceMonitor().startFrame();
  PerformanceMonitor().startUpdate();
  
  // Update pools
  GamePoolManager().update(dt);
  
  // ... other game systems ...
  
  PerformanceMonitor().endUpdate();
  PerformanceMonitor().endFrame();
}
```

### In Game Disposal

```dart
void disposeGame() {
  GamePoolManager().dispose();
  PerformanceOptimizer().dispose();
}
```

## Performance Benefits

The object pooling system provides several benefits:

1. **Reduced Garbage Collection** - Reusing objects reduces GC pressure
2. **Consistent Performance** - Eliminates allocation spikes during gameplay
3. **Memory Efficiency** - Pre-allocated pools use memory more efficiently
4. **Automatic Management** - Pools automatically handle object lifecycle

## Monitoring and Optimization

The performance monitoring system provides:

1. **Real-time Metrics** - FPS, frame time, memory usage, CPU usage
2. **Automatic Optimization** - Applies optimizations when performance drops
3. **Memory Leak Detection** - Identifies potential memory leaks
4. **Performance Grading** - Provides A-F performance grades
5. **Historical Data** - Tracks performance trends over time

## Configuration

Pool sizes can be configured based on your game's needs:

```dart
const config = PoolConfiguration(
  ballPoolSize: 20,        // Max 20 balls at once
  particlePoolSize: 500,   // Max 500 particles
  audioPlayerPoolSize: 30, // Max 30 audio players
  enableAutoOptimization: true,
  optimizationInterval: Duration(seconds: 30),
);
```

Performance thresholds can also be customized:

```dart
const thresholds = PerformanceThresholds(
  minFrameRate: 45.0,      // Minimum acceptable FPS
  maxFrameTime: 20.0,      // Maximum frame time in ms
  maxMemoryUsage: 150 * 1024 * 1024, // 150MB max
  maxCpuUsage: 80.0,       // 80% max CPU usage
);
```