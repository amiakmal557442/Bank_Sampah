import 'package:flutter/material.dart';
import 'db_helper.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  // Palet Warna Utama
  final Color oldGrassGreen = const Color(0xFF268B07);
  final Color limeGreen = const Color(0xFF32CD32);
  final Color baseBlack = const Color(0xFF000000);
  final Color baseWhite = const Color(0xFFFFFFFF);
  final Color textGrey = const Color(0xFF5F6368);
  final Color borderGrey = const Color(0xFFE0E0E0);

  String _selectedModule = 'Semua Modul';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await DatabaseHelper.instance.getAuditLogs(
      modul: _selectedModule,
      query: _searchQuery,
    );
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hitung statistik
    int totalLogs = _logs.length;
    int perubahanData = _logs.where((log) {
      final a = (log['action'] ?? '').toString().toLowerCase();
      return a.contains('mengubah') ||
          a.contains('menambahkan') ||
          a.contains('menghapus') ||
          a.contains('update') ||
          a.contains('delete');
    }).length;
    int aksesGagal = _logs.where((log) => log['status'] == 'GAGAL').length;

    // Hitung unique IP (sebagai estimasi active user)
    int uniqueUsers = _logs.map((e) => e['user_name']).toSet().length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: oldGrassGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audit Log Sistem',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: baseBlack,
                                fontFamily: 'Segoe UI',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Catatan aktivitas dan riwayat perubahan data sistem secara real-time untuk transparansi dan keamanan.',
                              style: TextStyle(
                                fontSize: 14,
                                color: textGrey,
                                fontFamily: 'Segoe UI',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: oldGrassGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mengekspor log ke CSV...'),
                              backgroundColor: Color(0xFF268B07),
                            ),
                          );
                        },
                        icon: Icon(Icons.download, color: baseWhite, size: 18),
                        label: Text(
                          'Ekspor Log (.CSV)',
                          style: TextStyle(
                            color: baseWhite,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Segoe UI',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Metric Summary Cards
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Log Ditampilkan',
                        '$totalLogs',
                        'Aktivitas terekam',
                        Icons.list_alt,
                        oldGrassGreen,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Perubahan Data',
                        '$perubahanData',
                        'Update, Add & Delete',
                        Icons.edit_note,
                        Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Percobaan Akses Gagal',
                        '$aksesGagal',
                        'Memerlukan Perhatian',
                        Icons.warning_amber_rounded,
                        Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Pengguna Terdeteksi',
                        '$uniqueUsers User',
                        'Dalam daftar',
                        Icons.verified_user_outlined,
                        Colors.blue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Filter & Search Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: baseWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderGrey),
                    ),
                    child: Row(
                      children: [
                        // Search Box
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              _searchQuery = val;
                              _loadLogs();
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Cari berdasarkan nama user, role, atau aktivitas...',
                              hintStyle: TextStyle(
                                fontFamily: 'Segoe UI',
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(Icons.search, color: textGrey),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderGrey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filter Modul
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedModule,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderGrey),
                              ),
                            ),
                            items:
                                [
                                      'Semua Modul',
                                      'Authentication',
                                      'Konfigurasi Sistem',
                                      'Manajemen Transaksi',
                                      'Master Data',
                                      'Operasional',
                                    ]
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          m,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Segoe UI',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedModule = val);
                                _loadLogs();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Date Filter Button (Static for now)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                          icon: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: textGrey,
                          ),
                          label: const Text(
                            'Hari Ini (04 Agu 2026)',
                            style: TextStyle(fontFamily: 'Segoe UI'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tabel Audit Log
                  Container(
                    decoration: BoxDecoration(
                      color: baseWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.8),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(1.8),
                            3: FlexColumnWidth(3.5),
                            4: FlexColumnWidth(1.5),
                            5: FlexColumnWidth(1.2),
                          },
                          children: [
                            // Header Table
                            TableRow(
                              decoration: BoxDecoration(
                                color: limeGreen.withOpacity(0.08),
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Waktu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Segoe UI',
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Pengguna',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Segoe UI',
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Modul',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Segoe UI',
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Aktivitas & Detail',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Segoe UI',
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'IP Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Segoe UI',
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Segoe UI',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Rows
                            ..._logs.map((log) {
                              final status =
                                  log['status']?.toString() ?? 'UNKNOWN';
                              return _buildLogRow(
                                time: log['time']?.toString() ?? '-',
                                userName: log['user_name']?.toString() ?? '-',
                                role: log['role']?.toString() ?? '-',
                                module: log['module']?.toString() ?? '-',
                                action: log['action']?.toString() ?? '-',
                                ip: log['ip_address']?.toString() ?? '-',
                                status: status,
                                statusColor: status == 'GAGAL'
                                    ? Colors.red
                                    : oldGrassGreen,
                              );
                            }),
                          ],
                        ),
                        if (_logs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'Tidak ada log yang ditemukan.',
                                style: TextStyle(
                                  color: textGrey,
                                  fontFamily: 'Segoe UI',
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

  // Widget Stat Card
  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: baseWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderGrey),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: textGrey,
                      fontFamily: 'Segoe UI',
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Segoe UI',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: textGrey,
                fontFamily: 'Segoe UI',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Baris Tabel Log Aktivitas
  TableRow _buildLogRow({
    required String time,
    required String userName,
    required String role,
    required String module,
    required String action,
    required String ip,
    required String status,
    required Color statusColor,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderGrey, width: 0.5)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Segoe UI',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Segoe UI',
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  color: textGrey,
                  fontFamily: 'Segoe UI',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              module,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Segoe UI',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            action,
            style: const TextStyle(fontSize: 13, fontFamily: 'Segoe UI'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            ip,
            style: TextStyle(
              fontSize: 12,
              color: textGrey,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Segoe UI',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
