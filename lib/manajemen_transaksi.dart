import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'api_service.dart';

// ============================================================================
// Halaman Manajemen Transaksi — Admin Dashboard (Desktop/Web)
// Berdasarkan SRS 3.3.2 Manajemen Transaksi:
//   FR-AD-04 — Approval/verifikasi transaksi setor sampah dari pengguna
//   FR-AD-05 — Kelola penarikan saldo/konversi poin: approval, riwayat,
//              dan deteksi anomali
//   FR-AD-06 — Kelola penjualan sampah ke mitra pengolah/pengepul/industri
//              daur ulang (modul B2B)
//
// RBAC: halaman ini bisa diakses Admin DAN Staf Kantor (berbeda dengan
// Master Data yang admin-only) — sesuai peran Staf Kantor di SRS 2.2:
// "Verifikasi transaksi, kelola penjualan sampah ke pengepul/industri".
// ============================================================================

const Color primaryGreen = Color(0xFF268B07);
const Color limeGreen = Color(0xFF32CD32);
const Color pageBackground = Color(0xFFF5F6F8);
const Color darkText = Color(0xFF0F172A);
const Color subtleText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);
const Color borderColor = Color(0xFFE2E8F0);
const Color secondaryDarkText = Color(0xFF334155);
const Color warningAmber = Color(0xFFB38600);
const Color warningBg = Color(0xFFFFF8E1);

// --------------------------------------------------------------------------
// MODELS
// --------------------------------------------------------------------------

enum SetorStatus { menunggu, terverifikasi, ditolak }

class SetorTransaksiModel {
  final String userName;
  final String jenis; // Drop-in / Jemput
  final String kategori;
  final double berat;
  final int estimasiPoin;
  final String waktu;
  SetorStatus status;

  SetorTransaksiModel({
    required this.userName,
    required this.jenis,
    required this.kategori,
    required this.berat,
    required this.estimasiPoin,
    required this.waktu,
    required this.status,
  });
}

enum PenarikanStatus { menunggu, diproses, selesai, ditolak }

class PenarikanModel {
  final String userName;
  final String tujuan; // DANA, GoPay, Bank, dst
  final int poin;
  final double nominal;
  final String waktu;
  PenarikanStatus status;
  final bool isAnomali;
  final String? anomaliReason;

  PenarikanModel({
    required this.userName,
    required this.tujuan,
    required this.poin,
    required this.nominal,
    required this.waktu,
    required this.status,
    this.isAnomali = false,
    this.anomaliReason,
  });
}

enum B2BStatus { negosiasi, disepakati, terkirim, selesai }

class B2BDealModel {
  final String mitraName;
  final String kategori;
  final double totalBerat;
  final double hargaPerKg;
  final String tanggal;
  B2BStatus status;

  B2BDealModel({
    required this.mitraName,
    required this.kategori,
    required this.totalBerat,
    required this.hargaPerKg,
    required this.tanggal,
    required this.status,
  });

  double get totalNilai => totalBerat * hargaPerKg;
}

// Sample data
final List<SetorTransaksiModel> sampleSetor = [
  SetorTransaksiModel(
    userName: 'Budi Santoso',
    jenis: 'Jemput',
    kategori: 'Plastik, Logam',
    berat: 2.8,
    estimasiPoin: 400,
    waktu: '10.02',
    status: SetorStatus.menunggu,
  ),
  SetorTransaksiModel(
    userName: 'Rina Wulandari',
    jenis: 'Drop-in',
    kategori: 'Plastik',
    berat: 1.5,
    estimasiPoin: 150,
    waktu: '09.40',
    status: SetorStatus.menunggu,
  ),
  SetorTransaksiModel(
    userName: 'Dewi Lestari',
    jenis: 'Drop-in',
    kategori: 'Kardus, Kertas',
    berat: 3.2,
    estimasiPoin: 240,
    waktu: '08.55',
    status: SetorStatus.terverifikasi,
  ),
];

final List<PenarikanModel> samplePenarikan = [
  PenarikanModel(
    userName: 'Agus Prasetyo',
    tujuan: 'Rekening Bank',
    poin: 85000,
    nominal: 850000,
    waktu: '11.05',
    status: PenarikanStatus.menunggu,
    isAnomali: true,
    anomaliReason: 'Nominal jauh di atas rata-rata (biasanya <Rp100rb)',
  ),
  PenarikanModel(
    userName: 'Dewi Lestari',
    tujuan: 'DANA',
    poin: 4500,
    nominal: 45000,
    waktu: '07.20',
    status: PenarikanStatus.menunggu,
  ),
  PenarikanModel(
    userName: 'Hendra Gunawan',
    tujuan: 'GoPay',
    poin: 1000,
    nominal: 10000,
    waktu: 'Kemarin, 16.10',
    status: PenarikanStatus.selesai,
  ),
];

final List<B2BDealModel> sampleB2B = [
  B2BDealModel(
    mitraName: 'PT Daur Ulang Nusantara',
    kategori: 'Plastik PET',
    totalBerat: 420,
    hargaPerKg: 3500,
    tanggal: '28 Jul 2026',
    status: B2BStatus.disepakati,
  ),
  B2BDealModel(
    mitraName: 'CV Kertas Hijau',
    kategori: 'Kertas & Kardus',
    totalBerat: 680,
    hargaPerKg: 1800,
    tanggal: '25 Jul 2026',
    status: B2BStatus.terkirim,
  ),
  B2BDealModel(
    mitraName: 'UD Logam Jaya',
    kategori: 'Logam Campur',
    totalBerat: 150,
    hargaPerKg: 6200,
    tanggal: '20 Jul 2026',
    status: B2BStatus.selesai,
  ),
];

// --------------------------------------------------------------------------
// MAIN SCREEN
// --------------------------------------------------------------------------

class ManajemenTransaksiScreen extends StatefulWidget {
  const ManajemenTransaksiScreen({super.key});

  @override
  State<ManajemenTransaksiScreen> createState() =>
      _ManajemenTransaksiScreenState();
}

class _ManajemenTransaksiScreenState extends State<ManajemenTransaksiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = [
    'Approval Setor',
    'Penarikan Saldo',
    'Penjualan B2B',
  ];

  List<Map<String, dynamic>> _dbTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> txs = [];
    try {
      txs = await ApiService.instance.getTransactions();
    } catch (_) {
      // Fallback ke lokal jika gagal
      txs = await DatabaseHelper.instance.getAllTransactions();
    }

    if (!mounted) return;
    setState(() {
      _dbTransactions = txs;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manajemen Transaksi',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'FR-AD-04 · FR-AD-05 · FR-AD-06 — approval setor, penarikan saldo, dan penjualan B2B',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: subtleText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryGreen,
          unselectedLabelColor: mutedText,
          indicatorColor: primaryGreen,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          onTap: (_) => setState(() {}),
          tabs: [
            const Tab(text: 'Approval Setor'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Penarikan Saldo'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: warningBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: warningAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Penjualan B2B'),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SHARED HELPERS
  // ------------------------------------------------------------------------

  Widget _tableContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 28, 24),
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
      child: Column(children: children),
    );
  }

  Widget _tableHeaderRow(List<String> columns, List<int> flexes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: List.generate(columns.length, (i) {
          return Expanded(
            flex: flexes[i],
            child: Text(
              columns[i],
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtleText,
                letterSpacing: 0.3,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _pill(String text, Color color, {Color? bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButton(
    String label, {
    bool primary = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: primary ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: primary ? null : Border.all(color: borderColor, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary ? Colors.white : secondaryDarkText,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 1: APPROVAL SETOR (FR-AD-04)
  // ------------------------------------------------------------------------

  String _setorStatusLabel(SetorStatus s) {
    switch (s) {
      case SetorStatus.menunggu:
        return 'Menunggu';
      case SetorStatus.terverifikasi:
        return 'Terverifikasi';
      case SetorStatus.ditolak:
        return 'Ditolak';
    }
  }

  Color _setorStatusColor(SetorStatus s) {
    switch (s) {
      case SetorStatus.menunggu:
        return warningAmber;
      case SetorStatus.terverifikasi:
        return primaryGreen;
      case SetorStatus.ditolak:
        return secondaryDarkText;
    }
  }

  Widget _buildApprovalSetorTab() {
    return SingleChildScrollView(
      child: _tableContainer(
        children: [
          _tableHeaderRow(
            [
              'User',
              'Jenis',
              'Kategori',
              'Berat',
              'Est. Poin',
              'Status',
              'Aksi',
            ],
            [2, 1, 2, 1, 1, 1, 2],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (_dbTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Belum ada transaksi',
                  style: TextStyle(color: subtleText),
                ),
              ),
            )
          else
            ..._dbTransactions.map((tx) {
              final String statusStr = tx['status'] ?? 'menunggu';
              final statusEnum = statusStr == 'menunggu'
                  ? SetorStatus.menunggu
                  : statusStr == 'terverifikasi' || statusStr == 'selesai'
                  ? SetorStatus.terverifikasi
                  : SetorStatus.ditolak;

              final String jenis = tx['type'] == 'drop_in'
                  ? 'Drop-in'
                  : 'Jemput';
              final String waktu = tx['pickup_date'] ?? tx['created_at'] ?? '';
              final items = (tx['items'] as List?) ?? [];

              String kategori = 'Campur';
              double berat = 0.0;
              int estimasiPoin = 0;
              if (tx['total_est_points'] is num) {
                estimasiPoin = (tx['total_est_points'] as num).toInt();
              } else if (tx['total_est_points'] is String) {
                estimasiPoin = int.tryParse(tx['total_est_points']) ?? 0;
              }

              if (items.isNotEmpty) {
                // Mapped logic: usually waste category names are stored, or we just show a generic string since we only have IDs in items table here.
                kategori = items.length == 1
                    ? '1 Jenis Sampah'
                    : '${items.length} Jenis Sampah';
                for (var item in items) {
                  final w = item['estimated_weight'];
                  if (w is num) {
                    berat += w.toDouble();
                  } else if (w is String) {
                    berat += double.tryParse(w) ?? 0.0;
                  }
                }
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['nasabah_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                          Text(
                            waktu,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _pill(
                        jenis,
                        jenis == 'Jemput'
                            ? const Color(0xFF32CD32)
                            : primaryGreen,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        kategori,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: subtleText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${berat.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '$estimasiPoin',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _pill(
                        _setorStatusLabel(statusEnum),
                        _setorStatusColor(statusEnum),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: statusEnum == SetorStatus.menunggu
                          ? Row(
                              children: [
                                _actionButton(
                                  'Setujui',
                                  onTap: () async {
                                    bool success = false;
                                    try {
                                      success = await ApiService.instance
                                          .updateTransactionStatus(
                                            tx['id'],
                                            'terverifikasi',
                                          );
                                    } catch (_) {}

                                    if (!success) {
                                      await DatabaseHelper.instance
                                          .updateTransactionStatus(
                                            tx['id'],
                                            'terverifikasi',
                                          );
                                    }
                                    _loadTransactions();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Setor sampah disetujui',
                                          ),
                                          backgroundColor: primaryGreen,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 6),
                                _actionButton(
                                  'Tolak',
                                  primary: false,
                                  onTap: () async {
                                    bool success = false;
                                    try {
                                      success = await ApiService.instance
                                          .updateTransactionStatus(
                                            tx['id'],
                                            'ditolak',
                                          );
                                    } catch (_) {}

                                    if (!success) {
                                      await DatabaseHelper.instance
                                          .updateTransactionStatus(
                                            tx['id'],
                                            'ditolak',
                                          );
                                    }
                                    _loadTransactions();
                                  },
                                ),
                              ],
                            )
                          : const Text(
                              '—',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12,
                                color: mutedText,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 2: PENARIKAN SALDO (FR-AD-05) — dgn deteksi anomali
  // ------------------------------------------------------------------------

  String _penarikanStatusLabel(PenarikanStatus s) {
    switch (s) {
      case PenarikanStatus.menunggu:
        return 'Menunggu';
      case PenarikanStatus.diproses:
        return 'Diproses';
      case PenarikanStatus.selesai:
        return 'Selesai';
      case PenarikanStatus.ditolak:
        return 'Ditolak';
    }
  }

  Color _penarikanStatusColor(PenarikanStatus s) {
    switch (s) {
      case PenarikanStatus.menunggu:
        return warningAmber;
      case PenarikanStatus.diproses:
        return const Color(0xFF5F8A4A);
      case PenarikanStatus.selesai:
        return primaryGreen;
      case PenarikanStatus.ditolak:
        return secondaryDarkText;
    }
  }

  Widget _buildPenarikanSaldoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tableContainer(
            children: [
              _tableHeaderRow(
                ['User', 'Tujuan', 'Nominal', 'Waktu', 'Status', 'Aksi'],
                [2, 2, 2, 2, 2, 2],
              ),
              ...samplePenarikan.map(
                (p) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: p.isAnomali
                        ? warningBg.withValues(alpha: 0.35)
                        : null,
                    border: const Border(
                      bottom: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                if (p.isAnomali)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      size: 15,
                                      color: warningAmber,
                                    ),
                                  ),
                                Text(
                                  p.userName,
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              p.tujuan,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: subtleText,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Rp ${p.nominal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: p.isAnomali ? warningAmber : darkText,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              p.waktu,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: mutedText,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _pill(
                              _penarikanStatusLabel(p.status),
                              _penarikanStatusColor(p.status),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: p.status == PenarikanStatus.menunggu
                                ? Row(
                                    children: [
                                      _actionButton(
                                        p.isAnomali ? 'Tinjau' : 'Setujui',
                                        onTap: () {
                                          if (p.isAnomali) {
                                            _showTinjauanAnomaliDialog(p);
                                          } else {
                                            setState(() {
                                              p.status =
                                                  PenarikanStatus.diproses;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Penarikan saldo disetujui dan diproses',
                                                ),
                                                backgroundColor: primaryGreen,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      _actionButton(
                                        'Tolak',
                                        primary: false,
                                        onTap: () {
                                          setState(() {
                                            p.status = PenarikanStatus.ditolak;
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                : const Text(
                                    '—',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 12,
                                      color: mutedText,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (p.isAnomali && p.anomaliReason != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: warningBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: warningAmber,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.anomaliReason!,
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: warningAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
  // TAB 3: PENJUALAN B2B (FR-AD-06)
  // ------------------------------------------------------------------------

  String _b2bStatusLabel(B2BStatus s) {
    switch (s) {
      case B2BStatus.negosiasi:
        return 'Negosiasi';
      case B2BStatus.disepakati:
        return 'Disepakati';
      case B2BStatus.terkirim:
        return 'Terkirim';
      case B2BStatus.selesai:
        return 'Selesai';
    }
  }

  Color _b2bStatusColor(B2BStatus s) {
    switch (s) {
      case B2BStatus.negosiasi:
        return warningAmber;
      case B2BStatus.disepakati:
        return const Color(0xFF5F8A4A);
      case B2BStatus.terkirim:
        return limeGreen;
      case B2BStatus.selesai:
        return primaryGreen;
    }
  }

  Widget _buildB2BTab() {
    final totalNilaiBulanIni = sampleB2B.fold<double>(
      0,
      (sum, item) => sum + item.totalNilai,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total nilai penjualan B2B (bulan ini)',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rp ${totalNilaiBulanIni.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddB2BDialog();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah Kesepakatan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _tableContainer(
            children: [
              _tableHeaderRow(
                [
                  'Mitra',
                  'Kategori',
                  'Total Berat',
                  'Harga/kg',
                  'Total Nilai',
                  'Status',
                ],
                [2, 2, 1, 1, 2, 1],
              ),
              ...sampleB2B.map(
                (deal) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deal.mitraName,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                            ),
                            Text(
                              deal.tanggal,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          deal.kategori,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: subtleText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${deal.totalBerat.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: darkText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Rp ${deal.hargaPerKg.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: subtleText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rp ${deal.totalNilai.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _pill(
                          _b2bStatusLabel(deal.status),
                          _b2bStatusColor(deal.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTinjauanAnomaliDialog(PenarikanModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tinjau Penarikan (Anomali)',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Alasan: ${p.anomaliReason}\n\nApakah Anda yakin ingin menyetujui penarikan ini?',
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: subtleText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                p.status = PenarikanStatus.ditolak;
              });
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                p.status = PenarikanStatus.diproses;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Penarikan saldo disetujui dan diproses'),
                  backgroundColor: primaryGreen,
                ),
              );
            },
            child: const Text('Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddB2BDialog() {
    final mitraController = TextEditingController();
    final kategoriController = TextEditingController();
    final beratController = TextEditingController();
    final hargaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Tambah Kesepakatan B2B',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: mitraController,
                  decoration: const InputDecoration(labelText: 'Nama Mitra'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kategoriController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Sampah',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: beratController,
                  decoration: const InputDecoration(
                    labelText: 'Total Berat (kg)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hargaController,
                  decoration: const InputDecoration(
                    labelText: 'Harga per kg (Rp)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: subtleText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
              ),
              onPressed: () {
                final mitra = mitraController.text.trim();
                final kategori = kategoriController.text.trim();
                final berat = double.tryParse(beratController.text.trim()) ?? 0;
                final harga = double.tryParse(hargaController.text.trim()) ?? 0;

                if (mitra.isNotEmpty &&
                    kategori.isNotEmpty &&
                    berat > 0 &&
                    harga > 0) {
                  setState(() {
                    sampleB2B.add(
                      B2BDealModel(
                        mitraName: mitra,
                        kategori: kategori,
                        totalBerat: berat,
                        hargaPerKg: harga,
                        tanggal: 'Hari ini',
                        status: B2BStatus.negosiasi,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kesepakatan B2B ditambahkan'),
                      backgroundColor: primaryGreen,
                    ),
                  );
                }
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApprovalSetorTab(),
                _buildPenarikanSaldoTab(),
                _buildB2BTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
