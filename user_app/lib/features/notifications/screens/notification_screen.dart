import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await NotificationAPI.getMyNotifications();
      if (mounted) setState(() { _notifications = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(dynamic n) async {
    if (n['is_read'] == true) return;
    try {
      await NotificationAPI.markAsRead(n['id'] as int);
      _load();
    } catch (_) {}
  }

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'booking': return Icons.book_online;
      case 'payment': return Icons.payment;
      case 'diagnosis': return Icons.psychology;
      case 'spare_part': return Icons.settings;
      case 'service': return Icons.build;
      case 'mechanic': return Icons.engineering;
      case 'news': return Icons.newspaper;
      case 'alert': return Icons.warning;
      case 'promotion': return Icons.local_offer;
      default: return Icons.notifications;
    }
  }

  Color _color(String type) {
    switch (type.toLowerCase()) {
      case 'booking': return Colors.blue;
      case 'payment': return Colors.green;
      case 'diagnosis': return Colors.purple;
      case 'spare_part': return Colors.orange;
      case 'alert': return Colors.red;
      case 'promotion': return Colors.pink;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_outlined,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text("Hakuna notifications bado",
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i] as Map;
                      final isRead = n['is_read'] == true;
                      final type = n['notification_type']?.toString() ?? 'system';
                      final icon = _icon(type);
                      final color = _color(type);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isRead ? Colors.white : color.withValues(alpha: 0.05),
                        child: ListTile(
                          onTap: () => _markRead(n),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          title: Text(
                            n['title']?.toString() ?? 'Notification',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                n['message']?.toString() ?? '',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n['created_at']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          trailing: isRead
                              ? null
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
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
