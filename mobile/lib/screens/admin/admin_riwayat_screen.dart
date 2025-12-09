import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/deposit_service.dart';
import '../../widgets/admin_bottom_navbar.dart';
import 'admin_screen.dart';
import 'jadwal_penjemputan_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_register_user_screen.dart';
import 'detail_penjemputan_screen.dart';

class AdminRiwayatScreen extends StatefulWidget {
  const AdminRiwayatScreen({super.key});

  @override
  State<AdminRiwayatScreen> createState() => _AdminRiwayatScreenState();
}

class _AdminRiwayatScreenState extends State<AdminRiwayatScreen> {
  List<dynamic> _allDeposits = [];
  bool _isLoading = true;
  double _totalBerat = 0;
  int _totalCompleted = 0;

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    final result = await DepositService.getAllDeposits();

    if (mounted) {
      setState(() {
        if (result['success']) {
          final deposits = result['deposits'] as List<dynamic>? ?? [];
          _allDeposits = deposits;
          // Sort by created_at descending
          _allDeposits.sort((a, b) {
            final dateA = a['created_at'] as String? ?? '';
            final dateB = b['created_at'] as String? ?? '';
            try {
              return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
            } catch (e) {
              return 0;
            }
          });
          // Calculate total berat from completed
          _totalBerat = 0;
          _totalCompleted = 0;
          for (var d in _allDeposits) {
            if (d['status']?.toString().toLowerCase() == 'completed') {
              _totalBerat += (d['weight'] as num?)?.toDouble() ?? 0;
              _totalCompleted++;
            }
          }
        }
        _isLoading = false;
      });
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

  void _onNavTap(int index) {
    if (index == 3) return; // Already on riwayat

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const JadwalPenjemputanScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminRegisterUserScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminProfileScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Penyetoran',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF81B840), Color(0xFF006B49)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Sampah Terkumpul',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_totalBerat.toStringAsFixed(1)} Kg',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_totalCompleted Selesai',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allDeposits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada riwayat penyetoran',
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
                        onRefresh: _loadDeposits,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _allDeposits.length,
                          itemBuilder: (context, index) {
                            final deposit = _allDeposits[index];
                            return _buildDepositCard(deposit);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
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

  Widget _buildDepositCard(Map<String, dynamic> deposit) {
    final schoolName = deposit['school_name'] ?? '-';
    final contactName = deposit['contact_name'] ?? '-';
    final jenisSampah = deposit['waste_type'] ?? 'Sampah Organik';
    final jumlahTong = deposit['bin_count'] ?? 0;
    final tanggal = _formatDate(deposit['pickup_date']);
    final status = deposit['status']?.toString() ?? 'pending';
    final user = deposit['User'] as Map<String, dynamic>?;
    final userPicture = user?['picture'] as String?;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPenjemputanScreen(deposit: deposit),
          ),
        );
        _loadDeposits();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // User photo
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF10B981),
              backgroundImage: (userPicture != null && userPicture.isNotEmpty)
                  ? NetworkImage(
                      userPicture.startsWith('http')
                          ? userPicture
                          : '$baseUrl$userPicture',
                    )
                  : null,
              child: (userPicture == null || userPicture.isEmpty)
                  ? Text(
                      contactName.isNotEmpty ? contactName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contactName,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    schoolName,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$jenisSampah • $jumlahTong Tong • $tanggal',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      color: Colors.grey[400],
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
