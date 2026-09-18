import 'obd_commands.dart';

/// PID response decoder: "410C1AF8" → 1726 RPM
class PidDecoder {
  PidDecoder._();

  static PidResult? decode(String pid, String rawResponse) {
    final clean = rawResponse
        .replaceAll(RegExp(r'[\s\r\n>]'), '')
        .toUpperCase();

    if (clean.length < 6) return null;

    // Response lazima ianze na "41" (Mode 01 + response offset 40)
    if (!clean.startsWith('41')) return null;

    // PID ni characters 2-3 (mfano "0C" kwa 010C)
    final pidHex = pid.substring(2); // Ondoa "01"

    // Hakikisha response inafanana na PID
    if (clean.substring(2, 4) != pidHex) return null;

    // Data bytes zinaanza baada ya "41" + PID hex
    final dataHex = clean.substring(4);
    if (dataHex.isEmpty) return null;

    final bytes = <int>[];
    for (var i = 0; i < dataHex.length - 1; i += 2) {
      final b = int.tryParse(dataHex.substring(i, i + 2), radix: 16);
      if (b == null) return null;
      bytes.add(b);
    }
    if (bytes.isEmpty) return null;

    final a = bytes[0];
    final b = bytes.length > 1 ? bytes[1] : 0;

    double? value;
    switch (pid) {
      case '0104':
        value = a * 100.0 / 255.0;
        break;
      case '0105':
      case '010F':
        value = a - 40.0;
        break;
      case '010C':
        value = (a * 256.0 + b) / 4.0;
        break;
      case '010D':
        value = a.toDouble();
        break;
      case '0110':
        value = (a * 256.0 + b) / 100.0;
        break;
      case '0111':
      case '012F':
        value = a * 100.0 / 255.0;
        break;
      case '0142':
        value = (a * 256.0 + b) / 1000.0;
        break;
      default:
        value = a.toDouble();
    }

    final info = allPids.firstWhere(
      (p) => p.pid == pid,
      orElse: () => PidInfo(pid: pid, name: pid, unit: '', formula: ''),
    );

    return PidResult(
      pid: pid,
      name: info.name,
      value: double.parse(value.toStringAsFixed(2)),
      unit: info.unit,
      rawHex: dataHex,
    );
  }
}

class PidResult {
  final String pid;
  final String name;
  final double value;
  final String unit;
  final String rawHex;

  PidResult({
    required this.pid,
    required this.name,
    required this.value,
    required this.unit,
    required this.rawHex,
  });

  @override
  String toString() => '$name: $value $unit';
}
