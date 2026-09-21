import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminAPI.getUsers();
      if (mounted) setState(() { _users = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _initial(dynamic u) {
    final fn = u['first_name']?.toString() ?? '';
    if (fn.isEmpty) return '?';
    return fn[0].toUpperCase();
  }

  Future<void> _block(dynamic u, {bool unblock = false}) async {
    try {
      final res = await AdminAPI.blockUser(u['id'] as int, unblock: unblock);
      if (mounted && res['success'] == true) {
        Navigator.pop(context);
        _snack(res['message']?.toString() ?? 'Imefanikiwa',
            color: unblock ? Colors.green : Colors.orange);
        _load();
      }
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _delete(dynamic u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Futa User?"),
        content: Text("Una uhakika kumfuta ${u['email']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Ghairi"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Futa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await AdminAPI.deleteUser(u['id'] as int);
        if (mounted && res['success'] == true) {
          Navigator.pop(context);
          _snack(res['message']?.toString() ?? 'Amefutwa', error: true);
          _load();
        }
      } catch (e) {
        _snack(e.toString(), error: true);
      }
    }
  }

  Future<void> _openEditForm(dynamic u) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserEditForm(user: Map<String, dynamic>.from(u as Map)),
    );
    if (result == true) _load();
  }

  void _snack(String m, {bool error = false, Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: color ?? (error ? Colors.red : Colors.green),
      ),
    );
  }

  void _showUserDetails(BuildContext context, dynamic u) {
    final isActive = u['is_active'] == true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isActive ? AppColors.primary : Colors.grey,
                  child: Text(
                    _initial(u),
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(u['email']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow('ID', u['id']?.toString() ?? '-'),
            _detailRow('Simu', u['phone_number']?.toString() ?? '-'),
            _detailRow('Role', u['role']?.toString() ?? '-'),
            _detailRow('Hali', isActive ? 'Active' : 'Blocked'),
            _detailRow('Alijisajili', u['created_at']?.toString() ?? '-'),
            const SizedBox(height: 24),
            // Edit button (full width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openEditForm(u);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Hariri Taarifa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _block(u, unblock: !isActive),
                    icon: Icon(isActive ? Icons.block : Icons.check_circle),
                    label: Text(isActive ? 'Block' : 'Unblock'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _delete(u),
                    icon: const Icon(Icons.delete),
                    label: const Text('Futa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text("Hakuna users", style: GoogleFonts.poppins()))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      final isActive = u['is_active'] == true;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () => _showUserDetails(context, u),
                          leading: CircleAvatar(
                            backgroundColor: isActive ? AppColors.primary : Colors.grey,
                            child: Text(_initial(u),
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(
                            '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['email']?.toString() ?? ''),
                              Text(u['phone_number']?.toString() ?? ''),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Chip(
                                label: Text(u['role']?.toString() ?? 'USER',
                                    style: const TextStyle(fontSize: 10)),
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              if (!isActive)
                                const Text('BLOCKED',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ==================== USER EDIT FORM ====================
class _UserEditForm extends StatefulWidget {
  final Map<String, dynamic> user;
  const _UserEditForm({required this.user});
  @override
  State<_UserEditForm> createState() => _UserEditFormState();
}

class _UserEditFormState extends State<_UserEditForm> {
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'USER';
  bool _isActive = true;
  bool _saving = false;

  final List<String> _roles = ['USER', 'ADMIN', 'MECHANIC'];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.text = widget.user['first_name']?.toString() ?? '';
    _middleNameCtrl.text = widget.user['middle_name']?.toString() ?? '';
    _lastNameCtrl.text = widget.user['last_name']?.toString() ?? '';
    _phoneCtrl.text = widget.user['phone_number']?.toString() ?? '';
    _role = widget.user['role']?.toString() ?? 'USER';
    _isActive = widget.user['is_active'] == true;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      _snack("First name na Last name ni lazima", error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await AdminAPI.updateUser(
        id: widget.user['id'] as int,
        firstName: _firstNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: _role,
        isActive: _isActive,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: AppColors.primary),
                const SizedBox(width: 8),
                Text("Hariri User",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.user['email']?.toString() ?? '',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                  labelText: "First Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _middleNameCtrl,
              decoration: const InputDecoration(
                  labelText: "Middle Name (hiari)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(
                  labelText: "Last Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: "Namba ya Simu", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                  labelText: "Role", border: OutlineInputBorder()),
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? 'USER'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text("Active"),
              subtitle: Text(_isActive ? "User anaweza kuingia" : "User amezuiwa"),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Hifadhi"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
