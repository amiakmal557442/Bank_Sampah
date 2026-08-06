import 'package:flutter/material.dart';
import 'session_service.dart';

// ============================================================================
// Halaman Riwayat — Aplikasi Mobile Petugas/Pekerja Lapangan
// Berdasarkan SRS:
//   FR-PL-04 — Menampilkan riwayat tugas harian & mingguan petugas.
//   FR-PL-03 — Status tugas: diterima → menuju lokasi → tiba →
//              selesai/dibatalkan (dua status akhir yang muncul di riwayat)
//
// Asumsi platform: mobile (Android/iOS), konsisten dengan
// petugas_profil_page.dart yang sudah dibuat sebelumnya.
// ============================================================================

const Color primaryGreen = Color(0xFF268B07);
const Color limeGreen = Color(0xFF32CD32);
const Color pageBackground = Color(0xFFF5F6F8);
const Color darkText = Color(0xFF0F172A);
const Color subtleText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);
const Color borderColor = Color(0xFFE2E8F0);
const Color secondaryDarkText = Color(0xFF334155);

enum TugasJenis { jemput, verifikasiDropIn }

enum TugasStatus { selesai, dibatalkan }

class RiwayatTugasItem {
  final String namaUser;
  final TugasJenis jenis;
  final String kategori;
  final double? beratAktual;
  final int? poinDihasilkan;
  final String waktu;
  final TugasStatus status;
  final String? alasanBatal;

  RiwayatTugasItem({
    required this.namaUser,
    required this.jenis,
    required this.kategori,
    this.beratAktual,
    this.poinDihasilkan,
    required this.waktu,
    required this.status,
    this.alasanBatal,
  });
}

// Sample data — dikelompokkan per tanggal untuk tampilan harian
final Map<String, List<RiwayatTugasItem>> sampleRiwayatHarian = {};

class PetugasRiwayatScreen extends StatefulWidget {
  const PetugasRiwayatScreen({super.key});

  @override
  State<PetugasRiwayatScreen> createState() => _PetugasRiwayatScreenState();
}

class _PetugasRiwayatScreenState extends State<PetugasRiwayatScreen> {
  bool isMingguan = false; // false = Harian, true = Mingguan

  int get _totalSelesai {
    int count = 0;
    for (var list in sampleRiwayatHarian.values) {
      count += list.where((t) => t.status == TugasStatus.selesai).length;
    }
    return count;
  }

  double get _totalBerat {
    double total = 0;
    for (var list in sampleRiwayatHarian.values) {
      for (var t in list) {
        if (t.beratAktual != null) total += t.beratAktual!;
      }
    }
    return total;
  }

  int get _totalPoin {
    int total = 0;
    for (var list in sampleRiwayatHarian.values) {
      for (var t in list) {
        if (t.poinDihasilkan != null) total += t.poinDihasilkan!;
      }
    }
    return total;
  }

  // ------------------------------------------------------------------------
  // HEADER (konsisten dengan halaman Profil petugas)
  // ------------------------------------------------------------------------

  Widget _buildHeader() {
    final String petugasName = SessionService.fullName.isNotEmpty
        ? SessionService.fullName
        : 'Dedi Kurniawan';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Tugas',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$petugasName · ID PL-2201',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          // Filter Harian / Mingguan
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(child: _filterTab('Harian', !isMingguan)),
                Expanded(child: _filterTab('Mingguan', isMingguan)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => isMingguan = label == 'Mingguan'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? primaryGreen : Colors.white,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SUMMARY STATS (periode terpilih)
  // ------------------------------------------------------------------------

  Widget _buildSummaryStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                '$_totalSelesai',
                isMingguan ? 'Tugas minggu ini' : 'Tugas hari ini',
                Icons.task_alt_rounded,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _summaryItem(
                '${_totalBerat.toStringAsFixed(1)} kg',
                'Total berat',
                Icons.scale_rounded,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _summaryItem(
                '$_totalPoin',
                'Total poin',
                Icons.stars_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() =>
      Container(width: 0.5, height: 36, color: borderColor);

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(
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
    );
  }

  // ------------------------------------------------------------------------
  // LIST RIWAYAT (dikelompokkan per tanggal)
  // ------------------------------------------------------------------------

  Widget _buildRiwayatList() {
    return Column(
      children: sampleRiwayatHarian.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8, top: 8),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: subtleText,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              ...entry.value.map((item) => _riwayatCard(item)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _riwayatCard(RiwayatTugasItem item) {
    final isSelesai = item.status == TugasStatus.selesai;
    final jenisLabel = item.jenis == TugasJenis.jemput
        ? 'Jemput'
        : 'Verifikasi Drop-in';
    final jenisIcon = item.jenis == TugasJenis.jemput
        ? Icons.local_shipping_rounded
        : Icons.qr_code_scanner_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelesai
                  ? const Color(0xFFE8F8E8)
                  : const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              jenisIcon,
              size: 17,
              color: isSelesai ? primaryGreen : const Color(0xFF5F5E5A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.namaUser,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                    ),
                    Text(
                      item.waktu,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isSelesai
                      ? '$jenisLabel · ${item.kategori} · ${item.beratAktual} kg'
                      : '$jenisLabel · Dibatalkan',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: subtleText,
                  ),
                ),
                if (!isSelesai && item.alasanBatal != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFE8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.alasanBatal!,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5F5E5A),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSelesai && item.poinDihasilkan != null)
                Text(
                  '+${item.poinDihasilkan} poin',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryGreen,
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelesai
                      ? const Color(0xFFE8F8E8)
                      : const Color(0xFFF1EFE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSelesai ? 'Selesai' : 'Dibatalkan',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isSelesai ? primaryGreen : const Color(0xFF5F5E5A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
              _buildSummaryStats(),
              _buildRiwayatList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
