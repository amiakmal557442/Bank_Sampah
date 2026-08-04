import 'package:flutter/material.dart';
import 'session_service.dart';
import 'masterdata.dart';
import 'manajemen_transaksi.dart';
import 'operasional_lapangan.dart';
import 'laporan_analitik.dart';
import 'kelolaakun.dart';
import 'konfigurasi_sistem.dart';
import 'audit_log.dart';
import 'login_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Palet Warna Utama
  final Color oldGrassGreen = const Color(0xFF268B07);
  final Color limeGreen = const Color(0xFF32CD32);
  final Color baseBlack = const Color(0xFF000000);
  final Color baseWhite = const Color(0xFFFFFFFF);
  final Color textGrey = const Color(0xFF5F6368);
  final Color borderGrey = const Color(0xFFE0E0E0);

  int _selectedMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String adminName = SessionService.fullName.isNotEmpty
        ? SessionService.fullName
        : 'Siti Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 1200,
                maxHeight: constraints.maxHeight - 48, // account for margin
              ),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: baseWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: baseBlack.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==================== SIDEBAR KIRI ====================
                    SizedBox(
                      width: 260,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: borderGrey, width: 1),
                          ),
                        ),
                        child: Column(
                          children: [
                            // 1. Logo (tetap di atas)
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: oldGrassGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.recycling,
                                      color: baseWhite,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Bank Sampah',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: baseBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 2. Menu (scrollable area)
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildMenuItem(
                                    Icons.grid_view,
                                    'Overview',
                                    index: 0,
                                  ),
                                  _buildMenuItem(
                                    Icons.dns_outlined,
                                    'Master data',
                                    index: 1,
                                  ),
                                  _buildMenuItem(
                                    Icons.receipt_long_outlined,
                                    'Manajemen transaksi',
                                    index: 2,
                                  ),
                                  _buildMenuItem(
                                    Icons.local_shipping_outlined,
                                    'Operasional lapangan',
                                    index: 3,
                                  ),
                                  _buildMenuItem(
                                    Icons.bar_chart_outlined,
                                    'Laporan & analitik',
                                    index: 4,
                                  ),
                                  _buildMenuItem(
                                    Icons.settings_outlined,
                                    'Konfigurasi sistem',
                                    index: 5,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    child: Divider(color: borderGrey),
                                  ),
                                  _buildMenuItem(
                                    Icons.people_outline,
                                    'Kelola akun & role',
                                    index: 6,
                                  ),
                                  _buildMenuItem(
                                    Icons.security_outlined,
                                    'Audit log',
                                    index: 7,
                                  ),
                                ],
                              ),
                            ),

                            // 3. Profil Bawah (tetap di bawah)
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: borderGrey, width: 1),
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: oldGrassGreen,
                                    radius: 20,
                                    child: Text(
                                      adminName
                                          .split(' ')
                                          .map((e) => e.isNotEmpty ? e[0] : '')
                                          .take(2)
                                          .join(),
                                      style: TextStyle(
                                        color: baseWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          adminName,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: baseBlack,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: oldGrassGreen,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Administrator',
                                            style: TextStyle(
                                              color: baseWhite,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Keluar (Logout)',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          SessionService.logout();
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (ctx) => const LoginPage(),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.logout_rounded,
                                            color: Colors.red.shade400,
                                            size: 22,
                                          ),
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
                    ),

                    // ==================== KONTEN UTAMA KANAN ====================
                    Expanded(
                      child: _selectedMenuIndex == 1
                          ? const MasterDataScreen()
                          : _selectedMenuIndex == 2
                          ? const ManajemenTransaksiScreen()
                          : _selectedMenuIndex == 3
                          ? const OperasionalLapanganScreen()
                          : _selectedMenuIndex == 4
                          ? const LaporanAnalitikScreen()
                          : _selectedMenuIndex == 5
                          ? const KonfigurasiSistemScreen()
                          : _selectedMenuIndex == 6
                          ? const KelolaAkunRoleScreen()
                          : _selectedMenuIndex == 7
                          ? const AuditLogScreen()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Section
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  'Halo, $adminName ',
                                                  style: TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: baseBlack,
                                                  ),
                                                ),
                                                const Text(
                                                  '👋',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Sebagai Administrator, kamu punya akses penuh ke seluruh modul sistem — termasuk konfigurasi harga poin, kelola akun & role, serta audit log yang tidak bisa diakses Staf Kantor.',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: textGrey,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: borderGrey),
                                        ),
                                        child: Icon(
                                          Icons.more_horiz,
                                          color: textGrey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  // Grid Cards (2x2)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPrivilegeCard(
                                          Icons.lock_outline,
                                          'Master data & konfigurasi sistem',
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildPrivilegeCard(
                                          Icons.lock_outline,
                                          'Kelola akun, role &\npermission',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPrivilegeCard(
                                          Icons.lock_outline,
                                          'Operasional lapangan & rute petugas',
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildPrivilegeCard(
                                          Icons.lock_outline,
                                          'Audit log seluruh sistem',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget untuk Item Menu Sidebar
  Widget _buildMenuItem(IconData icon, String title, {required int index}) {
    final bool isActive = _selectedMenuIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMenuIndex = index;
        });
      },
      child: Container(
        color: isActive
            ? oldGrassGreen.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            // Indikator aktif (Garis hijau di kiri)
            Container(
              width: 4,
              height: 48,
              color: isActive ? oldGrassGreen : Colors.transparent,
            ),
            const SizedBox(width: 20),
            Icon(icon, color: isActive ? oldGrassGreen : textGrey, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isActive ? oldGrassGreen : textGrey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk Kartu Hak Akses Administrator
  Widget _buildPrivilegeCard(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: limeGreen.withValues(
          alpha: 0.05,
        ), // Latar belakang hijau sangat tipis
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: limeGreen.withValues(alpha: 0.2), // Border hijau tipis
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: oldGrassGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: baseBlack,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
