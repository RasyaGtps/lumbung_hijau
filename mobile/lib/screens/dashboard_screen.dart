import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shimmer/shimmer.dart';
import 'login_screen.dart';
import 'admin/admin_screen.dart';
import 'setor_sampah_screen.dart';
import 'riwayat_penyetoran_screen.dart';
import 'notifikasi_screen.dart';
import 'penjemputan_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import '../services/auth_service.dart';
import '../services/deposit_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_navbar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = 'User';
  String userNamaSekolah = '';
  String? userPicture;
  bool isLoading = true;
  int _currentNavIndex = 0;
  Map<String, dynamic>? latestDeposit;
  Map<String, dynamic>? userData;
  List<dynamic> allDeposits = [];
  List<dynamic> completedDeposits = [];
  Map<int, double> monthlyStats = {};
  double totalBerat = 0;
  int unreadChatCount = 0;
  int unreadNotifCount = 0;
  
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await AuthService.getMe();
    final depositsResult = await DepositService.getMyDeposits();
    final chatUnread = await ChatService.getUnreadCount();
    final notifUnread = await NotificationService.getUnreadCount();
    
    if (mounted) {
      setState(() {
        unreadChatCount = chatUnread;
        unreadNotifCount = notifUnread;
        if (result['success']) {
          userData = result['user'];
          userName = result['user']['name'] ?? 'User';
          userNamaSekolah = result['user']['school_name'] ?? '';
          userPicture = result['user']['picture'];
        }
        if (depositsResult['success']) {
          final deposits = depositsResult['deposits'] as List<dynamic>?;
          if (deposits != null && deposits.isNotEmpty) {
            // Sort by created_at descending (newest first)
            deposits.sort((a, b) {
              final dateA = a['created_at'] as String? ?? '';
              final dateB = b['created_at'] as String? ?? '';
              // Parse ISO format dates
              try {
                final dtA = DateTime.parse(dateA);
                final dtB = DateTime.parse(dateB);
                return dtB.compareTo(dtA); // Descending
              } catch (e) {
                return 0;
              }
            });
            allDeposits = deposits;
            latestDeposit = deposits.first as Map<String, dynamic>; // Now first is newest (by created_at)
            // Filter only completed deposits for stats
            completedDeposits = deposits.where((d) => d['status'] == 'completed').toList();
            // Calculate total berat from completed deposits
            totalBerat = 0;
            for (var d in completedDeposits) {
              totalBerat += (d['weight'] as num?)?.toDouble() ?? 0;
            }
            _processMonthlyStats();
          }
        }
        isLoading = false;
      });
    }
  }

  void _processMonthlyStats() {
    monthlyStats.clear();
    for (var deposit in completedDeposits) {
      final dateStr = deposit['pickup_date'] as String?;
      if (dateStr != null) {
        try {
          int month = 1;
          // Try parsing ISO format (2025-12-27T07:00:00+07:00)
          if (dateStr.contains('-') && dateStr.contains('T')) {
            final dt = DateTime.parse(dateStr);
            month = dt.month;
          }
          // Try parsing DD/MM/YYYY format
          else if (dateStr.contains('/')) {
            final parts = dateStr.split('/');
            if (parts.length >= 2) {
              month = int.tryParse(parts[1]) ?? 1;
            }
          }
          final kg = (deposit['weight'] as num?)?.toDouble() ?? 0;
          monthlyStats[month] = (monthlyStats[month] ?? 0) + kg;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
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

  void _onNavTap(int index) async {
    if (index == 1) {
      // Middle button - Riwayat Penyetoran
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const RiwayatPenyetoranScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      // Refresh data when returning from riwayat
      _loadData();
    } else if (index == 2) {
      // Profile button
      final result = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (result == true) {
        _loadData(); // Refresh data if profile was updated
      }
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: isLoading
                  ? _buildHeaderSkeleton()
                  : Row(
                children: [
                  // Profile Photo with Dropdown
                  PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'profile') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                        if (result == true) {
                          _loadData(); // Refresh data if profile was updated
                        }
                      } else if (value == 'logout') {
                        await AuthService.deleteToken();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => [
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
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout, size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            const Text(
                              'Logout',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: (userPicture != null && userPicture!.isNotEmpty)
                        ? CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(
                              userPicture!.startsWith('http') 
                                  ? userPicture! 
                                  : '$baseUrl$userPicture',
                            ),
                          )
                        : CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF10B981),
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
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
                  // User Info
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
                        Row(
                          children: [
                            Icon(Icons.apartment, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              userNamaSekolah,
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                        ),
                      ],
                    ),
                  ),
                  // Chat Icon
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatListScreen()),
                      );
                      _loadData(); // Refresh unread count
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
                          child: const Icon(Icons.chat_bubble_outline, size: 22),
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
                                  unreadChatCount > 9 ? '9+' : '$unreadChatCount',
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
                  const SizedBox(width: 8),
                  // Notification Icon
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
                      );
                      _loadData(); // Refresh unread count
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
                          child: const Icon(Icons.notifications_outlined, size: 22),
                        ),
                        if (unreadNotifCount > 0)
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
                                  unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
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

            // Scrollable Content
            Expanded(
              child: isLoading
                  ? _buildSkeletonLoading()
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Stats Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          stops: [0.0, 1.0],
                          colors: [
                            Color(0xFF81B840),
                            Color(0xFF006B49),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userNamaSekolah,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${totalBerat.toStringAsFixed(0)} kg',
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 48,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Total Sampah Makanan Terkumpul',
                                      style: TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Lihat',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tabs: Akun Sekolah & Setor Sampah
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                              if (result == true) {
                                _loadData();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.school,
                                    size: 20,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Akun Sekolah',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SetorSampahScreen(namaSekolah: userNamaSekolah),
                                ),
                              );
                              if (result == true) {
                                _loadData(); // Refresh data after successful deposit
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.recycling,
                                    size: 20,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Setor Sampah',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Penyaluran Terbaru Section
                    const Text(
                      'Penyaluran Terbaru',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Transaction Card - Real Data
                    if (latestDeposit != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PenjemputanScreen(depositId: latestDeposit!['id'].toString()),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      latestDeposit!['waste_type'] ?? 'Sampah',
                                      style: TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${latestDeposit!['bin_count']} Tong',
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(latestDeposit!['pickup_date']),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(latestDeposit!['status'] ?? 'pending'),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusText(latestDeposit!['status'] ?? 'pending'),
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada penyetoran',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Statistik Bulanan Section
                    const Text(
                      'Statistik Penyetoran',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (context) {
                          final sortedMonths = monthlyStats.keys.toList()..sort();
                          final maxY = monthlyStats.isEmpty 
                              ? 10.0 
                              : (monthlyStats.values.reduce((a, b) => a > b ? a : b) + 5);
                          const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                          
                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    if (groupIndex < sortedMonths.length) {
                                      final month = sortedMonths[groupIndex];
                                      return BarTooltipItem(
                                        '${monthNames[month - 1]}\n${rod.toY.toStringAsFixed(1)} Kg',
                                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < sortedMonths.length) {
                                        final month = sortedMonths[idx];
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            monthNames[month - 1],
                                            style: TextStyle(
                                              fontFamily: 'PlusJakartaSans',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxY / 5,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey[200]!,
                                  strokeWidth: 1,
                                ),
                              ),
                              barGroups: List.generate(
                                sortedMonths.length > 6 ? 6 : sortedMonths.length,
                                (index) {
                                  final month = sortedMonths[index];
                                  final kg = monthlyStats[month] ?? 0;
                                  return _buildBarGroup(index, kg);
                                },
                              ),
                            ),
                            swapAnimationDuration: Duration.zero,
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            BottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF10B981),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Stats Card Skeleton
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            // Tabs Skeleton
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Title Skeleton
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Card Skeleton
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Chart Title Skeleton
            Container(
              width: 180,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Chart Skeleton
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          // Profile Skeleton
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Name Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Icons Skeleton
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
