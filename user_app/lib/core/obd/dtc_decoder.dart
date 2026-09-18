/// DTC response decoder: "430133..." → ["P0133", ...]
class DtcDecoder {
  DtcDecoder._();

  /// Decode response ya `03` (stored DTCs).
  static List<DtcResult> decode(String rawResponse) {
    final clean = rawResponse
        .replaceAll(RegExp(r'[\s\r\n>]'), '')
        .toUpperCase();

    if (clean.length < 4) return [];

    // Lazima ianze na "43" (Mode 03 + response offset 40)
    if (!clean.startsWith('43')) return [];

    // Ondoa "43"
    var data = clean.substring(2);

    // Kama data ni zero zote → hakuna DTCs
    if (RegExp(r'^0+$').hasMatch(data)) return [];

    final dtcs = <DtcResult>[];
    for (var i = 0; i < data.length - 3; i += 4) {
      final hex = data.substring(i, i + 4);
      final b1 = int.tryParse(hex.substring(0, 2), radix: 16);
      final b2 = int.tryParse(hex.substring(2, 4), radix: 16);
      if (b1 == null || b2 == null) continue;

      // "0000" = end marker
      if (b1 == 0 && b2 == 0) break;

      // Chagua system: P=0, C=1, B=2, U=3
      final system = ['P', 'C', 'B', 'U'][(b1 >> 6) & 0x03];
      final d1 = (b1 >> 4) & 0x03;
      final d2 = b1 & 0x0F;
      final d3 = (b2 >> 4) & 0x0F;
      final d4 = b2 & 0x0F;

      final code = '$system$d1'
          '${d2.toRadixString(16).toUpperCase()}'
          '${d3.toRadixString(16).toUpperCase()}'
          '${d4.toRadixString(16).toUpperCase()}';

      dtcs.add(DtcResult(
        code: code,
        rawHex: hex,
        system: _systemName(system),
      ));
    }
    return dtcs;
  }

  static String _systemName(String sys) {
    switch (sys) {
      case 'P':
        return 'Powertrain';
      case 'C':
        return 'Chassis';
      case 'B':
        return 'Body';
      case 'U':
        return 'Network';
      default:
        return 'Unknown';
    }
  }
}

class DtcResult {
  final String code;
  final String rawHex;
  final String system;

  DtcResult({
    required this.code,
    required this.rawHex,
    required this.system,
  });

  @override
  String toString() => '$code ($system)';
}
