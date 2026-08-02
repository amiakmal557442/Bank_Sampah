import 'package:flutter/material.dart';
import 'transaction_service.dart';

class VoucherItem {
  final String id;
  final String title;
  final String category;
  final int points;
  final IconData icon;
  final String description;
  final String validUntil;

  const VoucherItem({
    required this.id,
    required this.title,
    required this.category,
    required this.points,
    required this.icon,
    required this.description,
    required this.validUntil,
  });
}

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  late int currentPoints;
  String selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    currentPoints = TransactionService.userPoints;
  }

  final List<VoucherItem> vouchers = const [
    VoucherItem(
      id: '1',
      title: 'Voucher Minimarket Rp 25.000',
      category: 'Belanja',
      points: 2500,
      icon: Icons.shopping_bag_outlined,
      description: 'Potongan belanja Rp 25.000 di gerai Indomaret & Alfamart.',
      validUntil: '31 Des 2026',
    ),
    VoucherItem(
      id: '2',
      title: 'Token Listrik PLN Rp 20.000',
      category: 'Tagihan',
      points: 2000,
      icon: Icons.electric_bolt_outlined,
      description: 'Voucher stroom prepaid PLN nilai nominal Rp 20.000.',
      validUntil: '15 Des 2026',
    ),
    VoucherItem(
      id: '3',
      title: 'Diskon Ojek Online Rp 15.000',
      category: 'Transport',
      points: 1500,
      icon: Icons.two_wheeler_outlined,
      description: 'Diskon perjalanan ride/car hingga Rp 15.000.',
      validUntil: '30 Nov 2026',
    ),
    VoucherItem(
      id: '4',
      title: 'Paket Data 5 GB',
      category: 'Internet',
      points: 3000,
      icon: Icons.wifi_outlined,
      description:
          'Paket data internet 5 GB berlaku 30 hari untuk semua operator.',
      validUntil: '31 Des 2026',
    ),
    VoucherItem(
      id: '5',
      title: 'Voucher Supermarket Rp 50.000',
      category: 'Belanja',
      points: 4500,
      icon: Icons.store_outlined,
      description: 'Voucher belanja supermarket hemat Rp 50.000.',
      validUntil: '20 Des 2026',
    ),
    VoucherItem(
      id: '6',
      title: 'Voucher Pulsa Rp 10.000',
      category: 'Internet',
      points: 1000,
      icon: Icons.phone_android_outlined,
      description: 'Pulsa seluler Rp 10.000 untuk Telkomsel, Indosat, XL, Tri.',
      validUntil: '31 Jan 2027',
    ),
    VoucherItem(
      id: '7',
      title: 'Voucher Kopi Kekinian Rp 20.000',
      category: 'Kuliner',
      points: 1800,
      icon: Icons.local_cafe_outlined,
      description: 'Diskon minuman favorit di Kopi Kenangan & Janji Jiwa.',
      validUntil: '10 Des 2026',
    ),
    VoucherItem(
      id: '8',
      title: 'Voucher Tiket Bioskop',
      category: 'Hiburan',
      points: 3500,
      icon: Icons.local_activity_outlined,
      description: 'Tiket nonton film reguler di XXI dan CGV.',
      validUntil: '15 Jan 2027',
    ),
  ];

  void _redeemVoucher(VoucherItem voucher) {
    if (currentPoints < voucher.points) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Poin tidak cukup untuk menukar ${voucher.title}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Konfirmasi Penukaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF268B07),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menukar poin dengan:',
                style: TextStyle(color: Colors.grey[800]),
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF268B07).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      voucher.icon,
                      color: const Color(0xFF268B07),
                      size: 28,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${voucher.points} Poin',
                            style: const TextStyle(
                              color: Color(0xFF268B07),
                              fontWeight: FontWeight.w600,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF32CD32),
                foregroundColor: const Color(0xFFFFFFFF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentPoints -= voucher.points;
                  TransactionService.userPoints = currentPoints;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voucher berhasil ditukar!'),
                    backgroundColor: Color(0xFF268B07),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Ya, Tukar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVouchers = selectedCategory == 'Semua'
        ? vouchers
        : vouchers.where((v) => v.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Tukar Voucher',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: const Color(0xFF268B07),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Points Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Color(0xFF268B07),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.0),
                  bottomRight: Radius.circular(24.0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Poin saat ini:',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _formatPoints(currentPoints),
                                  style: const TextStyle(
                                    fontSize: 26.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF268B07),
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                const Text(
                                  'poin',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '≈ Rp ${_formatPoints(currentPoints * 10)}',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF32CD32).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars,
                            color: Color(0xFF32CD32),
                            size: 32.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20.0),

            // Category Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('Semua'),
                    _buildCategoryChip('Belanja'),
                    _buildCategoryChip('Tagihan'),
                    _buildCategoryChip('Transport'),
                    _buildCategoryChip('Internet'),
                    _buildCategoryChip('Kuliner'),
                    _buildCategoryChip('Hiburan'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Katalog Voucher',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF268B07),
                    ),
                  ),
                  Text(
                    '${filteredVouchers.length} Tersedia',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12.0),

            // Voucher List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredVouchers.length,
              itemBuilder: (context, index) {
                final voucher = filteredVouchers[index];
                return _buildVoucherCard(voucher);
              },
            ),

            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String categoryName) {
    final isSelected = selectedCategory == categoryName;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(categoryName),
        selected: isSelected,
        selectedColor: const Color(0xFF268B07),
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFFFFFFF) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.0,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              selectedCategory = categoryName;
            });
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: isSelected ? const Color(0xFF268B07) : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(VoucherItem voucher) {
    final bool canAfford = currentPoints >= voucher.points;

    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Voucher Icon Box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF268B07).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                voucher.icon,
                color: const Color(0xFF268B07),
                size: 26,
              ),
            ),
            const SizedBox(width: 14.0),

            // Voucher Title & Point Cost
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.title,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Membutuhkan: ${_formatPoints(voucher.points)} Poin',
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF268B07),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Berlaku s/d ${voucher.validUntil}',
                    style: TextStyle(fontSize: 11.0, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),

            // Redeem Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford
                    ? const Color(0xFF32CD32)
                    : Colors.grey[300],
                foregroundColor: const Color(0xFFFFFFFF),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () => _redeemVoucher(voucher),
              child: const Text(
                'Tukar',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoints(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
