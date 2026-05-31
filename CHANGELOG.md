<!-- markdownlint-disable-file MD025 -->

# 5.3.0

- **BinaryReader**:
  - **New Feature**: Added random access read methods — `getUint8(int position)`, `getInt16(int position)`, `getUint16(int position)`, `getInt32(int position)`, `getUint32(int position)`, `getInt64(int position)`, `getUint64(int position)`, `getFloat32(int position)`, `getFloat64(int position)` — read at arbitrary position without advancing offset.
  - **Refactoring**: Rewritten using `extension type` for zero-cost abstractions.
  - **Refactoring**: Methods organized into semantic extension groups (`BinaryReaderCore`, `BinaryReaderVarInt`, `BinaryReaderNumeric`, `BinaryReaderBytesString`, `BinaryReaderRandomAccess`, `BinaryReaderPosition`, `BinaryReaderInternal`).

- **BinaryWriter**:
  - **New Feature**: Added random access read methods — `getUint8(int position)`, `getInt16(int position)`, `getUint16(int position)`, `getInt32(int position)`, `getUint32(int position)`, `getInt64(int position)`, `getUint64(int position)`, `getFloat32(int position)`, `getFloat64(int position)` — read written bytes at arbitrary position.
  - **New Feature**: Added random access write methods — `setUint8(int position, int value)`, `setInt16(int position, int value)`, `setUint16(int position, int value)`, `setInt32(int position, int value)`, `setUint32(int position, int value)`, `setInt64(int position, int value)`, `setUint64(int position, int value)`, `setFloat32(int position, double value)`, `setFloat64(int position, double value)` — write at arbitrary position without changing offset.
  - **Refactoring**: Rewritten using `extension type` for zero-cost abstractions.
  - **Refactoring**: Methods organized into semantic extension groups (`BinaryWriterCore`, `BinaryWriterVarInt`, `BinaryWriterNumeric`, `BinaryWriterBytesString`, `BinaryWriterRandomAccess`, `BinaryWriterPosition`, `BinaryWriterInternal`).

- **Tests**:
  - Added `test/unit/binary_reader_get_test.dart` — 41 tests for random access reads.
  - Added `test/unit/binary_writer_set_get_test.dart` — 49 tests for random access reads/writes.

# 5.2.0

- **BinaryWriter**:
  - **New Feature**: Added `skip(int count)` — advances the write position by [count] bytes without writing data, for reserving space (Reserve & Backpatch pattern).
  - **New Feature**: Added `shiftBytes(int start, int end, int target)` — shifts a block of written bytes within the buffer, enabling in-place compaction when reserved header space exceeds actual needs.

# 5.1.0

- **BinaryWriterPool**:
  - **New Feature**: Added `BinaryWriterPool.configure()` for global pool settings (`maxPoolSize`, `initialBufferSize`, `maxReusableCapacity`).
  - **New Feature**: Implemented "best-fit" acquisition strategy to minimize memory fragmentation.
  - **New Feature**: Added `BinaryWriterPool.stats` for real-time pool performance monitoring.
  - **Improvement**: Optimized `release()` and `clear()` logic with zero-allocation buffer detachment.
  - **Bug Fix**: Renamed `initialBufferSizer` to `initialBufferSize` (API alignment).

- **BinaryWriter**:
  - **New Feature**: Added `operator []` and `operator []=` for symmetric random access to written bytes.
  - **New Feature**: Added `copy` parameter to `takeBytes()` to allow returning data while retaining the internal buffer for pool reuse.
  - **Improvement**: Refactored `writeUint8At` as a functional alias for `operator []=`.
  - **Fix**: Corrected documentation for bounds checks on random access methods.

- **Documentation**:
  - Unified terminology (using "1 KiB" consistently).
  - Updated `withWriter` examples to recommend `takeBytes(copy: true)` for pooling scenarios.

# 5.0.0

- **BREAKING CHANGES:**
  - **Stream API**: rewritten architecture — `StreamBinaryReader` now `implements TransactionalReader<List<int>>` with delegation to state
  - **`NotEnoughDataException`**: message changed from `required $required bytes` to `required $required`

- **New Features:**
  - **Strings**: added `writeStringFixed` and `readStringFixed` for fixed-width length-prefixed strings.
  - **Stream API**: added `TransactionalReader<TChunk>` interface for abstracting transactional read model
  - **Stream API**: added `ChunkedTransactionalState<TChunk>` base class for managing chunk queue and bookmarks
  - **Stream API**: added `TransactionalStreamTransformer<TMessage, TChunk, TReader>` — generic `StreamTransformer` for parsing streams
  - **Stream API**: `BinaryStreamTransformer` now extends `TransactionalStreamTransformer`
  - **BinaryWriter**: improved `writeVarString` documentation with examples
  - **BinaryReader**: `peekByte()` added bounds check — throws `RangeError`
  - **Examples**: full restructuring — removed `example/main.dart`, added `example/basic/`, `example/network_streaming/`, `example/file_streaming/`

# 4.0.0

**BREAKING CHANGES:**

- **BinaryReader**: removed `reset()` method — use `seek(0)` instead

**New Features:**

- **BinaryReader**: added `rebind(Uint8List)` — rebinds the reader to a new buffer without allocating a new instance (useful for streaming scenarios)
- **BinaryWriter**: added `seek(int position)` — sets the write position to the specified byte offset (useful for backtracking and overwriting data mid-stream)
- **BinaryWriter**: added `writeUint8At(int position, int value)` — writes a byte at the specified position without changing the current write position
- **BinaryWriter**: `writeVarString` now uses `seek` internally for VarInt length rewriting
- **Stream API**: added `StreamBinaryReader` — chunk-based reader for asynchronous streaming data with bookmark/rollback/commit transactional model
- **Stream API**: added `BinaryStreamTransformer<T>` — abstract `StreamTransformer` for parsing binary messages from streams with automatic `NotEnoughDataException` handling
- **Stream API**: added `NotEnoughDataException` — carries `required`/`available` byte counts for debugging incomplete data scenarios

**Fixes:**

- **BinaryReader**: added bounds check to `peekByte()` — now throws `RangeError` consistently like other read methods

**Tests:** Improved all tests

# 3.2.0

**BREAKING CHANGES:**

- **BinaryWriterPool**: renamed `_defaultBufferSize` → `_initialBufferSizer` (and parameter `defaultBufferSize` → `initialBufferSizer` in `acquire()` and `withWriter()`)

**New Features:**

- **BinaryWriterPool**: added `_discardedPoolFull` counter — tracks writers discarded due to pool full (max 32)
- **BinaryWriter**: added `_varIntSize(int value)` — helper function for VarInt size calculation (switch expression)
- **BinaryReader**: added `peekByte()` — returns byte at current position without advancing offset
- **BinaryReader**: added `BinaryReader.fromList(List<int>)` — convenient constructor for `List<int>`

**Fixes:**

- **BinaryWriterPool**: added validation for `initialBufferSizer` in `acquire()` — throws `RangeError` for invalid size
- **BinaryWriterPool**: `_initializeBuffer()` now resets `_isInPool = false`, correct `takeBytes()` → `release()` flow for pooled writers
- **BinaryWriterPool**: `clear()` now resets `_isInPool` for pooled writers
- **BinaryReader/BinaryWriter**: removed unnecessary `late` from `_ReaderState` and `_WriterState` (offset, capacity, list)
- **BinaryReader**: removed redundant bounds check in `peekBytes()` (already guarded by `_checkBounds`)

**Refactoring:**

- **_WriterState**: renamed `_validated` → `_fromSize`
- **string_utils.dart**: replaced JSDoc tags `@param`/`@return` with Dart style (`Parameters:`/`Returns:`)

**Tests:**

- Added tests for pool statistics, edge cases takeBytes/reset/release

# 3.1.0

- **feat**: Added `BinaryWriterPool.withWriter()` for safer and more concise object pool usage.
- **feat**: Added modern API features for a more idiomatic experience:
  - `BinaryReader`: Added `operator []` for absolute byte access (e.g., `reader[0]`).
  - `BinaryReader`: Added `call()` method for shorthand byte reading (e.g., `reader(10)`).
  - `BinaryWriter`: Added `call()` method for shorthand byte writing (e.g., `writer([1, 2, 3])`).
- **performance**: Optimized `writeVarString` with a high-performance one-pass "optimistic shift" algorithm (~30% faster).
- **performance**: Unrolled `readVarUint` loop for the first 3 bytes, resulting in ~25% speedup in AOT mode.
- **performance**: Applied Fast Path / Slow Path optimization to buffer expansion logic for better inlining.
- **improvement**: Enhanced `BinaryWriterPool.clear()` with explicit buffer reference discarding to assist GC.
- **fix**: Added missing `ensureSize` check in `BinaryWriterPool.acquire` to guarantee buffer capacity when reusing writers.
- **improvement**: Updated lint rules to `pro_lints/recommended.yaml` and resolved related lint issues.
- **deps**: Updated `pro_lints`, `test`, and `meta` dependencies to latest versions.
- **test**: Refactored pool benchmarks for better accuracy and reliability.
- **docs**: Fixed minor typos and improved documentation for `BinaryWriterPool`.
- **docs**: Complete README overhaul with a focus on recipes and technical clarity.

# 3.0.0

**Improvements:**

- **feat**: New methods and properties
  - `BinaryWriterPool` for reusing `BinaryWriter` instances
  - `getUtf8Length(String)` to calculate UTF-8 byte length without encoding
  - `writeVarString(String)` and `readVarString()` for variable-length string encoding
  - `writeBool` and `readBool` methods for boolean values
  - `writeVarUint` and `readVarUint` for variable-length unsigned integers
  - `writeVarInt` and `readVarInt` for variable-length signed integers
  - `writeVarBytes` and `readVarBytes` for variable-length byte arrays
  - Navigation methods in `BinaryReader`: `peekBytes()`, `skip()`, `seek()`, `rewind()`, and `reset()`
- **docs**: Comprehensive documentation overhaul
  - Added detailed API documentation with usage examples for all methods
  - Documented `writeVarString()`, `readVarString()`, and `getUtf8Length()`
  - Included performance notes and best practices
  - Added inline comments explaining complex encoding algorithms
- **test**: Expanded test suite
  - Coverage for all new methods and edge cases
  - Performance benchmarks for encoding/decoding functions
  - Validation tests for UTF-8 handling and error scenarios
- **improvement**: Refactored internal codebase
  - Improved modularity and readability
  - Enhanced error handling with descriptive messages
  - Optimized buffer management for better performance

- **fix**: Resolved known issues

# 2.2.0

 **test**: Added integration tests for new error handling features
 **deps**: Update internal dependencies to latest versions

# 2.1.0

- **feat**: Added detailed error messages with context (offset, available bytes)
- **feat**: Added `toBytes()` method in `BinaryWriter` (returns buffer without reset)
- **feat**: Added `reset()` method in `BinaryWriter` (resets without returning data)
- **feat**: Added `allowMalformed` parameter to `readString` in `BinaryReader`
- **improvement**: Increased performance of read/write operations
- **improvement**: Optimized internal buffer management in `BinaryWriter`
- **improvement**: Added validation for all boundary conditions
- **test**: Added new tests for boundary checks and new methods
- **docs**: Updated documentation with better examples and error handling

# 2.0.0

- Update dependencies
- sdk: ^3.6.0

# 1.1.1

- fix: warnings

# 1.1.0

- fix: Increased test coverage, providing more comprehensive validation for edge cases.
- performance: Optimized buffer management to reduce memory reallocations and improve efficiency.
- docs: Updated documentation to cover new properties and methods, including additional examples.

- Writer:
  - feat: Added `bytesWritten` property to track the total number of bytes written to the buffer.
  - feat: Introduced `initialBufferSize` parameter in the constructor, allowing configuration of the initial buffer size for optimized memory usage.
  - improvement: Enhanced memory management, with the buffer now resizing by doubling in size when capacity is reached to reduce frequent resizing.

- Reader:
  - feat: Added `bytesRead` property to monitor the total number of bytes read from the buffer.
  - feat: Introduced `reset` method, allowing users to reset the reading position to the start of the buffer for convenient re-reading.

# 1.0.2

- docs: Updated documentation.

# 1.0.1

- docs: Updated documentation.
- feat: Added `example` directory with basic usage examples.

# 1.0.0

- Initial release.
