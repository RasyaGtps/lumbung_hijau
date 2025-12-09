import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumbung Hijau',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF10B981),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
        ),
        fontFamily: 'PlusJakartaSans',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // Splash delay
    
    // Check if user is logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // Get user role
      final userResult = await AuthService.getMe();
      String role = 'user';
      
      if (userResult['success'] && userResult['user'] != null) {
        role = userResult['user']['role'] ?? 'user';
      }
      
      // Route based on role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => role == 'admin' ? const AdminScreen() : const DashboardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10B981),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/LHWhite.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
