import 'package:flutter/material.dart';
import 'api_service.dart';
import 'db_helper.dart';
import 'session_service.dart';

// ============================================================================
// Halaman Riwayat — Mobile Dashboard Petugas / Pekerja Lapangan
// Menampilkan rincian riwayat tugas yang sudah diterima dan diselesaikan
// (Drop-in Mandiri maupun Jemput Sampah) beserta rincian user, jenis sampah,
// berat aktual, dan poin yang dihasilkan.
// ============================================================================

const Color primaryGreen = Color(0xFF268B07);
const Color limeGreen = Color(0xFF32CD32);
const Color pageBackground = Color(0xFFF5F6F8);
const Color darkText = Color(0xFF0F172A);
const Color subtleText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);
const Color borderColor = Color(0xFFE2E8F0);

class PetugasRiwayatScreen extends StatefulWidget {
  const PetugasRiwayatScreen({super.key});

  @override
  State<PetugasRiwayatScreen> createState() => _PetugasRiwayatScreenState();
}

class _PetugasRiwayatScreenState extends State<PetugasRiwayatScreen> {
  bool isMingguan = false; // false = Harian, true = Mingguan
  bool _isLoading = true;

  List<Map<String, dynamic>> _allTransactions = [];
  Map<int, String> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 1. Ambil kategori sampah untuk mapping ID -> Nama Kategori
    try {
      final cats = await DatabaseHelper.instance.getWasteCategories();
      final Map<int, String> map = {};
      for (var c in cats) {
        final catId = (c['id'] as num).toInt();
        map[catId] = c['name'].toString();
      }
      _categoryMap = map;
    } catch (_) {}

    // 2. Ambil riwayat dari API
    List<Map<String, dynamic>> list = [];
    try {
      final petugasId = SessionService.currentUser?['id'] as String?;
      list = await ApiService.instance.getTransactions(
        status: 'selesai,dibatalkan,terverifikasi',
        petugasId: petugasId,
      );
    } catch (_) {}

    // 3. Fallback ke database lokal jika API kosong
    if (list.isEmpty) {
      try {
        final allLocal = await DatabaseHelper.instance.getAllTransactions();
        list = allLocal.where((tx) {
          final s = (tx['status'] ?? '').toString().toLowerCase();
          return s == 'selesai' || s == 'dibatalkan' || s == 'terverifikasi';
        }).toList();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _allTransactions = list;
        _isLoading = false;
      });
    }
  }

  // Filter transaksi berdasarkan periode terpilih (Harian = Hari Ini, Mingguan = 7 hari terakhir)
  List<Map<String, dynamic>> get _filteredTransactions {
    final now = DateTime.now();
    final list = _allTransactions.where((tx) {
      final dateStr = (tx['created_at'] ?? tx['pickup_date'] ?? '').toString();
      DateTime dt = DateTime.now();
      if (dateStr.isNotEmpty && !dateStr.startsWith('0000')) {
        try {
          dt = DateTime.parse(dateStr);
        } catch (_) {}
      }

      if (isMingguan) {
        final diff = now.difference(dt).inDays;
        return diff >= 0 && diff <= 7;
      } else {
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      }
    }).toList();

    // Jika filter spesifik kosong tetapi ada riwayat transaksi, fallback tampilkan semua agar tidak kosong
    if (list.isEmpty && _allTransactions.isNotEmpty) {
      return _allTransactions;
    }

    return list;
  }

  int get _totalSelesai {
    return _filteredTransactions
        .where((t) => (t['status'] ?? '').toString().toLowerCase() == 'selesai')
        .length;
  }

  double get _totalBerat {
    double total = 0;
    for (var tx in _filteredTransactions) {
      if ((tx['status'] ?? '').toString().toLowerCase() == 'selesai') {
        total += _extractTotalWeight(tx);
      }
    }
    return total;
  }

  int get _totalPoin {
    int total = 0;
    for (var tx in _filteredTransactions) {
      if ((tx['status'] ?? '').toString().toLowerCase() == 'selesai') {
        final pts = (tx['total_actual_points'] ?? tx['total_est_points'] ?? 0) as num;
        total += pts.toInt();
      }
    }
    return total;
  }

  double _extractTotalWeight(Map<String, dynamic> tx) {
    final items = List<Map<String, dynamic>>.from(tx['items'] ?? []);
    double sum = 0.0;
    for (var item in items) {
      final w = double.tryParse(
            (item['actual_weight'] ?? item['estimated_weight'] ?? '0')
                .toString(),
          ) ??
          0.0;
      sum += w;
    }
    if (sum == 0.0) {
      final estStr = (tx['estimasi_berat'] ?? tx['total_est_weight'] ?? '0')
          .toString()
          .replaceAll(' kg', '');
      sum = double.tryParse(estStr) ?? 0.0;
    }
    return sum;
  }

  String _extractCategoryString(Map<String, dynamic> tx) {
    final items = List<Map<String, dynamic>>.from(tx['items'] ?? []);
    List<String> names = [];
    for (var item in items) {
      String? catName = item['category_name']?.toString() ?? item['name']?.toString();
      if (catName == null || catName.isEmpty) {
        final catId = int.tryParse(
          (item['waste_category_id'] ?? item['id'] ?? '0').toString(),
        );
        if (catId != null && _categoryMap.containsKey(catId)) {
          catName = _categoryMap[catId];
        }
      }
      if (catName != null && catName.isNotEmpty && !names.contains(catName)) {
        names.add(catName);
      }
    }

    if (names.isEmpty && tx['jenis_sampah'] != null && tx['jenis_sampah'].toString().isNotEmpty) {
      return tx['jenis_sampah'].toString();
    }
    return names.isNotEmpty ? names.join(', ') : 'Sampah Daur Ulang';
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return 'Hari ini';
    final str = dateStr.toString().trim();
    if (str.isEmpty || str.startsWith('0000')) return 'Hari ini';
    try {
      final dt = DateTime.parse(str);
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final days = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      if (isToday) {
        return 'Hari ini • $timeStr';
      }
      return '${days[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year} • $timeStr';
    } catch (_) {
      return str;
    }
  }

  // ------------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------------

  Widget _buildHeader() {
    final String petugasName = SessionService.fullName.isNotEmpty
        ? SessionService.fullName
        : 'Petugas Lapangan';

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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$petugasName · Petugas Lapangan',
            style: const TextStyle(
              fontSize: 12,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? primaryGreen : Colors.white,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SUMMARY STATS
  // ------------------------------------------------------------------------

  Widget _buildSummaryStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
        Icon(icon, size: 18, color: primaryGreen),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: mutedText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ------------------------------------------------------------------------
  // LIST RIWAYAT CARD
  // ------------------------------------------------------------------------

  Widget _buildRiwayatList() {
    final list = _filteredTransactions;
    if (list.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text(
                'Belum Ada Riwayat Tugas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tugas yang selesai atau dibatalkan akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildRiwayatCard(list[index]);
      },
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> tx) {
    final String typeRaw = (tx['type'] ?? tx['tipe_tugas'] ?? '').toString().toLowerCase();
    final bool isDropIn = typeRaw == 'drop_in' || typeRaw == 'drop-in';
    final String tipeLabel = isDropIn ? 'Drop-in Mandiri' : 'Jemput Sampah';

    final Color badgeBg = isDropIn ? const Color(0xFFF3E8FF) : const Color(0xFFE8F5E9);
    final Color badgeTextColor = isDropIn ? const Color(0xFF7E22CE) : primaryGreen;
    final IconData tipeIcon = isDropIn ? Icons.store_rounded : Icons.local_shipping_rounded;

    final String statusStr = (tx['status'] ?? 'selesai').toString().toLowerCase();
    final bool isSelesai = statusStr == 'selesai' || statusStr == 'terverifikasi';

    final String namaUser = (tx['nasabah_name'] ?? tx['full_name'] ?? 'Nasabah').toString();
    final String kategoriStr = _extractCategoryString(tx);
    final double beratKg = _extractTotalWeight(tx);
    final int poin = ((tx['total_actual_points'] ?? tx['total_est_points'] ?? 0) as num).toInt();
    final String waktuStr = _formatDateTime(tx['created_at'] ?? tx['pickup_date']);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: borderColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Header: Tipe Request + Badge & Waktu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(tipeIcon, size: 14, color: badgeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        tipeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  waktuStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: mutedText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Baris User Siapa Yang Melakukan Request
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: subtleText),
                const SizedBox(width: 6),
                Text(
                  'User: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Expanded(
                  child: Text(
                    namaUser,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Container Rincian Sampah (Jenis + Berat + Poin)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pageBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.recycling_rounded, size: 20, color: primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kategoriStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Berat: ${beratKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 11,
                            color: subtleText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isSelesai) ...[
                        Text(
                          '+$poin poin',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          '0 poin',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Baris Status Pengerjaan (Selesai / Dibatalkan)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${tx['id'] ?? '-'}',
                  style: const TextStyle(fontSize: 11, color: mutedText),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelesai ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSelesai ? 'Selesai' : 'Dibatalkan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelesai ? primaryGreen : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildSummaryStats(),
                    _buildRiwayatList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
