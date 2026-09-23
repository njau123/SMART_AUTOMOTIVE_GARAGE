import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';
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
  // Voice note
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  // I'M READY
  bool _imReady = false;
  int _readyRemainingSeconds = 0;
  String _readyStatus = '';
  Timer? _readyTimer;

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

  // ============ VOICE NOTE ============
  final List<int> _audioChunks = [];
  StreamSubscription? _audioStreamSub;

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        _audioChunks.clear();
        final stream = await _audioRecorder.startStream(
          const RecordConfig(encoder: AudioEncoder.aacLc),
        );
        _audioStreamSub = stream.listen((data) {
          _audioChunks.addAll(data);
        });
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) setState(() => _recordSeconds++);
          if (_recordSeconds >= 120) _stopAndSendRecording();
        });
      } else {
        _snackError('Ruhusa ya microphone haijatolewa');
      }
    } catch (e) {
      _snackError('Imeshindwa kuanza recording: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      _recordTimer?.cancel();
      await _audioRecorder.stop();
      await _audioStreamSub?.cancel();
      setState(() => _isRecording = false);
      if (_audioChunks.isEmpty) return;

      final bytes = List<int>.from(_audioChunks);
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _uploadAndSend(bytes, fileName, 'audio/m4a');
      _audioChunks.clear();
    } catch (e) {
      _snackError('Imeshindwa kutuma voice note: $e');
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _audioRecorder.stop();
      await _audioStreamSub?.cancel();
    } catch (_) {}
    _audioChunks.clear();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  // ============ I'M READY FLOW ============
  Future<Position?> _requestLocation() async {
    try {
      // Check kama location services zipo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snackError('Tafadhali washa GPS kwenye simu yako');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snackError('Tunahitaji location yako ili mechanic akufikie');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _snackError('Location imezuiwa. Fungua settings na uruhusu.');
        await Geolocator.openAppSettings();
        return null;
      }

      // Pata location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return position;
    } catch (e) {
      _snackError('Imeshindwa kupata location: $e');
      return null;
    }
  }

  Future<void> _toggleReady() async {
    if (_imReady) {
      // Cancel
      try {
        await ChatAPI.cancelReady(widget.roomId);
        setState(() {
          _imReady = false;
          _readyStatus = '';
          _readyRemainingSeconds = 0;
        });
        _readyTimer?.cancel();
      } catch (e) {
        _snackError(e.toString());
      }
      return;
    }

    // Omba location KABLA ya kutuma request
    final position = await _requestLocation();
    if (position == null) return;

    try {
      await ChatAPI.sendReady(
        roomId: widget.roomId,
        userLat: position.latitude,
        userLng: position.longitude,
      );
      setState(() {
        _imReady = true;
        _readyStatus = 'pending';
      });
      _startReadyPolling();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ombi limetumwa kwa mechanic...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _snackError(e.toString());
    }
  }

  void _startReadyPolling() {
    _readyTimer?.cancel();
    _readyTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final res = await ChatAPI.getReadyStatus(widget.roomId);
        final data = res['data'] as Map? ?? {};
        if (!mounted) return;
        setState(() {
          _readyStatus = data['status']?.toString() ?? '';
          _readyRemainingSeconds = int.tryParse(data['remaining_seconds']?.toString() ?? '0') ?? 0;
          if (_readyStatus == 'accepted') {
            _imReady = true;
          } else if (_readyStatus == 'cancelled' || _readyStatus == 'completed' || data['active'] == false) {
            _imReady = false;
          }
        });
      } catch (_) {}
    });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
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
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        color: isDeleted
            ? Colors.grey.shade300
            : (isMine ? AppColors.primary : Colors.white),
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
          if (isDeleted)
            Text(
              '🚫 Message imefutwa',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            )
          else
            _messageContent(msgType, content, mediaUrls, isMine),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
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
                    Text(
                      '(edited)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    // Long press menu (kama ni yangu na haijafutwa)
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
            const SizedBox(height: 0),
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
      _snackError(e.toString());
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
      _snackError(e.toString());
    }
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
        child: _isRecording ? _recordingBar() : _normalInputBar(),
      ),
    );
  }

  Widget _normalInputBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // I'M READY TOGGLE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _imReady
                    ? (_readyStatus == 'accepted'
                        ? 'Mechanic anakuja — ETA ${(_readyRemainingSeconds ~/ 60)}:${(_readyRemainingSeconds % 60).toString().padLeft(2, '0')}'
                        : 'Inasubiri mechanic akubali...')
                    : 'Je, uko tayari kupata mechanic?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _imReady ? Colors.green : Colors.grey.shade700,
                  ),
                ),
              ),
              Switch(
                value: _imReady,
                onChanged: (_) => _toggleReady(),
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ),
        Row(
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
        const SizedBox(width: 6),
        // MIC BUTTON
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          child: IconButton(
            icon: const Icon(Icons.mic, color: AppColors.primary, size: 22),
            onPressed: _sending ? null : _startRecording,
          ),
        ),
        const SizedBox(width: 6),
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
    ],
    );
  }

  Widget _recordingBar() {
    final mins = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_recordSeconds % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        // Cancel button
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: _cancelRecording,
        ),
        const SizedBox(width: 6),
        // Red dot + timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$mins:$secs',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Inarekodi...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        // Send button
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary,
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            onPressed: _stopAndSendRecording,
          ),
        ),
      ],
    );
  }
}
