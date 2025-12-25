## 3.0.0

**Improvements:**

- **docs**: Comprehensive documentation overhaul
  - Added detailed API documentation with usage examples for all methods
  - Documented `writeVarString()`, `readVarString()`, and `getUtf8Length()`
  - Included performance notes and best practices
  - Added inline comments explaining complex encoding algorithms
  - Improved README with real-world examples and migration guide
- **test**: Added 23 new comprehensive tests
  - 7 tests for `writeVarString()` (ASCII, UTF-8, emoji, empty, mixed, round-trip, malformed)
  - 8 tests for `getUtf8Length()` (ASCII, empty, 2-byte, 3-byte, 4-byte, mixed, validation, surrogates)
  - 8 tests for `readVarString()` (basic, UTF-8, emoji, empty, multiple, error handling)

## 2.2.0

 **test**: Added integration tests for new error handling features
 **deps**: Update internal dependencies to latest versions

## 2.1.0

- **feat**: Added detailed error messages with context (offset, available bytes)
- **feat**: Added `toBytes()` method in `BinaryWriter` (returns buffer without reset)
- **feat**: Added `reset()` method in `BinaryWriter` (resets without returning data)
- **feat**: Added `allowMalformed` parameter to `readString` in `BinaryReader`
- **improvement**: Increased performance of read/write operations
- **improvement**: Optimized internal buffer management in `BinaryWriter`
- **improvement**: Added validation for all boundary conditions
- **test**: Added new tests for boundary checks and new methods
- **docs**: Updated documentation with better examples and error handling

## 2.0.0

- Update dependencies
- sdk: ^3.6.0

## 1.1.1

- fix: warnings

## 1.1.0

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

## 1.0.2

- docs: Updated documentation.

## 1.0.1

- docs: Updated documentation.
- feat: Added `example` directory with basic usage examples.

## 1.0.0

- Initial release.
