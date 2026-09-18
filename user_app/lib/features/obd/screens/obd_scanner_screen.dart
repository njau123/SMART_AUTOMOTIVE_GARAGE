import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/obd/dtc_decoder.dart';
import '../../../core/obd/obd_service.dart';
import '../../../core/obd/pid_decoder.dart';
import '../../../core/services/api_service.dart';

class ObdScannerScreen extends StatefulWidget {
  final int? vehicleId;
  const ObdScannerScreen({super.key, this.vehicleId});

  @override
  State<ObdScannerScreen> createState() => _ObdScannerScreenState();
}

enum ScanState { idle, scanning, connecting, connected, reading, done }

class _ObdScannerScreenState extends State<ObdScannerScreen> {
  final _obd = ObdService();
  ScanState _state = ScanState.idle;
  List<ScanResult> _devices = [];
  StreamSubscription? _scanSub;
  BluetoothDevice? _selectedDevice;
  List<DtcResult> _dtcs = [];
  List<PidResult> _liveData = [];
  String _protocol = '';
  double? _battery;
  String? _error;
  int? _backendSessionId;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _obd.stopScan();
    _obd.disconnect();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _startScan() async {
    setState(() {
      _state = ScanState.scanning;
      _devices = [];
      _error = null;
    });
    _scanSub?.cancel();
    _scanSub = _obd.scanForDevices().listen(
      (results) {
        if (!mounted) return;
        setState(() => _devices = results.toList());
      },
      onError: (e) => setState(() => _error = 'Scan error: $e'),
    );
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _state == ScanState.scanning) {
        _obd.stopScan();
        if (_devices.isEmpty) {
          setState(() => _error = 'No OBD-II devices. Hakikisha ELM327 imewashwa.');
        }
      }
    });
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    _obd.stopScan();
    await _scanSub?.cancel();
    setState(() {
      _state = ScanState.connecting;
      _selectedDevice = device;
      _statusMsg = 'Ina-connect...';
      _error = null;
    });
    final ok = await _obd.connect(device);
    if (!ok) {
      setState(() {
        _state = ScanState.idle;
        _error = 'Imeshindwa ku-connect. Hakikisha gari limewashwa.';
      });
      return;
    }
    setState(() {
      _state = ScanState.connected;
      _statusMsg = 'Ime-connect!';
    });
    try {
      _protocol = await _obd.getProtocol();
      _battery = await _obd.readBatteryVoltage();
    } catch (_) {}
    await _readDtcAndLive();
  }

  Future<void> _readDtcAndLive() async {
    setState(() {
      _state = ScanState.reading;
      _statusMsg = 'Inasoma DTCs...';
    });
    try {
      _dtcs = await _obd.readDtcs();
      _liveData = await _obd.readLiveData();
    } catch (e) {
      debugPrint('Read error: $e');
    }
    if (widget.vehicleId != null) {
      try {
        setState(() => _statusMsg = 'Inatuma kwa server...');
        final sessionResp = await ObdAPI.createSession(
          vehicleId: widget.vehicleId!,
          adapterName: _selectedDevice?.platformName ?? 'ELM327',
          protocol: _protocol,
        );
        final sessionId = sessionResp['id'] ??
            (sessionResp['data'] is Map ? sessionResp['data']['id'] : null);
        if (sessionId != null) {
          _backendSessionId = sessionId;
          final liveDataMap = <String, num>{};
          for (final d in _liveData) {
            liveDataMap[d.pid] = d.value;
          }
          await ObdAPI.processScan(
            sessionId: sessionId,
            dtcCodes: _dtcs.map((d) => d.code).toList(),
            liveData: liveDataMap,
          );
        }
      } catch (e) {
        debugPrint('Backend sync error: $e');
      }
    }
    setState(() {
      _state = ScanState.done;
      _statusMsg = 'Imekamilika!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('OBD-II Scanner'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.obdScannerBg),
            fit: BoxFit.cover,
            opacity: 0.45,
          ),
        ),
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statusCard(),
              const SizedBox(height: 16),
              if (_error != null) _errorCard(),
              if (_state == ScanState.idle) _startCard(),
              if (_state == ScanState.scanning) _scanningCard(),
              if (_state == ScanState.connecting) _connectingCard(),
              if (_state == ScanState.connected || _state == ScanState.reading)
                _readingCard(),
              if (_state == ScanState.done) ...[
                _resultsCard(),
                const SizedBox(height: 16),
                _rescanButton(),
              ],
            ],
          ),
        ),
      )),
    );
  }

  Widget _statusCard() {
    final isConnected = _obd.isConnected;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected
              ? [AppColors.success, const Color(0xFF15803D)]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isConnected ? 'Connected' : 'OBD-II Scanner',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_statusMsg.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_statusMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9))),
          ],
          if (_protocol.isNotEmpty && isConnected) ...[
            const SizedBox(height: 8),
            Text('Protocol: $_protocol',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85))),
          ],
          if (_battery != null && isConnected) ...[
            const SizedBox(height: 4),
            Text('Battery: ${_battery!.toStringAsFixed(1)}V',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85))),
          ],
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _startCard() {
    return Column(
      children: [
        _reqTile('Washa Bluetooth', 'Kwenye settings za simu', Icons.bluetooth),
        _reqTile('Chomeka ELM327 kwenye gari', 'OBD-II port', Icons.usb),
        _reqTile('Washa gari (ignition ON)', 'Sio kuwasha engine',
            Icons.directions_car_outlined),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Tafuta vifaa vya OBD'),
          ),
        ),
      ],
    );
  }

  Widget _reqTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanningCard() {
    return Column(
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Center(
          child: Text('Inatafuta vifaa...',
              style: GoogleFonts.poppins(fontSize: 14)),
        ),
        const SizedBox(height: 20),
        if (_devices.isEmpty)
          Center(
            child: Text('Subiri...',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          )
        else
          ..._devices.map(_deviceTile),
      ],
    );
  }

  Widget _deviceTile(ScanResult r) {
    final name = r.device.platformName.isEmpty
        ? '(Unknown)'
        : r.device.platformName;
    return GestureDetector(
      onTap: () => _connectDevice(r.device),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.bluetooth, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text('Connect',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _connectingCard() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(_statusMsg, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _readingCard() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(_statusMsg, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _resultsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_dtcs.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 24),
                    const SizedBox(width: 8),
                    Text('${_dtcs.length} DTC(s) Found',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger)),
                  ],
                ),
                const SizedBox(height: 12),
                ..._dtcs.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• ${d.code} — ${d.system}',
                          style: GoogleFonts.poppins(fontSize: 13)),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                const SizedBox(width: 10),
                Text('No DTCs — gari iko safi!',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_liveData.isNotEmpty) ...[
          Text('Live Data',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._liveData.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(d.name,
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Text('${d.value} ${d.unit}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _rescanButton() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _obd.disconnect();
          setState(() {
            _state = ScanState.idle;
            _dtcs = [];
            _liveData = [];
            _devices = [];
            _backendSessionId = null;
          });
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Scan tena'),
      ),
    );
  }
}
