import 'package:flutter/material.dart';
import 'api_service.dart';
import 'db_helper.dart';

class PetugasRegistrationPage extends StatefulWidget {
  const PetugasRegistrationPage({super.key});

  @override
  State<PetugasRegistrationPage> createState() =>
      _PetugasRegistrationPageState();
}

class _PetugasRegistrationPageState extends State<PetugasRegistrationPage> {
  // Form Key untuk Validasi
  final _formKey = GlobalKey<FormState>();

  // Controller Input Teks
  final _namaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _platNomorController = TextEditingController();

  // State Pilihan Dropdown & Visibility
  bool _isPasswordObscured = true;
  String? _selectedZona;
  String? _selectedKendaraan;

  // Skema Warna
  final Color _limeGreen = const Color(0xFF32CD32);
  final Color _oldGrassGreen = const Color(0xFF268B07);

  // Daftar Pilihan Zona Operasional
  final List<String> _zonaList = [
    'Drop Point 01 - Pusat Kota',
    'Drop Point 02 - Wilayah Utara',
    'Drop Point 03 - Wilayah Selatan',
    'Drop Point 04 - Waste Hub Timur',
    'Drop Point 05 - Waste Hub Barat',
  ];

  // Daftar Pilihan Jenis Kendaraan
  final List<String> _kendaraanList = [
    'Motor Roda 2',
    'Motor Roda 3',
    'Mobil Pick-up',
    'Truk / Mobil Box',
    'Pos Station (Tanpa Kendaraan)',
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _platNomorController.dispose();
    super.dispose();
  }

  Future<void> _handleRegisterPetugas() async {
    if (_formKey.currentState!.validate()) {
      final name = _namaController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Cek email & phone di API (XAMPP) dulu
      bool emailExists = false;
      bool phoneExists = false;
      try {
        final users = await ApiService.instance.getUsers();
        emailExists = users.any(
          (u) => u['email'].toString().toLowerCase() == email.toLowerCase(),
        );
        phoneExists = users.any((u) => u['phone_number']?.toString() == phone);
      } catch (_) {
        emailExists = await DatabaseHelper.instance.isEmailRegistered(email);
        phoneExists = await DatabaseHelper.instance.isPhoneRegistered(phone);
      }

      if (mounted) Navigator.pop(context);

      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email sudah terdaftar!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      if (phoneExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor WhatsApp/HP sudah terdaftar!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final details =
          'Zona: $_selectedZona, Armada: $_selectedKendaraan, Plat: ${_platNomorController.text.trim()}';

      final newPetugas = {
        'id': 'petugas-${DateTime.now().microsecondsSinceEpoch}',
        'phone_number': phone,
        'email': email,
        'full_name': name,
        'password': password,
        'role': 'petugas',
        'address': details,
        'default_setor_method': 'pickup',
        'point_balance': 0,
      };

      // Simpan ke XAMPP dulu, fallback ke lokal
      bool success = false;
      try {
        success = await ApiService.instance.createUser(newPetugas);
      } catch (_) {}
      if (!success) {
        success = await DatabaseHelper.instance.registerUser(newPetugas);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Pendaftaran Petugas Berhasil! Silakan login.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _oldGrassGreen,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran gagal. Silakan coba lagi.'),
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
      appBar: AppBar(
        title: const Text('Registrasi Petugas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge Penanda Peran Petugas Lapangan
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _oldGrassGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _oldGrassGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 18,
                              color: _oldGrassGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pendaftaran Petugas Lapangan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _oldGrassGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Judul Halaman
                    const Text(
                      'Bergabung Sebagai Petugas',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Lengkapi data akun dan area operasional untuk mulai bertugas.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 28),

                    // --- BAGIAN 1: DATA AKUN ---
                    _buildSectionHeader('1. Data Utama & Akun'),
                    const SizedBox(height: 14),

                    // Input Nama Lengkap
                    TextFormField(
                      controller: _namaController,
                      style: const TextStyle(color: Colors.black),
                      decoration: _buildInputDecoration(
                        label: 'Nama Lengkap (Sesuai KTP)',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Nomor WhatsApp / HP
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black),
                      decoration: _buildInputDecoration(
                        label: 'Nomor WhatsApp / HP',
                        prefixIcon: Icons.phone_android_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor WhatsApp wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black),
                      decoration: _buildInputDecoration(
                        label: 'Alamat Email Operasional',
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Kata Sandi
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isPasswordObscured,
                      style: const TextStyle(color: Colors.black),
                      decoration: _buildInputDecoration(
                        label: 'Kata Sandi',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi wajib diisi';
                        }
                        if (value.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // --- BAGIAN 2: DATA OPERASIONAL ---
                    _buildSectionHeader('2. Data Operasional & Kendaraan'),
                    const SizedBox(height: 14),

                    // Dropdown Zona / Drop Point
                    DropdownButtonFormField<String>(
                      value: _selectedZona,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      decoration: _buildInputDecoration(
                        label: 'Pilih Zona / Drop Point Utama',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      items: _zonaList.map((zona) {
                        return DropdownMenuItem<String>(
                          value: zona,
                          child: Text(zona),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedZona = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zona operasional wajib dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Jenis Kendaraan Operasional
                    DropdownButtonFormField<String>(
                      value: _selectedKendaraan,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      decoration: _buildInputDecoration(
                        label: 'Jenis Armada / Kendaraan',
                        prefixIcon: Icons.directions_car_outlined,
                      ),
                      items: _kendaraanList.map((kendaraan) {
                        return DropdownMenuItem<String>(
                          value: kendaraan,
                          child: Text(kendaraan),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedKendaraan = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jenis kendaraan wajib dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Plat Nomor (Bila Menggunakan Kendaraan)
                    if (_selectedKendaraan != null &&
                        !_selectedKendaraan!.contains('Tanpa Kendaraan')) ...[
                      TextFormField(
                        controller: _platNomorController,
                        style: const TextStyle(color: Colors.black),
                        textCapitalization: TextCapitalization.characters,
                        decoration: _buildInputDecoration(
                          label: 'Nomor Polisi (Plat Nomor Kendaraan)',
                          prefixIcon: Icons.subtitles_outlined,
                          hintText: 'Contoh: B 1234 ABC',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor polisi kendaraan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 20),

                    // Tombol Submit Pendaftaran Petugas
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_limeGreen, _oldGrassGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _oldGrassGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _handleRegisterPetugas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Daftar Sebagai Petugas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Header Sub-Bagian Form
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _oldGrassGreen,
      ),
    );
  }

  // Dekorasi Input Form Konsisten
  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: _oldGrassGreen),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
