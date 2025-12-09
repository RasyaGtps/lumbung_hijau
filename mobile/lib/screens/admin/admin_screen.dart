import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../login_screen.dart';
import '../chat_list_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_riwayat_screen.dart';
import 'admin_register_user_screen.dart';
import '../../services/auth_service.dart';
import '../../services/deposit_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/admin_bottom_navbar.dart';
import 'jadwal_penjemputan_screen.dart';
import 'detail_penjemputan_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String userName = 'Admin';
  String userRole = 'admin';
  bool isLoading = true;
  int _currentNavIndex = 0;
  int unreadChatCount = 0;

  // Stats
  List<dynamic> allDeposits = [];
  int totalPending = 0;
  int totalProses = 0;
  int totalCompleted = 0;
  double totalBerat = 0;
  List<dynamic> recentDeposits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await AuthService.getMe();
    final depositsResult = await DepositService.getAllDeposits();
    final chatUnread = await ChatService.getUnreadCount();

    if (mounted) {
      setState(() {
        unreadChatCount = chatUnread;
        if (result['success']) {
          userName = result['user']['name'] ?? 'Admin';
          userRole = result['user']['role'] ?? 'admin';
        }
        if (depositsResult['success']) {
          allDeposits = depositsResult['deposits'] ?? [];
          _processStats();
        }
        isLoading = false;
      });
    }
  }

  void _processStats() {
    totalPending = 0;
    totalProses = 0;
    totalCompleted = 0;
    totalBerat = 0;

    for (var d in allDeposits) {
      final status = d['status']?.toString().toLowerCase() ?? '';
      if (status == 'pending') {
        totalPending++;
      } else if (status == 'proses') {
        totalProses++;
      } else if (status == 'completed') {
        totalCompleted++;
        totalBerat += (d['weight'] as num?)?.toDouble() ?? 0;
      }
    }

    // Get recent 5 deposits sorted by created_at
    final sorted = List.from(allDeposits);
    sorted.sort((a, b) {
      final dateA = a['created_at'] as String? ?? '';
      final dateB = b['created_at'] as String? ?? '';
      try {
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      } catch (e) {
        return 0;
      }
    });
    recentDeposits = sorted.take(5).toList();
  }

  Future<void> _handleLogout() async {
    await AuthService.deleteToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onNavTap(int index) async {
    if (index == _currentNavIndex) return;

    if (index == 1) {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const JadwalPenjemputanScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      _loadData();
    } else if (index == 2) {
      // Register User
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminRegisterUserScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 3) {
      // Riwayat
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminRiwayatScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 4) {
      final result = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminProfileScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (result == true) _loadData();
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF86812);
      case 'proses':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'proses':
        return 'Proses';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'proses':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.recycling;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Profile
                  PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'profile') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminProfileScreen()),
                        );
                        if (result == true) _loadData();
                      } else if (value == 'logout') {
                        _handleLogout();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            const Text('Profil Saya'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Logout',
                                style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFF10B981),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $userName',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chat Icon with badge
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChatListScreen()),
                      );
                      _loadData();
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child:
                              const Icon(Icons.chat_bubble_outline, size: 22),
                        ),
                        if (unreadChatCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadChatCount > 9
                                      ? '9+'
                                      : '$unreadChatCount',
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [Color(0xFF81B840), Color(0xFF006B49)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Sampah Terkumpul',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${totalBerat.toStringAsFixed(0)} kg',
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dari ${allDeposits.length} penyetoran',
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Status Cards Row
                            Row(
                              children: [
                                _buildStatusCard('Pending', totalPending,
                                    const Color(0xFFF86812), Icons.pending_actions),
                                const SizedBox(width: 12),
                                _buildStatusCard('Proses', totalProses,
                                    const Color(0xFF3B82F6), Icons.local_shipping),
                                const SizedBox(width: 12),
                                _buildStatusCard('Selesai', totalCompleted,
                                    const Color(0xFF10B981), Icons.check_circle),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Quick Actions
                            const Text(
                              'Menu Cepat',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildQuickAction(
                                  'Jadwal\nPenjemputan',
                                  Icons.calendar_month,
                                  const Color(0xFF10B981),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const JadwalPenjemputanScreen()),
                                    ).then((_) => _loadData());
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildQuickAction(
                                  'Pesan\nMasuk',
                                  Icons.chat,
                                  const Color(0xFF3B82F6),
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ChatListScreen()),
                                    ).then((_) => _loadData());
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Recent Deposits
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Penyetoran Terbaru',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const JadwalPenjemputanScreen()),
                                    ).then((_) => _loadData());
                                  },
                                  child: const Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (recentDeposits.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Belum ada penyetoran',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...recentDeposits.map((d) => _buildDepositItem(d)),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }


  Widget _buildStatusCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositItem(Map<String, dynamic> deposit) {
    final status = deposit['status']?.toString() ?? 'pending';
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPenjemputanScreen(deposit: deposit),
          ),
        );
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deposit['school_name'] ?? '-',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${deposit['bin_count'] ?? 0} Tong • ${_formatDate(deposit['pickup_date'])}',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusText(status),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
