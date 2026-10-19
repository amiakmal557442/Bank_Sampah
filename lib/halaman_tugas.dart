import 'package:flutter/material.dart';
import 'api_service.dart';
import 'widgets/image_viewer_dialog.dart';
import 'db_helper.dart';
import 'session_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_page.dart';

class HalamanTugas extends StatefulWidget {
  const HalamanTugas({Key? key}) : super(key: key);

  @override
  State<HalamanTugas> createState() => _HalamanTugasState();
}

class _HalamanTugasState extends State<HalamanTugas> {
  List<Map<String, dynamic>> _daftarTugas = [];
  List<Map<String, dynamic>> _masterDropPoints = [];
  bool _isLoading = true;

  final Color greenTheme = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  String _resolveDropPointAddress(Map<String, dynamic> tugas) {
    final direct = (tugas['drop_point_address'] ?? '').toString().trim();
    if (direct.isNotEmpty && direct != '-') return direct;

    final dpId = tugas['drop_point_id']?.toString().trim();
    final dpName =
        (tugas['drop_point_name'] ?? '').toString().trim().toLowerCase();

    for (var dp in _masterDropPoints) {
      if (dpId != null && dpId.isNotEmpty && dp['id']?.toString() == dpId) {
        final a = dp['address']?.toString().trim();
        if (a != null && a.isNotEmpty) return a;
      }
      final n = (dp['name'] ?? '').toString().trim().toLowerCase();
      if (dpName.isNotEmpty &&
          (n == dpName || n.contains(dpName) || dpName.contains(n))) {
        final a = dp['address']?.toString().trim();
        if (a != null && a.isNotEmpty) return a;
      }
    }

    if (dpName.contains('lakessi')) {
      return 'Jl. Lasinrang No. 12, Pasar Lakessi, Parepare';
    }
    if (dpName.contains('lumpue')) {
      return 'Jl. H.A.M. Arsyad, Lumpue, Bacukiki Barat, Parepare';
    }
    if (dpName.contains('pusat') || dpName.contains('ujung')) {
      return 'Jl. Bau Massepe No. 10, Ujung, Parepare';
    }
    if (dpName.contains('soreang')) {
      return 'Jl. Jendral Sudirman No. 5, Soreang, Parepare';
    }

    return 'Jl. Lasinrang No. 12, Pasar Lakessi, Parepare';
  }

  String _resolvePickupAddress(Map<String, dynamic> tugas) {
    final candidates = [
      tugas['address'],
      tugas['nasabah_address'],
      tugas['pickup_address'],
      tugas['alamat'],
      tugas['user_address'],
    ];
    for (var c in candidates) {
      final s = c?.toString().trim();
      if (s != null &&
          s.isNotEmpty &&
          s != 'Unknown' &&
          s != 'Alamat tidak tersedia' &&
          s != '-') {
        return s;
      }
    }
    return 'Alamat penjemputan belum ditulis nasabah';
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final dps = await ApiService.instance.getDropPoints();
      if (dps.isNotEmpty) {
        _masterDropPoints = dps;
      } else {
        _masterDropPoints = await DatabaseHelper.instance.getDropPoints();
      }
    } catch (_) {
      try {
        _masterDropPoints = await DatabaseHelper.instance.getDropPoints();
      } catch (_) {}
    }

    List<Map<String, dynamic>> tasks = [];
    bool apiLoaded = false;
    try {
      tasks = await ApiService.instance.getPendingTasks(
        statuses: ['dikonfirmasi', 'menuju_lokasi', 'tiba'],
      );
      apiLoaded = true;
    } catch (_) {
      apiLoaded = false;
    }

    if (!apiLoaded) {
      final local = await DatabaseHelper.instance.getPendingPickupTasks();
      tasks = local
          .where((t) =>
              t['status'] == 'dikonfirmasi' ||
              t['status'] == 'menuju_lokasi' ||
              t['status'] == 'tiba')
          .toList();
    }

    // Pastikan transaksi yang dibatalkan / ditolak admin tidak muncul sama sekali di tugas petugas
    tasks = tasks.where((t) {
      final s = (t['status'] ?? '').toString().toLowerCase().trim();
      return s != 'dibatalkan' &&
          s != 'ditolak' &&
          s != 'rejected' &&
          s != 'selesai' &&
          s != 'menunggu' &&
          (s == 'dikonfirmasi' || s == 'menuju_lokasi' || s == 'tiba');
    }).toList();

    List<Map<String, dynamic>> titipan = [];
    try {
      final List<Map<String, dynamic>> res = await ApiService.instance
          .fetchWithdrawals();
      titipan = res.where((w) {
        return w['status'] == 'approved' &&
            w['account_details']?.toString().contains('(Titip Kurir)') == true;
      }).toList();
    } catch (e) {
      titipan = await DatabaseHelper.instance.getTitipanKurir();
    }

    for (var t in titipan) {
      String itemName =
          t['account_details']
              ?.toString()
              .replaceAll('(Titip Kurir)', '')
              .trim() ??
          'Sembako';
      String addr = t['nasabah_address']?.toString().trim() ?? '';
      if (addr.isEmpty) addr = t['address']?.toString().trim() ?? '';

      tasks.add({
        'id': t['id'],
        'tipe_tugas': 'Pengantaran Sembako',
        'status': 'siap_diantar',
        'nama_nasabah': t['full_name'] ?? t['nasabah_name'] ?? 'Nasabah',
        'nasabah_address': addr.isEmpty ? 'Alamat belum diatur' : addr,
        'jenis_sampah': 'Barang Titipan',
        'estimasi_berat': itemName,
        'is_pengantaran': true,
      });
    }

    if (mounted) {
      setState(() {
        _daftarTugas = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatusMenuju(String id) async {
    final petugasId = SessionService.currentUser?['id']?.toString() ?? '';
    bool success = false;
    String? errorMessage;

    try {
      success = await ApiService.instance.claimTask(id, petugasId);
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    if (!success && errorMessage == null) {
      success = await DatabaseHelper.instance.updateTransactionStatus(
        id,
        'menuju_lokasi',
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tugas berhasil diklaim!'),
          backgroundColor: greenTheme,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    _loadTasks();
  }

  Future<void> _showSelesaikanDialog(Map<String, dynamic> tugas) async {
    final txId = (tugas['id_transaksi'] ?? tugas['id'])?.toString() ?? '';
    final namaNasabah =
        (tugas['nama_nasabah'] ?? tugas['nasabah_name'] ?? 'Nasabah')
            .toString();

    final String selectedJenis = (tugas['jenis_sampah'] ?? '').toString();
    final List<Map<String, dynamic>> rawItems = List<Map<String, dynamic>>.from(
      tugas['items'] ?? [],
    );
    final Set<int> selectedCategoryIds = rawItems
        .map(
          (i) => int.tryParse(i['waste_category_id']?.toString() ?? '0') ?? 0,
        )
        .where((id) => id > 0)
        .toSet();

    List<Map<String, dynamic>> categories = [];
    try {
      categories = await ApiService.instance.getWasteCategories();
    } catch (_) {}
    if (categories.isEmpty) {
      categories = await DatabaseHelper.instance.getWasteCategories();
    }

    final List<Map<String, dynamic>> wasteItems = categories.map((c) {
      final catId = (c['id'] as num).toInt();
      final catName = c['name'].toString();
      final bool isSelectedByUser =
          selectedCategoryIds.contains(catId) ||
          selectedJenis.toLowerCase().contains(catName.toLowerCase());
      final double minWeight = (c['min_weight'] as num?)?.toDouble() ?? 1.0;

      return {
        'id': catId,
        'name': catName,
        'poin_per_kg': (c['point_per_kg'] as num).toInt(),
        'min_weight': minWeight,
        'icon': Icons.recycling_outlined,
        'selected': isSelectedByUser,
        'berat': minWeight,
      };
    }).toList();

    if (!wasteItems.any((e) => e['selected'] == true) &&
        wasteItems.isNotEmpty) {
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
        onSelesai:
            (
              int totalPoin,
              double totalBerat,
              List<Map<String, dynamic>> itemsToSend,
            ) async {
              try {
                await ApiService.instance.updateTransaction(txId, {
                  'status': 'selesai',
                  'total_actual_points': totalPoin,
                  'items': itemsToSend,
                });
              } catch (_) {}

              await DatabaseHelper.instance.completeTransaction(
                txId,
                totalPoin,
                items: itemsToSend,
              );

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

                _loadTasks();
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

  void _showLocationMapDialog(Map<String, dynamic> tugas) {
    double lat = -4.0150;
    double lng = 119.6290;

    final String tipeRaw =
        (tugas['tipe_tugas'] ?? tugas['type'] ?? '').toString();
    final bool isDropIn = tipeRaw == 'Drop-in' ||
        tipeRaw == 'drop_in' ||
        tipeRaw.toLowerCase().contains('drop');
    final bool isPengantaran = tugas['is_pengantaran'] == true;

    if (isDropIn) {
      final dpLat = double.tryParse(tugas['drop_point_lat']?.toString() ?? '');
      final dpLng = double.tryParse(tugas['drop_point_lng']?.toString() ?? '');
      if (dpLat != null && dpLng != null && dpLat != 0.0) {
        lat = dpLat;
        lng = dpLng;
      } else {
        final dpName =
            (tugas['drop_point_name'] ?? '').toString().toLowerCase();
        if (dpName.contains('lakessi')) {
          lat = -4.0045;
          lng = 119.6240;
        } else if (dpName.contains('lumpue')) {
          lat = -4.0410;
          lng = 119.6280;
        } else if (dpName.contains('soreang')) {
          lat = -3.9868;
          lng = 119.6341;
        } else {
          lat = -4.0150;
          lng = 119.6290;
        }
      }
    } else {
      final pLat = double.tryParse(tugas['pickup_lat']?.toString() ?? '');
      final pLng = double.tryParse(tugas['pickup_lng']?.toString() ?? '');
      if (pLat != null && pLng != null && pLat != 0.0) {
        lat = pLat;
        lng = pLng;
      }
    }

    final targetLatLng = LatLng(lat, lng);
    final targetName = isDropIn
        ? (tugas['drop_point_name'] ?? 'Drop Point Parepare').toString()
        : (tugas['nama_nasabah'] ??
                tugas['nasabah_name'] ??
                (isPengantaran ? 'Nasabah' : 'Nasabah Penjemputan'))
            .toString();
    final addressText = isDropIn
        ? _resolveDropPointAddress(tugas)
        : (isPengantaran
            ? (tugas['nasabah_address'] ?? tugas['address'] ?? 'Kota Parepare')
                .toString()
            : _resolvePickupAddress(tugas));

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Modal
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDropIn
                        ? [Colors.purple.shade700, Colors.deepPurple]
                        : (isPengantaran
                            ? [Colors.blue.shade700, Colors.blueAccent]
                            : [greenTheme, const Color(0xFF1B5E20)]),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDropIn
                            ? Icons.store_mall_directory_rounded
                            : Icons.location_on_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDropIn
                                ? 'Peta Lokasi Drop Point'
                                : (isPengantaran
                                    ? 'Peta Lokasi Pengantaran'
                                    : 'Peta Lokasi Penjemputan'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PlusJakartaSans',
                            ),
                          ),
                          Text(
                            targetName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Detail Alamat
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isDropIn ? Icons.store_rounded : Icons.place_rounded,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        addressText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Peta Interaktif FlutterMap
              Flexible(
                child: SizedBox(
                  height: 340,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: targetLatLng,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.bank_sampah',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: targetLatLng,
                            width: 60,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDropIn
                                        ? Colors.purple
                                        : Colors.redAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol Bawah
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDropIn ? Colors.purple : greenTheme,
                          side: BorderSide(
                            color: isDropIn ? Colors.purple : greenTheme,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: const Text(
                          'Buka di Google Maps',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDropIn ? Colors.purple : greenTheme,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    final String txId =
        (tugas['id_transaksi'] ?? tugas['id'])?.toString() ?? '';
    final bool isPengantaran = tugas['is_pengantaran'] == true;

    final String tipeTugas = isPengantaran
        ? 'Pengantaran Sembako'
        : (isDropIn ? 'Drop-in' : 'Jemput');

    final Color tipeColor = isPengantaran
        ? Colors.blue.shade700
        : (isDropIn ? Colors.purple : greenTheme);

    final IconData tipeIcon = isPengantaran
        ? Icons.shopping_bag_outlined
        : (isDropIn ? Icons.store : Icons.local_shipping_outlined);

    final String mainBtnLabel = isPengantaran
        ? 'Selesaikan Pengantaran'
        : (sudahMenuju
              ? 'Verifikasi & Timbang'
              : (isDropIn ? 'Terima Drop-in' : 'Menjemput'));

    final IconData mainBtnIcon = isPengantaran
        ? Icons.check_circle
        : (sudahMenuju
              ? Icons.fact_check_rounded
              : (isDropIn ? Icons.check_circle_outline : Icons.local_shipping));

    final Color mainBtnColor = isPengantaran
        ? Colors.blue.shade700
        : (sudahMenuju ? Colors.green.shade700 : greenTheme);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    statusStr == 'dikonfirmasi' || statusStr == 'siap_diantar'
                        ? (isPengantaran ? 'SIAP DIANTAR' : 'TERVERIFIKASI')
                        : statusStr.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: sudahMenuju
                          ? Colors.blue.shade800
                          : (isPengantaran
                                ? Colors.blue.shade800
                                : const Color(0xFF2E7D32)),
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

            InkWell(
              onTap: () => _showLocationMapDialog(tugas),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDropIn
                          ? Colors.purple
                          : (isPengantaran ? Colors.blue : greenTheme))
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isDropIn
                            ? Colors.purple
                            : (isPengantaran ? Colors.blue : greenTheme))
                        .withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isDropIn
                                ? Colors.purple
                                : (isPengantaran ? Colors.blue : greenTheme))
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDropIn
                            ? Icons.store_mall_directory_rounded
                            : Icons.location_on_rounded,
                        color: isDropIn
                            ? Colors.purple
                            : (isPengantaran
                                ? Colors.blueAccent
                                : Colors.redAccent),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Lacak Lokasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: (isDropIn
                                      ? Colors.purple.shade700
                                      : (isPengantaran
                                          ? Colors.blue.shade700
                                          : greenTheme)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDropIn
                                          ? Colors.purple
                                          : (isPengantaran
                                              ? Colors.blue
                                              : greenTheme))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Buka Peta',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: (isDropIn
                                        ? Colors.purple.shade700
                                        : (isPengantaran
                                            ? Colors.blue.shade700
                                            : greenTheme)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDropIn
                                ? _resolveDropPointAddress(tugas)
                                : (isPengantaran
                                    ? (tugas['nasabah_address'] ??
                                        'Alamat tujuan pengantaran')
                                    : _resolvePickupAddress(tugas)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.map_outlined,
                      color: (isDropIn
                          ? Colors.purple
                          : (isPengantaran ? Colors.blue : greenTheme)),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

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

            if (tugas['photo_evidence'] != null &&
                tugas['photo_evidence'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Foto Sampah:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tugas['photo_evidence'].toString().split(',').map((
                  filename,
                ) {
                  final url =
                      '${ApiService.baseUrl}/uploads/transactions/${filename.trim()}';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            if (isDropIn) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lokasi Drop Point (Master Data):',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tugas['drop_point_name']?.toString() ??
                          'Drop Point Pasar Lakessi',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resolveDropPointAddress(tugas),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isPengantaran) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Alamat Pengantaran Sembako:',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (tugas['nasabah_address'] ??
                              tugas['address'] ??
                              'Alamat belum diatur')
                          .toString(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: greenTheme.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: greenTheme.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: greenTheme,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Alamat Penjemputan (Tulis Nasabah):',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: greenTheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resolvePickupAddress(tugas),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            Row(
              children: [
                if (!isPengantaran) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (tugas['photo_evidence'] != null &&
                            tugas['photo_evidence'].toString().isNotEmpty) {
                          ImageViewerDialog.show(
                            context,
                            tugas['photo_evidence'].toString(),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tidak ada gambar foto sampah.'),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.image_outlined,
                        color: greenTheme,
                        size: 18,
                      ),
                      label: const Text('Lihat Gambar'),
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
                ],

                if (sudahMenuju && !isPengantaran) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final String nasabahId =
                            tugas['nasabah_id']?.toString() ?? 'nasabah123';
                        final String nasabahName =
                            tugas['nama_nasabah']?.toString() ??
                            tugas['nasabah_name']?.toString() ??
                            'Nasabah';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              peerId: nasabahId,
                              peerName: nasabahName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Chat Nasabah'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (isPengantaran) {
                        bool success = false;
                        try {
                          final err = await ApiService.instance
                              .updateWithdrawalStatus(txId, 'selesai');
                          if (err == null) {
                            success = true;
                            await DatabaseHelper.instance
                                .updateWithdrawalStatus(txId, 'selesai');
                          }
                        } catch (e) {
                          success = await DatabaseHelper.instance
                              .updateWithdrawalStatus(txId, 'selesai');
                        }
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Pengantaran berhasil diselesaikan!',
                              ),
                              backgroundColor: greenTheme,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadTasks();
                        }
                      } else if (sudahMenuju) {
                        _showSelesaikanDialog(tugas);
                      } else {
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

class _TimbangSheet extends StatefulWidget {
  final String txId;
  final String namaNasabah;
  final List<Map<String, dynamic>> wasteItems;
  final Color greenTheme;
  final Future<void> Function(
    int totalPoin,
    double totalBerat,
    List<Map<String, dynamic>> items,
  )
  onSelesai;

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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

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

            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (ctx, i) => _buildWasteRow(_items[i], green),
              ),
            ),

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
                              final itemsToSend = _items
                                  .where((e) => e['selected'] == true)
                                  .map(
                                    (e) => {
                                      'id':
                                          'ITI-${DateTime.now().microsecondsSinceEpoch}',
                                      'transaction_id': widget.txId,
                                      'waste_category_id': e['id'] ?? 0,
                                      'name': e['name'],
                                      'estimated_weight': 0.0,
                                      'actual_weight': e['berat'] ?? 0.0,
                                      'final_points':
                                          (((e['berat'] as num?)?.toDouble() ??
                                                      0.0) *
                                                  ((e['poin_per_kg'] as num?)
                                                          ?.toDouble() ??
                                                      0.0))
                                              .round(),
                                    },
                                  )
                                  .toList();
                              await widget.onSelesai(poin, berat, itemsToSend);
                              if (mounted) {
                                Navigator.pop(context);
                              }
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
    final double minWeight = (item['min_weight'] as num?)?.toDouble() ?? 1.0;
    final double berat = (item['berat'] as num?)?.toDouble() ?? minWeight;
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
            onChanged: (v) => setState(() {
              item['selected'] = v ?? false;
              if (item['selected'] == true &&
                  ((item['berat'] as num?)?.toDouble() ?? 0.0) < minWeight) {
                item['berat'] = minWeight;
              }
            }),
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
                  '$poinPerKg poin/kg  •  Min $minWeight kg',
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
                  if (berat > minWeight) {
                    item['berat'] = double.parse(
                      (berat - 0.5).toStringAsFixed(1),
                    );
                    if ((item['berat'] as double) < minWeight) {
                      item['berat'] = minWeight;
                    }
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
