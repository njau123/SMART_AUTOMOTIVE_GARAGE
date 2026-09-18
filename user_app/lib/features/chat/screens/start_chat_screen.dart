import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'chat_screen.dart';

class StartChatScreen extends StatefulWidget {
  const StartChatScreen({super.key});
  @override
  State<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends State<StartChatScreen> {
  List<dynamic> _mechanics = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ChatAPI.getAvailableMechanics();
      if (mounted) {
        setState(() {
          _mechanics = data;
          _filtered = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterList() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = _mechanics;
      } else {
        _filtered = _mechanics.where((m) {
          final name = (m['full_name'] ?? '').toString().toLowerCase();
          final expertise = (m['expertise'] ?? '').toString().toLowerCase();
          return name.contains(q) || expertise.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _startChat(dynamic mechanic) async {
    // Onyesha "Wait a moment" dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ConnectingDialog(),
    );

    try {
      // 1. Tengeneza room
      final res = await ChatAPI.createRoom(
        otherUserId: mechanic['user'] as int,
        roomType: 'direct',
        name: mechanic['full_name']?.toString() ?? 'Chat',
      );

      // 2. Pata room ID
      int? roomId;
      if (res['id'] != null) {
        roomId = res['id'] as int;
      } else if (res['data'] is Map && res['data']['id'] != null) {
        roomId = res['data']['id'] as int;
      }

      if (!mounted) return;

      // Funga dialog
      Navigator.pop(context);

      if (roomId != null) {
        // Subiri kidogo (kwa "connection" feel)
        await Future.delayed(const Duration(milliseconds: 1500));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: roomId!,
              roomName: mechanic['full_name']?.toString() ?? 'Chat',
            ),
          ),
        );
      } else {
        _snack('Imeshindikana kutengeneza chat', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Anza Chat Mpya'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tafuta fundi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _card(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.engineering_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Center(
          child: Text('Hakuna mafundi waliopo online',
              style: GoogleFonts.poppins(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _card(dynamic m) {
    final name = m['full_name']?.toString() ?? 'Mechanic';
    final expertise = m['expertise']?.toString() ?? 'General';
    final isOnline = m['is_available'] == true;
    final region = m['region']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _startChat(m),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$expertise${region.isNotEmpty ? " • $region" : ""}',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
      ),
    );
  }
}

// ============ CONNECTING DIALOG ============
class _ConnectingDialog extends StatefulWidget {
  const _ConnectingDialog();
  @override
  State<_ConnectingDialog> createState() => _ConnectingDialogState();
}

class _ConnectingDialogState extends State<_ConnectingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _ctrl,
                child: const Icon(
                  Icons.autorenew,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tunakuunganisha na fundi...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wait a moment, tunaunganisha na expert mechanic.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ),
        ),
      ),
    );
  }
}
