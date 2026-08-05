import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'map_location_screen.dart';

class HalamanTugas extends StatefulWidget {
  const HalamanTugas({Key? key}) : super(key: key);

  @override
  State<HalamanTugas> createState() => _HalamanTugasState();
}

class _HalamanTugasState extends State<HalamanTugas> {
  List<Map<String, dynamic>> _daftarTugas = [];
  bool _isLoading = true;

  // Palet warna menyesuaikan dengan tema hijau
  final Color greenTheme = const Color(0xFF2E7D32); // Hijau solid

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    final tasks = await DatabaseHelper.instance.getPendingPickupTasks();

    if (mounted) {
      setState(() {
        _daftarTugas = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String currentStatus) async {
    String newStatus = 'menuju_lokasi';
    if (currentStatus == 'menuju_lokasi') {
      newStatus = 'selesai';
    }

    final success = await DatabaseHelper.instance.updateTransactionStatus(
      id,
      newStatus,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status tugas diperbarui!'),
          backgroundColor: greenTheme,
        ),
      );
      _loadTasks(); // Refresh daftar tugas
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status tugas.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Latar belakang abu-abu terang
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarTugas.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _daftarTugas.length,
              itemBuilder: (context, index) {
                final tugas = _daftarTugas[index];
                return _buildTaskCard(tugas);
              },
            ),
    );
  }

  // Widget untuk menampilkan kartu tugas (Task Card)
  Widget _buildTaskCard(Map<String, dynamic> tugas) {
    final String statusStr = tugas['status']?.toString() ?? 'menunggu';
    final bool isMenuju = statusStr == 'menuju_lokasi';
    final String buttonLabel = isMenuju ? 'Selesaikan' : 'Jemput';
    final IconData buttonIcon = isMenuju
        ? Icons.check_circle
        : Icons.local_shipping;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Header Card (ID Transaksi & Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tugas['id_transaksi']?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMenuju
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusStr.toUpperCase(),
                    style: TextStyle(
                      color: isMenuju
                          ? Colors.blue.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 1),
            ),

            // Info Nasabah
            Row(
              children: [
                Icon(Icons.person, color: greenTheme, size: 22),
                const SizedBox(width: 10),
                Text(
                  tugas['nama_nasabah']?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info Lokasi Nasabah
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tugas['alamat']} (${tugas['jarak']})',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info Jenis & Estimasi Sampah
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.recycling, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tugas['jenis_sampah']} \nEstimasi: ${tugas['estimasi_berat']}',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol Aksi Lapangan
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _updateStatus(
                        tugas['id_transaksi']?.toString() ?? '',
                        statusStr,
                      );
                    },
                    icon: Icon(buttonIcon, color: Colors.white, size: 18),
                    label: Text(buttonLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMenuju
                          ? Colors.blue.shade600
                          : greenTheme,
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

  // Tampilan ketika belum ada tugas yang masuk
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
            'Hore! Tidak ada tugas tersisa.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tunggu notifikasi penjemputan baru.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
