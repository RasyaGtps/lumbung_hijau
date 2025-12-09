import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/deposit_service.dart';

class PenjemputanScreen extends StatefulWidget {
  final String depositId;
  
  const PenjemputanScreen({super.key, required this.depositId});

  @override
  State<PenjemputanScreen> createState() => _PenjemputanScreenState();
}

class _PenjemputanScreenState extends State<PenjemputanScreen> {
  Map<String, dynamic>? _deposit;
  bool _isLoading = true;

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadDeposit();
  }

  Future<void> _loadDeposit() async {
    final result = await DepositService.getDepositById(widget.depositId);
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _deposit = result['deposit'];
          // Debug: print photo_proof value
          debugPrint('photo_proof: ${_deposit?['photo_proof']}');
        }
        _isLoading = false;
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

  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'proses':
        return 1;
      case 'completed':
        return 2;
      default:
        return 0;
    }
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
        title: const Text(
          'Penjemputan',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deposit == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Tracker
                      _buildStepTracker(),
                      const SizedBox(height: 32),
                      
                      // Photo from backend
                      _buildPhotoArea(),
                      const SizedBox(height: 32),
                      
                      // Tanggal Penjemputan
                      _buildLabel('Tanggal Penjemputan'),
                      const SizedBox(height: 8),
                      _buildInfoField(_formatDate(_deposit!['pickup_date'])),
                      const SizedBox(height: 20),
                      
                      // Jumlah Tong
                      _buildLabel('Jumlah Tong'),
                      const SizedBox(height: 8),
                      _buildInfoField('${_deposit!['bin_count']}'),
                      const SizedBox(height: 20),
                      
                      // Jenis Sampah
                      _buildLabel('Jenis Sampah'),
                      const SizedBox(height: 8),
                      _buildInfoField(_deposit!['waste_type'] ?? ''),
                      
                      // Jumlah Berat - hanya tampil jika completed
                      if (_deposit!['status']?.toString().toLowerCase() == 'completed') ...[
                        const SizedBox(height: 20),
                        _buildLabel('Jumlah Berat'),
                        const SizedBox(height: 8),
                        _buildInfoField(_deposit!['weight'] != null 
                            ? '${_deposit!['weight']} Kg' 
                            : '0 Kg'),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPhotoArea() {
    final photoPath = _deposit!['photo_proof'] as String?;
    debugPrint('photoPath: $photoPath');
    debugPrint('baseUrl: $baseUrl');
    
    if (photoPath != null && photoPath.isNotEmpty) {
      // Fix Windows backslash to forward slash
      final fixedPath = photoPath.replaceAll('\\', '/');
      final photoUrl = fixedPath.startsWith('http') ? fixedPath : '$baseUrl$fixedPath';
      debugPrint('photoUrl: $photoUrl');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          photoUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 160,
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Gagal memuat foto', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          },
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('Tidak ada foto', style: TextStyle(color: Colors.grey[500], fontFamily: 'PlusJakartaSans')),
        ],
      ),
    );
  }

  Widget _buildStepTracker() {
    final status = _deposit!['status'] ?? 'pending';
    final currentStep = _getStepIndex(status);
    
    final steps = [
      {
        'title': 'Pending',
        'desc': 'Menunggu Konfirmasi tim Lumbung Hijau melakukan penjemputan.',
      },
      {
        'title': 'Proses',
        'desc': 'Tim dalam perjalanan ke sekolah dan melakukan Penimbangan',
      },
      {
        'title': 'Selesai',
        'desc': 'Penimbangan selesai.',
      },
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // Gradient circle with checkmark
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [Color(0xFF10B981), Color(0xFF006B49)],
                          )
                        : null,
                    color: isActive ? null : Colors.grey[300],
                  ),
                  child: isActive
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 50,
                    color: isCompleted ? const Color(0xFF10B981) : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index]['title']!,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF10B981) : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index]['desc']!,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildInfoField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}

