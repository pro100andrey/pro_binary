import 'dart:typed_data';

/// The [BinaryWriterInterface] class is an abstract base class used to encode
/// various types of data into a binary format.
abstract class BinaryWriterInterface {
  /// Returns the number of bytes written to the buffer.
  int get bytesWritten;

  /// Writes an 8-bit unsigned integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 8-bit unsigned integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position, and the offset is
  /// incremented by 1 byte.
  ///
  /// The [value] parameter must be an unsigned 8-bit integer
  /// (range: 0 to 255).
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint8(200); // Writes the value 200 as a single byte.
  /// ```
  void writeUint8(int value);

  /// Writes an 8-bit signed integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 8-bit signed integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position, and the offset is
  /// incremented by 1 byte.
  ///
  /// The [value] parameter must be a signed 8-bit integer
  /// (range: -128 to 127).
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt8(-5); // Writes the value -5 as a single byte.
  /// ```
  void writeInt8(int value);

  /// Writes a 16-bit unsigned integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 16-bit unsigned integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position with the specified
  /// byte order (endian), and the offset is incremented by 2 bytes.
  ///
  /// The [value] parameter must be an unsigned 16-bit integer
  /// (range: 0 to 65535).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Throws [RangeError] if [value] is out of range.
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint16(500); // Writes the value 500 as two bytes in big-endian order.
  /// writer.writeUint16(500, Endian.little); // Writes the value 500 as two bytes in little-endian order.
  /// ```
  void writeUint16(int value, [Endian endian = Endian.big]);

  /// Writes a 16-bit signed integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 16-bit signed integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position with the specified
  /// byte order (endian), and the offset is incremented by 2 bytes.
  ///
  /// The [value] parameter must be a signed 16-bit integer
  /// (range: -32768 to 32767).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Throws [RangeError] if [value] is out of range.
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt16(-100); // Writes the value -100 as two bytes in big-endian order.
  /// writer.writeInt16(-100, Endian.little); // Writes the value -100 as two bytes in little-endian order.
  /// ```
  void writeInt16(int value, [Endian endian = Endian.big]);

  /// Writes a 32-bit unsigned integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 32-bit unsigned integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position with the specified
  /// byte order (endian), and the offset is incremented by 4 bytes.
  ///
  /// The [value] parameter must be an unsigned 32-bit integer
  /// (range: 0 to 4294967295).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Throws [RangeError] if [value] is out of range.
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint32(100000); // Writes the value 100000 as four bytes in big-endian order.
  /// writer.writeUint32(100000, Endian.little); // Writes the value 100000 as four bytes in little-endian order.
  /// ```
  void writeUint32(int value, [Endian endian = Endian.big]);

  /// Writes a 32-bit signed integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 32-bit signed integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position with the specified
  /// byte order (endian), and the offset is incremented by 4 bytes.
  ///
  /// The [value] parameter must be a signed 32-bit integer
  /// (range: -2147483648 to 2147483647).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt32(-50000); // Writes the value -50000 as four bytes in big-endian order.
  /// writer.writeInt32(-50000, Endian.little); // Writes the value -50000 as four bytes in little-endian order.
  /// ```
  void writeInt32(int value, [Endian endian = Endian.big]);

  /// Writes a 64-bit unsigned integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 64-bit unsigned integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position with the
  /// specified byte order (endian), and the offset is incremented by 8
  /// bytes.
  ///
  /// The [value] parameter must be an unsigned 64-bit integer
  /// (range: 0 to 18446744073709551615).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  ///  to [Endian.big]).
  ///
  /// Throws [RangeError] if [value] is out of range.
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint64(10000000000); // Writes the value 10000000000 as eight bytes in big-endian order.
  /// writer.writeUint64(10000000000, Endian.little); // Writes the value 10000000000 as eight bytes in little-endian order.
  /// ```
  void writeUint64(int value, [Endian endian = Endian.big]);

  /// Writes a 64-bit signed integer to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 64-bit signed integer. If necessary, it expands the buffer size. The
  /// integer is then written at the current offset position with the
  /// specified byte order (endian), and the offset is incremented by 8
  /// bytes.
  ///
  /// The [value] parameter must be a signed 64-bit integer
  /// (range: -9223372036854775808 to 9223372036854775807).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  ///  to [Endian.big]).
  ///
  /// Throws [RangeError] if [value] is out of range.
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt64(-10000000000); // Writes the value -10000000000 as eight bytes in big-endian order.
  /// writer.writeInt64(-10000000000, Endian.little); // Writes the value -10000000000 as eight bytes in little-endian order.
  /// ```
  void writeInt64(int value, [Endian endian = Endian.big]);

  /// Writes a 32-bit floating point number to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 32-bit float. If necessary, it expands the buffer size. The float is then
  /// written at the current offset position with the specified byte
  /// order (endian), and the offset is incremented by 4 bytes.
  ///
  /// The [value] parameter must be a 32-bit floating point number.
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Throws [RangeError] if [value] is out of range.
  ///
  /// Example:
  /// ```dart
  /// writer.writeFloat32(3.14); // Writes the value 3.14 as four bytes in big-endian order.
  /// writer.writeFloat32(3.14, Endian.little); // Writes the value 3.14 as four bytes in little-endian order.
  /// ```
  void writeFloat32(double value, [Endian endian = Endian.big]);

  /// Writes a 64-bit floating point number to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// 64-bit float. If necessary, it expands the buffer size. The float is then
  /// written at the current offset position with the specified byte
  /// order (endian), and the offset is incremented by 8 bytes.
  ///
  /// The [value] parameter must be a 64-bit floating point number.
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// writer.writeFloat64(3.14); // Writes the value 3.14 as eight bytes in big-endian order.
  /// writer.writeFloat64(3.14, Endian.little); // Writes the value 3.14 as eight bytes in little-endian order.
  /// ```
  void writeFloat64(double value, [Endian endian = Endian.big]);

  /// Writes a list of bytes to the buffer.
  ///
  /// This method ensures that there is enough space in the buffer to write the
  /// provided list of bytes. If necessary, it expands the buffer size. The
  /// bytes are then written at the current offset position. If the offset is 0,
  /// the bytes are added directly to the builder. Otherwise, the bytes are
  /// copied to the buffer, either directly (if the list is a [Uint8List]) or
  /// byte by byte.
  ///
  /// The [bytes] parameter must be a list of integers, where each integer is
  /// between 0 and 255 inclusive. The list may be retained until [takeBytes]
  /// is called.
  ///
  /// Example:
  /// ```dart
  /// writer.writeBytes([1, 2, 3, 4, 5]); // Writes the bytes 1, 2, 3, 4, and 5 to the buffer.
  /// ```
  void writeBytes(Iterable<int> bytes);

  /// Writes a UTF-8 encoded string to the buffer.
  ///
  /// This method encodes the provided string using UTF-8 encoding and writes
  /// the resulting bytes to the buffer. If necessary, it expands the buffer
  /// size to accommodate the encoded string. The encoded bytes are then written
  /// at the current offset position, and the offset is incremented by the
  /// length of the encoded string.
  ///
  /// The [value] parameter is the string to be encoded and written to the
  ///  buffer.
  ///
  /// The optional [allowMalformed] parameter specifies whether to allow
  /// malformed UTF-16 sequences (lone surrogates). If false, a
  /// [FormatException]
  /// is thrown when encountering invalid surrogate pairs. If true (default),
  /// invalid surrogates are replaced with the Unicode replacement character
  /// U+FFFD (�).
  ///
  /// Example:
  /// ```dart
  /// writer.writeString("Hello, world!"); // Writes the string "Hello, world!" as UTF-8 bytes to the buffer.
  /// writer.writeString("Test\uD800End", allowMalformed: false); // Throws FormatException for lone surrogate
  /// ```
  void writeString(String value, {bool allowMalformed = true});

  /// Returns the written bytes as a [Uint8List] and resets the writer.
  ///
  /// This method returns a copy of the written bytes from the beginning to the
  /// current offset position. After returning the bytes, it resets the internal
  /// state by clearing the offset and reinitializing the buffer to its initial
  /// size, preparing the writer for new data.
  ///
  /// Use this method when you want to retrieve the data and start fresh.
  ///
  /// Example:
  /// ```dart
  /// final writer = BinaryWriter();
  /// writer.writeUint8(42);
  /// final bytes = writer.takeBytes(); // Returns [42] and resets the writer
  /// writer.writeUint8(100); // Can write new data
  /// ```
  Uint8List takeBytes();

  /// Returns the written bytes as a [Uint8List] without resetting the writer.
  ///
  /// This method returns a view of the written bytes from the beginning to the
  /// current offset position. Unlike [takeBytes], this method does not reset
  /// the internal state, allowing you to continue writing more data.
  ///
  /// Use this method when you want to inspect the current buffer state without
  /// losing the ability to continue writing.
  ///
  /// Example:
  /// ```dart
  /// final writer = BinaryWriter();
  /// writer.writeUint8(42);
  /// final bytes = writer.toBytes(); // Returns [42] without resetting
  /// writer.writeUint8(100); // Continues writing, buffer is now [42, 100]
  /// ```
  Uint8List toBytes();

  /// Resets the writer to its initial state.
  ///
  /// This method resets the offset to 0 and reinitializes the buffer to its
  /// initial size. Unlike [takeBytes], this method does not return the written
  /// bytes, making it useful when you want to discard the current data and
  /// start fresh.
  ///
  /// Use this method when you want to clear the buffer without retrieving data.
  ///
  /// Example:
  /// ```dart
  /// final writer = BinaryWriter();
  /// writer.writeUint8(42);
  /// writer.reset(); // Resets the writer without returning bytes
  /// writer.writeUint8(100); // Starts fresh with new data
  /// ```
  void reset();
}
