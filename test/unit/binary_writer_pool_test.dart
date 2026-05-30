import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriterPool', () {
    setUp(BinaryWriterPool.clear);

    tearDown(BinaryWriterPool.clear);

    test('acquire returns a working writer', () {
      final writer = BinaryWriterPool.acquire()..writeUint32(42);
      final bytes = writer.toBytes();
      BinaryWriterPool.release(writer);

      expect(bytes, hasLength(4));
    });

    test('acquire reuses pooled writer', () {
      final writer1 = BinaryWriterPool.acquire()..writeUint32(42);
      BinaryWriterPool.release(writer1);
      expect(BinaryWriterPool.stats.pooled, equals(1));

      final writer2 = BinaryWriterPool.acquire();
      expect(BinaryWriterPool.stats.pooled, equals(0));
      expect(writer2.bytesWritten, equals(0)); // Should be cleared
      BinaryWriterPool.release(writer2);
    });

    test('clear empties the pool', () {
      final writer1 = BinaryWriterPool.acquire();
      final writer2 = BinaryWriterPool.acquire();
      BinaryWriterPool.release(writer1);
      BinaryWriterPool.release(writer2);
      expect(BinaryWriterPool.stats.pooled, equals(2));

      BinaryWriterPool.clear();
      expect(BinaryWriterPool.stats.pooled, equals(0));
    });

    test('discardedLargeBuffers increments when buffer exceeds limit', () {
      expect(BinaryWriterPool.stats.discardedLargeBuffers, equals(0));
      final writer = BinaryWriterPool.acquire();
      // Write enough data to expand buffer beyond 64 KiB
      final largeData = List<int>.filled(70 * 1024, 42);
      writer.writeBytes(largeData);
      BinaryWriterPool.release(writer);

      expect(BinaryWriterPool.stats.discardedLargeBuffers, equals(1));
      expect(BinaryWriterPool.stats.pooled, equals(0));
    });

    test('withWriter executes action and releases writer', () {
      final result = BinaryWriterPool.withWriter((w) {
        w.writeUint32(42);
        return w.toBytes();
      });
      expect(result, equals([0, 0, 0, 42]));
      expect(BinaryWriterPool.stats.pooled, greaterThan(0));
    });

    test('withWriter releases writer even on error', () {
      BinaryWriterPool.clear();
      expect(
        () => BinaryWriterPool.withWriter((w) {
          throw Exception('Test');
        }),
        throwsException,
      );
      expect(BinaryWriterPool.stats.pooled, equals(1));
    });

    test('acquire expands pooled writer if requested size is larger', () {
      BinaryWriterPool.clear();
      final writer = BinaryWriterPool.acquire(100);
      BinaryWriterPool.release(writer);

      final largerWriter = BinaryWriterPool.acquire(1000);
      expect(largerWriter.capacity, greaterThanOrEqualTo(1000));
      BinaryWriterPool.release(largerWriter);
    });

    group('configure', () {
      test('sets pool limits correctly', () {
        BinaryWriterPool.configure(
          maxPoolSize: 10,
          initialBufferSize: 512,
          maxReusableCapacity: 2048,
        );

        final stats = BinaryWriterPool.stats;
        expect(stats.maxPoolSize, equals(10));
        expect(stats.initialBufferSize, equals(512));
        expect(stats.maxReusableCapacity, equals(2048));
      });

      test('throws ArgumentError for invalid values', () {
        expect(
          () => BinaryWriterPool.configure(maxPoolSize: 0),
          throwsArgumentError,
        );
        expect(
          () => BinaryWriterPool.configure(initialBufferSize: 0),
          throwsArgumentError,
        );
        expect(
          () => BinaryWriterPool.configure(maxReusableCapacity: 0),
          throwsArgumentError,
        );
        expect(
          () => BinaryWriterPool.configure(maxPoolSize: -1),
          throwsArgumentError,
        );
      });

      test(
        'throws ArgumentError if initialBufferSize > maxReusableCapacity',
        () {
          expect(
            () => BinaryWriterPool.configure(
              initialBufferSize: 2048,
              maxReusableCapacity: 1024,
            ),
            throwsArgumentError,
          );
        },
      );
    });

    group('Custom Instances', () {
      test('custom pool is isolated from global pool', () {
        final customPool = BinaryWriterPool(maxPoolSize: 5);
        final writer = customPool.acquireInstance();
        customPool.releaseInstance(writer);

        expect(customPool.instanceStats.pooled, equals(1));
        expect(BinaryWriterPool.stats.pooled, equals(0));
      });

      test('custom pool uses its own configuration', () {
        final customPool = BinaryWriterPool(
          maxPoolSize: 2,
          initialBufferSize: 256,
          maxReusableCapacity: 512,
        );

        final stats = customPool.instanceStats;
        expect(stats.maxPoolSize, equals(2));
        expect(stats.initialBufferSize, equals(256));
        expect(stats.maxReusableCapacity, equals(512));
      });

      test('withWriterInstance works correctly', () {
        final customPool = BinaryWriterPool();
        final result = customPool.withWriterInstance((w) {
          w.writeUint8(100);
          return w.toBytes();
        });
        expect(result, equals([100]));
        expect(customPool.instanceStats.pooled, equals(1));
      });

      test('reconfigure updates instance settings', () {
        final customPool = BinaryWriterPool(maxPoolSize: 5)
          ..reconfigure(maxPoolSize: 10);
        expect(customPool.instanceStats.maxPoolSize, equals(10));
      });
    });
  });
}
