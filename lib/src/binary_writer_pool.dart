part of 'binary_writer.dart';

/// Object pool for reusing [BinaryWriter] instances to reduce GC pressure.
///
/// This pool maintains a cache of [BinaryWriter] instances with their
/// internal buffers, allowing efficient reuse without allocating new memory
/// for each write operation.
///
/// ## Features
/// - **Automatic reuse:** [acquire] gets a pooled writer or creates a new one
/// - **Memory bounds:** Only reuses writers with
///    buffers ≤ `maxReusableCapacity`
/// - **Size limits:** Maintains max `maxPoolSize` pooled instances
/// - **Safe:** Prevents double-release and handles edge cases
/// - **Instantiable:** Create custom pools for specific use cases or use the
///   default global pool.
///
/// ## Usage Pattern
///
/// **Using the default global pool:**
/// ```dart
/// final writer = BinaryWriterPool.acquire();
/// try {
///   writer.writeUint32(42);
///   writer.writeString('Hello');
///   final bytes = writer.toBytes();
/// } finally {
///   BinaryWriterPool.release(writer);
/// }
/// ```
///
/// **Creating a custom pool:**
/// ```dart
/// final myPool = BinaryWriterPool(
///   maxPoolSize: 10,
///   initialBufferSize: 512,
///   maxReusableCapacity: 4096,
/// );
///
/// final writer = myPool.acquireInstance();
/// // ...
/// myPool.releaseInstance(writer);
/// ```
///
/// ## Performance Considerations
/// - Pooling is beneficial for high-frequency write operations
/// - Overhead is minimal for single-use writers (use regular constructor)
/// - Large buffers (>64 KiB by default) are discarded to avoid memory waste
///
/// See also: [BinaryWriter]
final class BinaryWriterPool {
  /// Creates a new, isolated [BinaryWriterPool].
  ///
  /// Parameters:
  /// - [maxPoolSize]: Maximum number of writers to keep in the pool
  ///   (default: 32).
  /// - [initialBufferSize]: Default initial buffer size for new writers
  ///   (default: 1 KiB).
  /// - [maxReusableCapacity]: Maximum buffer capacity allowed for pooling
  ///   (default: 64 KiB). Writers exceeding this are discarded on release.
  BinaryWriterPool({
    int maxPoolSize = 32,
    int initialBufferSize = 1024,
    int maxReusableCapacity = 64 * 1024,
  }) {
    _validateConfig(maxPoolSize, initialBufferSize, maxReusableCapacity);
    _maxPoolSize = maxPoolSize;
    _initialBufferSize = initialBufferSize;
    _maxReusableCapacity = maxReusableCapacity;
  }

  /// The default global instance of [BinaryWriterPool].
  ///
  /// This is used when calling the static methods on [BinaryWriterPool].
  static final global = BinaryWriterPool();

  // The internal pool of reusable writer states.
  final List<_WriterState> _pool = [];

  late int _maxPoolSize;
  late int _initialBufferSize;
  late int _maxReusableCapacity;

  // Performance counters
  var _acquireHit = 0;
  var _acquireMiss = 0;
  var _peakPoolSize = 0;
  var _discardedLargeBuffers = 0;
  var _discardedPoolFull = 0;

  static void _validateConfig(
    int maxPoolSize,
    int initialBufferSize,
    int maxReusableCapacity,
  ) {
    if (maxPoolSize <= 0) {
      throw ArgumentError.value(maxPoolSize, 'maxPoolSize', 'Must be positive');
    }

    if (initialBufferSize <= 0) {
      throw ArgumentError.value(
        initialBufferSize,
        'initialBufferSize',
        'Must be positive',
      );
    }

    if (maxReusableCapacity <= 0) {
      throw ArgumentError.value(
        maxReusableCapacity,
        'maxReusableCapacity',
        'Must be positive',
      );
    }

    if (initialBufferSize > maxReusableCapacity) {
      throw ArgumentError(
        'initialBufferSize ($initialBufferSize) cannot be larger than '
        'maxReusableCapacity ($maxReusableCapacity). '
        'This would cause all pooled writers to be discarded immediately.',
      );
    }
  }

  /// Configures the default global pool settings.
  ///
  /// This should typically be called once at application startup.
  static void configure({
    int maxPoolSize = 32,
    int initialBufferSize = 1024,
    int maxReusableCapacity = 64 * 1024,
  }) {
    global.reconfigure(
      maxPoolSize: maxPoolSize,
      initialBufferSize: initialBufferSize,
      maxReusableCapacity: maxReusableCapacity,
    );
  }

  /// Reconfigures the settings of this specific pool instance.
  void reconfigure({
    int maxPoolSize = 32,
    int initialBufferSize = 1024,
    int maxReusableCapacity = 64 * 1024,
  }) {
    _validateConfig(maxPoolSize, initialBufferSize, maxReusableCapacity);
    _maxPoolSize = maxPoolSize;
    _initialBufferSize = initialBufferSize;
    _maxReusableCapacity = maxReusableCapacity;
  }

  /// Acquires a [BinaryWriter] from the default global pool.
  static BinaryWriter acquire([int? initialBufferSize]) =>
      global.acquireInstance(initialBufferSize);

  /// Acquires a [BinaryWriter] from this specific pool instance.
  BinaryWriter acquireInstance([int? initialBufferSize]) {
    final size = initialBufferSize ?? _initialBufferSize;

    if (size <= 0) {
      throw RangeError.value(
        size,
        'initialBufferSize',
        'Must be positive',
      );
    }

    if (_pool.isNotEmpty) {
      var bestIndex = -1;
      var smallestSuitableCapacity = double.infinity;

      for (var i = 0; i < _pool.length; i++) {
        final cap = _pool[i].capacity;
        if (cap >= size && cap < smallestSuitableCapacity) {
          bestIndex = i;
          smallestSuitableCapacity = cap.toDouble();
        }
      }

      if (bestIndex == -1) {
        var largestCap = -1;
        for (var i = 0; i < _pool.length; i++) {
          if (_pool[i].capacity > largestCap) {
            largestCap = _pool[i].capacity;
            bestIndex = i;
          }
        }
      }

      _acquireHit++;
      final state = _pool.removeAt(bestIndex).._isInPool = false;

      if (state.capacity < size) {
        state.ensureSize(size);
      }

      return BinaryWriter._(state);
    }

    _acquireMiss++;

    return BinaryWriter(initialBufferSize: size);
  }

  /// Acquires a writer from the default global pool, executes the given
  /// [action], and automatically releases it.
  static T withWriter<T>(
    T Function(BinaryWriter writer) action, [
    int? initialBufferSize,
  ]) => global.withWriterInstance(action, initialBufferSize);

  /// Acquires a writer from this pool instance, executes the given
  /// [action], and automatically releases it.
  T withWriterInstance<T>(
    T Function(BinaryWriter writer) action, [
    int? initialBufferSize,
  ]) {
    final writer = acquireInstance(initialBufferSize);
    try {
      return action(writer);
    } finally {
      releaseInstance(writer);
    }
  }

  /// Returns a [BinaryWriter] to the default global pool.
  static void release(BinaryWriter writer) => global.releaseInstance(writer);

  /// Returns a [BinaryWriter] to this specific pool instance.
  void releaseInstance(BinaryWriter writer) {
    final state = writer._ws;

    if (state._isInPool) {
      return;
    }

    if (state.capacity <= _maxReusableCapacity && _pool.length < _maxPoolSize) {
      state
        ..offset = 0
        .._isInPool = true;
      _pool.add(state);

      if (_pool.length > _peakPoolSize) {
        _peakPoolSize = _pool.length;
      }
    } else if (state.capacity > _maxReusableCapacity) {
      _discardedLargeBuffers++;
    } else {
      _discardedPoolFull++;
    }
  }

  /// Returns statistics for the default global pool.
  static PoolStatistics get stats => global.instanceStats;

  /// Returns statistics for this specific pool instance.
  PoolStatistics get instanceStats => PoolStatistics({
    'pooled': _pool.length,
    'maxPoolSize': _maxPoolSize,
    'initialBufferSize': _initialBufferSize,
    'maxReusableCapacity': _maxReusableCapacity,
    'acquireHit': _acquireHit,
    'acquireMiss': _acquireMiss,
    'peakPoolSize': _peakPoolSize,
    'discardedLargeBuffers': _discardedLargeBuffers,
    'discardedPoolFull': _discardedPoolFull,
  });

  /// Clears the default global pool.
  static void clear() => global.clearInstance();

  /// Clears this specific pool instance.
  void clearInstance() {
    _pool.clear();
    _acquireHit = 0;
    _acquireMiss = 0;
    _peakPoolSize = 0;
    _discardedLargeBuffers = 0;
    _discardedPoolFull = 0;
  }
}

extension type PoolStatistics(Map<String, int> _stats) {
  /// Number of writers currently in the pool.
  int get pooled => _stats['pooled']!;

  /// Maximum pool capacity.
  int get maxPoolSize => _stats['maxPoolSize']!;

  /// Initial buffer size for new writers.
  int get initialBufferSize => _stats['initialBufferSize']!;

  /// Maximum buffer size for pooling.
  int get maxReusableCapacity => _stats['maxReusableCapacity']!;

  /// Number of successful reuses from pool (cache hits).
  int get acquireHit => _stats['acquireHit']!;

  /// Number of new writer allocations (cache misses).
  int get acquireMiss => _stats['acquireMiss']!;

  /// Maximum pool size reached during runtime.
  int get peakPoolSize => _stats['peakPoolSize']!;

  /// Number of oversized buffers discarded to prevent memory bloat.
  int get discardedLargeBuffers => _stats['discardedLargeBuffers']!;

  /// Number of writers discarded because the pool was full.
  int get discardedPoolFull => _stats['discardedPoolFull']!;

  /// Total number of acquire operations.
  int get totalAcquires => acquireHit + acquireMiss;

  /// Cache hit rate (0.0 to 1.0).
  double get hitRate => totalAcquires > 0 ? acquireHit / totalAcquires : 0.0;
}
