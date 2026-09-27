import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'diagnosis_screen.dart';

/// History ya AI chats — kama ChatGPT.
class AiChatHistoryScreen extends StatefulWidget {
  const AiChatHistoryScreen({super.key});

  @override
  State<AiChatHistoryScreen> createState() => _AiChatHistoryScreenState();
}

class _AiChatHistoryScreenState extends State<AiChatHistoryScreen> {
  bool _loading = true;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await MethodsAPI.aiChatList();
      if (!mounted) return;
      setState(() {
        _conversations = (res['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat(dynamic conv) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisScreen(conversationId: conv['id'] as int),
      ),
    );
    _load();
  }

  Future<void> _newChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiagnosisScreen()),
    );
    _load();
  }

  Future<void> _delete(dynamic conv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Futa chat?'),
        content: Text('"${conv['title']}" itafutwa kabisa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await MethodsAPI.aiChatDelete(conv['id'] as int);
      _load();
    } catch (_) {}
  }

  Future<void> _rename(dynamic conv) async {
    final ctrl = TextEditingController(text: conv['title']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Badilisha jina'),
        content: TextField(controller: ctrl, maxLength: 50),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    try {
      await MethodsAPI.aiChatRename(conv['id'] as int, t);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AI Chats Zangu',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Hauna AI chats bado',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversations.length,
                    itemBuilder: (_, i) {
                      final c = _conversations[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _openChat(c),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy_outlined,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(c['title']?.toString() ?? 'Chat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            c['preview']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'rename') _rename(c);
                              if (v == 'delete') _delete(c);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Badilisha jina'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Futa', style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newChat,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Chat Mpya',
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }
}
