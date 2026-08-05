import 'package:flutter/material.dart';
import 'register_user_page.dart';
import 'register_petugas_page.dart';
import 'dashboard_user.dart';
import 'dashboard_petugas.dart';
import 'dashboard_admin.dart';
import 'db_helper.dart';
import 'api_service.dart';
import 'session_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Definisi Warna Sesuai Permintaan
  final Color _limeGreen = const Color(0xFF32CD32);
  final Color _oldGrassGreen = const Color(0xFF268b07);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Coba login via API (XAMPP) terlebih dahulu, lalu fallback ke lokal
      Map<String, dynamic>? user;
      try {
        user = await ApiService.instance.login(email, password);
      } catch (_) {
        user = null;
      }

      // Fallback ke SQLite lokal jika API tidak tersedia
      if (user == null) {
        user = await DatabaseHelper.instance.login(email, password);
      }

      if (mounted) Navigator.pop(context);

      if (user != null) {
        await SessionService.saveSession(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selamat datang kembali, ${user['full_name']}!'),
              backgroundColor: const Color(0xFF268B07),
            ),
          );

          final role = user['role'] as String? ?? 'nasabah';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (role == 'admin') {
                  return const AdminDashboardScreen();
                } else if (role == 'petugas') {
                  return const WorkerDashboardScreen();
                } else {
                  return const MainNavigationScreen();
                }
              },
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email atau Password salah!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- MULAI PERUBAHAN DI SINI ---
                  // Logo / Header Icon (Diubah menjadi Tempat Sampah)
                  Container(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _limeGreen.withValues(
                          alpha: 0.2,
                        ), // Warna latar hijau muda
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons
                            .delete_outline_rounded, // Ikon diubah dari lock ke delete
                        size: 64,
                        color: _oldGrassGreen, // Warna ikon hijau tua
                      ),
                    ),
                  ),
                  // --- SELESAI PERUBAHAN DI SINI ---
                  const SizedBox(height: 24),

                  // Judul Halaman
                  const Text(
                    'Selamat Datang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan masuk ke akun Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // Input Email / Username
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: _oldGrassGreen,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _limeGreen, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: _oldGrassGreen,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _limeGreen, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Lupa Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: _oldGrassGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Login dengan Gradasi Warna (Lime Green & Old Grass Green)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_limeGreen, _oldGrassGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _oldGrassGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- PERBAIKAN: Opsi Menjadi Daftar User & Daftar Petugas ---
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun?',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tombol Daftar User
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Daftar User',
                              style: TextStyle(
                                color: _oldGrassGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Text(
                            '  |  ',
                            style: TextStyle(color: Colors.black38),
                          ),
                          // Tombol Daftar Petugas Lapangan
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PetugasRegistrationPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Daftar Petugas',
                              style: TextStyle(
                                color: _oldGrassGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // --- SELESAI PERUBAHAN ---
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
