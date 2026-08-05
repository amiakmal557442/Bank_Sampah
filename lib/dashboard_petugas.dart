import 'package:flutter/material.dart';
import 'session_service.dart';
import 'profil_petugas.dart';
import 'riwayatpetugas.dart';
import 'halaman_tugas.dart';

// ============================================================
// Model Data Dummy untuk Antrean Penjemputan
// ============================================================
class PickupTask {
  final String wasteId;
  final String customerName;
  final String address;
  final String time;
  final List<String> wasteTypes;
  final double estWeightKg;
  String status; // 'menuju', 'tiba', 'selesai'

  PickupTask({
    required this.wasteId,
    required this.customerName,
    required this.address,
    required this.time,
    required this.wasteTypes,
    required this.estWeightKg,
    this.status = 'menuju',
  });
}

// ============================================================
// Model Data Dummy untuk Drop Point
// ============================================================
class WorkerDropPoint {
  final String id;
  final String name;
  final String address;
  String capacityStatus; // 'aman', 'penuh', 'kritis'

  WorkerDropPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.capacityStatus,
  });
}

// ============================================================
// Model Kategori Sampah (untuk Timbang Manual)
// ============================================================
class ManualWasteItem {
  final String name;
  final int pointsPerKg;
  final IconData icon;
  bool isSelected;
  double weightKg;

  ManualWasteItem({
    required this.name,
    required this.pointsPerKg,
    required this.icon,
    this.isSelected = false,
    this.weightKg = 1.0,
  });

  int get totalPoints => (pointsPerKg * weightKg).round();
}

// ============================================================
// WorkerDashboardScreen — Main Widget
// ============================================================
class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  // Palet Warna
  static const Color limeGreen = Color(0xFF32CD32);
  static const Color oldGrassGreen = Color(0xFF268B07);
  static const Color baseBlack = Color(0xFF000000);
  static const Color baseWhite = Color(0xFFFFFFFF);
  static const Color bgGrey = Color(0xFFF5F6FA);

  // State
  bool isOnline = true;
  int _bottomNavIndex = 0;

  // Ambil info petugas dari sesi
  String get _petugasName => SessionService.fullName;

  String get _armada {
    final addr = SessionService.currentUser?['address'] as String? ?? '';
    final match = RegExp(r'Armada:\s*([^,]+)').firstMatch(addr);
    return match?.group(1)?.trim() ?? 'Petugas Lapangan';
  }

  // Data Tugas Aktif
  final PickupTask _currentTask = PickupTask(
    wasteId: 'WJ-5T2N',
    customerName: 'Siti Aminah',
    address: 'Jl. Sudirman No. 45, Jakarta Selatan',
    time: '13:00',
    wasteTypes: ['Plastik', 'Kertas'],
    estWeightKg: 5.0,
    status: 'menuju',
  );

  // Data Antrean
  final List<PickupTask> _queue = [
    PickupTask(
      wasteId: 'WJ-7R3K',
      customerName: 'Budi Santoso',
      address: 'Kebayoran Baru (~2.5 km)',
      time: '14:00',
      wasteTypes: ['Logam', 'Kardus'],
      estWeightKg: 3.2,
    ),
    PickupTask(
      wasteId: 'WJ-9A1X',
      customerName: 'Rina Marlina',
      address: 'Cipete Raya (~4.1 km)',
      time: '15:30',
      wasteTypes: ['Plastik', 'Kaca'],
      estWeightKg: 2.8,
    ),
  ];

  // Data Drop Point
  final List<WorkerDropPoint> _dropPoints = [
    WorkerDropPoint(
      id: 'dp1',
      name: 'Drop Point Margonda',
      address: 'Jl. Margonda Raya No. 12, Depok',
      capacityStatus: 'aman',
    ),
    WorkerDropPoint(
      id: 'dp2',
      name: 'Waste Station Beji',
      address: 'Jl. Kartini No. 5, Beji, Depok',
      capacityStatus: 'aman',
    ),
    WorkerDropPoint(
      id: 'dp3',
      name: 'Bank Sampah Pancoran Mas',
      address: 'Jl. Pitara Raya No. 88, Depok',
      capacityStatus: 'aman',
    ),
    WorkerDropPoint(
      id: 'dp4',
      name: 'Drop Point 01 - Pusat Kota',
      address: 'Jl. MH Thamrin No. 1, Jakarta Pusat',
      capacityStatus: 'aman',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: (_bottomNavIndex == 2 || _bottomNavIndex == 3)
          ? null
          : _buildAppBar(),
      body: _bottomNavIndex == 0
          ? _buildBerandaBody()
          : _bottomNavIndex == 1
          ? const HalamanTugas()
          : _bottomNavIndex == 2
          ? const PetugasRiwayatScreen()
          : _bottomNavIndex == 3
          ? const PetugasProfilScreen()
          : _buildComingSoonBody(_bottomNavIndex),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: oldGrassGreen,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: GestureDetector(
        onTap: () => setState(() => _bottomNavIndex = 3),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: baseWhite,
              radius: 18,
              child: Icon(Icons.person_rounded, color: oldGrassGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $_petugasName',
                    style: const TextStyle(
                      fontSize: 14,
                      color: baseWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _armada,
                    style: TextStyle(
                      fontSize: 11,
                      color: baseWhite.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOnline ? 'Aktif' : 'Istirahat',
                style: const TextStyle(
                  fontSize: 12,
                  color: baseWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: isOnline,
                activeThumbColor: limeGreen,
                activeTrackColor: limeGreen.withValues(alpha: 0.4),
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[600],
                onChanged: (val) {
                  setState(() => isOnline = val);
                  _showStatusChangedSnackBar(val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Bottom Navigation
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: oldGrassGreen,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (i) => setState(() => _bottomNavIndex = i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          activeIcon: Icon(Icons.list_alt_rounded),
          label: 'Tugas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history_rounded),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Beranda Body
  // ─────────────────────────────────────────────
  Widget _buildBerandaBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status Aktif / Istirahat
          _buildStatusBanner(),

          // 1. Menu Aksi Cepat
          _buildQuickActionBar(),

          const SizedBox(height: 16),

          // 2. Tugas Saat Ini
          _buildSectionHeader('TUGAS SAAT INI'),
          const SizedBox(height: 8),
          _buildCurrentTaskCard(),

          const SizedBox(height: 20),

          // 3. Antrean Penjemputan
          _buildSectionHeader(
            'ANTREAN PENJEMPUTAN',
            trailing: Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: oldGrassGreen,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final task in _queue) _buildQueueTaskCard(task),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Coming Soon placeholder untuk tab lain
  // ─────────────────────────────────────────────
  Widget _buildComingSoonBody(int index) {
    const labels = ['', 'Tugas', 'Riwayat', 'Profil'];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Halaman ${labels[index]}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur ini sedang dalam pengembangan.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Status Banner
  // ─────────────────────────────────────────────
  Widget _buildStatusBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? oldGrassGreen : Colors.grey[700],
        gradient: isOnline
            ? const LinearGradient(
                colors: [oldGrassGreen, Color(0xFF4CAF50)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnline ? limeGreen : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: limeGreen.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isOnline
                ? 'Anda sedang aktif bertugas hari ini'
                : 'Status istirahat — tugas tidak akan diterima',
            style: const TextStyle(
              color: baseWhite,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Quick Action Bar
  // ─────────────────────────────────────────────
  Widget _buildQuickActionBar() {
    return Container(
      color: baseWhite,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(
            Icons.qr_code_scanner_rounded,
            'Scan\nWaste-ID',
            limeGreen,
            onTap: _showScanWasteIdModal,
          ),
          _buildQuickAction(
            Icons.scale_rounded,
            'Timbang\nManual',
            Colors.orange,
            onTap: _showTimbangManualSheet,
          ),
          _buildQuickAction(
            Icons.storefront_rounded,
            'Update\nDrop Point',
            Colors.blue,
            onTap: _showUpdateDropPointSheet,
          ),
          _buildQuickAction(
            Icons.report_problem_rounded,
            'Lapor\nKendala',
            Colors.redAccent,
            onTap: _showLaporKendalaSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: baseBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section Header helper
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Kartu Tugas Aktif
  // ─────────────────────────────────────────────
  Widget _buildCurrentTaskCard() {
    final task = _currentTask;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: limeGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: limeGreen.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: limeGreen.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge status + ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: limeGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '🚛  Menuju Lokasi',
                  style: TextStyle(
                    color: baseWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                task.wasteId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: oldGrassGreen,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nama nasabah
          Text(
            task.customerName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: baseBlack,
            ),
          ),
          const SizedBox(height: 6),

          // Alamat
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.address,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Estimasi berat
          Row(
            children: [
              Icon(Icons.scale_rounded, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Estimasi: ${task.estWeightKg} Kg (${task.wasteTypes.join(", ")})',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tombol aksi
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: oldGrassGreen,
                    side: const BorderSide(color: oldGrassGreen),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _launchMaps,
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text('Arahkan', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oldGrassGreen,
                    foregroundColor: baseWhite,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _showTibaDialogForCurrentTask,
                  child: const Text(
                    'Tiba di Lokasi',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Kartu Antrean
  // ─────────────────────────────────────────────
  Widget _buildQueueTaskCard(PickupTask task) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baseWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: baseBlack.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: Colors.grey[500],
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: baseBlack,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          task.time,
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
                Text(
                  task.address,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final t in task.wasteTypes) _buildMiniChip(t),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: limeGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: limeGreen.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: oldGrassGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  FR-PL-07: SCAN WASTE-ID
  // ═══════════════════════════════════════════════════════════
  void _showScanWasteIdModal() {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: baseWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icon & Judul
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: limeGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: oldGrassGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan Waste-ID',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan ID Waste (Waste-ID) dari transaksi nasabah untuk konfirmasi penjemputan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Simulasi Viewfinder QR
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _qrCorner(true, true),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _qrCorner(true, false),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: _qrCorner(false, true),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _qrCorner(false, false),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 52,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Arahkan ke QR Code',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'atau input manual',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 12),

                // Input Manual
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Contoh: WJ-5T2N',
                    labelText: 'Waste-ID',
                    prefixIcon: const Icon(
                      Icons.tag_rounded,
                      color: oldGrassGreen,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: limeGreen, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Konfirmasi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: oldGrassGreen,
                      foregroundColor: baseWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final id = controller.text.trim().toUpperCase();
                      Navigator.pop(ctx);
                      if (id.isEmpty) return;
                      _showWasteIdResult(id);
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Konfirmasi ID',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qrCorner(bool top, bool left) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _QrCornerPainter(top: top, left: left),
      ),
    );
  }

  void _showWasteIdResult(String id) {
    final isMatch = id == _currentTask.wasteId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: isMatch
                  ? limeGreen.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.1),
              child: Icon(
                isMatch ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isMatch ? oldGrassGreen : Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMatch ? 'Waste-ID Cocok!' : 'Waste-ID Tidak Ditemukan',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isMatch
                  ? 'ID $id terverifikasi untuk nasabah ${_currentTask.customerName}.'
                  : 'ID "$id" tidak cocok dengan tugas aktif. Periksa kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: oldGrassGreen)),
          ),
          if (isMatch)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: oldGrassGreen,
                foregroundColor: baseWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showTimbangManualSheet(wasteId: id);
              },
              child: const Text('Lanjut Timbang'),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  FR-PL-05: TIMBANG MANUAL
  // ═══════════════════════════════════════════════════════════
  void _showTimbangManualSheet({String? wasteId}) {
    final items = [
      ManualWasteItem(
        name: 'Plastik',
        pointsPerKg: 100,
        icon: Icons.local_drink_outlined,
        isSelected: true,
        weightKg: 1.0,
      ),
      ManualWasteItem(
        name: 'Kertas',
        pointsPerKg: 80,
        icon: Icons.description_outlined,
      ),
      ManualWasteItem(
        name: 'Kardus',
        pointsPerKg: 70,
        icon: Icons.inventory_2_outlined,
      ),
      ManualWasteItem(
        name: 'Logam',
        pointsPerKg: 250,
        icon: Icons.build_outlined,
      ),
      ManualWasteItem(
        name: 'Kaca',
        pointsPerKg: 60,
        icon: Icons.wine_bar_outlined,
      ),
      ManualWasteItem(
        name: 'Minyak Jelantah',
        pointsPerKg: 150,
        icon: Icons.opacity_outlined,
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _TimbangManualSheet(
          items: items,
          wasteId: wasteId ?? _currentTask.wasteId,
          customerName: _currentTask.customerName,
          oldGrassGreen: oldGrassGreen,
          limeGreen: limeGreen,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  FR-PL-09: UPDATE DROP POINT
  // ═══════════════════════════════════════════════════════════
  void _showUpdateDropPointSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _UpdateDropPointSheet(
          dropPoints: _dropPoints,
          oldGrassGreen: oldGrassGreen,
          limeGreen: limeGreen,
          onUpdate: (dp, newStatus) {
            setState(() {
              dp.capacityStatus = newStatus;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Status "${dp.name}" diperbarui menjadi ${_statusLabel(newStatus)}.',
                ),
                backgroundColor: oldGrassGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'aman':
        return 'Aman';
      case 'penuh':
        return 'Penuh';
      case 'kritis':
        return 'Kritis';
      default:
        return s;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  FR-PL-14: LAPOR KENDALA
  // ═══════════════════════════════════════════════════════════
  void _showLaporKendalaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _LaporKendalaSheet(
          oldGrassGreen: oldGrassGreen,
          onSubmit: (jenis, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Laporan "$jenis" berhasil dikirim ke admin.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  FR-PL-03: Tiba di Lokasi
  // ═══════════════════════════════════════════════════════════
  void _showTibaDialogForCurrentTask() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Tiba',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda sudah tiba di lokasi nasabah ${_currentTask.customerName}?\n\nStatus tugas akan diperbarui.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: oldGrassGreen,
              foregroundColor: baseWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentTask.status = 'tiba');
              _showTimbangManualSheet();
            },
            child: const Text('Ya, Tiba'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FR-PL-02: Navigasi Maps (simulasi)
  // ─────────────────────────────────────────────
  void _launchMaps() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka Google Maps menuju ${_currentTask.address}...'),
        backgroundColor: oldGrassGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showStatusChangedSnackBar(bool online) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          online
              ? 'Status Anda sekarang: Aktif Bertugas'
              : 'Status Anda sekarang: Istirahat',
        ),
        backgroundColor: online ? oldGrassGreen : Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Custom Painter untuk sudut QR viewfinder
// ════════════════════════════════════════════════════════════
class _QrCornerPainter extends CustomPainter {
  final bool top;
  final bool left;

  _QrCornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF32CD32)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════
//  FR-PL-05: Timbang Manual — StatefulWidget Sheet
// ════════════════════════════════════════════════════════════
class _TimbangManualSheet extends StatefulWidget {
  final List<ManualWasteItem> items;
  final String wasteId;
  final String customerName;
  final Color oldGrassGreen;
  final Color limeGreen;

  const _TimbangManualSheet({
    required this.items,
    required this.wasteId,
    required this.customerName,
    required this.oldGrassGreen,
    required this.limeGreen,
  });

  @override
  State<_TimbangManualSheet> createState() => _TimbangManualSheetState();
}

class _TimbangManualSheetState extends State<_TimbangManualSheet> {
  late List<ManualWasteItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  double get _totalWeight =>
      _items.where((e) => e.isSelected).fold(0.0, (s, e) => s + e.weightKg);
  int get _totalPoints =>
      _items.where((e) => e.isSelected).fold(0, (s, e) => s + e.totalPoints);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
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
                          color: Colors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.scale_rounded,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            '${widget.wasteId} · ${widget.customerName}',
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

            // Daftar sampah (scrollable)
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (ctx, i) => _buildWasteRow(_items[i]),
              ),
            ),

            // Total & Kirim
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                      color: widget.limeGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.limeGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Berat',
                          '${_totalWeight.toStringAsFixed(1)} kg',
                          Icons.scale_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: widget.limeGreen.withValues(alpha: 0.3),
                        ),
                        _buildSummaryItem(
                          'Total Poin',
                          '$_totalPoints poin',
                          Icons.stars_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.oldGrassGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _totalWeight > 0 ? _konfirmasiTimbang : null,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'Konfirmasi Timbangan',
                        style: TextStyle(
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

  Widget _buildWasteRow(ManualWasteItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isSelected
            ? widget.limeGreen.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isSelected
              ? widget.limeGreen.withValues(alpha: 0.4)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isSelected,
            activeColor: widget.oldGrassGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (v) => setState(() => item.isSelected = v ?? false),
          ),
          Icon(
            item.icon,
            color: item.isSelected ? widget.oldGrassGreen : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: item.isSelected ? Colors.black87 : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${item.pointsPerKg} poin/kg',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (item.isSelected) ...[
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
                  if (item.weightKg > 0.5) {
                    item.weightKg = double.parse(
                      (item.weightKg - 0.5).toStringAsFixed(1),
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
                item.weightKg.toStringAsFixed(1),
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
              icon: Icon(Icons.add_circle_rounded, color: widget.oldGrassGreen),
              onPressed: () {
                setState(() {
                  item.weightKg = double.parse(
                    (item.weightKg + 0.5).toStringAsFixed(1),
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

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: widget.oldGrassGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  void _konfirmasiTimbang() {
    final totalWeight = _totalWeight;
    final totalPoints = _totalPoints;
    final customerName = widget.customerName;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: widget.limeGreen.withValues(alpha: 0.15),
              child: Icon(
                Icons.check_circle_rounded,
                color: widget.oldGrassGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Timbangan Dikonfirmasi!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Total ${totalWeight.toStringAsFixed(1)} kg → $totalPoints poin telah dicatat untuk nasabah $customerName.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.oldGrassGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FR-PL-09: Update Drop Point — StatefulWidget Sheet
// ════════════════════════════════════════════════════════════
class _UpdateDropPointSheet extends StatefulWidget {
  final List<WorkerDropPoint> dropPoints;
  final Color oldGrassGreen;
  final Color limeGreen;
  final void Function(WorkerDropPoint dp, String newStatus) onUpdate;

  const _UpdateDropPointSheet({
    required this.dropPoints,
    required this.oldGrassGreen,
    required this.limeGreen,
    required this.onUpdate,
  });

  @override
  State<_UpdateDropPointSheet> createState() => _UpdateDropPointSheetState();
}

class _UpdateDropPointSheetState extends State<_UpdateDropPointSheet> {
  WorkerDropPoint? _selected;
  String _selectedStatus = 'aman';

  final _statusOptions = const [
    {
      'value': 'aman',
      'label': 'Aman',
      'color': Color(0xFF268B07),
      'icon': Icons.check_circle_rounded,
    },
    {
      'value': 'penuh',
      'label': 'Penuh',
      'color': Colors.orange,
      'icon': Icons.warning_rounded,
    },
    {
      'value': 'kritis',
      'label': 'Kritis',
      'color': Colors.redAccent,
      'icon': Icons.error_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            margin: const EdgeInsets.only(top: 14, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Update Status Drop Point',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih drop point yang ingin diperbarui kapasitasnya:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List Drop Point
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.dropPoints.length,
              itemBuilder: (ctx, i) {
                final dp = widget.dropPoints[i];
                final isSelected = _selected?.id == dp.id;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selected = dp;
                    _selectedStatus = dp.capacityStatus;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.limeGreen.withValues(alpha: 0.07)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? widget.limeGreen
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: isSelected
                              ? widget.oldGrassGreen
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dp.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                dp.address,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(dp.capacityStatus),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_rounded,
                            color: widget.oldGrassGreen,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Pilih Status baru
          if (_selected != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubah status "${_selected!.name}" menjadi:',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final opt in _statusOptions)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _selectedStatus = opt['value'] as String,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedStatus == opt['value']
                                      ? (opt['color'] as Color).withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedStatus == opt['value']
                                        ? opt['color'] as Color
                                        : Colors.grey.shade200,
                                    width: _selectedStatus == opt['value']
                                        ? 1.5
                                        : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      opt['icon'] as IconData,
                                      color: _selectedStatus == opt['value']
                                          ? opt['color'] as Color
                                          : Colors.grey,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      opt['label'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            _selectedStatus == opt['value']
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _selectedStatus == opt['value']
                                            ? opt['color'] as Color
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Tombol Simpan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected != null
                      ? widget.oldGrassGreen
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _selected == null
                    ? null
                    : () {
                        widget.onUpdate(_selected!, _selectedStatus);
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'penuh':
        color = Colors.orange;
        label = 'Penuh';
      case 'kritis':
        color = Colors.redAccent;
        label = 'Kritis';
      default:
        color = const Color(0xFF268B07);
        label = 'Aman';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FR-PL-14: Lapor Kendala — StatefulWidget Sheet
// ════════════════════════════════════════════════════════════
class _LaporKendalaSheet extends StatefulWidget {
  final Color oldGrassGreen;
  final void Function(String jenis, String deskripsi) onSubmit;

  const _LaporKendalaSheet({
    required this.oldGrassGreen,
    required this.onSubmit,
  });

  @override
  State<_LaporKendalaSheet> createState() => _LaporKendalaSheetState();
}

class _LaporKendalaSheetState extends State<_LaporKendalaSheet> {
  final _descController = TextEditingController();
  String? _selectedJenis;

  final List<Map<String, dynamic>> _jenisKendala = const [
    {'label': 'Nasabah tidak ada di lokasi', 'icon': Icons.person_off_rounded},
    {'label': 'Alamat tidak ditemukan', 'icon': Icons.location_off_rounded},
    {'label': 'Kendaraan bermasalah', 'icon': Icons.car_crash_rounded},
    {'label': 'Sampah terlalu banyak/berat', 'icon': Icons.scale_outlined},
    {'label': 'Gangguan keamanan', 'icon': Icons.security_rounded},
    {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              margin: const EdgeInsets.only(top: 14, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.report_problem_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lapor Kendala',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Laporan akan diteruskan ke admin',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih jenis kendala:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in _jenisKendala)
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectedJenis = k['label'] as String,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedJenis == k['label']
                                    ? Colors.redAccent.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedJenis == k['label']
                                      ? Colors.redAccent
                                      : Colors.grey.shade300,
                                  width: _selectedJenis == k['label'] ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    k['icon'] as IconData,
                                    size: 16,
                                    color: _selectedJenis == k['label']
                                        ? Colors.redAccent
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    k['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _selectedJenis == k['label']
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _selectedJenis == k['label']
                                          ? Colors.redAccent
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Deskripsi tambahan (opsional):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan kendala yang Anda alami...',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedJenis != null
                              ? Colors.redAccent
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _selectedJenis == null
                            ? null
                            : () {
                                widget.onSubmit(
                                  _selectedJenis!,
                                  _descController.text,
                                );
                                Navigator.pop(context);
                              },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          'Kirim Laporan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
