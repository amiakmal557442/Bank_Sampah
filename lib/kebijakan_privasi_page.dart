import 'package:flutter/material.dart';

class KebijakanPrivasiPage extends StatelessWidget {
  const KebijakanPrivasiPage({super.key});

  final Color primaryGreen = const Color(0xFF16A34A);
  final Color darkGreen = const Color(0xFF14532D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Syarat & Kebijakan Privasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Syarat & Kebijakan Privasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Terakhir diperbarui: 08 Agustus 2026',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('1. Pengumpulan Data Informasi'),
              _buildSectionText(
                'Kami mengumpulkan informasi identitas diri Anda seperti Nama Lengkap, Alamat Email, Nomor Telepon, dan Alamat Rumah/Penjemputan guna memastikan layanan penjemputan dan pengelolaan akun berjalan lancar.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('2. Penggunaan Data'),
              _buildSectionText(
                'Data Anda digunakan secara eksklusif untuk tujuan operasional Bank Sampah, seperti proses validasi setor sampah, konversi poin, serta transfer saldo ke e-wallet atau rekening Anda.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('3. Keamanan Data'),
              _buildSectionText(
                'Kami menerapkan langkah-langkah keamanan fisik maupun digital secara ketat untuk melindungi data pribadi pengguna dari akses, perubahan, atau pengungkapan yang tidak sah oleh pihak ketiga.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('4. Perubahan Kebijakan'),
              _buildSectionText(
                'Kami berhak mengubah atau memperbarui kebijakan privasi ini sewaktu-waktu. Pengguna akan selalu mendapatkan notifikasi jika terdapat perubahan secara masif yang berkaitan dengan data Anda.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
          height: 1.6,
        ),
      ),
    );
  }
}
