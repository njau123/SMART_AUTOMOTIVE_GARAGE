import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../chat/screens/chat_screen.dart';

/// Offline Requests — user anaomba wakati mechanic yupo offline.
class OfflineRequestsScreen extends StatefulWidget {
  const OfflineRequestsScreen({super.key});

  @override
  State<OfflineRequestsScreen> createState() => _OfflineRequestsScreenState();
}

class _OfflineRequestsScreenState extends State<OfflineRequestsScreen> {
  bool _loading = true;
  bool _online = false;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await MechanicAPI.getOfflineRequests();
      if (!mounted) return;
      setState(() {
        _requests = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleOnline(bool v) async {
    setState(() => _online = v);
    try {
      await MechanicAPI.toggleOnlineStatus(v);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(v
                ? '✅ Uko online — utapokea requests'
                : 'Uko offline — huwezi kupokea requests'),
            backgroundColor: v ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _online = !v);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _respond(dynamic req, String action) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          action == 'accept' ? 'Kubali ombi?' : 'Kataa ombi?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mteja: ${req['user_name']}',
                style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 6),
            if ((req['user_message'] ?? '').toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(req['user_message'].toString(),
                    style: GoogleFonts.poppins(fontSize: 12)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: action == 'accept'
                    ? 'Jibu (optional)'
                    : 'Sababu ya kukataa',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Ghairi', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept' ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action == 'accept' ? 'Kubali' : 'Kataa',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await MechanicAPI.respondOfflineRequest(
        requestId: req['id'] as int,
        action: action,
        message: ctrl.text.trim(),
      );

      if (!mounted) return;

      if (action == 'accept' && res['data']?['room_id'] != null) {
        // Fungua chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: res['data']['room_id'] as int,
              roomName: req['user_name']?.toString() ?? 'Mteja',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept'
                ? 'Umekubali ✅'
                : 'Umekataa'),
            backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: Text('Maombi ya Wateja',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_online ? Icons.circle : Icons.circle_outlined,
                color: _online ? Colors.green : Colors.grey),
            onPressed: () => _toggleOnline(!_online),
          ),
        ],
      ),
      body: Column(
        children: [
          // Online toggle banner
          Container(
            padding: const EdgeInsets.all(12),
            color: _online
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(_online ? Icons.wifi : Icons.wifi_off,
                    color: _online ? Colors.green : Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _online ? 'Uko ONLINE' : 'Uko OFFLINE',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _online
                          ? Colors.green.shade900
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                Switch(
                  value: _online,
                  onChanged: _toggleOnline,
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 70, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Hakuna maombi bado',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: AppColors.textGrey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _requests.length,
                          itemBuilder: (_, i) {
                            final r = _requests[i];
                            final isPending = r['status'] == 'PENDING' ||
                                r['status'] == 'NOTIFIED';
                            final isAccepted = r['status'] == 'ACCEPTED';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              AppColors.primaryBlue.withValues(alpha: 0.15),
                                          child: Text(
                                            (r['user_name'] ?? 'U')
                                                .toString()
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  r['user_name']?.toString() ??
                                                      'Mteja',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              Text(
                                                  r['user_phone']?.toString() ??
                                                      '',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: AppColors.textGrey)),
                                            ],
                                          ),
                                        ),
                                        if (isAccepted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text('Accepted',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 9,
                                                    color: Colors.white)),
                                          ),
                                      ],
                                    ),
                                    if ((r['user_message'] ?? '')
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(r['user_message'].toString(),
                                            style: GoogleFonts.poppins(
                                                fontSize: 12, height: 1.4)),
                                      ),
                                    ],
                                    if (isPending) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _respond(r, 'reject'),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize:
                                                    const Size(0, 40),
                                              ),
                                              child: Text('Kataa',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.red)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _respond(r, 'accept'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                minimumSize:
                                                    const Size(0, 40),
                                              ),
                                              child: Text('Kubali',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (isAccepted && r['room_id'] != null) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  roomId: r['room_id'] as int,
                                                  roomName:
                                                      r['user_name']?.toString() ??
                                                          'Mteja',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.chat, size: 18),
                                          label: Text('Fungua Chat',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryBlue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
