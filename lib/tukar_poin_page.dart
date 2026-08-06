import 'package:flutter/material.dart';
import 'transaction_service.dart';
import 'session_service.dart';
import 'db_helper.dart';

// ============================================================================
// Halaman Tukar Poin ke Saldo
// Berdasarkan SRS: FR-EU-10 (info saldo), FR-EU-11 (konversi ke e-wallet/
// bank/saldo internal), FR-EU-12 (riwayat konversi & minimum penarikan)
//
// CATATAN OPEN ISSUE DARI SRS (perlu konfirmasi tim sebelum production):
// - Ambang batas nominal wajib verifikasi KTP belum ditentukan di SRS.
//   Nilai 50.000 poin di bawah ini adalah ASUMSI SEMENTARA, tandai TODO.
// - Payment gateway (DANA/GoPay/OVO/Bank) masih tahap seleksi vendor,
//   jadi integrasi API belum bisa final di kode ini (masih placeholder).
// ============================================================================

// Color Palette (konsisten dengan voucher_page.dart)
const Color primaryGreen = Color(0xFF268B07);
const Color pageBackground = Color(0xFFF5F6F8);
const Color darkText = Color(0xFF0F172A);
const Color subtleText = Color(0xFF64748B);
const Color mutedText = Color(0xFF94A3B8);
const Color borderColor = Color(0xFFE2E8F0);
const Color secondaryDarkText = Color(0xFF334155);
const Color limeGreen = Color(0xFF32CD32);

// TODO: konfirmasi threshold ini ke tim — belum ada di SRS
const int ktpVerificationThresholdPoints = 50000; // ~Rp 500.000, ASUMSI

// Rate konversi poin -> rupiah (asumsi 1 poin = Rp 10, konsisten dgn contoh
// SRS: 4.820 poin ≈ Rp 48.200). TODO: pastikan rate final dari business rule.
const double pointToRupiahRate = 10.0;

enum DestinationType { ewallet, bank, internal }

class WithdrawalDestination {
  final String id;
  final String name;
  final String subtitle;
  final DestinationType type;
  final IconData icon;

  WithdrawalDestination({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.type,
    required this.icon,
  });
}

final List<WithdrawalDestination> destinations = [
  WithdrawalDestination(
    id: 'dana',
    name: 'DANA',
    subtitle: 'E-wallet',
    type: DestinationType.ewallet,
    icon: Icons.account_balance_wallet_rounded,
  ),
  WithdrawalDestination(
    id: 'gopay',
    name: 'GoPay',
    subtitle: 'E-wallet',
    type: DestinationType.ewallet,
    icon: Icons.account_balance_wallet_rounded,
  ),
  WithdrawalDestination(
    id: 'ovo',
    name: 'OVO',
    subtitle: 'E-wallet',
    type: DestinationType.ewallet,
    icon: Icons.account_balance_wallet_rounded,
  ),
  WithdrawalDestination(
    id: 'bank',
    name: 'Rekening Bank',
    subtitle: 'Transfer bank',
    type: DestinationType.bank,
    icon: Icons.account_balance_rounded,
  ),
  WithdrawalDestination(
    id: 'internal',
    name: 'Saldo Aplikasi',
    subtitle: 'Simpan sebagai saldo internal',
    type: DestinationType.internal,
    icon: Icons.savings_rounded,
  ),
];

class ConversionHistoryItem {
  final String destination;
  final int points;
  final double amount;
  final String date;
  final String status; // 'Selesai', 'Diproses', 'Gagal'

  ConversionHistoryItem({
    required this.destination,
    required this.points,
    required this.amount,
    required this.date,
    required this.status,
  });
}

final List<ConversionHistoryItem> sampleHistory = [
  ConversionHistoryItem(
    destination: 'DANA',
    points: 1000,
    amount: 10000,
    date: '25 Jul 2026, 07.20',
    status: 'Selesai',
  ),
  ConversionHistoryItem(
    destination: 'Rekening Bank',
    points: 5000,
    amount: 50000,
    date: '20 Jul 2026, 11.05',
    status: 'Gagal',
  ),
  ConversionHistoryItem(
    destination: 'GoPay',
    points: 2000,
    amount: 20000,
    date: '14 Jul 2026, 16.40',
    status: 'Selesai',
  ),
];

class TukarPoinScreen extends StatefulWidget {
  const TukarPoinScreen({super.key});

  @override
  State<TukarPoinScreen> createState() => _TukarPoinScreenState();
}

class _TukarPoinScreenState extends State<TukarPoinScreen> {
  int get userPoints => SessionService.pointBalance;
  final int minWithdrawalPoints = 1000;

  WithdrawalDestination? selectedDestination;
  final TextEditingController amountController = TextEditingController();
  int inputPoints = 0;
  String? errorText;

  @override
  void initState() {
    super.initState();
    selectedDestination = destinations.first;
    amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final parsed = int.tryParse(amountController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      inputPoints = parsed;
      errorText = _validateAmount(parsed);
    });
  }

  String? _validateAmount(int points) {
    if (points == 0) return null;
    if (points < minWithdrawalPoints) {
      return 'Minimum penarikan $minWithdrawalPoints poin';
    }
    if (points > userPoints) {
      return 'Poin tidak mencukupi';
    }
    return null;
  }

  bool get _needsKtpVerification =>
      inputPoints >= ktpVerificationThresholdPoints;

  bool get _canSubmit =>
      selectedDestination != null &&
      inputPoints >= minWithdrawalPoints &&
      inputPoints <= userPoints &&
      errorText == null;

  double get _estimatedRupiah => inputPoints * pointToRupiahRate;

  void _showConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildConfirmationBottomSheet(),
    );
  }

  // --------------------------------------------------------------------
  // UI BUILDERS
  // --------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: pageBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: darkText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tukar Poin ke Saldo',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.15),
            blurRadius: 10,
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
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$userPoints poin',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ Rp ${(userPoints * pointToRupiahRate).toStringAsFixed(0)}  ·  Min. tarik: $minWithdrawalPoints poin',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: subtleText,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDestinationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('PILIH TUJUAN PENCAIRAN'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: destinations.map((dest) {
              final isSelected = selectedDestination?.id == dest.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedDestination = dest),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF7FCF5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryGreen : borderColor,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: pageBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(dest.icon, color: primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dest.name,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                              Text(
                                dest.subtitle,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? primaryGreen : borderColor,
                              width: 2,
                            ),
                            color: isSelected
                                ? primaryGreen
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('JUMLAH POIN YANG DITUKAR'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorText != null
                        ? Colors.red.shade300
                        : borderColor,
                    width: errorText != null ? 1.2 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'poin',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FCE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kamu akan menerima',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5F8A4A),
                      ),
                    ),
                    Text(
                      'Rp ${_estimatedRupiah.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKtpVerificationSection() {
    if (!_needsKtpVerification) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge_rounded, color: primaryGreen, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Verifikasi KTP diperlukan',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Penarikan dengan nominal besar memerlukan verifikasi identitas untuk keamanan akun kamu.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: subtleText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // TODO: implementasi image picker untuk upload foto KTP
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: pageBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGreen,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: primaryGreen,
                      size: 22,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ambil atau unggah foto KTP',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RIWAYAT KONVERSI POIN',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtleText,
                  letterSpacing: 0.4,
                ),
              ),
              const Text(
                'Lihat semua',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: sampleHistory.map((item) {
              final isSuccess = item.status == 'Selesai';
              final statusColor = isSuccess
                  ? primaryGreen
                  : const Color(0xFF5F5E5A);
              final statusBg = isSuccess
                  ? const Color(0xFFE8F8E8)
                  : const Color(0xFFF1EFE8);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: pageBackground,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.destination,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${item.points} poin',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSubmit ? _showConfirmationBottomSheet : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            disabledBackgroundColor: mutedText.withOpacity(0.3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Tukar Sekarang',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationBottomSheet() {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Konfirmasi Penukaran Poin',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pageBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Column(
              children: [
                _summaryRow('Tujuan', selectedDestination?.name ?? '-'),
                const SizedBox(height: 8),
                _summaryRow('Poin ditukar', '$inputPoints poin'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Akan diterima',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtleText,
                        ),
                      ),
                      Text(
                        'Rp ${_estimatedRupiah.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: limeGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: limeGreen, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Dana akan diproses 1x24 jam kerja setelah dikonfirmasi',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F8A4A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: pageBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 0.5),
                    ),
                    child: const Text(
                      'Batal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryDarkText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    int newPoints = SessionService.pointBalance - inputPoints;
                    await DatabaseHelper.instance.updateUserPointBalance(
                      SessionService.userId,
                      newPoints,
                    );
                    await SessionService.refresh();

                    if (mounted) {
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Permintaan penukaran poin berhasil diajukan',
                            style: TextStyle(fontFamily: 'PlusJakartaSans'),
                          ),
                          backgroundColor: primaryGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Konfirmasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: subtleText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPointInfoCard(),
                    _buildDestinationSelector(),
                    const SizedBox(height: 8),
                    _buildAmountInput(),
                    _buildKtpVerificationSection(),
                    _buildHistorySection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}
