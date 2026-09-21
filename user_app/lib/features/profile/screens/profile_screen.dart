import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/state/auth_state.dart';
import '../../../core/theme/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();

  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _vehicleReg = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _vehicleMake.dispose();
    _vehicleModel.dispose();
    _vehicleYear.dispose();
    _vehicleReg.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AuthAPI.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _firstName.text = data['first_name']?.toString() ?? '';
        _middleName.text = data['middle_name']?.toString() ?? '';
        _lastName.text = data['last_name']?.toString() ?? '';
        _phone.text = data['phone_number']?.toString() ?? '';

        final v = data['vehicle'];
        if (v is Map) {
          _vehicleMake.text = v['make']?.toString() ?? '';
          _vehicleModel.text = v['model']?.toString() ?? '';
          _vehicleYear.text = v['year']?.toString() ?? '';
          _vehicleReg.text = v['registration_number']?.toString() ?? '';
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = picked.name;
        });
      }
    } catch (e) {
      _snack('Failed to pick image: $e', error: true);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final vehicleData = <String, dynamic>{};
      if (_vehicleMake.text.isNotEmpty) vehicleData['make'] = _vehicleMake.text.trim();
      if (_vehicleModel.text.isNotEmpty) vehicleData['model'] = _vehicleModel.text.trim();
      if (_vehicleYear.text.isNotEmpty) vehicleData['year'] = _vehicleYear.text.trim();
      if (_vehicleReg.text.isNotEmpty) vehicleData['registration_number'] = _vehicleReg.text.trim();

      await AuthAPI.updateProfile(
        firstName: _firstName.text.trim(),
        middleName: _middleName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        profileImageBytes: _pickedImageBytes,
        profileImageName: _pickedImageName,
        vehicle: vehicleData.isEmpty ? null : vehicleData,
      );

      await _load();
      await AuthState.instance.init();

      if (mounted) {
        _snack('Profile updated successfully');
        setState(() {
          _pickedImageBytes = null;
          _pickedImageName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _imageUrl {
    final url = _profile?['profile_image_url']?.toString();
    return url ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(
              ThemeController.instance.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => ThemeController.instance.toggle(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _avatarCard(isDark),
                  const SizedBox(height: 20),
                  _section('Personal Information', isDark),
                  const SizedBox(height: 10),
                  _card(isDark, [
                    _field('First name', _firstName),
                    _field('Middle name', _middleName, required: false),
                    _field('Last name', _lastName),
                    _field('Phone', _phone, keyboard: TextInputType.phone),
                  ]),
                  const SizedBox(height: 20),
                  _section('Vehicle Information', isDark),
                  const SizedBox(height: 10),
                  _card(isDark, [
                    Row(children: [
                      Expanded(child: _field('Make', _vehicleMake)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Model', _vehicleModel)),
                    ]),
                    Row(children: [
                      Expanded(child: _field('Year', _vehicleYear, keyboard: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Reg No.', _vehicleReg)),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 20),
                      label: Text(_saving ? 'Saving...' : 'Save changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _avatarCard(bool isDark) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _buildAvatar(),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _firstName.text.isEmpty
                ? 'Your Name'
                : '${_firstName.text} ${_lastName.text}'.trim(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _profile?['email']?.toString() ?? '',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_pickedImageBytes != null) {
      return Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    }
    if (_imageUrl.isNotEmpty) {
      return Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final letter = _firstName.text.isNotEmpty
        ? _firstName.text[0].toUpperCase()
        : 'U';
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.poppins(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _section(String t, bool isDark) => Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _card(bool isDark, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F29) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3038) : AppColors.border,
          ),
        ),
        child: Column(
          children: children
              .expand((w) => [w, const SizedBox(height: 12)])
              .toList()
            ..removeLast(),
        ),
      );

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboard, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
