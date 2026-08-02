import 'package:flutter/material.dart';

// ============================================================================
// Halaman Master Data — Admin Dashboard (Desktop/Web)
// Berdasarkan SRS 3.3.1 Manajemen Master Data:
//   FR-AD-01 — Kelola kategori sampah & harga/poin per kg
//   FR-AD-02 — Kelola lokasi drop point (tambah, edit, jam operasional)
//   FR-AD-03 — Kelola akun user/petugas/staf beserta role & permission
//
// Catatan: halaman ini didesain untuk layar desktop (sesuai SRS 2.1 —
// dashboard web admin/staf), bukan mobile. Konsisten dengan RBAC: akses
// halaman ini hanya untuk role Admin (Staf Kantor tidak bisa masuk ke sini).
// ============================================================================

const Color primaryGreen = Color(0xFF268B07);
const Color limeGreen = Color(0xFF32CD32);
const Color pageBackground = Color(0xFFF5F6F8);
const Color darkText = Color(0xFF0F172A);
const Color subtleText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);
const Color borderColor = Color(0xFFE2E8F0);
const Color secondaryDarkText = Color(0xFF334155);

// --------------------------------------------------------------------------
// MODELS
// --------------------------------------------------------------------------

class WasteCategoryModel {
  final String name;
  final int pointsPerKg;
  final bool isActive;
  IconData icon;

  WasteCategoryModel({
    required this.name,
    required this.pointsPerKg,
    required this.isActive,
    required this.icon,
  });
}

class DropPointModel {
  final String name;
  final String address;
  final String operatingHours;
  final int capacityPercent;
  final bool isActive;

  DropPointModel({
    required this.name,
    required this.address,
    required this.operatingHours,
    required this.capacityPercent,
    required this.isActive,
  });
}

enum UserRole { admin, stafKantor, petugas, endUser }

class AccountModel {
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;

  AccountModel({
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });
}

// Sample data
final List<WasteCategoryModel> sampleCategories = [
  WasteCategoryModel(name: 'Plastik', pointsPerKg: 100, isActive: true, icon: Icons.local_drink_rounded),
  WasteCategoryModel(name: 'Kertas', pointsPerKg: 80, isActive: true, icon: Icons.description_rounded),
  WasteCategoryModel(name: 'Kardus', pointsPerKg: 70, isActive: true, icon: Icons.inventory_2_rounded),
  WasteCategoryModel(name: 'Logam', pointsPerKg: 250, isActive: true, icon: Icons.build_rounded),
  WasteCategoryModel(name: 'Kaca', pointsPerKg: 60, isActive: true, icon: Icons.wine_bar_rounded),
  WasteCategoryModel(name: 'Elektronik', pointsPerKg: 400, isActive: false, icon: Icons.devices_rounded),
];

final List<DropPointModel> sampleDropPoints = [
  DropPointModel(name: 'Drop Point Margonda', address: 'Jl. Margonda Raya No. 12, Depok', operatingHours: '08.00–17.00', capacityPercent: 92, isActive: true),
  DropPointModel(name: 'Waste Station Beji', address: 'Jl. Kartini No. 5, Beji, Depok', operatingHours: '07.00–16.00', capacityPercent: 88, isActive: true),
  DropPointModel(name: 'Drop Point Kemang Pratama', address: 'Jl. Kemang Raya No. 3, Depok', operatingHours: '08.00–18.00', capacityPercent: 31, isActive: true),
];

final List<AccountModel> sampleAccounts = [
  AccountModel(name: 'Siti Admin', email: 'siti.admin@banksampah.id', role: UserRole.admin, isActive: true),
  AccountModel(name: 'Andi Wijaya', email: 'andi.wijaya@banksampah.id', role: UserRole.stafKantor, isActive: true),
  AccountModel(name: 'Dedi Kurniawan', email: 'dedi.k@banksampah.id', role: UserRole.petugas, isActive: true),
  AccountModel(name: 'Rina Marlina', email: 'rina.m@banksampah.id', role: UserRole.stafKantor, isActive: false),
];

// --------------------------------------------------------------------------
// MAIN SCREEN
// --------------------------------------------------------------------------

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = ['Kategori Sampah', 'Drop Point', 'Kelola Akun & Role'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _addButtonLabel {
    switch (_tabController.index) {
      case 0:
        return 'Tambah Kategori';
      case 1:
        return 'Tambah Drop Point';
      default:
        return 'Tambah Akun';
    }
  }

  // ------------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Master Data',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'FR-AD-01 · FR-AD-02 · FR-AD-03 — kategori sampah, drop point, dan akun pengguna',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: subtleText,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: buka form tambah sesuai tab aktif
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(_addButtonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SHARED TABLE HELPERS
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

  Widget _statusBadge(bool isActive, {String? activeLabel, String? inactiveLabel}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F8E8) : const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? (activeLabel ?? 'Aktif') : (inactiveLabel ?? 'Nonaktif'),
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isActive ? primaryGreen : const Color(0xFF5F5E5A),
        ),
      ),
    );
  }

  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _iconActionButton(Icons.edit_outlined, () {
          // TODO: buka form edit
        }),
        const SizedBox(width: 6),
        _iconActionButton(Icons.delete_outline_rounded, () {
          // TODO: konfirmasi hapus
        }, isDestructive: true),
      ],
    );
  }

  Widget _iconActionButton(IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: pageBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(
          icon,
          size: 15,
          color: isDestructive ? secondaryDarkText : subtleText,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 1: KATEGORI SAMPAH (FR-AD-01)
  // ------------------------------------------------------------------------

  Widget _buildKategoriSampahTab() {
    return SingleChildScrollView(
      child: _tableContainer(
        children: [
          _tableHeaderRow(
            ['Kategori', 'Poin per kg', 'Status', 'Aksi'],
            [3, 2, 2, 2],
          ),
          ...sampleCategories.map((cat) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(cat.icon, size: 15, color: primaryGreen),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cat.name,
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
                        '${cat.pointsPerKg} poin/kg',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    Expanded(flex: 2, child: _statusBadge(cat.isActive)),
                    Expanded(flex: 2, child: _actionButtons()),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 2: DROP POINT (FR-AD-02)
  // ------------------------------------------------------------------------

  Widget _buildDropPointTab() {
    return SingleChildScrollView(
      child: _tableContainer(
        children: [
          _tableHeaderRow(
            ['Nama Lokasi', 'Alamat', 'Jam Operasional', 'Kapasitas', 'Status', 'Aksi'],
            [2, 3, 2, 2, 1, 2],
          ),
          ...sampleDropPoints.map((dp) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dp.name,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        dp.address,
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
                        dp.operatingHours,
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
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: dp.capacityPercent / 100,
                                minHeight: 5,
                                backgroundColor: pageBackground,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  dp.capacityPercent > 85 ? primaryGreen : limeGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${dp.capacityPercent}%',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(flex: 1, child: _statusBadge(dp.isActive, activeLabel: 'Buka', inactiveLabel: 'Tutup')),
                    Expanded(flex: 2, child: _actionButtons()),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 3: KELOLA AKUN & ROLE (FR-AD-03)
  // ------------------------------------------------------------------------

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.stafKantor:
        return 'Staf Kantor';
      case UserRole.petugas:
        return 'Petugas Lapangan';
      case UserRole.endUser:
        return 'End User';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return primaryGreen;
      case UserRole.stafKantor:
        return const Color(0xFF5F8A4A);
      case UserRole.petugas:
        return const Color(0xFF64748B);
      case UserRole.endUser:
        return mutedText;
    }
  }

  Widget _buildKelolaAkunTab() {
    return SingleChildScrollView(
      child: _tableContainer(
        children: [
          _tableHeaderRow(
            ['Nama', 'Email', 'Role', 'Status', 'Aksi'],
            [2, 3, 2, 1, 2],
          ),
          ...sampleAccounts.map((acc) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F8E8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                acc.name.substring(0, 1),
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              acc.name,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        acc.email,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: subtleText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _roleColor(acc.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _roleLabel(acc.role),
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _roleColor(acc.role),
                          ),
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: _statusBadge(acc.isActive)),
                    Expanded(flex: 2, child: _actionButtons()),
                  ],
                ),
              )),
        ],
      ),
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
                _buildKategoriSampahTab(),
                _buildDropPointTab(),
                _buildKelolaAkunTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
