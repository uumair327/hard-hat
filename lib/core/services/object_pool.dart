import 'dart:collection';

/// Generic object pool interface for managing reusable objects
abstract class ObjectPool<T> {
  /// Get an object from the pool
  T acquire();
  
  /// Return an object to the pool
  void release(T object);
  
  /// Get pool statistics
  PoolStats get stats;
  
  /// Clear all objects from the pool
  void clear();
  
  /// Dispose of the pool and all objects
  void dispose();
}

/// Statistics for object pool monitoring
class PoolStats {
  const PoolStats({
    required this.available,
    required this.active,
    required this.total,
    required this.maxSize,
    required this.hitRate,
    required this.missRate,
  });
  
  final int available;
  final int active;
  final int total;
  final int maxSize;
  final double hitRate;
  final double missRate;
  
  @override
  String toString() {
    return 'PoolStats(available: $available, active: $active, total: $total, '
           'maxSize: $maxSize, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
           'missRate: ${(missRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Generic implementation of object pool with configurable factory and reset functions
class GenericObjectPool<T> implements ObjectPool<T> {
  GenericObjectPool({
    required this.factory,
    required this.reset,
    this.initialSize = 10,
    this.maxSize = 100,
    this.autoExpand = true,
  }) {
    // Pre-allocate initial objects
    for (int i = 0; i < initialSize; i++) {
      _available.add(factory());
    }
  }
  
  /// Factory function to create new objects
  final T Function() factory;
  
  /// Function to reset objects when returned to pool
  final void Function(T object) reset;
  
  /// Initial pool size
  final int initialSize;
  
  /// Maximum pool size
  final int maxSize;
  
  /// Whether to automatically expand the pool when needed
  final bool autoExpand;
  
  final Queue<T> _available = Queue<T>();
  final Set<T> _active = <T>{};
  
  // Statistics tracking
  int _hits = 0;
  int _misses = 0;
  
  @override
  T acquire() {
    T object;
    
    if (_available.isNotEmpty) {
      // Pool hit - reuse existing object
      object = _available.removeFirst();
      _hits++;
    } else if (autoExpand && _active.length + _available.length < maxSize) {
      // Pool miss - create new object
      object = factory();
      _misses++;
    } else {
      // Pool is full, force recycle oldest active object
      if (_active.isNotEmpty) {
        object = _active.first;
        _active.remove(object);
        reset(object);
      } else {
        // Fallback - create new object even if over limit
        object = factory();
        _misses++;
      }
    }
    
    _active.add(object);
    return object;
  }
  
  @override
  void release(T object) {
    if (_active.remove(object)) {
      reset(object);
      _available.add(object);
    }
  }
  
  /// Release multiple objects at once
  void releaseAll(Iterable<T> objects) {
    for (final object in objects) {
      release(object);
    }
  }
  
  @override
  PoolStats get stats {
    final totalRequests = _hits + _misses;
    return PoolStats(
      available: _available.length,
      active: _active.length,
      total: _available.length + _active.length,
      maxSize: maxSize,
      hitRate: totalRequests > 0 ? _hits / totalRequests : 0.0,
      missRate: totalRequests > 0 ? _misses / totalRequests : 0.0,
    );
  }
  
  @override
  void clear() {
    _available.addAll(_active);
    _active.clear();
  }
  
  @override
  void dispose() {
    _available.clear();
    _active.clear();
    _hits = 0;
    _misses = 0;
  }
  
  /// Get all active objects (read-only)
  Iterable<T> get activeObjects => Set.unmodifiable(_active);
  
  /// Get all available objects (read-only)
  Iterable<T> get availableObjects => List.unmodifiable(_available);
}

/// Pool manager for managing multiple object pools
class PoolManager {
  static final PoolManager _instance = PoolManager._internal();
  factory PoolManager() => _instance;
  PoolManager._internal();
  
  final Map<String, ObjectPool> _pools = {};
  
  /// Register a pool with a name
  void registerPool<T>(String name, ObjectPool<T> pool) {
    _pools[name] = pool;
  }
  
  /// Get a pool by name
  ObjectPool<T>? getPool<T>(String name) {
    return _pools[name] as ObjectPool<T>?;
  }
  
  /// Get statistics for all pools
  Map<String, PoolStats> getAllStats() {
    return _pools.map((name, pool) => MapEntry(name, pool.stats));
  }
  
  /// Clear all pools
  void clearAll() {
    for (final pool in _pools.values) {
      pool.clear();
    }
  }
  
  /// Dispose all pools
  void disposeAll() {
    for (final pool in _pools.values) {
      pool.dispose();
    }
    _pools.clear();
  }
}