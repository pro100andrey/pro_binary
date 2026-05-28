// See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER
// for explanation of max safe integer in JavaScript.
export 'constants/native.dart' if (dart.library.js_util) 'constants/web.dart';

enum LengthEncoding {
  u8(1),
  u16(2),
  u32(4),
  u64(8);

  const LengthEncoding(this.sizeInBytes);

  final int sizeInBytes;
}
