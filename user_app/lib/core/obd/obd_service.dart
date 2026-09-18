import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'obd_commands.dart';
import 'dtc_decoder.dart';
import 'pid_decoder.dart';

/// OBD-II Service - inaunganisha na ELM327 kupitia Bluetooth.
class ObdService {
  // ELM327 inatumia UUIDs hizi
  static const String _obdServiceUuid = '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String _obdCharacteristicUuid = '0000fff1-0000-1000-8000-00805f9b34fb';
  // Fallback UUIDs kwa ELM327 za bei rahisi
  static const List<String> _fallbackServiceUuids = [
    '0000ffe0-0000-1000-8000-00805f9b34fb',
    '0000fff0-0000-1000-8000-00805f9b34fb',
  ];
  static const List<String> _fallbackCharUuids = [
    '0000ffe1-0000-1000-8000-00805f9b34fb',
    '0000fff1-0000-1000-8000-00805f9b34fb',
    '0000fff2-0000-1000-8000-00805f9b34fb',
  ];

  BluetoothDevice? _device;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  StreamSubscription? _rxSub;
  final _rxBuffer = StringBuffer();

  bool _connected = false;
  bool get isConnected => _connected;

  /// Listen kwa scan results.
  Stream<List<ScanResult>> scanForDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    return FlutterBluePlus.scanResults;
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  /// Connect kwa ELM327.
  Future<bool> connect(BluetoothDevice device) async {
    try {
      debugPrint('OBD: Connecting to ${device.platformName}');
      _device = device;

      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Tafuta services
      final services = await device.discoverServices();

      for (final service in services) {
        final svcUuid = service.uuid.toString().toLowerCase();

        if (_fallbackServiceUuids.contains(svcUuid) ||
            svcUuid == _obdServiceUuid) {
          for (final char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();
            debugPrint('  Found char: $charUuid');

            if (_fallbackCharUuids.contains(charUuid) ||
                charUuid == _obdCharacteristicUuid) {
              _txCharacteristic = char;
              _rxCharacteristic = char;
              break;
            }
          }
        }
        if (_txCharacteristic != null) break;
      }

      if (_txCharacteristic == null) {
        // Chukua characteristic yoyote yenye write + notify
        for (final service in services) {
          for (final char in service.characteristics) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              _txCharacteristic = char;
              if (char.properties.notify) _rxCharacteristic = char;
              break;
            }
          }
          if (_txCharacteristic != null) break;
        }
      }

      if (_txCharacteristic == null) {
        debugPrint('OBD: No writable characteristic found');
        await disconnect();
        return false;
      }

      // Weka notify
      if (_rxCharacteristic != null && _rxCharacteristic!.properties.notify) {
        await _rxCharacteristic!.setNotifyValue(true);
        _rxSub = _rxCharacteristic!.onValueReceived.listen(_onData);
      }

      _connected = true;

      // Initialize ELM327
      await _initializeAdapter();
      return true;
    } catch (e) {
      debugPrint('OBD connect error: $e');
      _connected = false;
      return false;
    }
  }

  void _onData(List<int> data) {
    final chunk = utf8.decode(data, allowMalformed: true);
    _rxBuffer.write(chunk);
  }

  Future<void> disconnect() async {
    await _rxSub?.cancel();
    _rxSub = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _rxBuffer.clear();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _connected = false;
  }

  /// Initialize ELM327 na AT commands.
  Future<void> _initializeAdapter() async {
    await _sendCommand(ObdCommands.reset, waitMs: 1500);
    await _sendCommand(ObdCommands.echoOff);
    await _sendCommand(ObdCommands.linefeedsOff);
    await _sendCommand(ObdCommands.spacesOff);
    await _sendCommand(ObdCommands.headersOff);
    await _sendCommand(ObdCommands.autoProtocol, waitMs: 800);
  }

  /// Tuma command na subiri response.
  Future<String> _sendCommand(String command, {int waitMs = 400}) async {
    if (_txCharacteristic == null) return '';

    _rxBuffer.clear();
    final bytes = utf8.encode('$command\r');
    await _txCharacteristic!.write(bytes, withoutResponse: false);

    await Future.delayed(Duration(milliseconds: waitMs));
    final response = _rxBuffer.toString();
    debugPrint('OBD CMD: $command → $response');
    return response;
  }

  /// Soma protocol ya adapter.
  Future<String> getProtocol() async {
    final r = await _sendCommand(ObdCommands.describeProtocol, waitMs: 800);
    return r.trim();
  }

  /// Soma voltage ya gari.
  Future<double?> readBatteryVoltage() async {
    final r = await _sendCommand(ObdCommands.readVoltage);
    final match = RegExp(r'([\d.]+)V').firstMatch(r);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Soma DTCs zote zilizohifadhiwa.
  Future<List<DtcResult>> readDtcs() async {
    final r = await _sendCommand(ObdCommands.readDtcs, waitMs: 1500);
    return DtcDecoder.decode(r);
  }

  /// Soma PIDs zote za live data.
  Future<List<PidResult>> readLiveData() async {
    final results = <PidResult>[];
    for (final pid in ObdCommands.livePids) {
      final r = await _sendCommand(pid);
      final result = PidDecoder.decode(pid, r);
      if (result != null) results.add(result);
    }
    return results;
  }

  /// Futa DTCs (baada ya kurekebisha).
  Future<bool> clearDtcs() async {
    final r = await _sendCommand(ObdCommands.clearDtcs, waitMs: 2000);
    return r.contains('44') || r.contains('OK');
  }
}
