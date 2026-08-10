import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'api_service.dart';

class LaporanAnalitikScreen extends StatefulWidget {
  const LaporanAnalitikScreen({super.key});

  @override
  State<LaporanAnalitikScreen> createState() => _LaporanAnalitikScreenState();
}

class _LaporanAnalitikScreenState extends State<LaporanAnalitikScreen> {
  // ── Palet Warna
  static const Color _green = Color(0xFF268B07);
  static const Color _lime = Color(0xFF32CD32);
  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _grey = Color(0xFF5F6368);
  static const Color _border = Color(0xFFE0E0E0);

  // ── State
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  // Filter bulan yang tersedia
  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'Semua Waktu', 'bulan': 0, 'tahun': 0},
    {'label': 'Agustus 2026', 'bulan': 8, 'tahun': 2026},
    {'label': 'Juli 2026', 'bulan': 7, 'tahun': 2026},
    {'label': 'Juni 2026', 'bulan': 6, 'tahun': 2026},
    {'label': 'Mei 2026', 'bulan': 5, 'tahun': 2026},
  ];
  int _selectedFilterIndex = 1; // default: Agustus 2026

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final filter = _filterOptions[_selectedFilterIndex];
    final result = await ApiService.instance.getLaporanAnalitikData(
      bulan: filter['bulan'] as int,
      tahun: filter['tahun'] as int,
    );
    if (mounted) {
      setState(() {
        _data = result;
        _isLoading = false;
      });
    }
  }

  // ── Format angka
  String _formatKg(double kg) {
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)} ton';
    return '${kg.toStringAsFixed(0)} kg';
  }

  String _formatRupiah(int pts) {
    if (pts >= 1000000) {
      return 'Rp ${(pts / 1000000).toStringAsFixed(1)} Jt';
    }
    return 'Rp ${pts.toString()}';
  }

  String _formatPoin(int pts) {
    if (pts >= 1000000) return '${(pts / 1000000).toStringAsFixed(1)}M Pts';
    if (pts >= 1000) return '${(pts / 1000).toStringAsFixed(0)}K Pts';
    return '$pts Pts';
  }

  // ── Pilih filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Pilih Rentang Waktu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_filterOptions.length, (i) {
              final isSelected = i == _selectedFilterIndex;
              return ListTile(
                dense: true,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? _green : _grey,
                  size: 20,
                ),
                title: Text(
                  _filterOptions[i]['label'],
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? _green : _black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedFilterIndex = i);
                  _loadData();
                },
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: TextStyle(color: _grey)),
          ),
        ],
      ),
    );
  }

  // ── Dialog Export
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: _green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ekspor Laporan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode: ${_filterOptions[_selectedFilterIndex]['label']}',
                  style: TextStyle(color: _grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _exportFormatButton(
                  ctx,
                  Icons.picture_as_pdf_outlined,
                  'Ekspor sebagai PDF',
                  'Format laporan siap cetak',
                  Colors.redAccent,
                ),
                const SizedBox(height: 10),
                _exportFormatButton(
                  ctx,
                  Icons.table_chart_outlined,
                  'Ekspor sebagai Excel (.xlsx)',
                  'Buka dan edit di Microsoft Excel',
                  Colors.teal,
                ),
                const SizedBox(height: 10),
                _exportFormatButton(
                  ctx,
                  Icons.code_outlined,
                  'Ekspor sebagai CSV',
                  'Kompatibel semua aplikasi spreadsheet',
                  Colors.blueGrey,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: TextStyle(color: _grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _exportFormatButton(
    BuildContext ctx,
    IconData icon,
    String label,
    String subtitle,
    Color color,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pop(ctx);
        _simulateExport(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: _grey, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _grey, size: 18),
          ],
        ),
      ),
    );
  }

  void _simulateExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Mengekspor laporan ($format)...'),
          ],
        ),
        backgroundColor: _green,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Laporan berhasil diekspor ($format)!'),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _green),
            const SizedBox(height: 16),
            Text('Memuat data laporan...', style: TextStyle(color: _grey)),
          ],
        ),
      );
    }

    final totalKg = (_data['totalKg'] as num?)?.toDouble() ?? 0.0;
    final totalPoints = (_data['totalPoints'] as num?)?.toInt() ?? 0;
    final totalNasabah = (_data['totalNasabah'] as num?)?.toInt() ?? 0;
    final allNasabah = (_data['allNasabah'] as num?)?.toInt() ?? 1;
    final recyclePct = (_data['recyclePct'] as num?)?.toDouble() ?? 94.2;
    final _ = (_data['totalTx'] as num?)?.toInt() ?? 0;
    final kategoriData =
        (_data['kategoriData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final trendData =
        (_data['trendData'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rekapData =
        (_data['rekapData'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Hitung total KG dari kategori
    final totalKatKg = kategoriData.fold<double>(
      0,
      (sum, e) => sum + ((e['kg'] as num?)?.toDouble() ?? 0),
    );

    // Tren - cari nilai max
    final maxPts = trendData.isEmpty
        ? 1
        : trendData
              .map((e) => (e['pts'] as num?)?.toInt() ?? 0)
              .reduce((a, b) => a > b ? a : b);

    final filterLabel = _filterOptions[_selectedFilterIndex]['label'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kiri: judul dan deskripsi – bisa menyusut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan & Analitik',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analisis statistik penyetoran sampah, konversi poin, serta rekapitulasi data operasional.',
                      style: TextStyle(fontSize: 14, color: _grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Kanan: filter + tombol ekspor – bungkus Wrap agar tidak overflow
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Filter waktu
                  InkWell(
                    onTap: _showFilterDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 15, color: _grey),
                          const SizedBox(width: 6),
                          Text(
                            filterLabel as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, color: _grey),
                        ],
                      ),
                    ),
                  ),
                  // Tombol Ekspor
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _showExportDialog,
                    icon: const Icon(Icons.download, color: _white, size: 16),
                    label: const Text(
                      'Ekspor',
                      style: TextStyle(
                        color: _white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Metric Cards
          Row(
            children: [
              _buildMetricCard(
                'Total Sampah Terkumpul',
                _formatKg(totalKg),
                '+14.2% bulan ini',
                Icons.scale,
                _green,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                'Total Poin Terdistribusi',
                _formatPoin(totalPoints),
                _formatRupiah(totalPoints),
                Icons.monetization_on_outlined,
                _lime,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                'Nasabah Menyetor',
                '$totalNasabah Orang',
                'Dari $allNasabah Total User',
                Icons.groups_outlined,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                'Tingkat Daur Ulang',
                '${recyclePct.toStringAsFixed(1)}%',
                '+2.1% efisiensi',
                Icons.recycling,
                Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Grafik & Komposisi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grafik Batang Tren Mingguan
              Expanded(
                flex: 3,
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tren Penyetoran Sampah (Poin)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _black,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _lime.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Mingguan',
                              style: TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: trendData.isEmpty
                            ? Center(
                                child: Text(
                                  'Tidak ada data tren',
                                  style: TextStyle(color: _grey),
                                ),
                              )
                            : _buildBarChart(trendData, maxPts),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Komposisi Kategori
              Expanded(
                flex: 2,
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Komposisi Jenis Sampah',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: () {
                            final colors = [
                              _green,
                              _lime,
                              Colors.orange,
                              Colors.blueGrey,
                              Colors.purple,
                            ];
                            return List.generate(kategoriData.length, (i) {
                              final item = kategoriData[i];
                              final kg = (item['kg'] as num?)?.toDouble() ?? 0;
                              final pct = totalKatKg > 0
                                  ? (kg / totalKatKg)
                                  : 0.0;
                              final color = colors[i % colors.length];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildCategoryBar(
                                  item['name'] ?? 'Kategori',
                                  '${(pct * 100).toStringAsFixed(0)}%',
                                  pct.toDouble(),
                                  color,
                                  '${kg.toStringAsFixed(0)} kg',
                                ),
                              );
                            });
                          }(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Tabel Rekapitulasi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rekapitulasi Laporan Siap Unduh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _black,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadData,
                      icon: Icon(Icons.refresh, size: 16, color: _green),
                      label: Text(
                        'Segarkan Data',
                        style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(
                        color: _lime.withValues(alpha: 0.08),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Periode Laporan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Total Transaksi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Total Volume',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Nilai Konversi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Aksi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Data Rows
                    ...rekapData.map((row) {
                      final tx = row['totalTx'] ?? row['totalTx'] ?? 0;
                      final pts = (row['totalPts'] as num?)?.toInt() ?? 0;
                      final kg = (row['totalKg'] as num?)?.toDouble();
                      return _buildRekapRow(
                        row['periode']?.toString() ?? '-',
                        '$tx Transaksi',
                        kg != null ? '${kg.toStringAsFixed(0)} kg' : '-',
                        _formatRupiah(pts),
                        row['periode']?.toString() ?? '-',
                      );
                    }),
                  ],
                ),
                if (rekapData.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Belum ada data rekap untuk periode ini.',
                        style: TextStyle(color: _grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Metric Card
  Widget _buildMetricCard(
    String title,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: _grey),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bar Chart Custom (tanpa library)
  Widget _buildBarChart(List<Map<String, dynamic>> data, int maxPts) {
    return Column(
      children: [
        // Chart area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW =
                  (constraints.maxWidth - (data.length - 1) * 8) / data.length;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final pts = (item['pts'] as num?)?.toInt() ?? 0;
                  final pct = maxPts > 0 ? pts / maxPts : 0.0;
                  return SizedBox(
                    width: barW,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tooltip-ish label on top
                          Text(
                            pts >= 1000
                                ? '${(pts / 1000).toStringAsFixed(1)}K'
                                : '$pts',
                            style: TextStyle(
                              fontSize: 9,
                              color: _grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            width: double.infinity,
                            // Maximum bar height = available height minus the space taken by Text and SizedBox (~18px)
                            height: (constraints.maxHeight - 20) * pct,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_lime, _green],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // X Labels
        Row(
          children: data.map((item) {
            return Expanded(
              child: Text(
                item['label']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: _grey),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Category Progress Bar
  Widget _buildCategoryBar(
    String name,
    String pct,
    double progress,
    Color color,
    String kgLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              pct,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 3),
        Text(kgLabel, style: TextStyle(fontSize: 10, color: _grey)),
      ],
    );
  }

  // ── Rekap Table Row
  TableRow _buildRekapRow(
    String periode,
    String totalTx,
    String volume,
    String nilai,
    String periodeLabel,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            periode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Text(totalTx)),
        Padding(padding: const EdgeInsets.all(12), child: Text(volume)),
        Padding(padding: const EdgeInsets.all(12), child: Text(nilai)),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Tooltip(
                message: 'Ekspor PDF',
                child: InkWell(
                  onTap: () => _simulateExport('PDF - $periodeLabel'),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Ekspor Excel',
                child: InkWell(
                  onTap: () => _simulateExport('Excel - $periodeLabel'),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.table_chart_outlined,
                      color: Colors.teal,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
