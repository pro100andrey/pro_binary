import 'dart:convert';
import 'dart:typed_data';

/// The [BinaryReaderInterface] is used to bring data back from the binary
/// format data.
abstract class BinaryReaderInterface {
  /// The UTF-8 decoder is used to decode Strings.
  static const utf8Decoder = Utf8Decoder();

  /// Reads an 8-bit unsigned integer from the buffer.
  ///
  /// This method reads a single byte from the current offset position in the
  /// buffer, interprets it as an unsigned 8-bit integer, and returns the
  /// result. The offset is then incremented by 1 byte.
  ///
  /// Returns the read unsigned 8-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUInt8(); // Reads an 8-bit unsigned integer from the buffer.
  /// ```
  int readUInt8();

  /// Reads an 8-bit signed integer from the buffer.
  ///
  /// This method reads a single byte from the current offset position in the
  ///  buffer, interprets it as a signed 8-bit integer, and returns the result.
  /// The offset is then incremented by 1 byte.
  ///
  /// Returns the read signed 8-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt8(); // Reads an 8-bit signed integer from the buffer.
  /// ```
  int readInt8();

  /// Reads a 16-bit unsigned integer from the buffer.
  ///
  /// This method reads two bytes from the current offset position in the
  /// buffer, interprets them as an unsigned 16-bit integer with the specified
  /// byte order (endian), and returns the result. The offset is then
  /// incremented by 2 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read unsigned 16-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUInt16(); // Reads a 16-bit unsigned integer from the buffer in big-endian order.
  /// int value = reader.readUInt16(Endian.little); // Reads a 16-bit unsigned integer from the buffer in little-endian order.
  /// ```
  int readUInt16([Endian endian = Endian.big]);

  /// Reads a 16-bit signed integer from the buffer.
  ///
  /// This method reads two bytes from the current offset position in the
  /// buffer, interprets them as a signed 16-bit integer with the specified byte
  /// order (endian), and returns the result. The offset is then incremented
  /// by 2 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read signed 16-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt16(); // Reads a 16-bit signed integer from the buffer in big-endian order.
  /// int value = reader.readInt16(Endian.little); // Reads a 16-bit signed integer from the buffer in little-endian order.
  /// ```
  int readInt16([Endian endian = Endian.big]);

  /// Reads a 32-bit unsigned integer from the buffer.
  ///
  /// This method reads four bytes from the current offset position in the
  /// buffer, interprets them as an unsigned 32-bit integer with the specified
  /// byte order (endian),
  /// and returns the result. The offset is then incremented by 4 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read unsigned 32-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUInt32(); // Reads a 32-bit unsigned integer from the buffer in big-endian order.
  /// int value = reader.readUInt32(Endian.little); // Reads a 32-bit unsigned integer from the buffer in little-endian order.
  /// ```
  int readUInt32([Endian endian = Endian.big]);

  /// Reads a 32-bit signed integer from the buffer.
  ///
  /// This method reads four bytes from the current offset position in the
  /// buffer, interprets them as a signed 32-bit integer with the specified byte
  /// order (endian), and returns the result. The offset is then incremented by
  /// 4 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read signed 32-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt32(); // Reads a 32-bit signed integer from the buffer in big-endian order.
  /// int value = reader.readInt32(Endian.little); // Reads a 32-bit signed integer from the buffer in little-endian order.
  /// ```
  int readInt32([Endian endian = Endian.big]);

  /// Reads a 64-bit unsigned integer from the buffer.
  ///
  /// This method reads eight bytes from the current offset position in the
  /// buffer, interprets them as an unsigned 64-bit integer with the specified
  /// byte order (endian), and returns the result. The offset is then
  /// incremented by 8 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read unsigned 64-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUInt64(); // Reads a 64-bit unsigned integer from the buffer in big-endian order.
  /// int value = reader.readUInt64(Endian.little); // Reads a 64-bit unsigned integer from the buffer in little-endian order.
  /// ```
  int readUInt64([Endian endian = Endian.big]);

  /// Reads a 64-bit signed integer from the buffer.
  ///
  /// This method reads eight bytes from the current offset position in the
  /// buffer, interprets them as a signed 64-bit integer with the specified byte
  /// order (endian), and returns the result. The offset is then incremented by
  /// 8 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read signed 64-bit integer.
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt64(); // Reads a 64-bit signed integer from the buffer in big-endian order.
  /// int value = reader.readInt64(Endian.little); // Reads a 64-bit signed integer from the buffer in little-endian order.
  /// ```
  int readInt64([Endian endian = Endian.big]);

  /// Reads a 32-bit floating point number from the buffer.
  ///
  /// This method reads four bytes from the current offset position in the
  /// buffer, interprets them as a 32-bit floating point number with the
  /// specified byte order (endian), and returns the result. The offset is then
  /// incremented by 4 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read 32-bit floating point number.
  ///
  /// Example:
  /// ```dart
  /// double value = reader.readFloat32(); // Reads a 32-bit float from the buffer in big-endian order.
  /// double value = reader.readFloat32(Endian.little); // Reads a 32-bit float from the buffer in little-endian order.
  /// ```
  double readFloat32([Endian endian = Endian.big]);

  /// Reads a 64-bit floating point number from the buffer.
  ///
  /// This method reads eight bytes from the current offset position in the
  /// buffer, interprets them as a 64-bit floating point number with the
  /// specified byte order (endian), and returns the result. The offset is then
  /// incremented by 8 bytes.
  ///
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Returns the read 64-bit floating point number.
  ///
  /// Example:
  /// ```dart
  /// double value = reader.readFloat64(); // Reads a 64-bit float from the buffer in big-endian order.
  /// double value = reader.readFloat64(Endian.little); // Reads a 64-bit float from the buffer in little-endian order.
  /// ```
  double readFloat64([Endian endian = Endian.big]);
}
