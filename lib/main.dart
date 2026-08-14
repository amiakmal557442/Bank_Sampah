import 'package:flutter/material.dart';
import 'session_service.dart';
import 'db_helper.dart';
import 'login_page.dart';
import 'dashboard_user.dart';
import 'dashboard_petugas.dart';
import 'dashboard_admin.dart';

import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper.instance.initWebStorage();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Sampah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF268B07),
          primary: const Color(0xFF268B07),
        ),
        fontFamily: 'PlusJakartaSans',
      ),
      home: const SplashRouter(),
    );
  }
}

/// Widget ini menentukan halaman pertama berdasarrkan sesi yang tersimpan.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasSession = await SessionService.loadSession();

    if (!mounted) return;

    if (hasSession) {
      final role = SessionService.role;
      Widget home;
      if (role == 'admin' || role == 'staf_kantor') {
        home = const AdminDashboardScreen();
      } else if (role == 'petugas') {
        home = const WorkerDashboardScreen();
      } else {
        home = const MainNavigationScreen();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => home),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan loading sementara saat cek sesi
    return const Scaffold(
      backgroundColor: Color(0xFF268B07),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Bank Sampah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
