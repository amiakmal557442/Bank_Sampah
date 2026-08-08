import 'package:flutter/material.dart';
import 'login_page.dart';
import 'drop_in_mandiri_page.dart';
import 'transaction_service.dart';
import 'jemput_sampah_page.dart';
import 'map_location_screen.dart';
import 'session_service.dart';
import 'tukar_poin_page.dart';
import 'voucher_page.dart';
import 'edit_profile_page.dart';
import 'api_service.dart';

void main() {
  runApp(const BankSampahApp());
}

class BankSampahApp extends StatelessWidget {
  const BankSampahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Sampah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF268B07),
          primary: const Color(0xFF268B07),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await SessionService.refresh();
    await TransactionService.loadTransactions(SessionService.userId);
    if (mounted) {
      setState(() {});
    }
  }

  final List<Widget> _pages = const [
    BerandaPage(),
    MapLocationScreen(),
    Center(child: Text('Halaman Setor')),
    RiwayatPage(),
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _showSetorBottomSheet(context);
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF268B07),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Peta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.recycling_outlined),
              activeIcon: Icon(Icons.recycling_rounded),
              label: 'Setor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  void _showSetorBottomSheet(BuildContext context) {
    final animationController = BottomSheet.createAnimationController(this);
    animationController.duration = const Duration(milliseconds: 450);
    animationController.reverseDuration = const Duration(milliseconds: 350);
    animationController.drive(CurveTween(curve: Curves.easeOutCubic));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: animationController,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Pilih cara setor sampah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: Drop-in mandiri
              _buildSetorOption(
                icon: Icons.add_location_alt_outlined,
                title: 'Drop-in mandiri',
                description:
                    'Cari drop point terdekat dan antar sampah sendiri',
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DropInMandiriScreen(),
                    ),
                  );
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Jemput sampah
              _buildSetorOption(
                icon: Icons.local_shipping_outlined,
                title: 'Jemput sampah',
                description:
                    'Petugas datang ke lokasi kamu untuk mengambil sampah',
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PickupScheduleScreen(),
                    ),
                  );
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              // Tombol Batal
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetorOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    const Color primaryGreen = Color(0xFF268B07);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: primaryGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  @override
  void initState() {
    super.initState();
    _refreshPoints();
  }

  Future<void> _refreshPoints() async {
    await SessionService.refresh();
    await TransactionService.loadTransactions(SessionService.userId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF268B07);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: RefreshIndicator(
        onRefresh: _refreshPoints,
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- HEADER ATAS & KARTU POIN ---
              SizedBox(
                height: 290,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background Hijau dengan Lengkungan Atas
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 50,
                        left: 20,
                        right: 20,
                        bottom: 70,
                      ),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selamat pagi,',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                SessionService.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Tombol Notifikasi
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Positioned(
                                  top: 10,
                                  right: 11,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFD600),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kartu Poin Saya
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 115,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Poin saya',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  SessionService.pointBalance
                                      .toString()
                                      .replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (Match m) => '${m[1]}.',
                                      ),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'poin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '≈ Rp ${(SessionService.pointBalance * 10).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} · Min. tarik: 1.000 poin',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TukarPoinScreen(),
                                        ),
                                      );
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Tukar poin',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              VoucherScreen(),
                                        ),
                                      );
                                      setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.card_giftcard_outlined,
                                      size: 18,
                                      color: const Color(0xFF334155),
                                    ),
                                    label: const Text(
                                      'Voucher',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 140),

              // --- SEKSI 1: SETOR SAMPAH ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SETOR SAMPAH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Card 1: Drop-in Mandiri
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.add_location_alt_outlined,
                            title: 'Drop-in mandiri',
                            description: 'Cari & antar ke drop point terdekat',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DropInMandiriScreen(),
                                ),
                              );
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Card 2: Jemput Sampah
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.local_shipping_outlined,
                            title: 'Jemput sampah',
                            description: 'Request ke rumah atau kantor',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PickupScheduleScreen(),
                                ),
                              );
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- SEKSI 2: TRANSAKSI TERAKHIR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TRANSAKSI TERAKHIR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SemuaTransaksiPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Lihat semua',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...TransactionService.transactions.map((tx) {
                      return Column(
                        children: [
                          _buildTransactionItem(context: context, tx: tx),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- SEKSI 3: DAMPAK LINGKUNGAN SAYA ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAMPAK LINGKUNGAN SAYA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildImpactMetric(
                            value: TransactionService.totalWasteKg
                                .toStringAsFixed(1)
                                .replaceAll('.', ','),
                            unit: 'kg',
                            label: 'Total sampah\ndisetor',
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildImpactMetric(
                            value: TransactionService.co2Reduced
                                .toStringAsFixed(1)
                                .replaceAll('.', ','),
                            unit: 'kg CO₂',
                            label: 'Emisi dikurangi',
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildImpactMetric(
                            value: TransactionService.treesSaved.toString(),
                            unit: 'pohon',
                            label: 'Setara pohon\nterselamatkan',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Pembantu Card Setor Sampah
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 155,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF268B07), size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu Item Transaksi
  Widget _buildTransactionItem({
    required BuildContext context,
    required TransactionModel tx,
  }) {
    return GestureDetector(
      onTap: () {
        // Show dialog with transaction details
        showDialog(
          context: context,
          builder: (ctx) {
            String jenisSampah = 'N/A';
            if (tx.rawItems.isNotEmpty) {
              jenisSampah = tx.rawItems
                  .map((e) {
                    String? n =
                        (e['category_name'] ?? e['name'] ?? e['waste_name'])
                            as String?;
                    if (n == null || n.isEmpty) {
                      final catId = e['waste_category_id']?.toString();
                      if (catId == '1')
                        n = 'Plastik';
                      else if (catId == '2')
                        n = 'Kertas & Kardus';
                      else if (catId == '3')
                        n = 'Besi & Logam';
                      else if (catId == '4')
                        n = 'Elektronik Bekas';
                      else
                        n = 'Sampah';
                    }
                    return n;
                  })
                  .join(', ');
            } else if (tx.title.contains('-')) {
              // Extract from title if rawItems is somehow empty but title has it
              final parts = tx.title.split('-');
              if (parts.length > 1) {
                jenisSampah = parts.last.trim();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Detail Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Jenis sampah', jenisSampah),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Jumlah berat sampah',
                    '${tx.totalBerat.toStringAsFixed(1).replaceAll('.', ',')} kg',
                  ),
                  const SizedBox(height: 8),
                  _detailRow('Jumlah poin', tx.points),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Color(0xFF268B07),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tx.icon, color: const Color(0xFF268B07), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tx.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.points,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF268B07),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tx.status,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
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

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // Widget Pembantu Metrik Dampak Lingkungan
  Widget _buildImpactMetric({
    required String value,
    required String unit,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HALAMAN: SEMUA TRANSAKSI
// ============================================================================
class SemuaTransaksiPage extends StatefulWidget {
  const SemuaTransaksiPage({super.key});

  @override
  State<SemuaTransaksiPage> createState() => _SemuaTransaksiPageState();
}

class _SemuaTransaksiPageState extends State<SemuaTransaksiPage> {
  static const Color primaryGreen = Color(0xFF268B07);

  // Gabungkan semua sumber transaksi menjadi satu list
  List<TransactionModel> get _semuaTransaksi {
    final all = <TransactionModel>[];
    all.addAll(TransactionService.riwayatHariIni);
    // Tambahkan transaksi dari beranda yang belum ada di riwayatHariIni
    for (final tx in TransactionService.transactions) {
      final alreadyAdded = all.any(
        (t) =>
            t.title == tx.title &&
            t.subtitle.contains(tx.subtitle.split(',').last.trim()),
      );
      if (!alreadyAdded) all.add(tx);
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final transaksi = _semuaTransaksi;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: transaksi.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: transaksi.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tx = transaksi[index];
                return _buildItem(tx);
              },
            ),
    );
  }

  Widget _buildItem(TransactionModel tx) {
    final bool isFailed = tx.isFailed;
    final Color iconBg = isFailed
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFE8F5E9);
    final Color iconColor = isFailed ? const Color(0xFFDC2626) : primaryGreen;
    final Color pointsColor = isFailed ? const Color(0xFF94A3B8) : primaryGreen;
    final Color badgeBg = isFailed
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFDCFCE7);
    final Color badgeText = isFailed
        ? const Color(0xFFDC2626)
        : const Color(0xFF166534);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            String jenisSampah = 'N/A';
            if (tx.rawItems.isNotEmpty) {
              jenisSampah = tx.rawItems
                  .map((e) {
                    String? n =
                        (e['category_name'] ?? e['name'] ?? e['waste_name'])
                            as String?;
                    if (n == null || n.isEmpty) {
                      final catId = e['waste_category_id']?.toString();
                      if (catId == '1')
                        n = 'Plastik';
                      else if (catId == '2')
                        n = 'Kertas & Kardus';
                      else if (catId == '3')
                        n = 'Besi & Logam';
                      else if (catId == '4')
                        n = 'Elektronik Bekas';
                      else
                        n = 'Sampah';
                    }
                    return n;
                  })
                  .join(', ');
            } else if (tx.title.contains('-')) {
              final parts = tx.title.split('-');
              if (parts.length > 1) {
                jenisSampah = parts.last.trim();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Detail Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Jenis sampah', jenisSampah),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Jumlah berat sampah',
                    '${tx.totalBerat.toStringAsFixed(1).replaceAll('.', ',')} kg',
                  ),
                  const SizedBox(height: 8),
                  _detailRow('Jumlah poin', tx.points),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Color(0xFF268B07),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tx.icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tx.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.points,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: pointsColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tx.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeText,
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

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String _selectedJenis = 'Semua';
  String _selectedStatus = 'Semua';

  final Color primaryGreen = const Color(0xFF268B07);

  // Helper untuk memfilter transaksi berdasarkan Jenis Transaksi dan Status
  bool _matchesFilter({
    required String title,
    required String statusText,
    required String valueText,
    required bool isFailed,
  }) {
    final lowerTitle = title.toLowerCase();
    String jenis = 'Poin dan saldo';
    if (lowerTitle.contains('jemput') ||
        lowerTitle.contains('drop-in') ||
        lowerTitle.contains('setor') ||
        lowerTitle.contains('sampah') ||
        lowerTitle.contains('plastik') ||
        lowerTitle.contains('kardus') ||
        lowerTitle.contains('logam') ||
        lowerTitle.contains('kaca') ||
        lowerTitle.contains('elektronik')) {
      jenis = 'Setor sampah';
    }

    final lowerStatus = statusText.toLowerCase();
    final lowerValue = valueText.toLowerCase();
    String status =
        (isFailed ||
            lowerStatus == 'gagal' ||
            lowerStatus == 'dibatalkan' ||
            lowerValue == 'dibatalkan')
        ? 'Gagal'
        : 'Selesai';

    bool matchesJenis =
        (_selectedJenis == 'Semua') || (_selectedJenis == jenis);
    bool matchesStatus =
        (_selectedStatus == 'Semua') || (_selectedStatus == status);

    return matchesJenis && matchesStatus;
  }

  List<TransactionModel> get _riwayatKemarin => [
    TransactionModel(
      icon: Icons.local_shipping_outlined,
      title: 'Jemput sampah',
      subtitle: '14.30 - 2,8 kg',
      points: '+210 poin',
      status: 'Selesai',
      isFailed: false,
    ),
    TransactionModel(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Penarikan saldo ke Bank',
      subtitle: '11.05 - Rekening tidak valid',
      points: 'Rp 50.000',
      status: 'Gagal',
      isFailed: true,
    ),
    TransactionModel(
      icon: Icons.recycling_rounded,
      title: 'Drop-in — Logam dan Kaca',
      subtitle: '09.40 - 0,8 kg',
      points: '+85 poin',
      status: 'Selesai',
      isFailed: false,
    ),
  ];

  List<TransactionModel> get _riwayat22Juli => [
    TransactionModel(
      icon: Icons.card_giftcard_outlined,
      title: 'Tukar voucher belanja',
      subtitle: '18.10 - Voucher Rp 25.000',
      points: '-500 poin',
      status: 'Selesai',
      isFailed: false,
    ),
    TransactionModel(
      icon: Icons.recycling_rounded,
      title: 'Drop-in — Elektronik',
      subtitle: '16.20 - 0,5 kg',
      points: '+150 poin',
      status: 'Selesai',
      isFailed: false,
    ),
  ];

  Future<void> _refreshRiwayat() async {
    await SessionService.refresh();
    await TransactionService.loadTransactions(SessionService.userId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredHariIni = TransactionService.riwayatHariIni.where((tx) {
      return _matchesFilter(
        title: tx.title,
        statusText: tx.status,
        valueText: tx.points,
        isFailed: tx.isFailed,
      );
    }).toList();

    final filteredKemarin = _riwayatKemarin.where((tx) {
      return _matchesFilter(
        title: tx.title,
        statusText: tx.status,
        valueText: tx.points,
        isFailed: tx.isFailed,
      );
    }).toList();

    final filtered22Juli = _riwayat22Juli.where((tx) {
      return _matchesFilter(
        title: tx.title,
        statusText: tx.status,
        valueText: tx.points,
        isFailed: tx.isFailed,
      );
    }).toList();

    final bool isAllEmpty =
        filteredHariIni.isEmpty &&
        filteredKemarin.isEmpty &&
        filtered22Juli.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: RefreshIndicator(
        onRefresh: _refreshRiwayat,
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER RIWAYAT ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: const Text(
                  'Riwayat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- FILTER 1: JENIS TRANSAKSI ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JENIS TRANSAKSI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Semua',
                            isSelected: _selectedJenis == 'Semua',
                            onTap: () =>
                                setState(() => _selectedJenis = 'Semua'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Setor sampah',
                            isSelected: _selectedJenis == 'Setor sampah',
                            onTap: () => setState(() {
                              _selectedJenis =
                                  (_selectedJenis == 'Setor sampah')
                                  ? 'Semua'
                                  : 'Setor sampah';
                            }),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Poin dan saldo',
                            isSelected: _selectedJenis == 'Poin dan saldo',
                            onTap: () => setState(() {
                              _selectedJenis =
                                  (_selectedJenis == 'Poin dan saldo')
                                  ? 'Semua'
                                  : 'Poin dan saldo';
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- FILTER 2: STATUS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterChip(
                          label: 'Semua',
                          isSelected: _selectedStatus == 'Semua',
                          onTap: () =>
                              setState(() => _selectedStatus = 'Semua'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Selesai',
                          isSelected: _selectedStatus == 'Selesai',
                          onTap: () => setState(() {
                            _selectedStatus = (_selectedStatus == 'Selesai')
                                ? 'Semua'
                                : 'Selesai';
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Gagal',
                          isSelected: _selectedStatus == 'Gagal',
                          onTap: () => setState(() {
                            _selectedStatus = (_selectedStatus == 'Gagal')
                                ? 'Semua'
                                : 'Gagal';
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (isAllEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada riwayat transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tidak ditemukan transaksi dengan filter yang dipilih',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- SEKSI: HARI INI ---
              if (filteredHariIni.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HARI INI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...filteredHariIni.map((tx) {
                        return Column(
                          children: [
                            _buildRiwayatItem(context: context, tx: tx),
                            const SizedBox(height: 10),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

              if (filteredHariIni.isNotEmpty &&
                  (filteredKemarin.isNotEmpty || filtered22Juli.isNotEmpty))
                const SizedBox(height: 20),

              // --- SEKSI: KEMARIN ---
              if (filteredKemarin.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KEMARIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...filteredKemarin.map((tx) {
                        return Column(
                          children: [
                            _buildRiwayatItem(context: context, tx: tx),
                            const SizedBox(height: 10),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

              if (filteredKemarin.isNotEmpty && filtered22Juli.isNotEmpty)
                const SizedBox(height: 20),

              // --- SEKSI: 22 JULI 2026 ---
              if (filtered22Juli.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '22 JULI 2026',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...filtered22Juli.map((tx) {
                        return Column(
                          children: [
                            _buildRiwayatItem(context: context, tx: tx),
                            const SizedBox(height: 10),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Pembantu Filter Chip Interaktif
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  // Widget Pembantu Item Riwayat Transaksi
  Widget _buildRiwayatItem({
    required BuildContext context,
    required TransactionModel tx,
  }) {
    final isFailed = tx.isFailed;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            String jenisSampah = 'N/A';
            if (tx.rawItems.isNotEmpty) {
              jenisSampah = tx.rawItems
                  .map((e) {
                    String? n =
                        (e['category_name'] ?? e['name'] ?? e['waste_name'])
                            as String?;
                    if (n == null || n.isEmpty) {
                      final catId = e['waste_category_id']?.toString();
                      if (catId == '1')
                        n = 'Plastik';
                      else if (catId == '2')
                        n = 'Kertas & Kardus';
                      else if (catId == '3')
                        n = 'Besi & Logam';
                      else if (catId == '4')
                        n = 'Elektronik Bekas';
                      else
                        n = 'Sampah';
                    }
                    return n;
                  })
                  .join(', ');
            } else if (tx.title.contains('-')) {
              final parts = tx.title.split('-');
              if (parts.length > 1) {
                jenisSampah = parts.last.trim();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Detail Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Jenis sampah', jenisSampah),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Jumlah berat sampah',
                    '${tx.totalBerat.toStringAsFixed(1).replaceAll('.', ',')} kg',
                  ),
                  const SizedBox(height: 8),
                  _detailRow('Jumlah poin', tx.points),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Color(0xFF268B07),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFailed
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tx.icon,
                color: isFailed ? const Color(0xFF64748B) : primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tx.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.points,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFailed ? const Color(0xFF475569) : primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isFailed
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tx.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isFailed
                          ? const Color(0xFF475569)
                          : const Color(0xFF166534),
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

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF268B07);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER PROFIL & AVATAR ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Hijau Atas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 55,
                    left: 20,
                    right: 20,
                    bottom: 75,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profil Saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Kartu Informasi Pengguna
                Positioned(
                  left: 20,
                  right: 20,
                  top: 105,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Foto Profil dengan Badge Edit
                            GestureDetector(
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfilePage(),
                                  ),
                                );
                                if (updated == true) {
                                  setState(() {});
                                }
                              },
                              child: Stack(
                                children: [
                                  if (SessionService.profilePicture.isNotEmpty &&
                                      ApiService.getProfileImageUrl(SessionService.profilePicture) != null)
                                    CircleAvatar(
                                      radius: 34,
                                      backgroundColor: const Color(0xFFDCFCE7),
                                      child: ClipOval(
                                        child: Image.network(
                                          ApiService.getProfileImageUrl(SessionService.profilePicture)!,
                                          width: 68,
                                          height: 68,
                                          fit: BoxFit.cover,
                                          headers: const {'ngrok-skip-browser-warning': 'true'},
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              (() {
                                                final names = SessionService.fullName.split(' ');
                                                if (names.length >= 2) {
                                                  return (names[0].isNotEmpty ? names[0][0] : '') +
                                                      (names[1].isNotEmpty ? names[1][0] : '');
                                                } else if (names.isNotEmpty && names[0].isNotEmpty) {
                                                  return names[0][0];
                                                }
                                                return 'US';
                                              })().toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: primaryGreen,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 34,
                                      backgroundColor: const Color(0xFFDCFCE7),
                                      child: Text(
                                        (() {
                                          final names = SessionService.fullName
                                              .split(' ');
                                          if (names.length >= 2) {
                                            return (names[0].isNotEmpty
                                                    ? names[0][0]
                                                    : '') +
                                                (names[1].isNotEmpty
                                                    ? names[1][0]
                                                    : '');
                                          } else if (names.isNotEmpty &&
                                              names[0].isNotEmpty) {
                                            return names[0][0];
                                          }
                                          return 'US';
                                        })().toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: primaryGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        SessionService.fullName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 18,
                                        color: primaryGreen,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    SessionService.phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Badge Tingkat Keanggotaan
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.stars_rounded,
                                          size: 14,
                                          color: Color(0xFFD97706),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Nasabah Hero · Level 3',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
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
              ],
            ),

            const SizedBox(height: 110),

            // --- SEKSI 1: AKUN & ALAMAT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PENGATURAN AKUN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildProfileMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Ubah Profil',
                          subtitle: 'Nama, email, dan foto profil',
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfilePage(),
                              ),
                            );
                            if (updated == true) {
                              setState(() {});
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16),
                        _buildProfileMenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Alamat Penjemputan',
                          subtitle: 'Rumah, kantor, atau lokasi pilihan',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16),
                        _buildProfileMenuItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Rekening & E-Wallet',
                          subtitle: 'Pilihan pencairan saldo poin',
                          badgeText: 'GoPay / BCA',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- SEKSI 3: BANTUAN & KEAMANAN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAINNYA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildProfileMenuItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Pusat Bantuan & FAQ',
                          subtitle: 'Pertanyaan umum & panduan aplikasi',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16),
                        _buildProfileMenuItem(
                          icon: Icons.shield_outlined,
                          title: 'Syarat & Kebijakan Privasi',
                          subtitle: 'Ketentuan penggunaan data',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await SessionService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  label: const Text(
                    'Keluar Akun',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Bank Sampah Mobile v1.2.0',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu Baris Menu Profil
  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF334155), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor ?? const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
        ],
      ),
    );
  }
}
