import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/deposit_service.dart';
import '../chat_room_screen.dart';

class DetailPenjemputanScreen extends StatefulWidget {
  final Map<String, dynamic> deposit;

  const DetailPenjemputanScreen({super.key, required this.deposit});

  @override
  State<DetailPenjemputanScreen> createState() => _DetailPenjemputanScreenState();
}

class _DetailPenjemputanScreenState extends State<DetailPenjemputanScreen> {
  late Map<String, dynamic> deposit;
  final _beratController = TextEditingController();
  bool _isLoading = false;

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    deposit = widget.deposit;
    final weight = deposit['weight'];
    if (weight != null) {
      _beratController.text = weight.toString();
    }
  }

  @override
  void dispose() {
    _beratController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    
    double? weight;
    if (_beratController.text.isNotEmpty) {
      weight = double.tryParse(_beratController.text);
    }
    
    final result = await DepositService.updateDepositStatus(
      deposit['id'].toString(),
      status: newStatus,
      weight: weight,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success']) {
        setState(() {
          deposit['status'] = newStatus;
          if (weight != null) deposit['weight'] = weight;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diupdate ke ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'proses': return 'Proses';
      case 'completed': return 'Selesai';
      default: return status;
    }
  }

  int _getStatusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 0;
      case 'proses': return 1;
      case 'completed': return 2;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = deposit['status'] as String? ?? 'pending';
    final statusIndex = _getStatusIndex(status);
    final photoProof = deposit['photo_proof'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Detail Penjemputan',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - School & Contact Info
            Row(
              children: [
                Builder(builder: (context) {
                  final user = deposit['User'] as Map<String, dynamic>?;
                  final userPicture = user?['picture'] as String?;
                  final contactName = deposit['contact_name'] ?? '';
                  
                  return CircleAvatar(
                    radius: 30,
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
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  );
                }),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposit['school_name'] ?? '-',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        deposit['contact_name'] ?? '-',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        deposit['contact_phone'] ?? '-',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    final userId = deposit['user_id']?.toString();
                    final userName = deposit['contact_name'] ?? 'User';
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            otherUserId: userId,
                            otherUserName: userName,
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Status Timeline
            _buildStatusTimeline(statusIndex),
            
            const SizedBox(height: 24),
            
            // Photo from user - full width
            if (photoProof != null && photoProof.isNotEmpty) ...[
              Builder(builder: (context) {
                // Fix Windows backslash to forward slash
                final fixedPath = photoProof.replaceAll('\\', '/');
                final photoUrl = fixedPath.startsWith('http') ? fixedPath : '$baseUrl$fixedPath';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, size: 50)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            
            // Address
            _buildLabel('Alamat'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      deposit['address'] ?? '-',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Detail Penyaluran
            const Text(
              'Detail Penyaluran',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tanggal Penjemputan
            _buildLabel('Tanggal Penjemputan'),
            const SizedBox(height: 8),
            _buildInfoField(_formatDate(deposit['pickup_date']), icon: Icons.calendar_today_outlined),
            const SizedBox(height: 16),
            
            // Jumlah Tong
            _buildLabel('Jumlah Tong'),
            const SizedBox(height: 8),
            _buildInfoField('${deposit['bin_count'] ?? 0}'),
            const SizedBox(height: 16),
            
            // Jenis Sampah
            _buildLabel('Jenis Sampah'),
            const SizedBox(height: 8),
            _buildInfoField(deposit['waste_type'] ?? '-', icon: Icons.link),
            const SizedBox(height: 16),
            
            // Jumlah Berat (editable only when status is proses, readonly when completed)
            _buildLabel('Jumlah Berat'),
            const SizedBox(height: 8),
            if (status == 'proses')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: TextField(
                  controller: _beratController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Masukkan berat sampah',
                    suffixText: 'Kg',
                    suffixStyle: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                  ),
                ),
              )
            else
              _buildInfoField(
                deposit['weight'] != null ? '${deposit['weight']} Kg' : '-',
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: status == 'completed'
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (status == 'pending') {
                              _updateStatus('proses');
                            } else if (status == 'proses') {
                              // Validate berat
                              if (_beratController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Masukkan berat sampah terlebih dahulu'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              final weight = double.tryParse(_beratController.text);
                              if (weight == null || weight <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Berat sampah tidak valid'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _updateStatus('completed');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF86812),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            status == 'pending' ? 'Jemput' : 'Selesai',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatusTimeline(int currentIndex) {
    final steps = [
      {'title': 'Pending', 'desc': 'Menunggu Konfirmasi tim Lumbung Hijau melakukan penjemputan.'},
      {'title': 'Proses', 'desc': 'Tim dalam perjalanan ke sekolah dan melakukan Penimbangan'},
      {'title': 'Selesai', 'desc': 'Penimbangan selesai.'},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentIndex;
        final isCompleted = index < currentIndex;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
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
        fontSize: 14,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildInfoField(String value, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
            ),
          ),
          if (icon != null) Icon(icon, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
