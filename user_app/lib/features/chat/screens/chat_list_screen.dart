import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'chat_screen.dart';
import 'start_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ChatAPI.getRooms();
      if (mounted) setState(() { _rooms = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
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
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StartChatScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add_comment),
        label: const Text('Chat Mpya'),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
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
        Center(child: Text(_error ?? 'Error', style: GoogleFonts.poppins())),
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
          child: Text('Hakuna messages bado',
              style: GoogleFonts.poppins(fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Bonyeza "Chat Mpya" chini kuanza kuchat na fundi.',
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
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.engineering, color: AppColors.primary),
            ),
            title: Text(name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
