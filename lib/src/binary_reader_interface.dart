import 'dart:typed_data';

/// The [BinaryReaderInterface] class is an abstract base class used to decode
/// various types of data from a binary format.
abstract class BinaryReaderInterface {
  /// Reads an 8-bit unsigned integer from the buffer.
  ///
  /// This method reads an 8-bit unsigned integer from the current offset
  /// position and increments the offset by 1 byte.
  ///
  /// Returns an unsigned 8-bit integer (range: 0 to 255).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUint8(); // Reads a single byte as an unsigned integer.
  /// ```
  int readUint8();

  /// Reads an 8-bit signed integer from the buffer.
  ///
  /// This method reads an 8-bit signed integer from the current offset position
  /// and increments the offset by 1 byte.
  ///
  /// Returns a signed 8-bit integer (range: -128 to 127).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt8(); // Reads a single byte as a signed integer.
  /// ```
  int readInt8();

  /// Reads a 16-bit unsigned integer from the buffer.
  ///
  /// This method reads a 16-bit unsigned integer from the current offset
  /// position with the specified byte order (endian) and increments the offset
  /// by 2 bytes.
  ///
  /// Returns an unsigned 16-bit integer (range: 0 to 65535).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUint16(); // Reads two bytes as an unsigned integer in big-endian order.
  /// int value = reader.readUint16(Endian.little); // Reads two bytes as an unsigned integer in little-endian order.
  /// ```
  int readUint16([Endian endian = Endian.big]);

  /// Reads a 16-bit signed integer from the buffer.
  ///
  /// This method reads a 16-bit signed integer from the current offset position
  /// with the specified byte order (endian) and increments the offset by 2
  /// bytes.
  ///
  /// Returns a signed 16-bit integer (range: -32768 to 32767).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt16(); // Reads two bytes as a signed integer in big-endian order.
  /// int value = reader.readInt16(Endian.little); // Reads two bytes as a signed integer in little-endian order.
  /// ```
  int readInt16([Endian endian = Endian.big]);

  /// Reads a 32-bit unsigned integer from the buffer.
  ///
  /// This method reads a 32-bit unsigned integer from the current offset
  /// position with the specified byte order (endian) and increments the offset
  /// by 4 bytes.
  ///
  /// Returns an unsigned 32-bit integer (range: 0 to 4294967295).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUint32(); // Reads four bytes as an unsigned integer in big-endian order.
  /// int value = reader.readUint32(Endian.little); // Reads four bytes as an unsigned integer in little-endian order.
  /// ```
  int readUint32([Endian endian = Endian.big]);

  /// Reads a 32-bit signed integer from the buffer.
  ///
  /// This method reads a 32-bit signed integer from the current offset position
  /// with the specified byte order (endian) and increments the offset by 4
  /// bytes.
  ///
  /// Returns a signed 32-bit integer (range: -2147483648 to 2147483647).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt32(); // Reads four bytes as a signed integer in big-endian order.
  /// int value = reader.readInt32(Endian.little); // Reads four bytes as a signed integer in little-endian order.
  /// ```
  int readInt32([Endian endian = Endian.big]);

  /// Reads a 64-bit unsigned integer from the buffer.
  ///
  /// This method reads a 64-bit unsigned integer from the current offset
  /// position with the specified byte order (endian) and increments the offset
  /// by 8 bytes.
  ///
  /// Returns an unsigned 64-bit integer (range: 0 to 18446744073709551615).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readUint64(); // Reads eight bytes as an unsigned integer in big-endian order.
  /// int value = reader.readUint64(Endian.little); // Reads eight bytes as an unsigned integer in little-endian order.
  /// ```
  int readUint64([Endian endian = Endian.big]);

  /// Reads a 64-bit signed integer from the buffer.
  ///
  /// This method reads a 64-bit signed integer from the current offset position
  /// with the specified byte order (endian) and increments the offset by 8
  /// bytes.
  ///
  /// Returns a signed 64-bit integer
  /// (range: -9223372036854775808 to 9223372036854775807).
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// int value = reader.readInt64(); // Reads eight bytes as a signed integer in big-endian order.
  /// int value = reader.readInt64(Endian.little); // Reads eight bytes as a signed integer in little-endian order.
  /// ```
  int readInt64([Endian endian = Endian.big]);

  /// Reads a 32-bit floating point number from the buffer.
  ///
  /// This method reads a 32-bit float from the current offset position with the
  /// specified byte order (endian) and increments the offset by 4 bytes.
  ///
  /// Returns a 32-bit floating point number.
  /// The optional [endian] parameter specifies the byte order to use
  /// (defaults to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// double value = reader.readFloat32(); // Reads four bytes as a float in big-endian order.
  /// double value = reader.readFloat32(Endian.little); // Reads four bytes as a float in little-endian order.
  /// ```
  double readFloat32([Endian endian = Endian.big]);

  /// Reads a 64-bit floating point number from the buffer.
  ///
  /// This method reads a 64-bit float from the current offset position with the
  /// specified byte order (endian) and increments the offset by 8 bytes.
  ///
  /// Returns a 64-bit floating point number.
  /// The optional [endian] parameter specifies the byte order to use (defaults
  /// to [Endian.big]).
  ///
  /// Example:
  /// ```dart
  /// double value = reader.readFloat64(); // Reads eight bytes as a float in big-endian order.
  /// double value = reader.readFloat64(Endian.little); // Reads eight bytes as a float in little-endian order.
  /// ```
  double readFloat64([Endian endian = Endian.big]);

  /// Reads a list of bytes from the buffer.
  ///
  /// This method reads the specified number of bytes from the current offset
  /// position and increments the offset by that number of bytes.
  ///
  /// The [length] parameter specifies the number of bytes to read.
  ///
  /// Returns a [Uint8List] containing the read bytes.
  ///
  /// Example:
  /// ```dart
  /// Uint8List bytes = reader.readBytes(5); // Reads five bytes from the buffer.
  /// ```
  Uint8List readBytes(int length);
}
