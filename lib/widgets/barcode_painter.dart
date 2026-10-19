import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BarcodePainter extends CustomPainter {
  final String code;
  final Color color;

  BarcodePainter({this.code = 'WD-12345678', this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bytes = code.codeUnits;
    double currentX = 12.0;
    int index = 0;

    while (currentX < size.width - 12.0) {
      int val = (index < bytes.length) ? bytes[index % bytes.length] : (index * 7);
      double barW = (val % 3 == 0) ? 4.0 : ((val % 2 == 0) ? 2.0 : 3.0);
      double gap = (val % 4 == 0) ? 4.0 : 2.5;

      if (currentX + barW > size.width - 12.0) {
        barW = (size.width - 12.0) - currentX;
      }
      if (barW > 0) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 6, barW, size.height - 12),
          paint,
        );
      }
      currentX += barW + gap;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) =>
      oldDelegate.code != code || oldDelegate.color != color;
}

class BarcodeCard extends StatelessWidget {
  final String code;
  final String? subtitle;
  final double height;

  const BarcodeCard({
    super.key,
    required this.code,
    this.subtitle,
    this.height = 70,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF268B07).withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: BarcodePainter(code: code),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.2,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode barcode berhasil disalin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: Color(0xFF268B07),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void showWithdrawalBarcodeModal({
  required BuildContext context,
  required String barcodeId,
  required String method,
  required int points,
  required double amount,
  String status = 'pending',
  VoidCallback? onClosed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isPending = status == 'pending' ||
          status == 'Proses' ||
          status == 'Diproses' ||
          status == 'menunggu';

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF268B07).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFF268B07),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Barcode Penarikan Saldo',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tunjukkan barcode ini kepada kasir/admin saat pencairan uang tunai atau konfirmasi transfer DANA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            BarcodeCard(
              code: barcodeId,
              subtitle: 'ID Transaksi Penarikan',
              height: 75,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
              ),
              child: Column(
                children: [
                  _modalDetailRow('Metode Penarikan', method),
                  const SizedBox(height: 8),
                  _modalDetailRow('Poin Digunakan', '$points poin'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nominal Diterima',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Rp ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF268B07),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPending ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPending
                      ? const Color(0xFFB38600).withValues(alpha: 0.3)
                      : const Color(0xFF268B07).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                    size: 16,
                    color: isPending ? const Color(0xFFB38600) : const Color(0xFF268B07),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPending
                          ? 'Status: Menunggu verifikasi & scan barcode oleh kasir/admin'
                          : 'Status: Penarikan saldo telah disetujui (Selesai)',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPending ? const Color(0xFFB38600) : const Color(0xFF268B07),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF268B07),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (onClosed != null) {
                    onClosed();
                  }
                },
                child: const Text(
                  'Tutup & Simpan',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _modalDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    ],
  );
}

void showSetorBarcodeModal({
  required BuildContext context,
  required String barcodeId,
  required String type,
  required String nasabahName,
  required String lokasi,
  String? waktu,
  String status = 'menunggu',
  String kategori = 'Campur',
  int estimasiPoin = 0,
  VoidCallback? onApproved,
  VoidCallback? onRejected,
  VoidCallback? onClosed,
}) {
  final isDropIn = type.toLowerCase().contains('drop');
  final typeLabel = isDropIn ? 'Drop-in Mandiri' : 'Jemput Sampah';
  final typeColor = isDropIn ? const Color(0xFF268B07) : const Color(0xFF16A34A);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isPending = status.toLowerCase() == 'menunggu' || status.toLowerCase() == 'pending';
      final isApproved = status.toLowerCase() == 'terverifikasi' ||
          status.toLowerCase() == 'selesai' ||
          status.toLowerCase() == 'dikonfirmasi' ||
          status.toLowerCase() == 'approved';

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDropIn ? Icons.recycling_rounded : Icons.local_shipping_rounded,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Barcode Bukti Setor ($typeLabel)',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isDropIn
                  ? 'Tunjukkan barcode ini kepada petugas drop point untuk verifikasi setor sampah.'
                  : 'Tunjukkan barcode ini kepada petugas kurir saat penjemputan sampah kamu.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            BarcodeCard(
              code: barcodeId,
              subtitle: 'Kode Bukti Setor',
              height: 75,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
              ),
              child: Column(
                children: [
                  _modalDetailRow('Nama Nasabah', nasabahName),
                  const SizedBox(height: 8),
                  _modalDetailRow('Jenis Layanan', typeLabel),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lokasi',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          lokasi.isNotEmpty ? lokasi : '-',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (waktu != null && waktu.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _modalDetailRow('Waktu / Jadwal', waktu),
                  ],
                  const SizedBox(height: 8),
                  _modalDetailRow('Kategori', kategori),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimasi Poin',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '+$estimasiPoin poin',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFFFFBEB)
                    : isApproved
                        ? const Color(0xFFEFF9F0)
                        : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPending
                      ? const Color(0xFFFDE68A)
                      : isApproved
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPending
                        ? Icons.hourglass_top_rounded
                        : isApproved
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                    size: 16,
                    color: isPending
                        ? const Color(0xFFD97706)
                        : isApproved
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPending
                          ? 'Status: Menunggu verifikasi petugas'
                          : isApproved
                              ? 'Status: Terverifikasi / Selesai'
                              : 'Status: Ditolak / Dibatalkan',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isPending
                            ? const Color(0xFF92400E)
                            : isApproved
                                ? const Color(0xFF14532D)
                                : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (onApproved != null && onRejected != null && isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF268B07),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text(
                        'Setujui Setor',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onApproved();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onRejected();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (onClosed != null) {
                    onClosed();
                  }
                },
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
