/// ELM327 AT commands and OBD-II PID definitions.
class ElmCommands {
  // Initialization sequence
  static const reset = 'ATZ';        // Reset adapter
  static const echoOff = 'ATE0';     // Echo off
  static const linefeedOff = 'ATL0'; // Linefeed off
  static const spacesOff = 'ATS0';   // Spaces off
  static const headersOff = 'ATH0';  // Headers off
  static const autoProtocol = 'ATSP0'; // Auto-detect protocol
  static const describeProtocol = 'ATDP'; // Describe protocol
  static const readVoltage = 'ATRV'; // Read battery voltage

  // Engine PIDs (Mode 01)
  static const engineLoad = '0104';      // %
  static const coolantTemp = '0105';     // °C
  static const rpm = '010C';             // rpm
  static const speed = '010D';           // km/h
  static const intakeTemp = '010F';      // °C
  static const maf = '0110';             // g/s
  static const throttle = '0111';        // %
  static const fuelLevel = '012F';       // %
  static const moduleVoltage = '0142';   // V

  // Diagnostic Trouble Codes
  static const readDtcs = '03';          // Read stored DTCs
  static const pendingDtcs = '07';       // Read pending DTCs
  static const clearDtcs = '04';         // Clear DTCs
}

/// PID metadata: unit and formula (for display)
class PidDefinition {
  final String pid;
  final String name;
  final String unit;
  final String formula; // For reference

  const PidDefinition({
    required this.pid,
    required this.name,
    required this.unit,
    required this.formula,
  });
}

const List<PidDefinition> enginePids = [
  PidDefinition(pid: '0104', name: 'Engine Load', unit: '%', formula: 'A*100/255'),
  PidDefinition(pid: '0105', name: 'Coolant Temp', unit: '°C', formula: 'A-40'),
  PidDefinition(pid: '010C', name: 'RPM', unit: 'rpm', formula: '(A*256+B)/4'),
  PidDefinition(pid: '010D', name: 'Speed', unit: 'km/h', formula: 'A'),
  PidDefinition(pid: '010F', name: 'Intake Temp', unit: '°C', formula: 'A-40'),
  PidDefinition(pid: '0110', name: 'MAF Flow', unit: 'g/s', formula: '(A*256+B)/100'),
  PidDefinition(pid: '0111', name: 'Throttle', unit: '%', formula: 'A*100/255'),
  PidDefinition(pid: '012F', name: 'Fuel Level', unit: '%', formula: 'A*100/255'),
  PidDefinition(pid: '0142', name: 'Module Voltage', unit: 'V', formula: '(A*256+B)/1000'),
];

/// PID response decoder
class PidDecoder {
  /// Returns {value: double, unit: String} or null
  static Map<String, dynamic>? decode(String pid, String response) {
    // Response format: "41 04 XX XX" (headers off, so "4104XX XX")
    final clean = response.replaceAll(RegExp(r'[\s\r\n>]'), '').toUpperCase();
    if (clean.length < 4) return null;

    // Must start with "41" + PID (Mode 01 + 40)
    if (!clean.startsWith('41')) return null;

    // Extract data bytes (after "41XX")
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

    final def = enginePids.firstWhere(
      (p) => p.pid == pid,
      orElse: () => PidDefinition(pid: pid, name: pid, unit: '', formula: ''),
    );

    return {
      'value': double.parse(value.toStringAsFixed(2)),
      'unit': def.unit,
      'name': def.name,
    };
  }
}

/// DTC decoder: "430133..." -> ["P0300", ...]
class DtcDecoder {
  static List<String> decode(String response) {
    final clean = response.replaceAll(RegExp(r'[\s\r\n>]'), '').toUpperCase();
    if (clean.length < 4) return [];

    // Must start with "43" (Mode 03 + 40)
    if (!clean.startsWith('43')) return [];

    // Remove mode byte
    var data = clean.substring(2);

    // If data is all zeros -> no DTCs
    if (RegExp(r'^0+$').hasMatch(data)) return [];

    final dtcs = <String>[];
    for (var i = 0; i < data.length - 3; i += 4) {
      final hex = data.substring(i, i + 4);
      final b1 = int.tryParse(hex.substring(0, 2), radix: 16);
      final b2 = int.tryParse(hex.substring(2, 4), radix: 16);
      if (b1 == null || b2 == null) continue;

      // "00 00" = no DTC (end marker)
      if (b1 == 0 && b2 == 0) break;

      final system = ['P', 'C', 'B', 'U'][(b1 >> 6) & 0x03];
      final d1 = (b1 >> 4) & 0x03;
      final d2 = b1 & 0x0F;
      final d3 = (b2 >> 4) & 0x0F;
      final d4 = b2 & 0x0F;

      final code = '$system$d1${d2.toRadixString(16).toUpperCase()}'
                   '${d3.toRadixString(16).toUpperCase()}'
                   '${d4.toRadixString(16).toUpperCase()}';
      dtcs.add(code);
    }
    return dtcs;
  }
}
