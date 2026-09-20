import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markRead();

    // Polling: angalia messages mpya kila sekunde 3
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadMessages(silent: true),
    );
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final data = await ChatAPI.getMessages(widget.roomId);
      if (!mounted) return;

      // Kama silent (polling) — angalia kama message mpya zimeongezeka
      if (silent) {
        if (data.length != _messages.length) {
          setState(() => _messages = data);
          _scrollToBottom();
          // Mark read kwa messages mpya
          _markRead();
        }
      } else {
        setState(() { _messages = data; _loading = false; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _markRead() async {
    try {
      await ChatAPI.markRead(widget.roomId);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ChatAPI.sendMessage(roomId: widget.roomId, content: text);
      _msgCtrl.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ============ ATTACHMENT PICKER ============
  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tuma Faili',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachOption(Icons.camera_alt, 'Picha', Colors.blue,
                    () => _pickImage(ImageSource.camera)),
                _attachOption(Icons.photo_library, 'Gallery', Colors.purple,
                    () => _pickImage(ImageSource.gallery)),
                _attachOption(Icons.videocam, 'Video', Colors.red,
                    _pickVideo),
                _attachOption(Icons.description, 'Document', Colors.orange,
                    _pickDocument),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _attachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 75);
      if (file != null) {
        final bytes = await file.readAsBytes();
        await _uploadAndSend(bytes, file.name, file.mimeType ?? 'image/jpeg');
      }
    } catch (e) {
      _snackError('Imeshindikana kuchagua picha: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        await _uploadAndSend(bytes, file.name, 'video/mp4');
      }
    } catch (e) {
      _snackError('Imeshindikana kuchagua video: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await _uploadAndSend(
            file.bytes!,
            file.name,
            file.extension != null ? 'application/${file.extension}' : 'application/octet-stream',
          );
        }
      }
    } catch (e) {
      _snackError('Imeshindikana kuchagua document: $e');
    }
  }

  Future<void> _uploadAndSend(List<int> bytes, String fileName, String contentType) async {
    if (_sending) return;

    setState(() => _sending = true);
    try {
      // 1. Tuma message tupu
      final msgRes = await ChatAPI.sendMessage(
        roomId: widget.roomId,
        content: fileName,
        messageType: _getTypeFromContentType(contentType),
      );

      final msgId = msgRes['id'] as int?;
      if (msgId == null) throw Exception('Message ID haipo');

      // 2. Upload file
      await ChatAPI.uploadAttachment(
        messageId: msgId,
        bytes: bytes,
        fileName: fileName,
      );

      // 3. Reload messages
      await _loadMessages();
    } catch (e) {
      _snackError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _getTypeFromContentType(String ct) {
    if (ct.startsWith('image/')) return 'image';
    if (ct.startsWith('video/')) return 'video';
    if (ct.startsWith('audio/')) return 'audio';
    if (ct == 'application/pdf') return 'file';
    return 'file';
  }

  void _snackError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ============ END ATTACHMENT PICKER ============

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Anza mazungumzo...',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _bubble(_messages[i]),
                      ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(dynamic msg) {
    final isMine = msg['is_mine'] == true;
    final content = msg['content']?.toString() ?? '';
    final sender = msg['sender_name']?.toString() ?? '';
    final time = msg['formatted_time']?.toString() ?? '';
    final msgType = msg['message_type']?.toString() ?? 'text';
    final mediaUrls = (msg['media_urls'] as List?) ?? [];

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(
          horizontal: msgType == 'image' || msgType == 'video' ? 6 : 14,
          vertical: msgType == 'image' || msgType == 'video' ? 6 : 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine && sender.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  sender,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            _messageContent(msgType, content, mediaUrls, isMine),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _messageContent(
    String msgType,
    String content,
    List mediaUrls,
    bool isMine,
  ) {
    // ===== IMAGE =====
    if (msgType == 'image' && mediaUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          mediaUrls.first.toString(),
          width: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 220,
              height: 160,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Icon(Icons.broken_image, color: Colors.grey),
                const SizedBox(height: 4),
                Text('Picha haipatikani',
                    style: GoogleFonts.poppins(fontSize: 11)),
              ],
            ),
          ),
        ),
      );
    }

    // ===== VIDEO =====
    if (msgType == 'video' && mediaUrls.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openVideo(mediaUrls.first.toString()),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 220,
                height: 140,
                color: Colors.black26,
                child: const Center(
                  child: Icon(Icons.play_circle_fill,
                      size: 56, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Video',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    // ===== AUDIO =====
    if (msgType == 'audio' && mediaUrls.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.audiotrack,
              color: isMine ? Colors.white : AppColors.primary),
          const SizedBox(width: 8),
          Text('Audio message',
              style: GoogleFonts.poppins(
                  color: isMine ? Colors.white : Colors.black87)),
        ],
      );
    }

    // ===== FILE (PDF, DOC, etc) =====
    if (msgType == 'file' && mediaUrls.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openFile(mediaUrls.first.toString()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file,
                color: isMine ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                content.isNotEmpty ? content : 'Faili',
                style: GoogleFonts.poppins(
                  color: isMine ? Colors.white : Colors.black87,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // ===== TEXT (default) =====
    return Text(
      content,
      style: GoogleFonts.poppins(
        color: isMine ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
    );
  }

  void _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.attach_file, color: AppColors.primary),
                onPressed: _sending ? null : _showAttachmentPicker,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Andika message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: _sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
