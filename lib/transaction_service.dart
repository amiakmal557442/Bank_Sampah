import 'package:flutter/material.dart';
import 'db_helper.dart';

class TransactionModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final String points;
  final String status;
  final bool isFailed;

  TransactionModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.status,
    this.isFailed = false,
  });
}

class TransactionService {
  static int userPoints = 4820;
  static double totalWasteKg = 48.5;
  static double get co2Reduced => totalWasteKg * 0.25;
  static int get treesSaved => (totalWasteKg / 16).round();

  static List<TransactionModel> transactions = [
    TransactionModel(
      icon: Icons.recycling_rounded,
      title: 'Drop-in — Plastik dan Kardus',
      subtitle: 'Hari ini, 08.15 · 1,2 kg',
      points: '+120 poin',
      status: 'Selesai',
    ),
    TransactionModel(
      icon: Icons.local_shipping_rounded,
      title: 'Jemput sampah',
      subtitle: 'Kemarin, 14.30 · 2,8 kg',
      points: '+210 poin',
      status: 'Selesai',
    ),
    TransactionModel(
      icon: Icons.recycling_rounded,
      title: 'Drop-in — Logam dan Kaca',
      subtitle: '22 Jul · 0,8 kg',
      points: '+85 poin',
      status: 'Selesai',
    ),
  ];

  static List<TransactionModel> riwayatHariIni = [
    TransactionModel(
      icon: Icons.local_shipping_outlined,
      title: 'Jemput sampah',
      subtitle: '10.02 - Lokasi di luar radius layanan',
      points: 'Dibatalkan',
      status: 'Gagal',
      isFailed: true,
    ),
    TransactionModel(
      icon: Icons.recycling_rounded,
      title: 'Drop-in — Plastik dan Kardus',
      subtitle: '08.15 - 1,2 kg',
      points: '+120 poin',
      status: 'Selesai',
      isFailed: false,
    ),
    TransactionModel(
      icon: Icons.swap_horiz_rounded,
      title: 'Tukar poin ke DANA',
      subtitle: '07.20 - Rp 10.000',
      points: '-1.000 poin',
      status: 'Selesai',
      isFailed: false,
    ),
  ];

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
    final weightStr = weight > 0 ? ' · ${weight.toStringAsFixed(1).replaceAll('.', ',')} kg' : '';
    String subtitle = 'Hari ini, $hour.$minute$weightStr';

    final newTx = TransactionModel(
      icon: type == 'Drop-in'
          ? Icons.recycling_rounded
          : Icons.local_shipping_rounded,
      title: finalTitle,
      subtitle: subtitle,
      points: pointsText,
      status: 'Proses',
    );

    // Insert at front of beranda transactions list
    transactions.insert(0, newTx);

    // Also insert at front of riwayat list
    final newRiwayatTx = TransactionModel(
      icon: type == 'Drop-in'
          ? Icons.recycling_rounded
          : Icons.local_shipping_outlined,
      title: finalTitle,
      subtitle: '$hour.$minute${weightStr.isNotEmpty ? weightStr : ' - Menunggu'}',
      points: pointsText,
      status: 'Proses',
      isFailed: false,
    );
    riwayatHariIni.insert(0, newRiwayatTx);
  }

  static Future<void> loadTransactions(String nasabahId) async {
    final txs = await DatabaseHelper.instance.getUserTransactions(nasabahId);
    
    final List<TransactionModel> newTxs = [];
    
    for (var tx in txs) {
      final type = tx['type'] == 'drop_in' ? 'Drop-in' : 'Jemput sampah';
      final status = tx['status'];
      final dateStr = tx['pickup_date'] ?? tx['created_at'] ?? 'Hari ini';
      
      // Calculate points or subtitle
      final points = (tx['total_actual_points'] ?? 0) as int;
      String pointsText = points > 0 ? '+$points poin' : (status == 'menunggu' ? 'Menunggu' : '0 poin');
      
      newTxs.add(TransactionModel(
        icon: tx['type'] == 'drop_in'
            ? Icons.recycling_rounded
            : Icons.local_shipping_rounded,
        title: type,
        subtitle: dateStr,
        points: pointsText,
        status: status == 'menunggu' ? 'Proses' : status == 'selesai' ? 'Selesai' : status,
      ));
    }
    
    if (newTxs.isNotEmpty) {
      transactions = newTxs.take(3).toList();
      riwayatHariIni = newTxs;
    }
  }
}
