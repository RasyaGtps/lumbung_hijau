import 'package:flutter/material.dart';
import '../../services/deposit_service.dart';
import '../../widgets/admin_bottom_navbar.dart';
import 'admin_screen.dart';
import 'admin_riwayat_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_register_user_screen.dart';
import 'detail_penjemputan_screen.dart';

class JadwalPenjemputanScreen extends StatefulWidget {
  const JadwalPenjemputanScreen({super.key});

  @override
  State<JadwalPenjemputanScreen> createState() => _JadwalPenjemputanScreenState();
}

class _JadwalPenjemputanScreenState extends State<JadwalPenjemputanScreen> {
  List<dynamic> allDeposits = [];
  List<dynamic> filteredDeposits = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();
  List<DateTime> weekDates = [];
  final ScrollController _scrollController = ScrollController();
  int _todayIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateDatesForMonth();
    _loadDeposits();
    // Scroll to selected date after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    if (_scrollController.hasClients && _todayIndex > 0) {
      final offset = (_todayIndex - 1) * 62.0; // width 50 + margin 12
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _generateDatesForMonth() {
    final now = DateTime.now();
    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
    
    if (isCurrentMonth) {
      // Current month: 3 days before today + today + rest of month
      final startDate = now.subtract(const Duration(days: 3));
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysUntilEndOfMonth = endOfMonth.day - now.day;
      final totalDays = 3 + 1 + daysUntilEndOfMonth;
      weekDates = List.generate(totalDays, (i) => startDate.add(Duration(days: i)));
      _todayIndex = 3;
    } else {
      // Other months: show all days of that month
      final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
      weekDates = List.generate(endOfMonth.day, (i) => DateTime(currentMonth.year, currentMonth.month, i + 1));
      _todayIndex = 0;
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + delta, 1);
      _generateDatesForMonth();
      // Select first day of new month if not current month
      final now = DateTime.now();
      if (currentMonth.year != now.year || currentMonth.month != now.month) {
        selectedDate = DateTime(currentMonth.year, currentMonth.month, 1);
      } else {
        selectedDate = now;
      }
      _filterByDate();
    });
    // Reset scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
        _scrollToSelectedDate();
      }
    });
  }

  Future<void> _loadDeposits() async {
    setState(() => isLoading = true);
    final result = await DepositService.getAllDeposits();
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          allDeposits = result['deposits'] as List<dynamic>? ?? [];
          _filterByDate();
        }
        isLoading = false;
      });
    }
  }

  void _filterByDate() {
    filteredDeposits = allDeposits.where((deposit) {
      final dateStr = deposit['pickup_date'] as String?;
      if (dateStr == null) return false;
      try {
        final depositDate = DateTime.parse(dateStr);
        return depositDate.year == selectedDate.year &&
               depositDate.month == selectedDate.month &&
               depositDate.day == selectedDate.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  String _getDayName(int weekday) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[weekday % 7];
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
        return 'Proses';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  void _onNavTap(int index) {
    if (index == 1) return; // Already on this screen
    
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AdminScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AdminRegisterUserScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AdminRiwayatScreen(),
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
        centerTitle: true,
        title: const Text(
          'Jadwal Penjemputan',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Month Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.grey),
                ),
                Text(
                  '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Week Calendar - Scrollable
          SizedBox(
            height: 80,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: weekDates.length,
              itemBuilder: (context, index) {
                final date = weekDates[index];
                final isSelected = date.year == selectedDate.year &&
                                   date.month == selectedDate.month &&
                                   date.day == selectedDate.day;
                final isToday = date.year == DateTime.now().year &&
                                date.month == DateTime.now().month &&
                                date.day == DateTime.now().day;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                      _filterByDate();
                    });
                  },
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text(
                          _getDayName(date.weekday),
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            color: isSelected ? const Color(0xFF10B981) : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      Color(0xFF81B840),
                                      Color(0xFF006B49),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : (isToday ? const Color(0xFF10B981) : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          
          // Deposits List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDeposits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada jadwal penjemputan',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDeposits,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDeposits.length,
                          itemBuilder: (context, index) {
                            final deposit = filteredDeposits[index];
                            return _buildDepositCard(deposit);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 1,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildDepositCard(Map<String, dynamic> deposit) {
    final status = deposit['status'] as String? ?? 'pending';
    
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPenjemputanScreen(deposit: deposit),
          ),
        );
        if (result == true) {
          _loadDeposits(); // Refresh after update
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deposit['waste_type'] ?? 'Sampah',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deposit['school_name'] ?? '-',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(deposit['pickup_date']),
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
