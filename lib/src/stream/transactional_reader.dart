import 'dart:collection';
import 'dart:typed_data';

/// Exception thrown when a [TransactionalReader] does not have enough data
/// to complete a read operation.
class NotEnoughDataException implements Exception {
  /// Creates a new [NotEnoughDataException].
  const NotEnoughDataException(this.required, this.available);

  /// The number of bytes/elements required to complete the operation.
  final int required;

  /// The number of bytes/elements currently available in the reader.
  final int available;

  @override
  String toString() =>
      'NotEnoughDataException: required $required, but only '
      '$available available.';
}

/// A reader that supports a transactional model for streaming data.
abstract interface class TransactionalReader<TChunk> {
  /// The total number of unread elements currently available.
  int get availableBytes;

  /// Adds a new chunk of data to the reader.
  ///
  /// **Performance Tip:** If the implementation supports it, passing a platform
  /// optimized list type (like `Uint8List` for bytes) can enable zero-copy
  /// operations.
  void addChunk(TChunk chunk);

  /// Creates a checkpoint of the current reader state.
  void bookmark();

  /// Restores the reader to the state of the last [bookmark].
  void rollback();

  /// Removes the last [bookmark] without restoring the state.
  void commit();
}

/// A reusable base class for managing chunked transactional state.
///
/// It provides the core logic for managing the chunk queue and bookmarks.
/// Subclasses should extend this class, implement the [TransactionalReader]
/// interface, and override the abstract hook methods to customize behavior.
abstract base class ChunkedTransactionalState<TChunk> {
  /// Creates a new [ChunkedTransactionalState].
  ChunkedTransactionalState()
    : availableBytes = 0,
      currentAbsoluteIndex = 0,
      queueStartIndex = 0,
      chunks = ListQueue<TChunk>(),
      bookmarkAbsoluteIndex = Int32List(16),
      bookmarkAvailableBytes = Int32List(16),
      bookmarkCount = 0;

  /// The queue of chunks currently being processed.
  final ListQueue<TChunk> chunks;

  /// The absolute index of the current chunk being read.
  int currentAbsoluteIndex;

  /// The absolute index of the first chunk in the queue.
  int queueStartIndex;

  /// The total number of unread elements currently available.
  int availableBytes;

  /// Parallel array for bookmarking [currentAbsoluteIndex].
  Int32List bookmarkAbsoluteIndex;

  /// Parallel array for bookmarking [availableBytes].
  Int32List bookmarkAvailableBytes;

  /// The current number of active bookmarks.
  int bookmarkCount;

  /// Internal implementation of [TransactionalReader.addChunk].
  void addChunk(TChunk chunk) {
    chunks.add(chunk);
    availableBytes += getChunkLength(chunk);

    if (!hasCurrentReader) {
      final relativeIndex = currentAbsoluteIndex - queueStartIndex;
      if (relativeIndex >= 0 && relativeIndex < chunks.length) {
        onBindReader(chunks.elementAt(relativeIndex), 0);
      }
    }
  }

  /// Internal implementation of [TransactionalReader.bookmark].
  void bookmark() {
    if (bookmarkCount >= bookmarkAbsoluteIndex.length) {
      growBookmarks();
    }

    final count = bookmarkCount;
    bookmarkAbsoluteIndex[count] = currentAbsoluteIndex;
    bookmarkAvailableBytes[count] = availableBytes;
    onSaveBookmark(count);
    bookmarkCount++;
  }

  /// Internal implementation of [TransactionalReader.rollback].
  void rollback() {
    if (bookmarkCount == 0) {
      throw StateError('No bookmark to rollback to');
    }

    bookmarkCount--;
    final count = bookmarkCount;
    currentAbsoluteIndex = bookmarkAbsoluteIndex[count];
    availableBytes = bookmarkAvailableBytes[count];

    if (chunks.isNotEmpty) {
      final relativeIndex = currentAbsoluteIndex - queueStartIndex;
      final chunk = chunks.elementAt(relativeIndex);
      onBindReader(chunk, onRestoreBookmark(count));
    } else {
      onUnbindReader();
    }
  }

  /// Internal implementation of [TransactionalReader.commit].
  void commit() {
    if (bookmarkCount == 0) {
      throw StateError('No bookmark to commit');
    }

    bookmarkCount--;
    prune();
  }

  /// Advances the read position to the next chunk.
  void advanceChunk() {
    currentAbsoluteIndex++;
    if (bookmarkCount == 0) {
      chunks.removeFirst();
      queueStartIndex++;
    }

    final relativeIndex = currentAbsoluteIndex - queueStartIndex;
    if (relativeIndex < chunks.length) {
      onBindReader(chunks.elementAt(relativeIndex), 0);
    } else {
      onUnbindReader();
    }
  }

  /// Removes consumed chunks from the queue that are no longer needed for any
  /// active bookmarks.
  void prune() {
    final minNeeded = bookmarkCount == 0
        ? currentAbsoluteIndex
        : bookmarkAbsoluteIndex[0];

    while (queueStartIndex < minNeeded) {
      chunks.removeFirst();
      queueStartIndex++;
    }
  }

  /// Increases the capacity of the bookmark arrays.
  /// Subclasses should override this if they have additional bookmark arrays,
  /// calling `super.growBookmarks()` first.
  void growBookmarks() {
    final newCapacity = bookmarkAbsoluteIndex.length * 2;
    final newAbsIndex = Int32List(newCapacity);
    final newAvail = Int32List(newCapacity);

    newAbsIndex.setRange(0, bookmarkCount, bookmarkAbsoluteIndex);
    newAvail.setRange(0, bookmarkCount, bookmarkAvailableBytes);

    bookmarkAbsoluteIndex = newAbsIndex;
    bookmarkAvailableBytes = newAvail;
  }

  // --- Abstract Hooks ---

  /// Returns the length of the given [chunk].
  int getChunkLength(TChunk chunk);

  /// Returns `true` if a reader is currently bound to a chunk.
  bool get hasCurrentReader;

  /// Binds a reader to the given [chunk] at the specified [offset].
  void onBindReader(TChunk chunk, int offset);

  /// Unbinds the current reader.
  void onUnbindReader();

  /// Hook for subclasses to save their specific cursor state for a bookmark.
  void onSaveBookmark(int bookmarkIndex);

  /// Hook for subclasses to restore their specific cursor state from a
  /// bookmark.
  /// Returns the offset within the chunk that should be passed to
  /// [onBindReader].
  int onRestoreBookmark(int bookmarkIndex);
}
