import 'package:flutter/material.dart';

class BantuanFaqPage extends StatelessWidget {
  const BantuanFaqPage({super.key});

  final Color primaryGreen = const Color(0xFF16A34A);
  final Color darkGreen = const Color(0xFF14532D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan & FAQ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Halo, ada yang bisa kami bantu?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temukan jawaban dari pertanyaan yang sering diajukan di bawah ini, atau hubungi layanan pelanggan kami.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pertanyaan Populer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            'Apa itu aplikasi Bank Sampah?',
            'Aplikasi Bank Sampah adalah platform yang memudahkan Anda untuk menabung sampah yang dapat didaur ulang, dan menukarkannya menjadi poin atau saldo tunai.',
          ),
          _buildFaqItem(
            'Bagaimana cara menyetor sampah?',
            'Anda dapat membawa langsung sampah yang sudah dipilah ke lokasi Bank Sampah terdekat, atau menggunakan fitur penjemputan oleh petugas kami (jika tersedia).',
          ),
          _buildFaqItem(
            'Kapan poin saya akan bertambah?',
            'Poin akan otomatis ditambahkan ke saldo akun Anda setelah petugas menimbang dan memvalidasi jenis serta berat sampah yang Anda setorkan.',
          ),
          _buildFaqItem(
            'Apakah saya bisa menarik saldo poin menjadi uang tunai?',
            'Tentu! Anda dapat melakukan penarikan saldo ke Rekening Bank atau E-Wallet yang terdaftar di akun Anda melalui menu Tarik Saldo.',
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () {
                // Future action: Open WhatsApp or Email
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, color: primaryGreen),
              label: Text(
                'Hubungi Customer Service',
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryGreen, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        iconColor: primaryGreen,
        collapsedIconColor: const Color(0xFF94A3B8),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
