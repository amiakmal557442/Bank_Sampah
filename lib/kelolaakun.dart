import 'package:flutter/material.dart';

// ============================================================================
// Halaman Kelola Akun & Role — Admin Dashboard (Desktop/Web)
// Berdasarkan SRS:
//   FR-AD-03 — Mengelola akun pengguna, petugas, dan staf beserta role &
//              permission masing-masing.
//   FR-SH-05 — Autentikasi multi-role dengan hak akses (permission) berbeda
//              untuk setiap peran pengguna.
//
// CATATAN DESAIN (SRS 2.2): "petugas lapangan mobile dengan mode kerja
// khusus, staf kantor web-only" — karena itu, matriks permission di
// halaman ini HANYA relevan untuk Admin & Staf Kantor (sama-sama pengguna
// dashboard web). Petugas Lapangan diatur lewat app mobile terpisah,
// bukan lewat matriks ini — ditampilkan sebagai info, bukan kolom aktif.
//
// RBAC: halaman ini admin-only, sama seperti Master Data.
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

enum UserRole { admin, stafKantor, petugas, endUser }

class AccountModel {
  final String name;
  final String email;
  final UserRole role;
  final String platform;
  final bool isActive;

  AccountModel({
    required this.name,
    required this.email,
    required this.role,
    required this.platform,
    required this.isActive,
  });
}

class PermissionModule {
  final String name;
  final IconData icon;
  bool adminAccess; // Admin selalu true & terkunci (full access tetap)
  bool stafAccess; // Bisa diubah admin

  PermissionModule({
    required this.name,
    required this.icon,
    this.adminAccess = true,
    required this.stafAccess,
  });
}

final List<AccountModel> sampleAccounts = [
  AccountModel(name: 'Siti Admin', email: 'siti.admin@banksampah.id', role: UserRole.admin, platform: 'Web', isActive: true),
  AccountModel(name: 'Andi Wijaya', email: 'andi.wijaya@banksampah.id', role: UserRole.stafKantor, platform: 'Web', isActive: true),
  AccountModel(name: 'Rina Marlina', email: 'rina.m@banksampah.id', role: UserRole.stafKantor, platform: 'Web', isActive: false),
  AccountModel(name: 'Dedi Kurniawan', email: 'dedi.k@banksampah.id', role: UserRole.petugas, platform: 'Mobile (app terpisah)', isActive: true),
  AccountModel(name: 'Budi Santoso', email: 'budi.s@gmail.com', role: UserRole.endUser, platform: 'Mobile', isActive: true),
];

final List<PermissionModule> permissionModules = [
  PermissionModule(name: 'Overview', icon: Icons.dashboard_rounded, stafAccess: true),
  PermissionModule(name: 'Master Data', icon: Icons.storage_rounded, stafAccess: false),
  PermissionModule(name: 'Manajemen Transaksi', icon: Icons.receipt_long_rounded, stafAccess: true),
  PermissionModule(name: 'Operasional Lapangan', icon: Icons.local_shipping_rounded, stafAccess: false),
  PermissionModule(name: 'Laporan & Analitik', icon: Icons.bar_chart_rounded, stafAccess: false),
  PermissionModule(name: 'Konfigurasi Sistem', icon: Icons.settings_rounded, stafAccess: false),
  PermissionModule(name: 'Kelola Akun & Role', icon: Icons.people_rounded, stafAccess: false),
  PermissionModule(name: 'Audit Log', icon: Icons.shield_rounded, stafAccess: false),
];

// --------------------------------------------------------------------------
// MAIN SCREEN
// --------------------------------------------------------------------------

class KelolaAkunRoleScreen extends StatefulWidget {
  const KelolaAkunRoleScreen({super.key});

  @override
  State<KelolaAkunRoleScreen> createState() => _KelolaAkunRoleScreenState();
}

class _KelolaAkunRoleScreenState extends State<KelolaAkunRoleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserRole? filterRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AccountModel> get _filteredAccounts {
    if (filterRole == null) return sampleAccounts;
    return sampleAccounts.where((a) => a.role == filterRole).toList();
  }

  // ------------------------------------------------------------------------
  // HEADER & TABS
  // ------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Akun & Role',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'FR-AD-03 · FR-SH-05 — kelola akun & atur permission tiap role',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: subtleText,
                ),
              ),
            ],
          ),
          if (_tabController.index == 0)
            ElevatedButton.icon(
              onPressed: () {
                // TODO: buka form tambah akun
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tambah Akun'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          tabs: const [
            Tab(text: 'Daftar Akun'),
            Tab(text: 'Role & Permission'),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SHARED HELPERS
  // ------------------------------------------------------------------------

  Widget _cardContainer({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(28, 16, 28, 24),
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
      child: child,
    );
  }

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

  // ------------------------------------------------------------------------
  // TAB 1: DAFTAR AKUN
  // ------------------------------------------------------------------------

  Widget _roleFilterChip(String label, UserRole? role) {
    final isSelected = filterRole == role;
    return GestureDetector(
      onTap: () => setState(() => filterRole = role),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : secondaryDarkText,
          ),
        ),
      ),
    );
  }

  Widget _buildDaftarAkunTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: Row(
              children: [
                _roleFilterChip('Semua', null),
                _roleFilterChip('Administrator', UserRole.admin),
                _roleFilterChip('Staf Kantor', UserRole.stafKantor),
                _roleFilterChip('Petugas Lapangan', UserRole.petugas),
                _roleFilterChip('End User', UserRole.endUser),
              ],
            ),
          ),
          _cardContainer(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Nama', style: _headerStyle)),
                      Expanded(flex: 3, child: Text('Email', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('Role', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('Platform', style: _headerStyle)),
                      Expanded(flex: 1, child: Text('Status', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('Aksi', style: _headerStyle)),
                    ],
                  ),
                ),
                ..._filteredAccounts.map((acc) => Container(
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
                          Expanded(
                            flex: 2,
                            child: Text(
                              acc.platform,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: mutedText,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: acc.isActive ? const Color(0xFFE8F8E8) : const Color(0xFFF1EFE8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                acc.isActive ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: acc.isActive ? primaryGreen : const Color(0xFF5F5E5A),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                _iconBtn(Icons.edit_outlined),
                                const SizedBox(width: 6),
                                _iconBtn(Icons.block_rounded),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return GestureDetector(
      onTap: () {
        // TODO: implementasi aksi
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: pageBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(icon, size: 15, color: subtleText),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 2: ROLE & PERMISSION MATRIX
  // ------------------------------------------------------------------------

  Widget _buildRolePermissionTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner tentang Petugas Lapangan
          Container(
            margin: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: limeGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: limeGreen.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: limeGreen.withValues(alpha: 0.9), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Matriks ini hanya berlaku untuk pengguna dashboard web (Admin & Staf Kantor). Petugas Lapangan bekerja lewat aplikasi mobile terpisah dengan mode kerja sendiri, jadi tidak diatur lewat matriks ini.',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F8A4A),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _cardContainer(
            child: Column(
              children: [
                // Header matrix
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text('Modul', style: _headerStyle)),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Column(
                            children: [
                              const Text('Admin', style: _headerStyle),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'terkunci',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Center(child: Text('Staf Kantor', style: _headerStyle)),
                      ),
                    ],
                  ),
                ),
                // Rows
                ...permissionModules.map((mod) => Container(
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
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: pageBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(mod.icon, size: 14, color: primaryGreen),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  mod.name,
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
                          const Expanded(
                            flex: 1,
                            child: Center(
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => mod.stafAccess = !mod.stafAccess);
                                },
                                child: Icon(
                                  mod.stafAccess
                                      ? Icons.check_circle_rounded
                                      : Icons.remove_circle_outline_rounded,
                                  size: 18,
                                  color: mod.stafAccess ? primaryGreen : mutedText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
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
                _buildDaftarAkunTab(),
                _buildRolePermissionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: subtleText,
  letterSpacing: 0.3,
);
