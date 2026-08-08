import 'package:flutter/material.dart';

class PengaturanNotifikasiPage extends StatefulWidget {
  const PengaturanNotifikasiPage({super.key});

  @override
  State<PengaturanNotifikasiPage> createState() => _PengaturanNotifikasiPageState();
}

class _PengaturanNotifikasiPageState extends State<PengaturanNotifikasiPage> {
  bool _pushNotif = true;
  bool _emailNotif = false;
  bool _soundNotif = true;
  bool _promoNotif = true;

  final Color primaryGreen = const Color(0xFF16A34A);
  final Color darkGreen = const Color(0xFF14532D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('Pemberitahuan Sistem'),
          _buildSwitchTile(
            title: 'Push Notification',
            subtitle: 'Terima notifikasi tugas dan status langsung di layar',
            value: _pushNotif,
            onChanged: (val) => setState(() => _pushNotif = val),
          ),
          _buildSwitchTile(
            title: 'Notifikasi Email',
            subtitle: 'Terima pembaruan penting via email terdaftar',
            value: _emailNotif,
            onChanged: (val) => setState(() => _emailNotif = val),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Suara & Getaran'),
          _buildSwitchTile(
            title: 'Suara Notifikasi',
            subtitle: 'Bunyikan nada dering saat ada pesan masuk',
            value: _soundNotif,
            onChanged: (val) => setState(() => _soundNotif = val),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Promosi & Informasi'),
          _buildSwitchTile(
            title: 'Info & Pembaruan',
            subtitle: 'Dapatkan berita terbaru seputar Bank Sampah',
            value: _promoNotif,
            onChanged: (val) => setState(() => _promoNotif = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
        value: value,
        activeColor: primaryGreen,
        onChanged: onChanged,
      ),
    );
  }
}
