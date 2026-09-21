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
  bool _busy = false;

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

  Future<void> _markAllRead() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await NotificationAPI.markAllRead();
      _snack("Zote zimemark kama read");
      _load();
    } catch (e) {
      _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteOne(dynamic n) async {
    try {
      await NotificationAPI.deleteOne(n['id'] as int);
      _snack("Notification imefutwa");
      _load();
    } catch (e) {
      _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Futa Zote?"),
        content: const Text("Una uhakika kufuta notifications zote?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hapana"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ndiyo, Futa"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await NotificationAPI.deleteAll();
      _snack("Zote zimefutwa");
      _load();
    } catch (e) {
      _snack(e.toString().replaceAll("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final unreadCount = _notifications.where((n) => (n as Map)['is_read'] != true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'mark_all') _markAllRead();
                if (v == 'delete_all') _deleteAll();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'mark_all',
                  enabled: unreadCount > 0,
                  child: const Row(
                    children: [
                      Icon(Icons.done_all, size: 18),
                      SizedBox(width: 8),
                      Text("Mark zote read"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Futa zote", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
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

                      return Dismissible(
                        key: ValueKey('notif_${n['id']}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 6),
                              Text("Futa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Futa Notification?"),
                                  content: Text(n['title']?.toString() ?? ''),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Hapana"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Futa"),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _deleteOne(n),
                        child: Card(
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
