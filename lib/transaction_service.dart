import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'api_service.dart';

class TransactionModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final String points;
  final String status;
  final bool isFailed;
  final List<dynamic> rawItems;
  final double totalBerat;
  final int totalPoin;

  TransactionModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.status,
    this.isFailed = false,
    this.rawItems = const [],
    this.totalBerat = 0.0,
    this.totalPoin = 0,
  });
}

class TransactionService {
  static int userPoints = 4820;
  static double totalWasteKg = 48.5;
  static double get co2Reduced => totalWasteKg * 0.25;
  static int get treesSaved => (totalWasteKg / 16).round();

  static List<TransactionModel> transactions = [];

  static List<TransactionModel> riwayatHariIni = [];

  static void addTransaction({
    required String title,
    double weight = 0.0,
    int points = 0,
    required String type, // 'Drop-in' atau 'Jemput'
  }) {
    userPoints += points;
    totalWasteKg += weight;

    String finalTitle = '$type — $title';
    String pointsText = points > 0 ? '+$points poin' : 'Menunggu Penimbangan';

    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final weightStr = weight > 0
        ? ' · ${weight.toStringAsFixed(1).replaceAll('.', ',')} kg'
        : '';
    String subtitle = 'Hari ini, $hour.$minute$weightStr';

    final newTx = TransactionModel(
      icon: type == 'Drop-in'
          ? Icons.recycling_rounded
          : Icons.local_shipping_rounded,
      title: finalTitle,
      subtitle: subtitle,
      points: pointsText,
      status: 'Proses',
      totalBerat: weight,
      totalPoin: points,
    );

    // Insert at front of beranda transactions list
    transactions.insert(0, newTx);

    // Also insert at front of riwayat list
    final newRiwayatTx = TransactionModel(
      icon: type == 'Drop-in'
          ? Icons.recycling_rounded
          : Icons.local_shipping_outlined,
      title: finalTitle,
      subtitle:
          '$hour.$minute${weightStr.isNotEmpty ? weightStr : ' - Menunggu'}',
      points: pointsText,
      status: 'Proses',
      isFailed: false,
    );
    riwayatHariIni.insert(0, newRiwayatTx);
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr.startsWith('0000')) {
      return 'Hari ini';
    }
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final days = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final dayName = days[dt.weekday];
      final monthName = months[dt.month];
      return '$dayName, ${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  static Future<void> loadTransactions(String nasabahId) async {
    List<Map<String, dynamic>> txs = [];
    try {
      txs = await ApiService.instance.getTransactions(nasabahId: nasabahId);
    } catch (_) {}

    if (txs.isEmpty) {
      txs = await DatabaseHelper.instance.getUserTransactions(nasabahId);
    }

    List<Map<String, dynamic>> userWds = [];
    try {
      final wds = await ApiService.instance.fetchWithdrawals();
      userWds = wds.where((w) => w['nasabah_id'] == nasabahId).toList();
    } catch (_) {}
    if (userWds.isEmpty) {
      final localWds = await DatabaseHelper.instance.getWithdrawals();
      userWds = localWds.where((w) => w['nasabah_id'] == nasabahId).toList();
    }

    List<Map<String, dynamic>> combinedRaw = [...txs, ...userWds];
    combinedRaw.sort((a, b) {
      String dateA = a['created_at'] ?? a['pickup_date'] ?? '';
      String dateB = b['created_at'] ?? b['pickup_date'] ?? '';
      return dateB.compareTo(dateA);
    });

    final List<TransactionModel> newTxs = [];

    for (var tx in combinedRaw) {
      final isWithdrawal = tx.containsKey('points_deducted');
      
      if (isWithdrawal) {
         final method = tx['method']?.toString() ?? 'Tarik Saldo';
         final isTukarBarang = method == 'tukar_barang';
         final details = tx['account_details']?.toString() ?? '';
         
         String status = tx['status'] ?? 'pending';
         String st = 'Proses';
         if (status == 'approved' || status == 'selesai') st = 'Selesai';
         if (status == 'rejected') st = 'Gagal';
         
         String title = isTukarBarang ? 'Tukar Sembako' : 'Penarikan Poin';
         if (details.isNotEmpty) title += ' ($details)';
         
         String rawDate = tx['created_at'] ?? '';
         final dateStr = formatDate(rawDate);
         
         final points = (tx['points_deducted'] ?? 0) as int;
         String pointsText = points > 0 ? '-$points poin' : '0 poin';
         if (status == 'pending') {
             pointsText = '0 poin (Proses)';
         }
         
         newTxs.add(
           TransactionModel(
             icon: isTukarBarang ? Icons.card_giftcard_outlined : Icons.account_balance_wallet_outlined,
             title: title,
             subtitle: dateStr,
             points: pointsText,
             status: st,
             rawItems: [],
             totalBerat: 0.0,
             totalPoin: -points,
           )
         );
      } else {
         final type = tx['type'] == 'drop_in' ? 'Drop-in' : 'Jemput sampah';
         final status = tx['status'];

         String title = type;
         final items = tx['items'] as List<dynamic>?;
         if (items != null && items.isNotEmpty) {
           final itemNames = items
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
           title = '$type - $itemNames';
         } else if (status != 'selesai') {
           title = '$type — (Belum ditimbang)';
         }

         String rawDate = tx['pickup_date'] ?? '';
         if (rawDate.isEmpty || rawDate.startsWith('0000')) {
           rawDate = tx['created_at'] ?? '';
         }
         final dateStr = formatDate(rawDate);

         // Calculate points or subtitle
         final points = (tx['total_actual_points'] ?? 0) as int;
         String pointsText = points > 0
             ? '+$points poin'
             : (status == 'menunggu' ? 'Menunggu' : '0 poin');

         newTxs.add(
           TransactionModel(
             icon: tx['type'] == 'drop_in'
                 ? Icons.recycling_rounded
                 : Icons.local_shipping_rounded,
             title: title,
             subtitle: dateStr,
             points: pointsText,
             status: status == 'menunggu'
                 ? 'Proses'
                 : status == 'selesai'
                 ? 'Selesai'
                 : status == 'menuju_lokasi'
                 ? 'Sedang menjemput'
                 : status,
             rawItems: items ?? [],
             totalBerat: items?.fold<double>(
                   0.0,
                   (sum, e) => sum + ((e['actual_weight'] ?? e['estimated_weight'] ?? 0.0) as num).toDouble(),
                 ) ??
                 0.0,
             totalPoin: points,
           ),
         );
      }
    }

    if (newTxs.isNotEmpty) {
      transactions = newTxs.take(3).toList();
      riwayatHariIni = newTxs;
    } else {
      transactions = [];
      riwayatHariIni = [];
    }
  }
}
