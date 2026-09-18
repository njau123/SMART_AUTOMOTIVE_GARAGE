/// ELM327 AT commands + OBD-II PIDs definitions.
class ObdCommands {
  ObdCommands._();

  // ===== AT Commands (ELM327 initialization) =====
  static const String reset = 'ATZ';        // Reset adapter
  static const String echoOff = 'ATE0';     // Echo off
  static const String linefeedsOff = 'ATL0';
  static const String spacesOff = 'ATS0';
  static const String headersOff = 'ATH0';
  static const String autoProtocol = 'ATSP0';
  static const String describeProtocol = 'ATDP';
  static const String readVoltage = 'ATRV';
  static const String deviceInfo = 'ATI';
  static const String supportedPids = '0100';

  // ===== Engine PIDs (Mode 01) =====
  static const String engineLoad = '0104';
  static const String coolantTemp = '0105';
  static const String fuelTrim1 = '0106';
  static const String fuelTrim2 = '0107';
  static const String intakePressure = '010B';
  static const String rpm = '010C';
  static const String speed = '010D';
  static const String timingAdvance = '010E';
  static const String intakeTemp = '010F';
  static const String maf = '0110';
  static const String throttle = '0111';
  static const String fuelLevel = '012F';
  static const String moduleVoltage = '0142';

  // ===== Diagnostic Trouble Codes =====
  static const String readDtcs = '03';          // Stored DTCs
  static const String pendingDtcs = '07';       // Pending DTCs
  static const String clearDtcs = '04';         // Clear DTCs

  /// PID list kwa live data scan.
  static const List<String> livePids = [
    rpm, speed, coolantTemp, engineLoad, throttle, intakeTemp,
  ];
}

/// Metadata ya kila PID.
class PidInfo {
  final String pid;
  final String name;
  final String unit;
  final String formula;

  const PidInfo({
    required this.pid,
    required this.name,
    required this.unit,
    required this.formula,
  });
}

const List<PidInfo> allPids = [
  PidInfo(pid: '0104', name: 'Engine Load', unit: '%', formula: 'A*100/255'),
  PidInfo(pid: '0105', name: 'Coolant Temp', unit: '°C', formula: 'A-40'),
  PidInfo(pid: '010C', name: 'RPM', unit: 'rpm', formula: '(A*256+B)/4'),
  PidInfo(pid: '010D', name: 'Speed', unit: 'km/h', formula: 'A'),
  PidInfo(pid: '010F', name: 'Intake Temp', unit: '°C', formula: 'A-40'),
  PidInfo(pid: '0110', name: 'MAF', unit: 'g/s', formula: '(A*256+B)/100'),
  PidInfo(pid: '0111', name: 'Throttle', unit: '%', formula: 'A*100/255'),
  PidInfo(pid: '012F', name: 'Fuel Level', unit: '%', formula: 'A*100/255'),
  PidInfo(pid: '0142', name: 'Module Voltage', unit: 'V', formula: '(A*256+B)/1000'),
];
