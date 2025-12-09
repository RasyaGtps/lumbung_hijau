import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import '../services/deposit_service.dart';
import '../widgets/bottom_navbar.dart';
import 'penjemputan_screen.dart';

class RiwayatPenyetoranScreen extends StatefulWidget {
  const RiwayatPenyetoranScreen({super.key});

  @override
  State<RiwayatPenyetoranScreen> createState() => _RiwayatPenyetoranScreenState();
}

class _RiwayatPenyetoranScreenState extends State<RiwayatPenyetoranScreen> {
  List<dynamic> _deposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    final result = await DepositService.getMyDeposits();
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _deposits = result['deposits'] ?? [];
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF86812);
      case 'proses':
      case 'approved':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'proses':
      case 'approved':
        return 'Proses';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _deposits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
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
                          padding: const EdgeInsets.all(20),
                          itemCount: _deposits.length,
                          itemBuilder: (context, index) {
                            final deposit = _deposits[index];
                            return _buildDepositCard(deposit);
                          },
                        ),
                      ),
          ),
          BottomNavBar(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                // Navigate to Dashboard (home)
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              } else if (index == 2) {
                // Navigate to Profile
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              } else {
                // Stay on current screen (Riwayat)
                // No action needed
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepositCard(Map<String, dynamic> deposit) {
    final status = deposit['status'] ?? 'pending';
    final jenisSampah = deposit['waste_type'] ?? 'Sampah Organik';
    final jumlahTong = deposit['bin_count'] ?? 0;
    final tanggal = _formatDate(deposit['pickup_date']);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PenjemputanScreen(depositId: deposit['id'].toString()),
          ),
        );
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jenisSampah,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$jumlahTong Tong',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tanggal,
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
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(status),
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
    );
  }
}
