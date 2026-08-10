import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'api_service.dart';

class OperasionalLapanganScreen extends StatefulWidget {
  const OperasionalLapanganScreen({super.key});

  @override
  State<OperasionalLapanganScreen> createState() =>
      _OperasionalLapanganScreenState();
}

class _OperasionalLapanganScreenState extends State<OperasionalLapanganScreen> {
  final Color oldGrassGreen = const Color(0xFF268B07);
  final Color limeGreen = const Color(0xFF32CD32);
  final Color baseBlack = const Color(0xFF000000);
  final Color baseWhite = const Color(0xFFFFFFFF);
  final Color textGrey = const Color(0xFF5F6368);
  final Color borderGrey = const Color(0xFFE0E0E0);

  Color get bgLightGreen => limeGreen.withValues(alpha: 0.1);

  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _dropPoints = [];
  List<Map<String, dynamic>> _workerStatus = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    final data = await ApiService.instance.getOperasionalData();
    final summary = Map<String, dynamic>.from(data['summary'] ?? {});
    final dropPoints = List<Map<String, dynamic>>.from(data['dropPoints'] ?? []);
    final workerStatus = List<Map<String, dynamic>>.from(data['workerStatus'] ?? []);

    if (mounted) {
      setState(() {
        _summary = summary;
        _dropPoints = dropPoints;
        _workerStatus = workerStatus;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operasional Lapangan & Monitoring',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: baseBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau aktivitas petugas, rute penjemputan, dan kapasitas drop point secara real-time.',
                    style: TextStyle(fontSize: 14, color: textGrey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: oldGrassGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _fetchData,
                icon: Icon(Icons.refresh, color: baseWhite, size: 18),
                label: Text(
                  'Segarkan Data',
                  style: TextStyle(
                    color: baseWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ringkasan Operasional (Top Cards)
          Row(
            children: [
              _buildSummaryCard(
                'Petugas Aktif',
                '${_summary['petugasAktif']} / ${_summary['totalPetugas']}',
                '${_summary['petugasIstirahat']} Sedang Istirahat',
                Icons.engineering,
                oldGrassGreen,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Drop Point Kritis',
                '${_summary['dropPointKritis']} Lokasi',
                'Perlu Pengangkutan',
                Icons.warning_amber_rounded,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Tugas Penjemputan',
                '${_summary['tugasSelesai']} Selesai',
                '${_summary['tugasAntrean']} Dalam Antrean',
                Icons.local_shipping,
                limeGreen,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section Utama: Peta Live (Kiri) & Kapasitas Drop Point (Kanan)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Map View (Google Maps API Placeholder)
              Expanded(
                flex: 3,
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: limeGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: limeGreen.withValues(alpha: 0.3)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: oldGrassGreen,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Peta Interaktif Lapangan (Google Maps API)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: oldGrassGreen,
                              ),
                            ),
                            Text(
                              'Menampilkan ${_summary['petugasAktif']} Petugas Aktif & Rute Optimasi',
                              style: TextStyle(fontSize: 12, color: textGrey),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: baseWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: baseBlack.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Live Tracking',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // 2. Pemantauan Kapasitas Drop Point (FR-AD-08)
              Expanded(
                flex: 2,
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: baseWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kapasitas Drop Point',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: baseBlack,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _dropPoints.isEmpty
                            ? Center(
                                child: Text(
                                  "Tidak ada data Drop Point",
                                  style: TextStyle(color: textGrey),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _dropPoints.length,
                                separatorBuilder: (ctx, i) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (ctx, index) {
                                  final dp = _dropPoints[index];
                                  return _buildDropPointBar(
                                    dp['name'],
                                    (dp['capacityPercent'] as int) / 100.0,
                                    '${dp['capacityPercent']}%',
                                    dp['isCritical'] as bool,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section Tabel: Daftar Penugasan & Status Petugas (FR-AD-07)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: baseWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Penugasan Petugas Lapangan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: baseBlack,
                  ),
                ),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: bgLightGreen),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Petugas / Armada',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Lokasi / Rute',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Tugas Saat Ini',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Aksi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ..._workerStatus.map((worker) {
                      Color statusColor;
                      switch (worker['status'].toString().toLowerCase()) {
                        case 'menuju lokasi':
                          statusColor = Colors.orange;
                          break;
                        case 'tiba di lokasi':
                          statusColor = limeGreen;
                          break;
                        case 'proses muat':
                          statusColor = oldGrassGreen;
                          break;
                        default:
                          statusColor = textGrey;
                      }
                      return _buildTableRow(
                        worker['petugas_name'],
                        worker['vehicle'],
                        worker['location'],
                        worker['task'],
                        worker['status'],
                        statusColor,
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: baseWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: textGrey)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropPointBar(
    String name,
    double value,
    String percentage,
    bool isCritical,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              percentage,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCritical ? Colors.redAccent : oldGrassGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[200],
          color: isCritical ? Colors.redAccent : oldGrassGreen,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  TableRow _buildTableRow(
    String name,
    String vehicle,
    String location,
    String task,
    String status,
    Color statusColor,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(vehicle, style: TextStyle(fontSize: 11, color: textGrey)),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(10), child: Text(location)),
        Padding(padding: const EdgeInsets.all(10), child: Text(task)),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: IconButton(
            icon: const Icon(Icons.near_me_outlined, size: 18),
            onPressed: () {},
            tooltip: 'Lacak / Reassign',
          ),
        ),
      ],
    );
  }
}
