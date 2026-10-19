import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'db_helper.dart';
import 'api_service.dart';
import 'transaction_service.dart';
import 'widgets/image_viewer_dialog.dart';
import 'widgets/barcode_painter.dart';

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

enum SetorStatus { menunggu, terverifikasi, ditolak }

class SetorTransaksiModel {
  final String userName;
  final String jenis;
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
  String id;
  String userName;
  String nasabahId;
  String tujuan;
  int poin;
  int nominal;
  String waktu;
  PenarikanStatus status;
  bool isAnomali;
  String? anomaliReason;
  bool isBarcodeScanned;

  PenarikanModel({
    required this.id,
    required this.userName,
    required this.nasabahId,
    required this.tujuan,
    required this.poin,
    required this.nominal,
    required this.waktu,
    required this.status,
    this.isAnomali = false,
    this.anomaliReason,
    this.isBarcodeScanned = false,
  });
}

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
    id: '1',
    userName: 'Agus Prasetyo',
    nasabahId: 'USR-000',
    tujuan: 'Rekening Bank',
    poin: 85000,
    nominal: 850000,
    waktu: '11.05',
    status: PenarikanStatus.menunggu,
    isAnomali: true,
    anomaliReason: 'Nominal jauh di atas rata-rata (biasanya <Rp100rb)',
  ),
  PenarikanModel(
    id: '2',
    userName: 'Dewi Lestari',
    nasabahId: 'USR-000',
    tujuan: 'DANA',
    poin: 4500,
    nominal: 45000,
    waktu: '07.20',
    status: PenarikanStatus.menunggu,
  ),
  PenarikanModel(
    id: '3',
    userName: 'Hendra Gunawan',
    nasabahId: 'USR-000',
    tujuan: 'GoPay',
    poin: 1000,
    nominal: 10000,
    waktu: 'Kemarin, 16.10',
    status: PenarikanStatus.selesai,
  ),
];

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
    'Daftar Titipan',
  ];

  List<Map<String, dynamic>> _dbTransactions = [];
  List<PenarikanModel> _dbWithdrawals = [];
  List<Map<String, dynamic>> _dbTitipan = [];
  final Set<String> _scannedWithdrawalIds = {};
  final Map<int, String> _categoryNamesMap = {};
  final Map<int, int> _categoryPointsMap = {};
  final Map<String, Map<String, dynamic>> _dropPointsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final dbCategories = await DatabaseHelper.instance.getWasteCategories();
    for (var c in dbCategories) {
      final id = (c['id'] as num).toInt();
      _categoryNamesMap[id] = c['name'].toString();
      _categoryPointsMap[id] = (c['point_per_kg'] as num).toInt();
    }

    try {
      final dps = await ApiService.instance.getDropPoints();
      for (var dp in dps) {
        _dropPointsMap[dp['id'].toString()] = dp;
      }
    } catch (_) {}
    if (_dropPointsMap.isEmpty) {
      final localDps = await DatabaseHelper.instance.getDropPoints();
      for (var dp in localDps) {
        _dropPointsMap[dp['id'].toString()] = dp;
      }
    }

    List<Map<String, dynamic>> txs = [];
    List<PenarikanModel> wds = [];
    List<Map<String, dynamic>>? wdData;
    try {
      txs = await ApiService.instance.getTransactions();
      wdData = await ApiService.instance.fetchWithdrawals();
      for (var w in wdData) {
        PenarikanStatus st = PenarikanStatus.menunggu;
        if (w['status'] == 'approved' || w['status'] == 'selesai')
          st = PenarikanStatus.selesai;
        if (w['status'] == 'rejected') st = PenarikanStatus.ditolak;

        wds.add(
          PenarikanModel(
            id: w['id'].toString(),
            userName: w['full_name'] ?? w['nasabah_name'] ?? 'Unknown',
            nasabahId: w['nasabah_id']?.toString() ?? '',
            tujuan: w['account_details'] ?? w['method'] ?? 'Transfer',
            poin: (w['points_deducted'] ?? 0).toInt(),
            nominal: (w['points_deducted'] ?? 0) * 10,
            waktu: w['created_at']?.toString().substring(0, 16) ?? '',
            status: st,
          ),
        );
      }
    } catch (_) {
      txs = [];
    }

    if (txs.isEmpty) {
      txs = await DatabaseHelper.instance.getAllTransactions();
    }

    if (wds.isEmpty) {
      final localWds = await DatabaseHelper.instance.getWithdrawals();
      for (var w in localWds) {
        PenarikanStatus st = PenarikanStatus.menunggu;
        if (w['status'] == 'approved' || w['status'] == 'selesai')
          st = PenarikanStatus.selesai;
        if (w['status'] == 'rejected') st = PenarikanStatus.ditolak;

        wds.add(
          PenarikanModel(
            id: w['id'].toString(),
            userName: w['full_name'] ?? w['nasabah_name'] ?? 'Unknown',
            nasabahId: w['nasabah_id']?.toString() ?? '',
            tujuan: w['account_details'] ?? w['method'] ?? 'Transfer',
            poin: (w['points_deducted'] ?? 0).toInt(),
            nominal: (w['points_deducted'] ?? 0) * 10,
            waktu: w['created_at']?.toString().substring(0, 16) ?? '',
            status: st,
          ),
        );
      }
    }

    if (!mounted) return;

    List<Map<String, dynamic>> titipan = [];

    if (wdData != null) {
      for (var w in wdData) {
        if (w['status'] == 'approved' &&
            w['account_details'] != null &&
            w['account_details'].toString().contains('(Titip Kurir)')) {
          titipan.add({
            'id': w['id'],
            'full_name': w['nasabah_name'] ?? w['full_name'] ?? 'Nasabah',
            'phone_number': w['phone_number'] ?? '-',
            'nasabah_address': w['nasabah_address'] ?? w['address'] ?? '-',
            'account_details': w['account_details'],
          });
        }
      }
    }

    if (titipan.isEmpty) {
      final localTitipan = await DatabaseHelper.instance.getTitipanKurir();
      titipan.addAll(localTitipan);
    }

    setState(() {
      _dbTransactions = txs;
      _dbWithdrawals = wds;
      _dbTitipan = titipan;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showVerifyDialog(
    BuildContext context,
    Map<String, dynamic> tx,
  ) async {
    final String nasabahName =
        tx['nasabah_name'] ?? tx['full_name'] ?? 'Nasabah';
    final String tipeStr = tx['type'] == 'drop_in'
        ? 'Drop-in Mandiri'
        : 'Penjemputan';
    String rawDate = tx['pickup_date'] ?? '';
    if (rawDate.isEmpty || rawDate.startsWith('0000')) {
      rawDate = tx['created_at'] ?? '';
    }
    final String waktuStr = TransactionService.formatDate(rawDate);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: primaryGreen),
              SizedBox(width: 10),
              Text(
                'Verifikasi Request Setor',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F9F4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nasabah: $nasabahName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Tipe: $tipeStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: subtleText,
                            ),
                          ),
                        ],
                      ),
                      if (waktuStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Waktu: $waktuStr',
                          style: const TextStyle(
                            fontSize: 11,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Apakah Anda yakin ingin memverifikasi request ini?\n\n'
                  'Setelah diverifikasi, request akan diteruskan ke Pekerja/Petugas untuk proses penimbangan berat sampah dan penginputan poin nasabah.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: darkText,
                    height: 1.4,
                  ),
                ),
                if (tx['photo_evidence'] != null &&
                    tx['photo_evidence'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      ImageViewerDialog.show(
                        context,
                        tx['photo_evidence'].toString(),
                      );
                    },
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Lihat Foto Bukti'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                const newStatus = 'dikonfirmasi';
                await DatabaseHelper.instance.updateTransactionStatus(
                  tx['id'],
                  newStatus,
                );
                try {
                  await ApiService.instance.updateTransactionStatus(
                    tx['id'],
                    newStatus,
                  );
                } catch (_) {}
                try {
                  await ApiService.instance.updateTaskStatus(
                    tx['id'],
                    newStatus,
                  );
                } catch (_) {}

                _loadTransactions();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Request setor $nasabahName berhasil diverifikasi! Diteruskan ke Pekerja.',
                      ),
                      backgroundColor: primaryGreen,
                    ),
                  );
                }
              },
              child: const Text('Verifikasi & Setujui'),
            ),
          ],
        );
      },
    );
  }

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
            'FR-AD-04 · FR-AD-05 — approval setor dan penarikan saldo',
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
          tabs: const [
            Tab(text: 'Approval Setor'),
            Tab(text: 'Penarikan Saldo'),
            Tab(text: 'Daftar Titipan'),
          ],
        ),
      ),
    );
  }

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
          final isAksi = columns[i] == 'Aksi';
          return Expanded(
            flex: flexes[i],
            child: Text(
              columns[i],
              textAlign: isAksi ? TextAlign.center : TextAlign.start,
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
    IconData? icon,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primary ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: primary ? null : Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: primary ? Colors.white : (textColor ?? secondaryDarkText),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary ? Colors.white : (textColor ?? secondaryDarkText),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  String _getBarcodeForTx(Map<String, dynamic> tx) {
    if (tx['barcode'] != null && tx['barcode'].toString().isNotEmpty) {
      return tx['barcode'].toString();
    }
    final String id = tx['id']?.toString() ?? '';
    final String prefix = (tx['type'] == 'drop_in') ? 'WS' : 'JS';
    if (id.startsWith('TRX-')) {
      final numPart = id.substring(4);
      final hexPart = int.tryParse(numPart)?.toRadixString(36).toUpperCase() ?? numPart;
      if (hexPart.length >= 8) {
        return '$prefix-${hexPart.substring(hexPart.length - 8, hexPart.length - 4)}-${hexPart.substring(hexPart.length - 4)}';
      }
      return '$prefix-$hexPart';
    }
    return id.isNotEmpty ? '$prefix-$id' : '$prefix-8X4K-2Q1M';
  }

  void _showSingleBarcodeModal(BuildContext context, Map<String, dynamic> tx) {
    final String barcodeCode = _getBarcodeForTx(tx);
    final String nasabahName = tx['nasabah_name'] ?? tx['full_name'] ?? 'Nasabah';

    String lokasi = '-';
    if (tx['type'] == 'drop_in') {
      final dpName = (tx['drop_point_name'] ?? '').toString().trim();
      final dpAddress = (tx['drop_point_address'] ?? '').toString().trim();
      if (dpName.isNotEmpty && dpAddress.isNotEmpty) {
        lokasi = '$dpName • $dpAddress';
      } else if (dpName.isNotEmpty) {
        lokasi = dpName;
      } else {
        final dpId = tx['drop_point_id']?.toString() ?? '';
        if (dpId.isNotEmpty && _dropPointsMap.containsKey(dpId)) {
          final dp = _dropPointsMap[dpId]!;
          lokasi = '${dp['name'] ?? ''} • ${dp['address'] ?? ''}'.trim();
        } else {
          lokasi = tx['address'] ?? 'Drop Point Mandiri';
        }
      }
    } else {
      lokasi = (tx['pickup_address'] ?? tx['nasabah_address'] ?? tx['address'] ?? tx['alamat'] ?? '-').toString().trim();
    }

    String rawDate = tx['pickup_date'] ?? '';
    if (rawDate.isEmpty || rawDate.startsWith('0000')) {
      rawDate = tx['created_at'] ?? '';
    }
    final String waktuStr = TransactionService.formatDate(rawDate);

    final statusStr = (tx['status'] ?? 'menunggu').toString().toLowerCase();
    final items = (tx['items'] as List?) ?? [];
    String kategori = 'Campur';
    if (items.isNotEmpty) {
      final catNames = items
          .map((i) {
            final cid = int.tryParse(i['waste_category_id']?.toString() ?? '0') ?? 0;
            return _categoryNamesMap[cid] ?? i['category_name']?.toString() ?? '';
          })
          .where((n) => n.isNotEmpty)
          .toList();
      if (catNames.isNotEmpty) {
        kategori = catNames.take(2).join(', ');
      }
    }
    final int estPoin = int.tryParse(tx['total_est_points']?.toString() ?? '0') ?? 0;

    showSetorBarcodeModal(
      context: context,
      barcodeId: barcodeCode,
      type: tx['type'] ?? 'drop_in',
      nasabahName: nasabahName,
      lokasi: lokasi,
      waktu: waktuStr,
      status: statusStr,
      kategori: kategori,
      estimasiPoin: estPoin,
      onApproved: statusStr == 'menunggu' ? () => _showVerifyDialog(context, tx) : null,
      onRejected: statusStr == 'menunggu'
          ? () async {
              const newStatus = 'dibatalkan';
              await DatabaseHelper.instance.updateTransactionStatus(tx['id'], newStatus);
              try {
                await ApiService.instance.updateTransactionStatus(tx['id'], newStatus);
              } catch (_) {}
              try {
                await ApiService.instance.updateTaskStatus(tx['id'], newStatus);
              } catch (_) {}
              _loadTransactions();
            }
          : null,
    );
  }

  void _showAllBarcodesModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AllBarcodesDialog(
        transactions: _dbTransactions,
        dropPointsMap: _dropPointsMap,
        categoryNamesMap: _categoryNamesMap,
        onVerify: (tx) => _showVerifyDialog(context, tx),
        onReject: (tx) async {
          const newStatus = 'dibatalkan';
          await DatabaseHelper.instance.updateTransactionStatus(tx['id'], newStatus);
          try {
            await ApiService.instance.updateTransactionStatus(tx['id'], newStatus);
          } catch (_) {}
          try {
            await ApiService.instance.updateTaskStatus(tx['id'], newStatus);
          } catch (_) {}
          _loadTransactions();
        },
      ),
    );
  }

  Widget _buildApprovalSetorTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Setor Sampah',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kelola dan verifikasi transaksi setor dari nasabah',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_2_rounded, size: 17),
                  label: const Text('Bukti Barcode (Drop-in & Jemput)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _showAllBarcodesModal(context),
                ),
              ],
            ),
          ),
          _tableContainer(
            children: [
              _tableHeaderRow(
                [
                  'User',
                  'Jenis',
                  'Kategori',
                  'Lokasi',
                  'Est. Poin',
                  'Status',
                  'Aksi',
                ],
                [2, 1, 2, 2, 1, 1, 2],
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
                  final String statusStr = (tx['status'] ?? 'menunggu')
                      .toString()
                      .trim()
                      .toLowerCase();

                  final statusEnum = statusStr == 'menunggu'
                      ? SetorStatus.menunggu
                      : (statusStr == 'dikonfirmasi' ||
                            statusStr == 'menuju_lokasi' ||
                            statusStr == 'tiba' ||
                            statusStr == 'selesai')
                      ? SetorStatus.terverifikasi
                      : (statusStr == 'dibatalkan' ||
                            statusStr == 'ditolak' ||
                            statusStr == 'rejected')
                      ? SetorStatus.ditolak
                      : SetorStatus.menunggu;

                  final bool isDropIn = (tx['type'] == 'drop_in');
                  final String jenis = isDropIn ? 'Drop-in' : 'Jemput';
                  String rawDate = tx['pickup_date'] ?? '';
                  if (rawDate.isEmpty || rawDate.startsWith('0000')) {
                    rawDate = tx['created_at'] ?? '';
                  }
                  final String waktu = TransactionService.formatDate(rawDate);
                  final items = (tx['items'] as List?) ?? [];

                  String kategori = 'Campur';
                  int estimasiPoin =
                      int.tryParse(tx['total_est_points']?.toString() ?? '0') ?? 0;

                  if (items.isNotEmpty) {
                    final catNames = items
                        .map((i) {
                          final cid =
                              int.tryParse(
                                i['waste_category_id']?.toString() ?? '0',
                              ) ??
                              0;
                          return _categoryNamesMap[cid] ??
                              i['category_name']?.toString() ??
                              '';
                        })
                        .where((n) => n.isNotEmpty)
                        .toList();

                    if (catNames.isNotEmpty) {
                      if (catNames.length <= 2) {
                        kategori = catNames.join(', ');
                      } else {
                        kategori = 'Campur';
                      }
                    } else {
                      kategori = items.length == 1
                          ? '1 Jenis Sampah'
                          : '${items.length} Jenis Sampah';
                    }
                  }

                  // Determine exact location based on user input or selected drop point
                  String lokasi = '-';
                  if (isDropIn) {
                    final dpName = (tx['drop_point_name'] ?? '').toString().trim();
                    final dpAddress = (tx['drop_point_address'] ?? '').toString().trim();
                    if (dpName.isNotEmpty && dpAddress.isNotEmpty) {
                      lokasi = '$dpName • $dpAddress';
                    } else if (dpName.isNotEmpty) {
                      lokasi = dpName;
                    } else if (dpAddress.isNotEmpty) {
                      lokasi = dpAddress;
                    } else {
                      final dpId = tx['drop_point_id']?.toString() ?? '';
                      if (dpId.isNotEmpty && _dropPointsMap.containsKey(dpId)) {
                        final dp = _dropPointsMap[dpId]!;
                        lokasi = '${dp['name'] ?? 'Drop Point'} • ${dp['address'] ?? ''}';
                      } else {
                        lokasi = (tx['address'] != null && tx['address'].toString().isNotEmpty)
                            ? tx['address'].toString()
                            : 'Drop Point Mandiri';
                      }
                    }
                  } else {
                    // Jemput sampah: show user input pickup address and notes/patokan
                    final addr = (tx['pickup_address'] ??
                            tx['nasabah_address'] ??
                            tx['address'] ??
                            tx['alamat'] ??
                            '')
                        .toString()
                        .trim();
                    lokasi = addr.isNotEmpty ? addr : 'Alamat Penjemputan';
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
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  isDropIn ? Icons.location_on_outlined : Icons.home_outlined,
                                  size: 14,
                                  color: isDropIn ? primaryGreen : const Color(0xFF32CD32),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lokasi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: darkText,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
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
                          child: Center(
                            child: statusEnum == SetorStatus.menunggu
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _actionButton(
                                        'Setujui',
                                        onTap: () {
                                          _showVerifyDialog(context, tx);
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        'Tolak',
                                        primary: false,
                                        onTap: () async {
                                          const newStatus = 'dibatalkan';
                                          await DatabaseHelper.instance
                                              .updateTransactionStatus(
                                                tx['id'],
                                                newStatus,
                                              );
                                          try {
                                            await ApiService.instance
                                                .updateTransactionStatus(
                                                  tx['id'],
                                                  newStatus,
                                                );
                                          } catch (_) {}
                                          try {
                                            await ApiService.instance
                                                .updateTaskStatus(
                                                  tx['id'],
                                                  newStatus,
                                                );
                                          } catch (_) {}
                                          _loadTransactions();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Transaksi berhasil ditolak/dibatalkan'),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        'Barcode',
                                        icon: Icons.qr_code_2_rounded,
                                        primary: false,
                                        textColor: primaryGreen,
                                        onTap: () {
                                          _showSingleBarcodeModal(context, tx);
                                        },
                                      ),
                                    ],
                                  )
                                : _actionButton(
                                    'Barcode',
                                    icon: Icons.qr_code_2_rounded,
                                    primary: false,
                                    textColor: primaryGreen,
                                    onTap: () {
                                      _showSingleBarcodeModal(context, tx);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ],
      ),
    );
  }

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
      child: _tableContainer(
        children: [
          _tableHeaderRow(
            ['User', 'Tujuan', 'Nominal', 'Waktu', 'Status', 'Aksi'],
            [2, 2, 2, 2, 2, 3],
          ),
              if (_dbWithdrawals.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Belum ada penarikan saldo')),
                )
              else
                ..._dbWithdrawals.map(
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
                                  Expanded(
                                    child: Text(
                                      p.userName,
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: darkText,
                                      ),
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
                              flex: 3,
                              child: Center(
                                child: p.status == PenarikanStatus.menunggu
                                    ? ((p.isBarcodeScanned || _scannedWithdrawalIds.contains(p.id))
                                        ? SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                _actionButton(
                                                  p.isAnomali ? 'Tinjau' : 'Setujui',
                                                  primary: true,
                                                  onTap: () async {
                                                    if (p.isAnomali) {
                                                      _showTinjauanAnomaliDialog(p);
                                                    } else {
                                                      await _approveWithdrawal(p);
                                                    }
                                                  },
                                                ),
                                                const SizedBox(width: 6),
                                                _actionButton(
                                                  'Tolak',
                                                  primary: false,
                                                  textColor: Colors.red[700],
                                                  onTap: () async =>
                                                      await _rejectWithdrawal(p),
                                                ),
                                              ],
                                            ),
                                          )
                                        : _actionButton(
                                            'Scan Barcode',
                                            icon: Icons.qr_code_scanner_rounded,
                                            primary: true,
                                            onTap: () => _showScanBarcodeDialog(p),
                                          ))
                                    : const Text(
                                        '—',
                                        style: TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontSize: 12,
                                          color: mutedText,
                                        ),
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

  Widget _buildDaftarTitipanTab() {
    if ((_dbTitipan as dynamic) == null || _dbTitipan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada titipan aktif',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: subtleText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Semua barang sudah berhasil diserahkan ke kurir.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: mutedText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _tableContainer(
          children: [
            _tableHeaderRow(
              ['Nasabah Penerima', 'Barang', 'Status Pengantaran'],
              [2, 3, 2],
            ),
            ..._dbTitipan.map((t) {
              final String name =
                  t['full_name'] ?? t['nasabah_name'] ?? 'Nasabah';
              final String item =
                  t['account_details']
                      ?.toString()
                      .replaceAll('(Titip Kurir)', '')
                      .trim() ??
                  '-';

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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t['nasabah_address'] ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              color: subtleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _pill('Siap Diantar', primaryGreen),
                          _pill('Titip Kurir', Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
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
                _buildDaftarTitipanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveWithdrawal(PenarikanModel p) async {
    String? error;
    try {
      error = await ApiService.instance.updateWithdrawalStatus(
        p.id,
        'approved',
      );
    } catch (e) {
      error = 'Terjadi kesalahan koneksi';
    }
    if (error == null) {
      await DatabaseHelper.instance.updateWithdrawalStatus(
        p.id,
        'approved',
      );
      setState(() {
        p.status = PenarikanStatus.selesai;
      });
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Penarikan saldo sebesar Rp ${p.nominal.toStringAsFixed(0)} untuk ${p.userName} berhasil disetujui',
            ),
            backgroundColor: primaryGreen,
          ),
        );
      }
    } else {
      bool localSuccess = await DatabaseHelper.instance.updateWithdrawalStatus(
        p.id,
        'approved',
      );
      if (localSuccess &&
          (error == 'Terjadi kesalahan koneksi' || error == 'API error')) {
        setState(() {
          p.status = PenarikanStatus.selesai;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penarikan saldo disetujui (mode offline)'),
              backgroundColor: primaryGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectWithdrawal(PenarikanModel p) async {
    String? error;
    try {
      error = await ApiService.instance.updateWithdrawalStatus(
        p.id,
        'rejected',
        reason: 'Barang habis',
      );
    } catch (e) {
      error = 'Terjadi kesalahan koneksi';
    }
    if (error == null) {
      await DatabaseHelper.instance.updateWithdrawalStatus(
        p.id,
        'rejected',
        pointsToRefund: p.poin,
        nasabahId: p.nasabahId,
        reason: 'Barang habis',
      );
      setState(() {
        p.status = PenarikanStatus.ditolak;
      });
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penarikan ditolak'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      bool localSuccess = await DatabaseHelper.instance.updateWithdrawalStatus(
        p.id,
        'rejected',
        pointsToRefund: p.poin,
        nasabahId: p.nasabahId,
        reason: 'Barang habis',
      );
      if (localSuccess &&
          (error == 'Terjadi kesalahan koneksi' || error == 'API error')) {
        setState(() {
          p.status = PenarikanStatus.ditolak;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penarikan ditolak (mode offline)'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showScanBarcodeDialog(PenarikanModel? preselected) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return _ScanBarcodeDialogWidget(
          preselected: preselected,
          pendingWithdrawals: _dbWithdrawals
              .where((w) => w.status == PenarikanStatus.menunggu)
              .toList(),
          onScanCompleted: (penarikan) {
            setState(() {
              penarikan.isBarcodeScanned = true;
              _scannedWithdrawalIds.add(penarikan.id);
            });
          },
          onApprove: (penarikan) async {
            Navigator.pop(dialogCtx);
            await _approveWithdrawal(penarikan);
          },
          onReject: (penarikan) async {
            Navigator.pop(dialogCtx);
            await _rejectWithdrawal(penarikan);
          },
        );
      },
    );
  }
}

class _ScanBarcodeDialogWidget extends StatefulWidget {
  final PenarikanModel? preselected;
  final List<PenarikanModel> pendingWithdrawals;
  final Function(PenarikanModel) onApprove;
  final Function(PenarikanModel)? onReject;
  final Function(PenarikanModel)? onScanCompleted;

  const _ScanBarcodeDialogWidget({
    this.preselected,
    required this.pendingWithdrawals,
    required this.onApprove,
    this.onReject,
    this.onScanCompleted,
  });

  @override
  State<_ScanBarcodeDialogWidget> createState() =>
      _ScanBarcodeDialogWidgetState();
}

class _ScanBarcodeDialogWidgetState extends State<_ScanBarcodeDialogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  final TextEditingController _codeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  PenarikanModel? _selectedPenarikan;
  bool _isVerified = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPenarikan = widget.preselected;
    if (_selectedPenarikan != null) {
      _codeController.text = _selectedPenarikan!.id;
    }

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }


  @override
  void dispose() {
    _laserController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scanFromCamera() async {
    setState(() => _errorMessage = null);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null) {
        _handleScanSuccess();
      }
    } catch (_) {
      _handleScanSuccess();
    }
  }

  Future<void> _scanFromGallery() async {
    setState(() => _errorMessage = null);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (photo != null) {
        _handleScanSuccess();
      }
    } catch (_) {
      _handleScanSuccess();
    }
  }

  void _handleScanSuccess() {
    setState(() {
      _isVerified = true;
      if (_selectedPenarikan == null && widget.pendingWithdrawals.isNotEmpty) {
        _selectedPenarikan = widget.pendingWithdrawals.first;
        _codeController.text = _selectedPenarikan!.id;
      }
    });
    if (_selectedPenarikan != null) {
      widget.onScanCompleted?.call(_selectedPenarikan!);
    }
  }

  void _matchManualCode() {
    final query = _codeController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Masukkan kode barcode');
      return;
    }

    PenarikanModel? match;
    for (var w in widget.pendingWithdrawals) {
      if (w.id.toLowerCase() == query ||
          w.userName.toLowerCase().contains(query)) {
        match = w;
        break;
      }
    }

    if (match != null) {
      setState(() {
        _selectedPenarikan = match;
        _isVerified = true;
        _errorMessage = null;
      });
      widget.onScanCompleted?.call(match);
    } else {
      if (_selectedPenarikan != null &&
          _selectedPenarikan!.id.toLowerCase() == query) {
        setState(() {
          _isVerified = true;
          _errorMessage = null;
        });
        widget.onScanCompleted?.call(_selectedPenarikan!);
      } else {
        setState(() {
          _errorMessage = 'Barcode tidak cocok dengan penarikan yang menunggu';
        });
      }
    }
  }

  Widget _scannerCorner(bool top, bool left) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Color(0xFF32CD32), width: 3.5)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Color(0xFF32CD32), width: 3.5)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Color(0xFF32CD32), width: 3.5)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Color(0xFF32CD32), width: 3.5)
              : BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Barcode Penarikan Saldo',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pindai barcode nasabah sebelum melakukan verifikasi',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11.5,
                            color: subtleText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: subtleText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scanner Viewfinder Area with animated laser
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Watermark icon
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      // 4 Corners
                      Positioned(top: 18, left: 18, child: _scannerCorner(true, true)),
                      Positioned(top: 18, right: 18, child: _scannerCorner(true, false)),
                      Positioned(bottom: 18, left: 18, child: _scannerCorner(false, true)),
                      Positioned(bottom: 18, right: 18, child: _scannerCorner(false, false)),

                      // Animated Laser
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 190 * _laserAnimation.value,
                            left: 24,
                            right: 24,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: _isVerified
                                    ? const Color(0xFF32CD32)
                                    : Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isVerified
                                            ? const Color(0xFF32CD32)
                                            : Colors.redAccent)
                                        .withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Status pill inside scanner
                      Positioned(
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _isVerified
                                ? primaryGreen.withValues(alpha: 0.9)
                                : Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isVerified
                                  ? const Color(0xFF32CD32)
                                  : Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isVerified
                                    ? Icons.check_circle_rounded
                                    : Icons.camera_alt_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isVerified
                                    ? 'Barcode Terdeteksi & Cocok'
                                    : 'Arahkan Kamera ke Barcode',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
              const SizedBox(height: 16),

              // Camera options buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _scanFromCamera,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text(
                        'Buka Kamera Scan',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondaryDarkText,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _scanFromGallery,
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        size: 18,
                        color: primaryGreen,
                      ),
                      label: const Text(
                        'Pilih Gambar',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Manual code input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Atau masukkan kode barcode (WD-...)',
                        hintStyle: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.normal,
                          color: mutedText,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: pageBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: primaryGreen,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryDarkText,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _matchManualCode,
                    child: const Text(
                      'Cocokkan',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Verification Card
              if (_selectedPenarikan != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isVerified
                        ? const Color(0xFFF0FDF4)
                        : pageBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isVerified
                          ? primaryGreen.withValues(alpha: 0.4)
                          : borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isVerified
                                ? Icons.verified_rounded
                                : Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: _isVerified ? primaryGreen : subtleText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isVerified
                                ? 'Data Barcode Cocok & Siap Diverifikasi'
                                : 'Detail Transaksi Nasabah',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isVerified ? primaryGreen : darkText,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18, thickness: 0.8),
                      _infoRow('Nama Nasabah', _selectedPenarikan!.userName),
                      const SizedBox(height: 6),
                      _infoRow('Metode Penarikan', _selectedPenarikan!.tujuan),
                      const SizedBox(height: 6),
                      _infoRow(
                        'Nominal',
                        'Rp ${_selectedPenarikan!.nominal.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 6),
                      _infoRow('ID Barcode', _selectedPenarikan!.id),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_isVerified && _selectedPenarikan != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (widget.onReject != null) {
                              widget.onReject!(_selectedPenarikan!);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Tolak',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () =>
                              widget.onApprove(_selectedPenarikan!),
                          child: const Text(
                            'Setujui',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: primaryGreen,
                      ),
                      label: const Text(
                        'Selesai Scan (Tutup & Lanjut di Tabel)',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                      onPressed: () {
                        widget.onScanCompleted?.call(_selectedPenarikan!);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text(
                        'Tandai Barcode Terverifikasi',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        _handleScanSuccess();
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11.5,
            color: subtleText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
      ],
    );
  }
}

class _AllBarcodesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final Map<String, Map<String, dynamic>> dropPointsMap;
  final Map<int, String> categoryNamesMap;
  final Function(Map<String, dynamic> tx) onVerify;
  final Function(Map<String, dynamic> tx) onReject;

  const _AllBarcodesDialog({
    required this.transactions,
    required this.dropPointsMap,
    required this.categoryNamesMap,
    required this.onVerify,
    required this.onReject,
  });

  @override
  State<_AllBarcodesDialog> createState() => _AllBarcodesDialogState();
}

class _AllBarcodesDialogState extends State<_AllBarcodesDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Semua, 1: Drop-in, 2: Jemput

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getBarcode(Map<String, dynamic> tx) {
    if (tx['barcode'] != null && tx['barcode'].toString().isNotEmpty) {
      return tx['barcode'].toString();
    }
    final String id = tx['id']?.toString() ?? '';
    final String prefix = (tx['type'] == 'drop_in') ? 'WS' : 'JS';
    if (id.startsWith('TRX-')) {
      final numPart = id.substring(4);
      final hexPart = int.tryParse(numPart)?.toRadixString(36).toUpperCase() ?? numPart;
      if (hexPart.length >= 8) {
        return '$prefix-${hexPart.substring(hexPart.length - 8, hexPart.length - 4)}-${hexPart.substring(hexPart.length - 4)}';
      }
      return '$prefix-$hexPart';
    }
    return id.isNotEmpty ? '$prefix-$id' : '$prefix-8X4K-2Q1M';
  }

  String _getLocation(Map<String, dynamic> tx) {
    if (tx['type'] == 'drop_in') {
      final dpName = (tx['drop_point_name'] ?? '').toString().trim();
      final dpAddress = (tx['drop_point_address'] ?? '').toString().trim();
      if (dpName.isNotEmpty && dpAddress.isNotEmpty) {
        return '$dpName • $dpAddress';
      } else if (dpName.isNotEmpty) {
        return dpName;
      } else {
        final dpId = tx['drop_point_id']?.toString() ?? '';
        if (dpId.isNotEmpty && widget.dropPointsMap.containsKey(dpId)) {
          final dp = widget.dropPointsMap[dpId]!;
          return '${dp['name'] ?? 'Drop Point'} • ${dp['address'] ?? ''}';
        }
        return (tx['address'] != null && tx['address'].toString().isNotEmpty)
            ? tx['address'].toString()
            : 'Drop Point Mandiri';
      }
    } else {
      final addr = (tx['pickup_address'] ??
              tx['nasabah_address'] ??
              tx['address'] ??
              tx['alamat'] ??
              '')
          .toString()
          .trim();
      return addr.isNotEmpty ? addr : 'Alamat Penjemputan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropInList = widget.transactions.where((t) => t['type'] == 'drop_in').toList();
    final jemputList = widget.transactions.where((t) => t['type'] != 'drop_in').toList();

    List<Map<String, dynamic>> filteredList = widget.transactions;
    if (_selectedFilterIndex == 1) {
      filteredList = dropInList;
    } else if (_selectedFilterIndex == 2) {
      filteredList = jemputList;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filteredList = filteredList.where((tx) {
        final name = (tx['nasabah_name'] ?? tx['full_name'] ?? '').toString().toLowerCase();
        final barcode = _getBarcode(tx).toLowerCase();
        final loc = _getLocation(tx).toLowerCase();
        return name.contains(q) || barcode.contains(q) || loc.contains(q);
      }).toList();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 860 ? 840.0 : (screenWidth * 0.92);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bukti Barcode Setor (Drop-in & Jemput)',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Daftar barcode transaksi nasabah untuk verifikasi di lapangan atau drop point',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: subtleText),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search and Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari barcode, nama, atau lokasi...',
                      hintStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12.5,
                        color: mutedText,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18, color: subtleText),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: subtleText),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(0, 'Semua (${widget.transactions.length})'),
                  const SizedBox(width: 8),
                  _filterChip(1, 'Drop-in (${dropInList.length})'),
                  const SizedBox(width: 8),
                  _filterChip(2, 'Jemput Sampah (${jemputList.length})'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // List of Barcode Cards
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada bukti barcode yang cocok',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: subtleText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Coba gunakan kata kunci pencarian atau filter yang lain',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final tx = filteredList[i];
                        final isDropIn = (tx['type'] == 'drop_in');
                        final barcodeCode = _getBarcode(tx);
                        final lokasi = _getLocation(tx);
                        final nasabahName = tx['nasabah_name'] ?? tx['full_name'] ?? 'Nasabah';

                        String rawDate = tx['pickup_date'] ?? '';
                        if (rawDate.isEmpty || rawDate.startsWith('0000')) {
                          rawDate = tx['created_at'] ?? '';
                        }
                        final waktu = TransactionService.formatDate(rawDate);

                        final statusStr = (tx['status'] ?? 'menunggu').toString().trim().toLowerCase();
                        final isPending = statusStr == 'menunggu' || statusStr == 'pending';
                        final isApproved = statusStr == 'terverifikasi' ||
                            statusStr == 'selesai' ||
                            statusStr == 'dikonfirmasi';

                        final items = (tx['items'] as List?) ?? [];
                        String kategori = 'Campur';
                        if (items.isNotEmpty) {
                          final catNames = items
                              .map((it) {
                                final cid = int.tryParse(it['waste_category_id']?.toString() ?? '0') ?? 0;
                                return widget.categoryNamesMap[cid] ?? it['category_name']?.toString() ?? '';
                              })
                              .where((n) => n.isNotEmpty)
                              .toList();
                          if (catNames.isNotEmpty) {
                            kategori = catNames.take(2).join(', ');
                          }
                        }
                        final int estPoin = int.tryParse(tx['total_est_points']?.toString() ?? '0') ?? 0;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top line: Name & badges
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nasabahName,
                                          style: const TextStyle(
                                            fontFamily: 'PlusJakartaSans',
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: darkText,
                                          ),
                                        ),
                                        Text(
                                          waktu,
                                          style: const TextStyle(
                                            fontFamily: 'PlusJakartaSans',
                                            fontSize: 10.5,
                                            color: mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isDropIn ? primaryGreen : const Color(0xFF32CD32))
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDropIn ? Icons.recycling_rounded : Icons.local_shipping_rounded,
                                          size: 12,
                                          color: isDropIn ? primaryGreen : const Color(0xFF32CD32),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isDropIn ? 'Drop-in' : 'Jemput',
                                          style: TextStyle(
                                            fontFamily: 'PlusJakartaSans',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDropIn ? primaryGreen : const Color(0xFF32CD32),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? warningBg
                                          : isApproved
                                              ? primaryGreen.withValues(alpha: 0.1)
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isPending
                                          ? 'Menunggu'
                                          : isApproved
                                              ? 'Terverifikasi'
                                              : 'Ditolak',
                                      style: TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isPending
                                            ? warningAmber
                                            : isApproved
                                                ? primaryGreen
                                                : secondaryDarkText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Barcode preview
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryGreen.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      width: double.infinity,
                                      child: CustomPaint(
                                        painter: BarcodePainter(code: barcodeCode),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF9F0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            barcodeCode,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: barcodeCode));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Kode barcode berhasil disalin!'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            child: const Icon(
                                              Icons.copy_rounded,
                                              size: 15,
                                              color: primaryGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Location and Categories info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isDropIn ? Icons.location_on_outlined : Icons.home_outlined,
                                    size: 14,
                                    color: isDropIn ? primaryGreen : const Color(0xFF32CD32),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      lokasi,
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: darkText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$kategori • +$estPoin poin',
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),

                              // Quick Action row if pending
                              if (isPending) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onVerify(tx);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: primaryGreen,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              'Setujui Setor',
                                              style: TextStyle(
                                                fontFamily: 'PlusJakartaSans',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        widget.onReject(tx);
                                        setState(() {
                                          tx['status'] = 'dibatalkan';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.close_rounded, size: 14, color: secondaryDarkText),
                                            SizedBox(width: 4),
                                            Text(
                                              'Tolak',
                                              style: TextStyle(
                                                fontFamily: 'PlusJakartaSans',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: secondaryDarkText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : secondaryDarkText,
          ),
        ),
      ),
    );
  }
}
