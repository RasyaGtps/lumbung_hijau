import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../widgets/admin_bottom_navbar.dart';
import '../login_screen.dart';
import 'admin_screen.dart';
import 'jadwal_penjemputan_screen.dart';
import 'admin_riwayat_screen.dart';
import 'admin_register_user_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _pictureUrl;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await AuthService.getMe();

    if (mounted) {
      setState(() {
        if (result['success']) {
          final user = result['user'];
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _pictureUrl = user['picture'];
        }
        _isLoading = false;
      });
    }
  }

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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.photo_library, color: Color(0xFF10B981)),
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
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
        maxWidth: 800,
        maxHeight: 800,
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final result = await AuthService.updateProfile(
        name: _nameController.text,
        photo: _selectedImage,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.deleteToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onNavTap(int index) {
    if (index == 4) return; // Already on profile

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
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminRiwayatScreen(),
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
          'Profil Admin',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Profile Picture
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                    image: _selectedImage != null
                                        ? DecorationImage(
                                            image: FileImage(_selectedImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : (_pictureUrl != null &&
                                                _pictureUrl!.isNotEmpty)
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    _pictureUrl!
                                                            .startsWith('http')
                                                        ? _pictureUrl!
                                                        : '$baseUrl$_pictureUrl'),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: (_selectedImage == null &&
                                          (_pictureUrl == null ||
                                              _pictureUrl!.isEmpty))
                                      ? Center(
                                          child: Text(
                                            _nameController.text.isNotEmpty
                                                ? _nameController.text[0]
                                                    .toUpperCase()
                                                : 'A',
                                            style: const TextStyle(
                                              fontFamily: 'PlusJakartaSans',
                                              fontSize: 48,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        size: 20, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk ganti foto',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Admin Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Name Field
                          _buildLabel('Nama Lengkap'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('Masukkan nama lengkap'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Nama tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Email Field (readonly)
                          _buildLabel('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            enabled: false,
                            decoration: _inputDecoration('Email').copyWith(
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          AdminBottomNavBar(
            currentIndex: 4,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
