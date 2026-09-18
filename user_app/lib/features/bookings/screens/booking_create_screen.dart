import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class BookingCreateScreen extends StatefulWidget {
  final int mechanicId;
  final String mechanicName;
  final String mechanicExpertise;

  const BookingCreateScreen({
    super.key,
    required this.mechanicId,
    required this.mechanicName,
    required this.mechanicExpertise,
  });

  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  List<dynamic> _vehicles = [];
  List<dynamic> _services = [];
  int? _selectedVehicleId;
  int? _selectedServiceId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesCtrl = TextEditingController();
  bool _loading = true;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AuthAPI.getProfile(),
        PublicAPI.getServices(),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final services = results[1] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _vehicles = profile['vehicles'] is List ? profile['vehicles'] as List : [];
        _services = services;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _createBooking() async {
    if (_selectedVehicleId == null) {
      _snack("Chagua gari lako", error: true); return;
    }
    if (_selectedServiceId == null) {
      _snack("Chagua huduma", error: true); return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _snack("Chagua tarehe na muda", error: true); return;
    }

    setState(() => _booking = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      final res = await BookingAPI.create(
        vehicleId: _selectedVehicleId!,
        serviceId: _selectedServiceId!,
        scheduledDate: dateStr,
        scheduledTime: timeStr,
        notes: _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'] as Map? ?? {};
        final bookingId = data['id'] as int?;
        final deposit = data['deposit_amount']?.toString() ?? '0';
        if (bookingId != null) {
          await _showDepositDialog(bookingId, deposit);
        }
      } else {
        _snack(res['message']?.toString() ?? "Booking imeshindikana", error: true);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  Future<void> _showDepositDialog(int bookingId, String depositAmount) async {
    final phoneCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Booking imeundwa!"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ili kuthibitisha booking yako, tafadhali lipa deposit 50%."),
              const SizedBox(height: 12),
              Text("Deposit: TSh $depositAmount",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Namba yako ya simu",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Baadaye"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Lipa Deposit"),
          ),
        ],
      ),
    );

    if (confirmed == true && phoneCtrl.text.trim().isNotEmpty && mounted) {
      try {
        final res = await BookingAPI.payDeposit(
          bookingId: bookingId,
          phoneNumber: phoneCtrl.text.trim(),
        );
        if (!mounted) return;
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Deposit imeanzishwa. Admin atathibitisha."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) _snack(e.toString(), error: true);
      }
    }
    phoneCtrl.dispose();
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text("Book ${widget.mechanicName}")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.engineering, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.mechanicName,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                Text(widget.mechanicExpertise,
                                    style: GoogleFonts.poppins(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Chagua Gari", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _vehicles.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Hauna gari lililosajiliwa. Ongeza kwenye profile kwanza."),
                          )
                        : DropdownButtonFormField<int>(
                            value: _selectedVehicleId,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: _vehicles.map<DropdownMenuItem<int>>((v) {
                              final id = int.tryParse(v['id'].toString()) ?? 0;
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text('${v['make'] ?? ''} ${v['model'] ?? ''} (${v['registration_number'] ?? ''})'.trim()),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedVehicleId = v),
                          ),
                    const SizedBox(height: 16),
                    Text("Chagua Huduma", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedServiceId,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _services.map<DropdownMenuItem<int>>((s) {
                        final id = int.tryParse(s['id'].toString()) ?? 0;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(s['name']?.toString() ?? 'Service'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedServiceId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: "Tarehe",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(_selectedDate == null
                                  ? 'Chagua'
                                  : DateFormat('dd MMM yyyy').format(_selectedDate!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: "Muda",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_selectedTime == null
                                  ? 'Chagua'
                                  : _selectedTime!.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Maelezo ya ziada (optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _booking ? null : _createBooking,
                        icon: const Icon(Icons.check_circle),
                        label: Text(_booking ? "Inatuma..." : "Book Sasa"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
