import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _rooms = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();

    // Polling: angalia rooms mpya kila sekunde 5
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await ChatAPI.getRooms();
      if (mounted) setState(() { _rooms = data; _loading = false; });
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openRoom(dynamic room) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          roomId: room['id'] as int,
          roomName: room['name']?.toString() ?? 'Chat',
        ),
      ),
    );
    _load(); // refresh baada ya kurudi
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _rooms.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Center(
          child: Text(_error ?? 'Error', style: GoogleFonts.poppins()),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Jaribu Tena'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Center(
          child: Text('Hakuna messages bado', style: GoogleFonts.poppins(fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Ukichukua kazi, utaweza kuchat na mteja.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r = _rooms[i];
        final name = r['name']?.toString() ?? 'Chat';
        final lastMsg = r['last_message']?.toString() ?? 'Bado hakuna message';
        final unread = int.tryParse(r['unread_count']?.toString() ?? '0') ?? 0;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => _openRoom(r),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.chat, color: AppTheme.primary),
            ),
            title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: unread > 0
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  )
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
