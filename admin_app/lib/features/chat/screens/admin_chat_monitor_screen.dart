import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AdminChatMonitorScreen extends StatefulWidget {
  const AdminChatMonitorScreen({super.key});
  @override
  State<AdminChatMonitorScreen> createState() => _AdminChatMonitorScreenState();
}

class _AdminChatMonitorScreenState extends State<AdminChatMonitorScreen> {
  List<dynamic> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await AdminChatAPI.getRooms();
      if (mounted) setState(() { _rooms = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center,
                            style: GoogleFonts.poppins()),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Jaribu Tena')),
                      ],
                    ),
                  ),
                )
              : _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('Hakuna conversations bado',
                              style: GoogleFonts.poppins()),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _rooms.length,
                        itemBuilder: (_, i) {
                          final r = _rooms[i];
                          final name = r['name']?.toString() ?? 'Chat #${r['id']}';
                          final lastMsg = r['last_message']?.toString() ?? 'Hakuna message';
                          final participants = r['participant_count']?.toString() ?? '0';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: const Icon(Icons.forum, color: Colors.white),
                              ),
                              title: Text(name,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Participants: $participants',
                                      style: GoogleFonts.poppins(fontSize: 11)),
                                  Text(lastMsg, maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminChatDetailScreen(
                                    roomId: r['id'] as int,
                                    roomName: name,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}


// ==================== CHAT DETAIL ====================
class AdminChatDetailScreen extends StatefulWidget {
  final int roomId;
  final String roomName;
  const AdminChatDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });
  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await AdminChatAPI.getMessages(widget.roomId);
      if (mounted) setState(() { _messages = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _messages.isEmpty
                  ? Center(child: Text('Hakuna messages',
                      style: GoogleFonts.poppins(color: AppColors.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _bubble(_messages[i]),
                    ),
    );
  }

  Widget _bubble(dynamic msg) {
    final isUser = msg['sender_id'] != null;
    final senderName = msg['sender_name']?.toString() ?? 'Unknown';
    final content = msg['content']?.toString() ?? '';
    final time = msg['formatted_time']?.toString() ?? '';
    final msgType = msg['message_type']?.toString() ?? 'text';
    final mediaUrls = (msg['media_urls'] as List?) ?? [];
    final isDeleted = msg['is_deleted'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDeleted ? Colors.grey.shade300 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDeleted)
                  Text('🚫 Message imefutwa',
                      style: GoogleFonts.poppins(
                          fontStyle: FontStyle.italic, color: Colors.grey))
                else if (msgType == 'image' && mediaUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(mediaUrls.first.toString(),
                        width: 200, fit: BoxFit.cover),
                  )
                else if (msgType == 'video' && mediaUrls.isNotEmpty)
                  Text('[VIDEO] ${mediaUrls.first}',
                      style: GoogleFonts.poppins(color: Colors.blue))
                else if (msgType == 'audio' && mediaUrls.isNotEmpty)
                  Text('[VOICE NOTE]',
                      style: GoogleFonts.poppins(color: Colors.purple))
                else if (msgType == 'file' && mediaUrls.isNotEmpty)
                  Text('[FILE] ${mediaUrls.first}',
                      style: GoogleFonts.poppins(color: Colors.orange))
                else
                  Text(content, style: GoogleFonts.poppins(fontSize: 13)),
                const SizedBox(height: 4),
                Text(time,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
