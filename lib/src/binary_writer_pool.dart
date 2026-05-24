part of 'binary_writer.dart';

// Disable lint to allow static-only class for pooling
/// Object pool for reusing [BinaryWriter] instances to reduce GC pressure.
///
/// This pool maintains a cache of [BinaryWriter] instances with their
/// internal buffers, allowing efficient reuse without allocating new memory
/// for each write operation.
///
/// ## Features
/// - **Automatic reuse:** [acquire] gets a pooled writer or creates a new one
/// - **Memory bounds:** Only reuses writers with buffers ≤ 64 KiB
/// - **Size limits:** Maintains max 32 pooled instances
/// - **Safe:** Prevents double-release and handles edge cases
///
/// ## Usage Pattern
/// Use `acquire()` and `release()` for short-lived write operations:
///
/// ```dart
/// final writer = BinaryWriterPool.acquire();
/// try {
///   writer.writeUint32(42);
///   writer.writeString('Hello');
///   final bytes = writer.toBytes();
///   // Use bytes...
/// } finally {
///   BinaryWriterPool.release(writer);  // Return to pool
/// }
/// ```
///
/// ## Thread Safety
/// This pool is isolate-local. Each Dart isolate maintains its own
/// static pool instance.
///
/// Avoid sharing [BinaryWriter] instances between different isolates.
/// For concurrent operations within the same isolate, ensure writers
/// are acquired and released synchronously or protected by logic
/// to prevent interleaved usage.
///
/// ## Performance Considerations
/// - Pooling is beneficial for high-frequency write operations
/// - Overhead is minimal for single-use writers (use regular constructor)
/// - Large buffers (>64 KiB) are discarded to avoid memory waste
///
/// ## Memory Management
/// - Pool max size: 32 writers
/// - Max reusable buffer: 64 KiB
/// - Default buffer size: 1 KiB
/// - Use [clear] to free pooled memory explicitly
///
/// See also: [BinaryWriter], [stats] for pool monitoring
// ignore: avoid_classes_with_only_static_members
abstract final class BinaryWriterPool {
  // The internal pool of reusable writer states.
  static final _pool = <_WriterState>[];

  /// Maximum number of writers to keep in the pool.
  static const _maxPoolSize = 32;

  /// Default initial buffer size for new writers (1 KiB).
  static const _initialBufferSizer = 1024;

  /// Maximum buffer capacity allowed for pooling (64 KiB).
  /// Writers that exceed this size are discarded to free up system memory
  static const int _maxReusableCapacity = 64 * 1024;

  // Performance counters
  static var _acquireHit = 0;
  static var _acquireMiss = 0;
  static var _peakPoolSize = 0;
  static var _discardedLargeBuffers = 0;
  static var _discardedPoolFull = 0;

  /// Acquires a [BinaryWriter] from the pool or creates a new one.
  ///
  /// Returns a pooled writer if available, otherwise creates a fresh instance
  /// with the default buffer size (1 KiB).
  ///
  /// The returned writer is ready to use and should be returned to the pool
  /// via [release] when no longer needed.
  ///
  /// **Best Practice:** Always use a `try-finally` block.
  ///
  /// There are two ways to get the data:
  /// 1. Use [BinaryWriter.toBytes] if you consume data **inside** the try
  ///   block (zero-copy view).
  /// 2. Use [BinaryWriter.takeBytes] if you need to **return** the data
  ///   (transfers buffer ownership).
  ///
  /// ```dart
  /// final writer = BinaryWriterPool.acquire();
  /// try {
  ///   writer.writeUint32(123);
  ///   return writer.takeBytes();
  /// } finally {
  ///   BinaryWriterPool.release(writer);
  /// }
  /// ```
  ///
  /// Returns: A [BinaryWriter] ready for use.
  static BinaryWriter acquire([int initialBufferSizer = _initialBufferSizer]) {
    if (initialBufferSizer <= 0) {
      throw RangeError.value(
        initialBufferSizer,
        'initialBufferSizer',
        'Must be positive',
      );
    }

    if (_pool.isNotEmpty) {
      _acquireHit++;
      final state = _pool.removeLast().._isInPool = false;

      if (state.capacity < initialBufferSizer) {
        state.ensureSize(initialBufferSizer);
      }

      return BinaryWriter._(state);
    }

    _acquireMiss++;

    return BinaryWriter(initialBufferSize: initialBufferSizer);
  }

  /// Acquires a writer, executes the given [action], and automatically
  /// releases the writer back to the pool.
  ///
  /// This is the recommended way to use the pool as it ensures the writer
  /// is always released even if an exception occurs.
  ///
  /// Parameters:
  /// - [action]: The function to execute with the acquired writer
  /// - [initialBufferSizer]: Initial buffer size for new writers (defaults to 1 KiB)
  ///
  /// Example:
  /// ```dart
  /// final bytes = BinaryWriterPool.withWriter((writer) {
  ///   writer.writeUint32(42);
  ///   return writer.takeBytes();
  /// });
  /// ```
  static T withWriter<T>(
    T Function(BinaryWriter writer) action, [
    int initialBufferSizer = _initialBufferSizer,
  ]) {
    final writer = acquire(initialBufferSizer);
    try {
      return action(writer);
    } finally {
      release(writer);
    }
  }

  /// Returns a [BinaryWriter] to the pool for future reuse.
  ///
  /// The writer is reset (offset cleared) and stored for future [acquire]
  /// calls. Writers with buffers larger than 64 KiB are not pooled to avoid
  /// long-term memory retention.
  ///
  /// **Safe to call multiple times** (duplicate releases are ignored).
  ///
  /// Only writers with capacity ≤ 64 KiB are pooled. Writers exceeding this
  /// limit are discarded, allowing the buffer to be garbage collected.
  ///
  /// **Do NOT use the writer after releasing it:**
  ///
  /// ```dart
  /// final writer = BinaryWriterPool.acquire();
  /// writer.writeUint32(42);
  /// final bytes = writer.toBytes();
  /// BinaryWriterPool.release(writer);
  /// // DON'T USE writer here - it's returned to the pool and may be reused!
  /// ```
  ///
  /// Parameters:
  /// - [writer]: The [BinaryWriter] to return to the pool
  static void release(BinaryWriter writer) {
    final state = writer._ws;

    // Prevent double-release and state corruption
    if (state._isInPool) {
      return;
    }

    // Only pool writers with reasonable buffer sizes
    // Prevents memory bloat from occasional large allocations
    if (state.capacity <= _maxReusableCapacity && _pool.length < _maxPoolSize) {
      state
        ..offset = 0
        .._isInPool = true;
      _pool.add(state);

      // Track peak pool size
      if (_pool.length > _peakPoolSize) {
        _peakPoolSize = _pool.length;
      }
    } else if (state.capacity > _maxReusableCapacity) {
      _discardedLargeBuffers++;
    } else {
      _discardedPoolFull++;
    }
  }

  /// Returns pool statistics for monitoring and debugging.
  ///
  /// Useful for performance analysis and detecting pool inefficiencies.
  ///
  /// Returns a map with keys:
  /// - `'pooled'`: Number of writers currently in the pool
  /// - `'maxPoolSize'`: Maximum pool capacity
  /// - `'initialBufferSizer'`: Initial buffer size for new writers
  /// - `'maxReusableCapacity'`: Maximum buffer size for pooling
  /// - `'acquireHit'`: Number of successful reuses from pool
  /// - `'acquireMiss'`: Number of new writer allocations
  /// - `'peakPoolSize'`: Maximum pool size reached
  /// - `'discardedLargeBuffers'`: Number of oversized buffers discarded
  /// - `'discardedPoolFull'`: Number of writers discarded when pool is full
  ///
  /// Example:
  /// ```dart
  /// final stats = BinaryWriterPool.stats;
  /// print('Pooled writers: ${stats.pooled}');  // 5
  /// print('Hit rate: ${stats.acquireHit / (stats.acquireHit + stats.acquireMiss)}');
  /// ```
  static PoolStatistics get stats => PoolStatistics({
    'pooled': _pool.length,
    'maxPoolSize': _maxPoolSize,
    'initialBufferSizer': _initialBufferSizer,
    'maxReusableCapacity': _maxReusableCapacity,
    'acquireHit': _acquireHit,
    'acquireMiss': _acquireMiss,
    'peakPoolSize': _peakPoolSize,
    'discardedLargeBuffers': _discardedLargeBuffers,
    'discardedPoolFull': _discardedPoolFull,
  });

  /// Clears the pool, releasing all cached writers.
  ///
  /// Use this to:
  /// - Free memory during low-activity periods
  /// - Reset pool state in tests
  /// - Handle memory pressure
  ///
  /// After clearing, subsequent [acquire] calls will create new writers.
  ///
  /// Example:
  /// ```dart
  /// BinaryWriterPool.clear();  // All pooled writers discarded
  /// ```
  static void clear() {
    // Assist GC by breaking links to potentially large byte buffers
    for (var i = 0; i < _pool.length; i++) {
      _pool[i]
        ..list = Uint8List(0)
        ..data = ByteData(0)
        .._isInPool = false;
    }
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
  int get initialBufferSizer => _stats['initialBufferSizer']!;

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
