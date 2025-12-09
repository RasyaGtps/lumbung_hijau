import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/deposit_service.dart';

class SetorSampahScreen extends StatefulWidget {
  final String namaSekolah;
  
  const SetorSampahScreen({super.key, required this.namaSekolah});

  @override
  State<SetorSampahScreen> createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaPJController = TextEditingController();
  final _noTeleponController = TextEditingController();
  final _alamatController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _jumlahTongController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _jenisSampah = 'Sampah Organik';
  bool _isLoading = false;

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF86812).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFFF86812)),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontFamily: 'PlusJakartaSans')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF86812).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFFF86812)),
                ),
                title: const Text('Ambil Foto',
                    style: TextStyle(fontFamily: 'PlusJakartaSans')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await DepositService.createDeposit(
        schoolName: widget.namaSekolah,
        contactName: _namaPJController.text,
        contactPhone: _noTeleponController.text,
        address: _alamatController.text,
        pickupDate: _tanggalController.text,
        binCount: int.tryParse(_jumlahTongController.text) ?? 0,
        wasteType: _jenisSampah,
        photo: _selectedImage,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menyimpan penyetoran!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _tanggalController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  void dispose() {
    _namaPJController.dispose();
    _noTeleponController.dispose();
    _alamatController.dispose();
    _tanggalController.dispose();
    _jumlahTongController.dispose();
    super.dispose();
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
          'Penyetoran Sampah',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi Sekolah Section
              const Text(
                'Informasi Sekolah',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Nama Sekolah (display only)
              _buildLabel('Nama Sekolah'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.namaSekolah.isEmpty ? 'Belum diatur' : widget.namaSekolah,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.namaSekolah.isEmpty ? Colors.grey[500] : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Nama PJ
              _buildLabel('Nama PJ'),
              const SizedBox(height: 8),
              _buildTextField(_namaPJController, hintText: 'Masukkan nama penanggung jawab'),
              const SizedBox(height: 16),
              
              // No Telepon PJ
              _buildLabel('No Telepon PJ'),
              const SizedBox(height: 8),
              _buildTextField(_noTeleponController, keyboardType: TextInputType.phone, hintText: 'Masukkan nomor telepon'),
              const SizedBox(height: 16),
              
              // Alamat
              _buildLabel('Alamat'),
              const SizedBox(height: 8),
              _buildTextField(
                _alamatController,
                suffixIcon: Icons.location_on_outlined,
                hintText: 'Masukkan alamat lengkap',
              ),
              const SizedBox(height: 32),
              
              // Detail Penyaluran Section
              const Text(
                'Detail Penyaluran',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tanggal Penjemputan
              _buildLabel('Tanggal Penjemputan'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: _buildTextField(
                    _tanggalController,
                    suffixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                    hintText: 'DD/MM/YYYY',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Jumlah Tong
              _buildLabel('Jumlah Tong'),
              const SizedBox(height: 8),
              _buildTextField(
                _jumlahTongController,
                keyboardType: TextInputType.number,
                hintText: 'Masukkan jumlah tong',
              ),
              const SizedBox(height: 32),
              
              // Jenis Sampah
              _buildLabel('Jenis Sampah'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _jenisSampah,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    items: const [
                      DropdownMenuItem(
                        value: 'Sampah Organik',
                        child: Text('Sampah Organik'),
                      ),
                      DropdownMenuItem(
                        value: 'Sampah Anorganik',
                        child: Text('Sampah Anorganik'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _jenisSampah = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Upload Bukti Foto
              _buildLabel('Upload Bukti Foto'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF86812),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    IconData? suffixIcon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            color: Colors.grey[400],
          ),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.grey[400], size: 20)
              : null,
        ),
      ),
    );
  }
}
