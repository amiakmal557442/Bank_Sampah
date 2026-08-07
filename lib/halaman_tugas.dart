import 'package:flutter/material.dart';
import 'api_service.dart';
import 'db_helper.dart';
import 'map_location_screen.dart';
import 'session_service.dart';

class HalamanTugas extends StatefulWidget {
  const HalamanTugas({Key? key}) : super(key: key);

  @override
  State<HalamanTugas> createState() => _HalamanTugasState();
}

class _HalamanTugasState extends State<HalamanTugas> {
  List<Map<String, dynamic>> _daftarTugas = [];
  bool _isLoading = true;

  final Color greenTheme = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> tasks = [];
    try {
      // Ambil semua tugas yang masih aktif dari XAMPP API
      tasks = await ApiService.instance.getPendingTasks(
        statuses: ['dikonfirmasi', 'menuju_lokasi', 'tiba'],
      );
    } catch (_) {}
    // Fallback ke local DB jika API gagal
    if (tasks.isEmpty) {
      tasks = await DatabaseHelper.instance.getPendingPickupTasks();
    }

    if (mounted) {
      setState(() {
        _daftarTugas = tasks;
        _isLoading = false;
      });
    }
  }

  // Update status ke menuju_lokasi
  Future<void> _updateStatusMenuju(String id) async {
    bool success = false;
    try {
      success = await ApiService.instance.updateTaskStatus(id, 'menuju_lokasi');
    } catch (_) {}
    if (!success) {
      success = await DatabaseHelper.instance.updateTransactionStatus(
        id,
        'menuju_lokasi',
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Status diperbarui: Menuju Lokasi'),
          backgroundColor: greenTheme,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadTasks();
    }
  }

  // Dialog timbang untuk menyelesaikan tugas dan menambah poin nasabah
  Future<void> _showSelesaikanDialog(Map<String, dynamic> tugas) async {
    final txId = (tugas['id_transaksi'] ?? tugas['id'])?.toString() ?? '';
    final namaNasabah =
        (tugas['nama_nasabah'] ?? tugas['nasabah_name'] ?? 'Nasabah')
            .toString();

    // Extract kategori yang dipilih nasabah dari API/database
    final String selectedJenis = (tugas['jenis_sampah'] ?? '').toString();
    final List<Map<String, dynamic>> rawItems =
        List<Map<String, dynamic>>.from(tugas['items'] ?? []);
    final Set<int> selectedCategoryIds = rawItems
        .map(
          (i) => int.tryParse(i['waste_category_id']?.toString() ?? '0') ?? 0,
        )
        .where((id) => id > 0)
        .toSet();

    // Daftar jenis sampah & poin per kg dari database
    final categories = await DatabaseHelper.instance.getWasteCategories();
    final List<Map<String, dynamic>> wasteItems = categories.map((c) {
      final catId = (c['id'] as num).toInt();
      final catName = c['name'].toString();
      final bool isSelectedByUser = selectedCategoryIds.contains(catId) ||
          selectedJenis.toLowerCase().contains(catName.toLowerCase());

      return {
        'name': catName,
        'poin_per_kg': (c['point_per_kg'] as num).toInt(),
        'icon': Icons.recycling_outlined,
        'selected': isSelectedByUser,
        'berat': 1.0,
      };
    }).toList();

    if (!wasteItems.any((e) => e['selected'] == true) && wasteItems.isNotEmpty) {
      wasteItems[0]['selected'] = true;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TimbangSheet(
        txId: txId,
        namaNasabah: namaNasabah,
        wasteItems: wasteItems,
        greenTheme: greenTheme,
        onSelesai: (int totalPoin, double totalBerat) async {
          // 1. Update API
          try {
            await ApiService.instance.updateTransaction(txId, {
              'status': 'selesai',
              'total_actual_points': totalPoin,
            });
          } catch (_) {}

          // 2. Selalu update lokal — ini yang menambah saldo poin nasabah
          await DatabaseHelper.instance.completeTransaction(txId, totalPoin);

          // 3. Refresh session petugas (kalau petugas juga punya poin)
          await SessionService.refresh();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Tugas selesai! $namaNasabah mendapat $totalPoin poin dari ${totalBerat.toStringAsFixed(1)} kg sampah.',
                ),
                backgroundColor: greenTheme,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
            // Hapus tugas dari list (langsung, tanpa nunggu reload)
            setState(() {
              _daftarTugas.removeWhere(
                (t) => (t['id_transaksi'] ?? t['id'])?.toString() == txId,
              );
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarTugas.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTasks,
              color: greenTheme,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _daftarTugas.length,
                itemBuilder: (context, index) {
                  return _buildTaskCard(_daftarTugas[index]);
                },
              ),
            ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> tugas) {
    final String statusStr = tugas['status']?.toString() ?? 'dikonfirmasi';
    final bool isMenuju = statusStr == 'menuju_lokasi';
    final bool isTiba = statusStr == 'tiba';
    final bool sudahMenuju = isMenuju || isTiba;

    final String tipeRaw = (tugas['tipe_tugas'] ?? tugas['type'] ?? '')
        .toString();
    final bool isDropIn = tipeRaw == 'Drop-in' || tipeRaw == 'drop_in';

    final String tipeTugas = isDropIn ? 'Drop-in' : 'Jemput';
    final Color tipeColor = isDropIn ? Colors.purple : greenTheme;
    final IconData tipeIcon = isDropIn
        ? Icons.store
        : Icons.local_shipping_outlined;

    // Drop-in:  "Tiba di Lokasi" (hijau) → langsung ke timbang
    // Pickup:   "Jemput" → "Tiba di Lokasi"
    final String mainBtnLabel = isDropIn
        ? 'Tiba di Lokasi'
        : (isTiba ? 'Timbang' : (isMenuju ? 'Tiba di Lokasi' : 'Jemput'));
    final IconData mainBtnIcon = isDropIn
        ? Icons.where_to_vote_rounded
        : (isTiba ? Icons.scale_rounded : (isMenuju ? Icons.where_to_vote_rounded : Icons.local_shipping));
    final Color mainBtnColor = isDropIn
        ? Colors.green.shade700
        : (sudahMenuju ? Colors.green.shade700 : greenTheme);

    final String txId =
        (tugas['id_transaksi'] ?? tugas['id'])?.toString() ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tipe + ID + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(tipeIcon, color: tipeColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        tipeTugas,
                        style: TextStyle(
                          color: tipeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          txId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: sudahMenuju
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusStr == 'dikonfirmasi'
                        ? 'MENUNGGU'
                        : statusStr.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: sudahMenuju
                          ? Colors.blue.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 1),
            ),

            // Nama Nasabah
            Row(
              children: [
                Icon(Icons.person, color: greenTheme, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (tugas['nama_nasabah'] ?? tugas['nasabah_name'] ?? '-')
                        .toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lokasi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isDropIn ? Icons.store_mall_directory : Icons.location_on,
                  color: isDropIn ? Colors.purple : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDropIn
                        ? (tugas['drop_point_name'] != null
                            ? '${tugas['drop_point_name']} — ${tugas['drop_point_address'] ?? ''}'
                            : (tugas['alamat'] ?? tugas['nasabah_address'] ?? 'Drop Point'))
                        : (tugas['alamat'] ?? tugas['nasabah_address'] ?? '-'),
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Jenis & Estimasi
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.recycling, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tugas['jenis_sampah'] ?? 'Sampah Campur'}\nEstimasi: ${tugas['estimasi_berat'] ?? '${tugas['total_est_weight'] ?? 0} kg'}',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol aksi
            Row(
              children: [
                // Tombol Peta
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const MapLocationScreen(showBottomNav: false),
                        ),
                      );
                    },
                    icon: Icon(Icons.map_outlined, color: greenTheme, size: 18),
                    label: const Text('Lokasi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: greenTheme,
                      side: BorderSide(color: greenTheme),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol aksi utama
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (isDropIn) {
                        // Drop-in: update status ke 'tiba' dulu, lalu buka dialog timbang
                        try {
                          await ApiService.instance.updateTaskStatus(
                              txId, 'tiba');
                        } catch (_) {
                          await DatabaseHelper.instance
                              .updateTransactionStatus(txId, 'tiba');
                        }
                        _showSelesaikanDialog(tugas);
                      } else if (isTiba) {
                        // Pickup: sudah tiba → selesaikan dengan timbang
                        _showSelesaikanDialog(tugas);
                      } else if (isMenuju) {
                        // Pickup: sudah menuju → update ke tiba, lalu buka dialog timbang
                        try {
                          await ApiService.instance.updateTaskStatus(txId, 'tiba');
                        } catch (_) {
                          await DatabaseHelper.instance.updateTransactionStatus(txId, 'tiba');
                        }
                        _showSelesaikanDialog(tugas);
                      } else {
                        // Pickup: belum berangkat (dikonfirmasi) → update ke menuju_lokasi
                        _updateStatusMenuju(txId);
                      }
                    },
                    icon: Icon(mainBtnIcon, color: Colors.white, size: 18),
                    label: Text(mainBtnLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBtnColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 90,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'Semua tugas selesai! 🎉',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada tugas yang tersisa saat ini.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Sheet Timbang & Selesaikan Tugas
// ─────────────────────────────────────────────────────────────
class _TimbangSheet extends StatefulWidget {
  final String txId;
  final String namaNasabah;
  final List<Map<String, dynamic>> wasteItems;
  final Color greenTheme;
  final Future<void> Function(int totalPoin, double totalBerat) onSelesai;

  const _TimbangSheet({
    required this.txId,
    required this.namaNasabah,
    required this.wasteItems,
    required this.greenTheme,
    required this.onSelesai,
  });

  @override
  State<_TimbangSheet> createState() => _TimbangSheetState();
}

class _TimbangSheetState extends State<_TimbangSheet> {
  late List<Map<String, dynamic>> _items;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Deep copy agar tidak mengubah data asli
    _items = widget.wasteItems
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  double get _totalBerat => _items
      .where((e) => e['selected'] == true)
      .fold(0.0, (s, e) => s + ((e['berat'] as num?)?.toDouble() ?? 0.0));

  int get _totalPoin => _items
      .where((e) => e['selected'] == true)
      .fold(
        0,
        (s, e) =>
            s +
            (((e['berat'] as num?)?.toDouble() ?? 0.0) *
                    ((e['poin_per_kg'] as num?)?.toDouble() ?? 0.0))
                .round(),
      );

  @override
  Widget build(BuildContext context) {
    final Color green = widget.greenTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.scale_rounded,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Timbang Manual',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.txId} · ${widget.namaNasabah}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(),
                ],
              ),
            ),

            // Daftar sampah
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (ctx, i) => _buildWasteRow(_items[i], green),
              ),
            ),

            // Total & Konfirmasi
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Summary berat & poin
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Berat',
                          '${_totalBerat.toStringAsFixed(1)} kg',
                          Icons.scale_rounded,
                          green,
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: green.withOpacity(0.3),
                        ),
                        _buildSummaryItem(
                          'Total Poin',
                          '$_totalPoin poin',
                          Icons.stars_rounded,
                          green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _totalBerat > 0 ? green : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _totalBerat > 0 && !_isLoading
                          ? () async {
                              setState(() => _isLoading = true);
                              final poin = _totalPoin;
                              final berat = _totalBerat;
                              Navigator.pop(context); // tutup sheet
                              await widget.onSelesai(poin, berat);
                            }
                          : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isLoading ? 'Menyimpan...' : 'Konfirmasi Timbangan',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteRow(Map<String, dynamic> item, Color green) {
    final bool selected = item['selected'] == true;
    final double berat = (item['berat'] as num?)?.toDouble() ?? 0.5;
    final int poinPerKg = (item['poin_per_kg'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? green.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? green.withOpacity(0.4) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            activeColor: green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (v) => setState(() => item['selected'] = v ?? false),
          ),
          Icon(
            item['icon'] as IconData? ?? Icons.recycling,
            color: selected ? green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black87 : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$poinPerKg poin/kg',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (selected) ...[
            IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: const Icon(
                Icons.remove_circle_rounded,
                color: Colors.redAccent,
              ),
              onPressed: () {
                setState(() {
                  if (berat > 0.5) {
                    item['berat'] = double.parse(
                      (berat - 0.5).toStringAsFixed(1),
                    );
                  }
                });
              },
            ),
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                berat.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: Icon(Icons.add_circle_rounded, color: green),
              onPressed: () {
                setState(() {
                  item['berat'] = double.parse(
                    (berat + 0.5).toStringAsFixed(1),
                  );
                });
              },
            ),
            Text('kg', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color green,
  ) {
    return Column(
      children: [
        Icon(icon, color: green, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
