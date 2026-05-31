import 'dart:io';
import 'dart:math';

import 'package:pro_binary/pro_binary.dart';

void main() async {
  const fileName = 'market_history.bin';
  const totalTicks = 500000;

  _log('- File Streaming Example: Market Tick Data -');

  // 1. Generation Phase
  _log('Generating $totalTicks ticks into "$fileName"...');

  final file = File(fileName);
  final ios = file.openWrite();

  final random = Random();
  var lastPrice = 50000.0;

  final writeWatch = Stopwatch()..start();

  final writer = BinaryWriter(initialBufferSize: 65536);

  for (var i = 0; i < totalTicks; i++) {
    // Simulate price movement
    lastPrice += (random.nextDouble() - 0.5) * 10;

    // final writer = BinaryWriterPool.acquire();
    TradeTick(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      price: lastPrice,
      volume: random.nextInt(100) + 1,
      isBuy: random.nextBool(),
    ).encode(writer);

    if (writer.bytesWritten >= 64000) {
      ios.add(writer.takeBytes(copy: true));
    }
  }

  if (writer.bytesWritten > 0) {
    ios.add(writer.takeBytes(copy: true));
  }

  writeWatch.stop();

  await ios.close();

  _log(
    'File generated. Size: '
    '${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB, '
    'time: ${writeWatch.elapsedMilliseconds} ms\n',
  );

  // 2. Parsing Phase
  _log('Reading and parsing file incrementally via File.openRead()...');

  var tickCount = 0;
  var totalVolume = 0;
  var maxPrice = 0.0;

  final readWatch = Stopwatch()..start();

  // Create the stream from file and pipe it through our transformer
  final tickStream = file.openRead().transform(TickTransformer());

  await for (final tick in tickStream) {
    tickCount++;
    totalVolume += tick.volume;
    if (tick.price > maxPrice) {
      maxPrice = tick.price;
    }

    if (tickCount % 50000 == 0) {
      _log('   Processed $tickCount ticks...');
    }
  }

  readWatch.stop();

  _log('\n✅ Parsing complete!');
  _log('Total Ticks: $tickCount');
  _log('Total Volume: $totalVolume');
  _log('Max Price: \$${maxPrice.toStringAsFixed(2)}');
  _log('Read time taken: ${readWatch.elapsedMilliseconds}ms');

  // 3. Cleanup
  if (file.existsSync()) {
    await file.delete();
    _log('\nTemporary file deleted.');
  }
}

/// Represents a single trade tick.
class TradeTick {
  TradeTick({
    required this.timestamp,
    required this.price,
    required this.volume,
    required this.isBuy,
  });

  factory TradeTick.decode(StreamBinaryReader r) => TradeTick(
    timestamp: r.readUint64(),
    price: r.readFloat64(),
    volume: r.readUint32(),
    isBuy: r.readBool(),
  );

  final int timestamp;
  final double price;
  final int volume;
  final bool isBuy;

  void encode(BinaryWriter w) {
    w
      ..writeUint64(timestamp)
      ..writeFloat64(price)
      ..writeUint32(volume)
      ..writeBool(isBuy);
  }
}

/// Transformer that parses [TradeTick]s from a stream.
/// Since the file is just a sequence of fixed-size records,
/// we can simply try to decode.
class TickTransformer extends BinaryStreamTransformer<TradeTick> {
  @override
  TradeTick? parse(StreamBinaryReader reader) {
    try {
      // TradeTick is exactly 8 + 8 + 4 + 1 = 21 bytes.
      // We can either check length explicitly or just try to decode.
      if (!reader.hasBytes(21)) {
        return null;
      }

      return TradeTick.decode(reader);
    } on NotEnoughDataException {
      return null;
    }
  }
}

void _log([Object? object = '']) => stdout.writeln(object);
