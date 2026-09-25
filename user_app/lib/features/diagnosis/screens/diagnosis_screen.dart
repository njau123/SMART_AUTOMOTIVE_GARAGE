import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/state/auth_state.dart';
import '../../mechanics/screens/mechanics_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  String content;
  final Uint8List? imageBytes;
  final DateTime timestamp;
  bool isLoading;

  _ChatMessage({
    required this.role,
    required this.content,
    this.imageBytes,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _sending = false;
  Uint8List? _pendingImage;
  String? _pendingImageName;

  @override
  void initState() {
    super.initState();
    _addGreeting();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _userName {
    final f = AuthState.instance.user?['first_name']?.toString() ?? '';
    return f.isEmpty ? 'Driver' : f;
  }

  Map<String, String> get _vehicle {
    final v = AuthState.instance.user?['vehicle'];
    if (v is Map) {
      return {
        'make': v['make']?.toString() ?? '',
        'model': v['model']?.toString() ?? '',
        'year': v['year']?.toString() ?? '',
      };
    }
    return {'make': '', 'model': '', 'year': ''};
  }

  void _addGreeting() {
    final v = _vehicle;
    final vehicleLine = (v['make']!.isNotEmpty || v['model']!.isNotEmpty)
        ? '\n\nI see your **${v['make']} ${v['model']} (${v['year']})**.'
        : '';
    _messages.add(_ChatMessage(
      role: 'assistant',
      content: 'Hello **$_userName** 👋\n\n'
          'What\'s wrong with your car today?$vehicleLine\n\n'
          'Unaweza kuniambia kwa **Kiswahili** au **English** — '
          'au tuma picha ya sehemu ya gari. 📷',
    ));
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pendingImage = bytes;
          _pendingImageName = file.name;
        });
      }
    } catch (e) {
      _showError('Image error: $e');
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty && _pendingImage == null) return;

    final userMsg = _ChatMessage(
      role: 'user',
      content: text.isEmpty ? '📷 (picha)' : text,
      imageBytes: _pendingImage,
    );
    setState(() {
      _messages.add(userMsg);
      _msgCtrl.clear();
      _pendingImage = null;
      _pendingImageName = null;
      _sending = true;
    });
    _scrollToBottom();

    // Unda history (bila ya message hii ya sasa)
    final history = _messages
        .sublist(0, _messages.length - 1)
        .where((m) => !m.isLoading)
        .map((m) => <String, dynamic>{
              'role': m.role,
              'content': m.content,
            })
        .toList();

    // Placeholder ya typing
    final loadingMsg = _ChatMessage(
      role: 'assistant',
      content: '...',
      isLoading: true,
    );
    setState(() => _messages.add(loadingMsg));
    _scrollToBottom();

    try {
      final v = _vehicle;
      final res = await MethodsAPI.diagnosisChat(
        message: text.isEmpty ? 'Tafadhali chambua picha hii ya gari langu.' : text,
        vehicleMake: v['make']!,
        vehicleModel: v['model']!,
        vehicleYear: v['year']!,
        history: history,
        imageBytes: userMsg.imageBytes,
        imageName: _pendingImageName ?? 'car_part.jpg',
      );
      final data = (res['data'] ?? res) as Map;
      final reply = data['reply']?.toString() ?? 'Samahani, sikuweza kujibu.';

      if (!mounted) return;
      setState(() {
        _messages.remove(loadingMsg);
        _messages.add(_ChatMessage(role: 'assistant', content: reply));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.remove(loadingMsg);
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: '❌ Samahani, kuna tatizo la mtandao. Jaribu tena.\n\n_${e.toString()}_',
        ));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.red),
    );
  }

  void _goToMechanics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MechanicsScreen()),
    );
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anza upya?'),
        content: const Text('Ujumbe wote utafutwa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addGreeting();
              });
            },
            child: const Text('Anza Upya'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mechanic AI',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Online • Multi-language',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetChat,
            tooltip: 'Anza upya',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.length == 1
                ? _emptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _bubble(_messages[i]),
                  ),
          ),
          if (_messages.length > 1 && !_sending) _findMechanicCTA(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final prompts = [
      '🚗 Gari linatoa moshi mweusi',
      '🔊 Breki zinasikika kwa kelele',
      '⚠️ Check engine light ipo',
      '🔋 Gari halizimi asubuhi',
      '💧 Kuna mafuta yanachuruzika',
      '🌡️ Gari linaoverheat',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text('Mechanic AI',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Ninaweza kukusaidia kuchunguza tatizo la gari lako',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('💡 Jaribu kuuliza:',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          ...prompts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _send(p.substring(2).trim()),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(p,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textPrimary)),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMessage m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    m.imageBytes!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: m.isLoading
                  ? _typingIndicator()
                  : _markdownish(
                      m.content,
                      isUser ? Colors.white : AppColors.textPrimary,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                '${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                    fontSize: 9, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.5 + i * 0.15),
          shape: BoxShape.circle,
        ),
      )),
    );
  }

  /// Simple markdown-ish formatter: **bold**, line breaks, numbered lists.
  Widget _markdownish(String text, Color color) {
    final lines = text.split('\n');
    final spans = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Bold segments
      final parts = line.split('**');
      for (var j = 0; j < parts.length; j++) {
        spans.add(TextSpan(
          text: parts[j],
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.5,
            color: color,
            fontWeight: j.isOdd ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      }
      if (i < lines.length - 1) {
        spans.add(TextSpan(
          text: '\n',
          style: GoogleFonts.poppins(fontSize: 13.5, color: color),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _findMechanicCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.amber.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.engineering_outlined,
              color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hujaridhika? Mwone mechanic wetu.',
              style: GoogleFonts.poppins(fontSize: 11.5),
            ),
          ),
          TextButton(
            onPressed: _goToMechanics,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 34),
            ),
            child: Text('Find Mechanic',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_pendingImage!,
                          width: 70, height: 70, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _pendingImage = null;
                          _pendingImageName = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.primary),
                  tooltip: 'Tuma picha',
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Andika tatizo la gari lako...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: _sending
                        ? Colors.grey
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sending ? null : () => _send(),
                    icon: _sending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    Colors.white)),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
