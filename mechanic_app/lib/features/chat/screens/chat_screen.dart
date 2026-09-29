import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:image_picker/image_picker.dart';
import 'image_preview_screen.dart';
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
  Timer? _etaTimerMechanic;
  int _etaSecondsMechanic = 0;
  bool _hasEtaMechanic = false;

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
  Map<String, dynamic>? _replyTo;
  Timer? _recordTimer;
  // I'M READY (mechanic anaona + ana-accept)
  bool _hasPendingReady = false;
  bool _readyAccepted = false;
  String _readyStatus = '';
  int _readyRemainingSeconds = 0;
  Timer? _readyTimer;
  // BOOKING APPROVAL (mechanic)
  String _approvalStatus = 'none';
  String? _approvalId;
  Timer? _approvalPoller;
  Timer? _countdownTimer;
  int _scheduleCountdown = 0;
  bool _sharingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadCountdown();
    _markRead();
    _startReadyPolling();
    _loadApprovalStatus();
    _startApprovalPolling();
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
    // Onyesha dialog ya ku-set muda
    final result = await _showEtaDialog();
    if (result == null) return;

    try {
      final res = await ChatAPI.acceptReady(
        roomId: widget.roomId,
        travelHours: result['hours'] as int,
        travelMinutes: result['minutes'] as int,
      );
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

  Future<Map<String, int>?> _showEtaDialog() async {
    int hours = 0;
    int minutes = 30;

    return await showDialog<Map<String, int>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Weka muda wa kufika',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mteja anakusubiri. Chagua muda utakaochukua kufika:',
                    style: GoogleFonts.poppins(fontSize: 12.5, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  // Masaa
                  Row(
                    children: [
                      Text('Masaa:',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: hours > 0
                            ? () => setDialogState(() => hours--)
                            : null,
                      ),
                      Text('$hours',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: hours < 12
                            ? () => setDialogState(() => hours++)
                            : null,
                      ),
                    ],
                  ),
                  // Dakika
                  Row(
                    children: [
                      Text('Dakika:',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: minutes >= 15
                            ? () => setDialogState(() => minutes -= 15)
                            : null,
                      ),
                      Text('$minutes',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: minutes < 45
                            ? () => setDialogState(() => minutes += 15)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jumla: ${hours}h ${minutes}m',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Ghairi', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: (hours == 0 && minutes == 0)
                      ? null
                      : () => Navigator.pop(ctx, {
                            'hours': hours,
                            'minutes': minutes,
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Kubali & Anza',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============ Extend Time (mechanic anaomba +15) ============
  Future<void> _extendTimeMechanic() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ongeza muda',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Umechelewa kufika? Ongeza dakika 15 na umjulishe mteja?',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hapana', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('+15 min',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ChatAPI.extendTime(roomId: widget.roomId, minutes: 15);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dakika 15 zimeongezwa — mteja amejulishwa'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final data = await ChatAPI.getMessages(widget.roomId);
      if (mounted) {
        setState(() { _messages = data; if (!silent) _loading = false; });
        if (!silent) _scrollToBottom();
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
      await ChatAPI.sendMessage(
        roomId: widget.roomId,
        content: text,
        replyTo: _replyTo?['id'],
      );
      _msgCtrl.clear();
      setState(() => _replyTo = null);
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

  Future<void> _loadCountdown() async {
    try {
      final res = await ChatAPI.getReadyStatus(widget.roomId);
      final data = res['data'] as Map? ?? {};
      final endsAt = data['schedule_countdown_ends_at']?.toString() ??
          data['countdown_ends_at']?.toString();
      if (endsAt != null && endsAt.isNotEmpty) {
        final end = DateTime.tryParse(endsAt);
        if (end != null) {
          final diff = end.difference(DateTime.now()).inSeconds;
          if (diff > 0 && mounted) {
            setState(() => _scheduleCountdown = diff);
            _startCountdownTick();
          }
        }
      }
    } catch (_) {}
  }

  void _startCountdownTick() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_scheduleCountdown <= 0) { t.cancel(); return; }
      setState(() => _scheduleCountdown--);
    });
  }

  Widget _countdownBanner() {
    if (_scheduleCountdown <= 0) return const SizedBox.shrink();
    final days = _scheduleCountdown ~/ 86400;
    final hours = (_scheduleCountdown % 86400) ~/ 3600;
    final mins = (_scheduleCountdown % 3600) ~/ 60;
    final secs = _scheduleCountdown % 60;
    String display = '';
    if (days > 0) display = '${days}d ${hours}h ${mins}m';
    else if (hours > 0) display = '${hours}h ${mins}m ${secs}s';
    else display = '${mins}m ${secs}s';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.orange, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mechanic anakuja baada ya:',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange.shade900)),
                Text(display,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _approvalPoller?.cancel();
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
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Omba location ya user',
            onPressed: _requestLocationMechanic,
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'Set ETA',
            onPressed: _showSetEtaDialog,
          ),
        ],
      ),
      body: Column(
        children: [
                     _approvalBanner(),
          // READY BANNER
          if (_hasPendingReady) _readyRequestBanner(),
          if (_readyAccepted) _readyCountdownBanner(),
          _etaBannerMechanic(),
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
          if (msg['reply_to_content'] != null && !isDeleted)
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: (isMine ? Colors.white : AppTheme.primary).withValues(alpha: 0.15),
                border: Border(
                  left: BorderSide(
                    color: isMine ? Colors.white : AppTheme.primary,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                msg['reply_to_content'].toString(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isMine ? Colors.white : AppTheme.primary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
            _VoiceNotePlayer(
              url: mediaUrls.first.toString(),
              isMine: isMine,
            )
          else if (msgType == 'location')
            _locationCard(msg, isMine)
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

    if (!isDeleted) {
      bubble = GestureDetector(
        onLongPress: () => _showMessageOptions(msg),
        onTap: () {
          if (msgType == 'text') {
            _showMessageOptions(msg);
          }
        },
        child: bubble,
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }


  Widget _locationCard(dynamic msg, bool isMine) {
    final content = msg['content']?.toString() ?? '';
    final address = content.replaceAll('📍', '').trim();
    final meta = msg['metadata'] is Map ? msg['metadata'] as Map : {};
    final lat = meta['latitude'] ?? '';
    final lng = meta['longitude'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? Colors.white.withValues(alpha: 0.15) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMine ? Colors.white54 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isMine ? Colors.white : Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Location ya mteja',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isMine ? Colors.white : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.isEmpty ? 'Location haipo' : address,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: isMine ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Open in Google Maps
              InkWell(
                onTap: () async {
                  final query = address.isNotEmpty
                      ? Uri.encodeComponent(address)
                      : '$lat,$lng';
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$query',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMine ? Colors.white : AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 14,
                        color: isMine ? AppTheme.primary : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fungua Maps',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isMine ? AppTheme.primary : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Share my location back
              InkWell(
                onTap: _shareLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 14,
                        color: isMine ? Colors.white : Colors.green.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tuma yangu',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isMine ? Colors.white : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.purple),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                  ClipboardData(text: msg['content']?.toString() ?? ''),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message imecopy'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.green),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyTo = Map<String, dynamic>.from(msg as Map));
              },
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
          const SizedBox(width: 6),
          IconButton(
            onPressed: _extendTimeMechanic,
            icon: const Icon(Icons.add_alarm, color: Colors.orange),
            tooltip: '+15 min',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _loadApprovalStatus() async {
    try {
      final res = await ChatAPI.getApprovalStatus(widget.roomId);
      final data = (res['data'] ?? res) as Map;
      final exists = data['exists'] == true;
      final status = exists
          ? (data['status'] ?? 'none').toString().toLowerCase()
          : 'none';
      if (!mounted) return;
      if (status != _approvalStatus) {
        setState(() {
          _approvalStatus = status;
        });
      }
      if (status == 'approved' || status == 'rejected') {
        _approvalPoller?.cancel();
      }
    } catch (_) {}
  }

  void _startApprovalPolling() {
    _approvalPoller?.cancel();
    _approvalPoller = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadApprovalStatus(),
    );
  }

  Future<void> _approveUser(String action) async {
    try {
      await ChatAPI.approveUser(roomId: widget.roomId, action: action);
      if (!mounted) return;
      setState(() {
        _approvalStatus = action == 'approve' ? 'approved' : 'rejected';
      });
      _approvalPoller?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'approve'
            ? 'User approved — wanaweza ku-book'
            : 'User declined')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Widget _approvalBanner() {
    switch (_approvalStatus) {
      case 'pending':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.amber.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.notifications_active,
                    size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'A user wants to book you',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveUser('approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(0, 34),
                    ),
                    child: Text('Allow',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _approveUser('reject'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                    ),
                    child: Text('Decline',
                        style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                ),
              ]),
            ],
          ),
        );
      case 'approved':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.green.shade100,
          child: Row(children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'You approved this user.',
              style: GoogleFonts.poppins(fontSize: 12),
            )),
          ]),
        );
      case 'rejected':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.red.shade100,
          child: Row(children: [
            const Icon(Icons.cancel, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'You declined this user.',
              style: GoogleFonts.poppins(fontSize: 12),
            )),
          ]),
        );
      default:
        return const SizedBox.shrink();
    }
  }


  Future<void> _shareLocation() async {
    if (_sharingLocation) return;
    setState(() => _sharingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Ruhusa ya location haijatolewa');
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      await ChatAPI.shareLocation(
        roomId: widget.roomId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location imetumwa ✅'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMessages(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sharingLocation = false);
    }
  }


  Future<void> _requestGps() async {
    try {
      await ChatAPI.requestGpsLocation(widget.roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ombi la GPS limetumwa ✅'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMessages(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setSchedule() async {
    int days = 0, hours = 1, minutes = 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Weka Muda wa Kufika',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _counter('Siku', days, (v) => setD(() => days = v), 0, 30),
              _counter('Masaa', hours, (v) => setD(() => hours = v), 0, 23),
              _counter('Dakika', minutes, (v) => setD(() => minutes = v), 0, 55),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ghairi')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Anza Countdown', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      await ChatAPI.setChatSchedule(
        roomId: widget.roomId,
        days: days, hours: hours, minutes: minutes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Countdown imeanza ✅'), backgroundColor: Colors.green),
        );
        _loadMessages(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _counter(String label, int val, Function(int) onCh, int min, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: GoogleFonts.poppins(fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: val > min ? () => onCh(val - 1) : null,
          ),
          Text('$val', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: val < max ? () => onCh(val + 1) : null,
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
      if (file == null) return;
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      final editedBytes = await Navigator.push<Uint8List?>(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(
            bytes: Uint8List.fromList(bytes),
            fileName: file.name,
          ),
        ),
      );
      if (editedBytes == null) return;

      await _uploadAndSend(editedBytes, file.name, 'image/jpeg');
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyTo != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: AppTheme.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.reply, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _replyTo!['sender_name']?.toString() ?? 'Reply',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        _replyTo!['content']?.toString() ?? '',
                        style: GoogleFonts.poppins(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _replyTo = null),
                ),
              ],
            ),
          ),
        Row(
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
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.gps_fixed, color: Colors.blue, size: 20),
            tooltip: 'Omba GPS ya mteja',
            onPressed: _sending ? null : _requestGps,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.timer, color: Colors.orange, size: 20),
            tooltip: 'Weka muda wa kufika',
            onPressed: _sending ? null : _setSchedule,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
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


  // ══════════════ GPS/ETA METHODS ══════════════

  Future<void> _loadEtaMechanic() async {
    try {
      final res = await ChatAPI.getEtaStatus(widget.roomId);
      final data = res['data'] as Map? ?? {};
      if (!mounted) return;
      setState(() {
        _hasEtaMechanic = data['has_eta'] == true;
        _etaSecondsMechanic = int.tryParse(data['countdown_seconds']?.toString() ?? '0') ?? 0;
      });
    } catch (_) {}
  }

  void _startEtaTimerMechanic() {
    _etaTimerMechanic?.cancel();
    _etaTimerMechanic = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadEtaMechanic();
    });
  }

  Future<void> _requestLocationMechanic() async {
    try {
      final res = await ChatAPI.requestLocation(widget.roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']?.toString() ?? 'Ombi limetumwa'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kosa: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showSetEtaDialog() async {
    final ctrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set ETA'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Masaa (mfano: 1 au 0.5)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Set')),
        ],
      ),
    );
    if (ok != true) return;
    final hours = double.tryParse(ctrl.text.trim());
    if (hours == null || hours <= 0) return;
    try {
      final res = await ChatAPI.setEta(widget.roomId, etaHours: hours);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']?.toString() ?? 'ETA imesetiwa'),
        backgroundColor: Colors.green,
      ));
      _loadEtaMechanic();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kosa: $e'), backgroundColor: Colors.red));
    }
  }

  String _fmtEtaM(int s) {
    if (s <= 0) return '0s';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  Widget _etaBannerMechanic() {
    if (!_hasEtaMechanic || _etaSecondsMechanic <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade400]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unakwenda kwa user',
                    style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                Text(_fmtEtaM(_etaSecondsMechanic),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ==================== VOICE NOTE PLAYER ====================
class _VoiceNotePlayer extends StatefulWidget {
  final String url;
  final bool isMine;
  const _VoiceNotePlayer({required this.url, required this.isMine});

  @override
  State<_VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      await _player.setUrl(widget.url);
      _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playerStateStream.listen((s) {
        if (mounted) setState(() => _isPlaying = s.playing);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle : Icons.play_circle_fill,
            color: widget.isMine ? Colors.white : AppTheme.primary,
            size: 32,
          ),
          onPressed: () async {
            if (_isPlaying) {
              await _player.pause();
            } else {
              await _player.play();
            }
          },
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 3,
              decoration: BoxDecoration(
                color: widget.isMine
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _duration.inSeconds > 0
                    ? (_position.inSeconds / _duration.inSeconds).clamp(0, 1)
                    : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isMine ? Colors.white : AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_fmt(_position)} / ${_fmt(_duration)}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: widget.isMine ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
