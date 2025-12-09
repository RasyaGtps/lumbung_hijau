import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'admin/admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        // Get user role from result
        final userResult = await AuthService.getMe();
        String role = 'user'; // default
        
        if (userResult['success'] && userResult['user'] != null) {
          role = userResult['user']['role'] ?? 'user';
        }
        
        // Route based on role
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        String errorMsg = result['message'] ?? 'Login gagal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient - horizontal (kiri ke kanan)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                stops: [0.0, 1.0],
                colors: [
                  Color(0xFF81B840),
                  Color(0xFF006B49),
                ],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Logo dan text di bagian hijau
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 32, 32, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo di kiri
                      Image.asset(
                        'assets/images/LHWhite.png',
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(Icons.eco, size: 25, color: Color(0xFF006B49)),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      // Text di kiri - 2 baris
                      const Text(
                        'Login ke Akun\nAnda',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          children: [
                            const TextSpan(text: 'Belum punya akun? '),
                            TextSpan(
                              text: 'Hubungi Admin',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Form putih dengan border radius di atas - Expanded to fill remaining space
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Loisbecket@gmail.com',
                                  hintStyle: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    color: Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                    borderSide: const BorderSide(color: Color(0xFF006B49), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                                  if (!value.contains('@')) return 'Email tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              // Sandi
                              Text(
                                'Sandi',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    color: Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                    borderSide: const BorderSide(color: Color(0xFF006B49), width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Password tidak boleh kosong' : null,
                              ),
                              const SizedBox(height: 16),
                              // Remember me
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                      activeColor: const Color(0xFF006B49),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Tombol Masuk
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontFamily: 'PlusJakartaSans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Terms
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        height: 1.5,
                                      ),
                                      children: const [
                                        TextSpan(text: 'By signing up, you agree to the '),
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(text: ' and\n'),
                                        TextSpan(
                                          text: 'Data Processing Agreement',
                                          style: TextStyle(
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
    );
  }
}
