import 'package:flutter/material.dart';
import 'session_service.dart';


// ============================================================================
// Halaman Profil — Aplikasi Mobile Petugas/Pekerja Lapangan
// Berdasarkan SRS:
//   FR-PL-12 — Mencatat absensi & lokasi kerja petugas untuk pemantauan admin
//   FR-PL-13 — Fitur chat dengan pengguna maupun dengan admin/kantor
//   FR-PL-14 — Melaporkan kendala di lapangan
//
// CATATAN: bagian "Info Akun", "Statistik Kinerja", dan "Pengaturan" TIDAK
// disebutkan eksplisit di SRS — ini elemen standar profil aplikasi yang
// wajar ada, ditandai jelas di komentar supaya beda dengan requirement asli.
//
// Asumsi platform: mobile (Android/iOS), sesuai SRS 2.1 — aplikasi mobile
// Petugas Lapangan terpisah mode kerjanya dari end user.
// ============================================================================

const Color primaryGreen = Color(0xFF268B07);
const Color limeGreen = Color(0xFF32CD32);
const Color pageBackground = Color(0xFFF5F6F8);
const Color darkText = Color(0xFF0F172A);
const Color subtleText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);
const Color borderColor = Color(0xFFE2E8F0);
const Color secondaryDarkText = Color(0xFF334155);

class AbsensiHistoryItem {
  final String tanggal;
  final String jamMasuk;
  final String jamKeluar;
  final String lokasi;
  final bool isComplete;

  AbsensiHistoryItem({
    required this.tanggal,
    required this.jamMasuk,
    required this.jamKeluar,
    required this.lokasi,
    required this.isComplete,
  });
}

final List<AbsensiHistoryItem> sampleAbsensi = [
  AbsensiHistoryItem(tanggal: 'Hari ini, 1 Agu', jamMasuk: '07.45', jamKeluar: '-', lokasi: 'Zona Depok Selatan', isComplete: false),
  AbsensiHistoryItem(tanggal: 'Kemarin, 31 Jul', jamMasuk: '07.50', jamKeluar: '16.20', lokasi: 'Zona Depok Selatan', isComplete: true),
  AbsensiHistoryItem(tanggal: '30 Jul', jamMasuk: '08.02', jamKeluar: '16.05', lokasi: 'Zona Depok Selatan', isComplete: true),
];

class KendalaHistoryItem {
  final String judul;
  final String tanggal;
  final String status; // 'Diproses', 'Selesai'

  KendalaHistoryItem({required this.judul, required this.tanggal, required this.status});
}

final List<KendalaHistoryItem> sampleKendala = [
  KendalaHistoryItem(judul: 'Lokasi tidak ditemukan - Jl. Kartini No. 8', tanggal: '29 Jul 2026', status: 'Selesai'),
  KendalaHistoryItem(judul: 'Ban motor bocor di tengah rute', tanggal: '22 Jul 2026', status: 'Selesai'),
];

class PetugasProfilScreen extends StatefulWidget {
  const PetugasProfilScreen({super.key});

  @override
  State<PetugasProfilScreen> createState() => _PetugasProfilScreenState();
}

class _PetugasProfilScreenState extends State<PetugasProfilScreen> {
  bool sudahAbsenHariIni = true;

  // ------------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------------

  Widget _buildHeader() {
    final String petugasName = SessionService.fullName.isNotEmpty
        ? SessionService.fullName
        : 'Dedi Kurniawan';
    final String address = SessionService.currentUser?['address'] as String? ?? '';
    final match = RegExp(r'Armada:\s*([^,]+)').firstMatch(address);
    final String subTitle = match != null ? 'ID: PL-2201 · ${match.group(1)}' : 'ID: PL-2201 · Petugas Lapangan';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petugasName,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subTitle,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: limeGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173404),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // ABSENSI CARD (FR-PL-12)
  // ------------------------------------------------------------------------

  Widget _buildAbsensiCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: primaryGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Absensi Hari Ini',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sudahAbsenHariIni)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FCE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: primaryGreen, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sudah absen masuk · 07.45 WIB',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Lokasi: Zona Depok Selatan',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: subtleText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => sudahAbsenHariIni = true),
                icon: const Icon(Icons.location_on_rounded, size: 16),
                label: const Text('Absen Masuk Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (sudahAbsenHariIni) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: proses absen keluar
                },
                icon: const Icon(Icons.logout_rounded, size: 15),
                label: const Text('Absen Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryDarkText,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  side: const BorderSide(color: borderColor, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // STATISTIK KINERJA (elemen tambahan, bukan requirement eksplisit)
  // ------------------------------------------------------------------------

  Widget _buildStatistikRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _statChip('142', 'Tugas selesai', Icons.task_alt_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _statChip('4,9', 'Rating', Icons.star_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _statChip('1,2 ton', 'Terkumpul', Icons.recycling_rounded)),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: primaryGreen),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // RIWAYAT ABSENSI (FR-PL-12)
  // ------------------------------------------------------------------------

  Widget _buildRiwayatAbsensi() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Absensi',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          const SizedBox(height: 10),
          ...sampleAbsensi.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: pageBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, size: 13, color: primaryGreen),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.tanggal,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                          Text(
                            item.lokasi,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.isComplete ? '${item.jamMasuk} – ${item.jamKeluar}' : 'Masuk ${item.jamMasuk}',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: subtleText,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // MENU: CHAT ADMIN (FR-PL-13), LAPOR KENDALA (FR-PL-14), PENGATURAN
  // ------------------------------------------------------------------------

  Widget _buildMenuList() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _menuItem(
            icon: Icons.support_agent_rounded,
            title: 'Chat dengan Admin/Kantor',
            subtitle: 'FR-PL-13 — hubungi kantor langsung',
            onTap: () {},
          ),
          _divider(),
          _menuItem(
            icon: Icons.report_problem_outlined,
            title: 'Riwayat Lapor Kendala',
            subtitle: 'FR-PL-14 — ${sampleKendala.length} laporan sebelumnya',
            onTap: () => _showKendalaHistory(context),
          ),
          _divider(),
          _menuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Pengaturan Notifikasi',
            onTap: () {},
          ),
          _divider(),
          _menuItem(
            icon: Icons.help_outline_rounded,
            title: 'Bantuan & FAQ',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showKendalaHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Riwayat Lapor Kendala',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            const SizedBox(height: 14),
            ...sampleKendala.map((k) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pageBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k.judul,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                )),
                            const SizedBox(height: 2),
                            Text(k.tanggal,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w400,
                                  color: mutedText,
                                )),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          k.status,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8E8),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: mutedText, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 0.5, color: borderColor, indent: 14, endIndent: 14);

  // ------------------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------------------

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // TODO: proses logout
          },
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: const Text('Keluar Akun'),
          style: OutlinedButton.styleFrom(
            foregroundColor: secondaryDarkText,
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: const BorderSide(color: borderColor, width: 0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SHARED CARD WRAPPER
  // ------------------------------------------------------------------------

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildAbsensiCard(),
              _buildStatistikRow(),
              _buildRiwayatAbsensi(),
              const SizedBox(height: 4),
              _buildMenuList(),
              const SizedBox(height: 8),
              _buildLogoutButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
