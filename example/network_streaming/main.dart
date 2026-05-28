import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';

import 'models.dart';
import 'transformer.dart';

void main() async {
  _log('Advanced Streaming Example');
  _log('Simulating a fragmented network stream...\n');

  // 1. Prepare some test data
  final packets = [
    TelemetryPacket(
      packetId: 1,
      readings: [
        SensorData(id: 'temp_1', value: 24.5, timestamp: 1622548800000),
        SensorData(id: 'hum_1', value: 45.2, timestamp: 1622548800000),
      ],
    ),
    TelemetryPacket(
      packetId: 2,
      readings: [
        SensorData(id: 'press_1', value: 1013.25, timestamp: 1622548805000),
      ],
    ),
  ];

  // 2. Encode packets into a single raw byte buffer with framing
  final writer = BinaryWriter();
  for (final packet in packets) {
    // Write framing: [Magic] [Length]
    final payloadWriter = BinaryWriter();
    packet.encode(payloadWriter);
    final payload = payloadWriter.takeBytes();

    writer
      ..writeUint8(TelemetryTransformer.magicByte)
      ..writeVarBytes(payload);
  }

  final allBytes = writer.takeBytes();

  // 3. Create a stream and apply our TelemetryTransformer
  final controller = StreamController<List<int>>();
  final telemetryStream = controller.stream.transform(TelemetryTransformer());

  // Listen for parsed packets
  final subscription = telemetryStream.listen((packet) {
    _log('✅ Received: $packet');
    for (final reading in packet.readings) {
      _log('   -> $reading');
    }
  });

  // 4. Simulate network fragmentation (sending 7 bytes at a time)
  _log('Streaming ${allBytes.length} bytes in 7-byte chunks...');
  const chunkSize = 7;
  for (var i = 0; i < allBytes.length; i += chunkSize) {
    final end = (i + chunkSize < allBytes.length)
        ? i + chunkSize
        : allBytes.length;
    final chunk = allBytes.sublist(i, end);

    _log('   [$i]Sending chunk: ${chunk.length} bytes');
    controller.add(Uint8List.fromList(chunk));

    // Small delay to simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  await controller.close();
  await subscription.asFuture<void>();
  await subscription.cancel();

  _log('\nStream closed. All packets reconstructed successfully.');
}

void _log([Object? object = '']) => stdout.writeln(object);
