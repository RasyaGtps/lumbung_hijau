import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final result = await NotificationService.getNotifications();
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _notifications = result['notifications'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)}';
    } catch (e) {
      return '';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_outlined, color: Colors.grey[700], size: 28),
            const SizedBox(width: 10),
            const Text(
              'Notifikasi',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return _buildNotificationItem(notif);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final isRead = notif['is_read'] ?? false;
    
    return InkWell(
      onTap: () async {
        if (!isRead) {
          await NotificationService.markAsRead(notif['id']);
          _loadNotifications();
        }
      },
      child: Container(
        color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] ?? '',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['message'] ?? '',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(notif['created_at']),
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
