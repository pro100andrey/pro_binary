part of 'binary_writer.dart';

/// Calculates the UTF-8 byte length of the given string without encoding it.
///
/// This function efficiently computes the number of bytes required to
/// encode the string in UTF-8, taking into account multi-byte characters
/// and surrogate pairs. It's optimized with an ASCII fast path that processes
/// up to 4 ASCII characters at once.
///
/// Useful for:
/// - Pre-allocating buffers of the correct size
/// - Calculating message sizes before serialization
/// - Validating string length constraints
///
/// Performance:
/// - ASCII strings: ~4 bytes per loop iteration
/// - Mixed content: Falls back to character-by-character analysis
///
/// Example:
/// ```dart
/// final text = 'Hello, 世界! 🌍';
/// final byteLength = getUtf8Length(text); // 20 bytes
/// // vs text.length would be 15 characters
/// ```
///
/// Parameters:
/// - [value]: The input string.
///
/// Returns: The number of bytes needed for UTF-8 encoding.
int getUtf8Length(String value) {
  if (value.isEmpty) {
    return 0;
  }

  final len = value.length;
  var bytes = 0;
  var i = 0;

  while (i < len) {
    final char = value.codeUnitAt(i);

    // ASCII fast path
    if (char < 0x80) {
      // Process 4 ASCII characters at a time
      final end = len - 4;
      while (i <= end) {
        final mask =
            value.codeUnitAt(i) |
            value.codeUnitAt(i + 1) |
            value.codeUnitAt(i + 2) |
            value.codeUnitAt(i + 3);

        if (mask >= 0x80) {
          break;
        }

        i += 4;
        bytes += 4;
      }

      // Handle remaining ASCII characters
      while (i < len && value.codeUnitAt(i) < 0x80) {
        i++;
        bytes++;
      }
      if (i >= len) {
        return bytes;
      }
      continue;
    }

    // 2-byte sequence
    if (char < 0x800) {
      bytes += 2;
      i++;
    }
    // 3-byte sequence
    else if (char >= 0xD800 && char <= 0xDBFF && i + 1 < len) {
      final next = value.codeUnitAt(i + 1);
      if (next >= 0xDC00 && next <= 0xDFFF) {
        bytes += 4;
        i += 2;
        continue;
      }
      // Malformed surrogate pair
      bytes += 3;
      i++;
    }
    // 3-byte sequence
    else {
      bytes += 3;
      i++;
    }
  }

  return bytes;
}
