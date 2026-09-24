import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:async';

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
  final _audioRecorder = AudioRecorder();
  final List<int> _audioChunks = [];
  StreamSubscription? _audioStreamSub;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  // I'M READY (mechanic anaona + ana-accept)
  bool _hasPendingReady = false;
  bool _readyAccepted = false;
  String _readyStatus = '';
  int _readyRemainingSeconds = 0;
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markRead();
    _startReadyPolling();
  }

  void _startReadyPolling() {
    _readyTimer?.cancel();
    _readyTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkReadyStatus());
    _checkReadyStatus();
  }

  Future<void> _checkReadyStatus() async {
    try {
      final res = await ChatAPI.getReadyStatus(widget.roomId);
      final data = res['data'] as Map? ?? {};
      if (!mounted) return;
      setState(() {
        final active = data['active'] == true;
        final status = data['status']?.toString() ?? '';
        final isUser = data['is_user'] == true;

        if (active && status == 'pending' && isUser) {
          // User ameomba — mechanic anaona button
          _hasPendingReady = true;
          _readyAccepted = false;
          _readyStatus = 'pending';
        } else if (active && status == 'accepted') {
          _hasPendingReady = false;
          _readyAccepted = true;
          _readyStatus = 'accepted';
          _readyRemainingSeconds = int.tryParse(data['remaining_seconds']?.toString() ?? '0') ?? 0;
        } else {
          _hasPendingReady = false;
          _readyAccepted = false;
          _readyStatus = '';
          _readyRemainingSeconds = 0;
        }
      });
    } catch (_) {}
  }

  Future<void> _acceptReady() async {
    try {
      final res = await ChatAPI.acceptReady(roomId: widget.roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Umekubali'),
            backgroundColor: Colors.green,
          ),
        );
        _checkReadyStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final data = await ChatAPI.getMessages(widget.roomId);
      if (mounted) {
        setState(() { _messages = data; _loading = false; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  @override
  void dispose() {
    _recordTimer?.cancel();
    _readyTimer?.cancel();
    _audioRecorder.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
        ],
      ),
      body: Column(
        children: [
          // READY BANNER
          if (_hasPendingReady) _readyRequestBanner(),
          if (_readyAccepted) _readyCountdownBanner(),
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
    final isDeleted = msg['is_deleted'] == true;
    final isEdited = msg['is_edited'] == true;
    final canEdit = msg['can_edit'] == true;
    final canDelete = msg['can_delete'] == true;

    Widget bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(
        horizontal: msgType == 'image' || msgType == 'video' ? 6 : 14,
        vertical: msgType == 'image' || msgType == 'video' ? 6 : 10,
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDeleted
            ? Colors.grey.shade300
            : (isMine ? AppTheme.primary : Colors.white),
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
            Text(
              sender,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          if (isDeleted)
            Text(
              '🚫 Message imefutwa',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            )
          else if (msgType == 'image' && mediaUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaUrls.first.toString(),
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            )
          else if (msgType == 'video' && mediaUrls.isNotEmpty)
            Container(
              width: 200, height: 140,
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
              ),
            )
          else if (msgType == 'audio' && mediaUrls.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, color: Colors.white),
                const SizedBox(width: 6),
                Text('Voice note',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ],
            )
          else
            Text(
              content,
              style: GoogleFonts.poppins(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isMine && !isDeleted
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey,
                    ),
                  ),
                  if (isEdited && !isDeleted) ...[
                    const SizedBox(width: 4),
                    Text('(edited)',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey,
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    if (isMine && !isDeleted && (canEdit || canDelete)) {
      bubble = GestureDetector(
        onLongPress: () => _showMessageOptions(msg),
        child: bubble,
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  void _showMessageOptions(dynamic msg) {
    final canEdit = msg['can_edit'] == true;
    final canDelete = msg['can_delete'] == true;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Hariri message'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessageDialog(msg);
                },
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Futa message',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(msg);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(dynamic msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Futa Message?'),
        content: const Text('Message itafutwa kwa wote wawili.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ChatAPI.deleteMessage(msg['id'] as int);
      await _loadMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editMessageDialog(dynamic msg) async {
    final ctrl = TextEditingController(text: msg['content']?.toString() ?? '');
    final newContent = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hariri Message'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
    if (newContent == null || newContent.isEmpty) return;
    try {
      await ChatAPI.editMessage(
        messageId: msg['id'] as int,
        content: newContent,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        _audioChunks.clear();
        if (kIsWeb) {
          final path = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.opus),
            path: path,
          );
        } else {
          final stream = await _audioRecorder.startStream(
            const RecordConfig(encoder: AudioEncoder.aacLc),
          );
          _audioStreamSub = stream.listen((data) => _audioChunks.addAll(data));
        }
        setState(() { _isRecording = true; _recordSeconds = 0; });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) setState(() => _recordSeconds++);
          if (_recordSeconds >= 120) _stopAndSendRecording();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      await _audioStreamSub?.cancel();
      setState(() => _isRecording = false);

      List<int> bytes;
      String fileName;
      if (kIsWeb && path != null) {
        final response = await http.get(Uri.parse(path));
        bytes = response.bodyBytes;
        fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        if (_audioChunks.isEmpty) return;
        bytes = List<int>.from(_audioChunks);
        fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      if (bytes.isEmpty) return;
      await _uploadAndSend(bytes, fileName, 'audio/m4a');
      _audioChunks.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _audioRecorder.stop();
      await _audioStreamSub?.cancel();
    } catch (_) {}
    _audioChunks.clear();
    setState(() { _isRecording = false; _recordSeconds = 0; });
  }

  Future<void> _uploadAndSend(List<int> bytes, String fileName, String contentType) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final msgType = contentType.startsWith('image/') ? 'image'
          : contentType.startsWith('video/') ? 'video'
          : contentType.startsWith('audio/') ? 'audio'
          : 'file';
      final msgRes = await ChatAPI.sendMessage(
        roomId: widget.roomId,
        content: fileName,
        messageType: msgType,
      );
      final msgId = msgRes['id'] as int?;
      if (msgId == null) throw Exception('Message ID haipo');
      await ChatAPI.uploadAttachment(
        messageId: msgId,
        bytes: bytes,
        fileName: fileName,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _readyRequestBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mteja anakuhitaji! Uko tayari?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade900,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _acceptReady,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('NDIYO'),
          ),
        ],
      ),
    );
  }

  Widget _readyCountdownBanner() {
    final mins = (_readyRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_readyRemainingSeconds % 60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.green.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mteja anakusubiri — fika ndani ya:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade900,
              ),
            ),
          ),
          Text(
            '$mins:$secs',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
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
        child: _isRecording ? _recordingBar() : _normalBar(),
      ),
    );
  }

  Future<void> _showAttachmentPicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachOpt(Icons.camera_alt, 'Camera', Colors.blue,
                    () => _pickImage(ImageSource.camera)),
                _attachOpt(Icons.photo_library, 'Gallery', Colors.purple,
                    () => _pickImage(ImageSource.gallery)),
                _attachOpt(Icons.videocam, 'Video', Colors.red,
                    () => _pickVideo()),
                _attachOpt(Icons.description, 'Document', Colors.orange,
                    () => _pickDocument()),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _attachOpt(IconData icon, String label, Color color, VoidCallback onTap) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      const typeGroup = XTypeGroup(label: 'Documents');
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        final bytes = await file.readAsBytes();
        await _uploadAndSend(bytes, file.name, file.mimeType ?? 'application/octet-stream');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _normalBar() {
    return Row(
      children: [
        // ATTACHMENT
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.attach_file, color: AppTheme.primary),
            onPressed: _sending ? null : _showAttachmentPicker,
          ),
        ),
        const SizedBox(width: 4),
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
        const SizedBox(width: 6),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          child: IconButton(
            icon: const Icon(Icons.mic, color: AppTheme.primary, size: 22),
            onPressed: _sending ? null : _startRecording,
          ),
        ),
        const SizedBox(width: 6),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primary,
          child: IconButton(
            icon: _sending
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.white, size: 20),
            onPressed: _sending ? null : _send,
          ),
        ),
      ],
    );
  }

  Widget _recordingBar() {
    final mins = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_recordSeconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: _cancelRecording,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(width: 10, height: 10,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('$mins:$secs',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text('Inarekodi...',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic))),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primary,
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            onPressed: _stopAndSendRecording,
          ),
        ),
      ],
    );
  }
}
