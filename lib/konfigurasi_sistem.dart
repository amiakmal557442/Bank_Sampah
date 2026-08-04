import 'package:flutter/material.dart';
import 'db_helper.dart';

class KonfigurasiSistemScreen extends StatefulWidget {
  const KonfigurasiSistemScreen({super.key});

  @override
  State<KonfigurasiSistemScreen> createState() =>
      _KonfigurasiSistemScreenState();
}

class _KonfigurasiSistemScreenState extends State<KonfigurasiSistemScreen> {
  // Palet Warna Utama
  final Color oldGrassGreen = const Color(0xFF268B07);
  final Color limeGreen = const Color(0xFF32CD32);
  final Color baseBlack = const Color(0xFF000000);
  final Color baseWhite = const Color(0xFFFFFFFF);
  final Color textGrey = const Color(0xFF5F6368);
  final Color borderGrey = const Color(0xFFE0E0E0);

  // State Form Konfigurasi (FR-AD-14)
  final TextEditingController _minWeightController = TextEditingController();
  final TextEditingController _maxRadiusController = TextEditingController();
  final TextEditingController _minWithdrawController = TextEditingController();
  final TextEditingController _pointRateController = TextEditingController();
  final TextEditingController _jamBukaController = TextEditingController();
  final TextEditingController _jamTutupController = TextEditingController();

  bool _autoAssignPetugas = true;
  bool _enableWaNotification = true;
  bool _enablePushNotification = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await DatabaseHelper.instance.getSystemConfig();
      if (mounted) {
        setState(() {
          _minWeightController.text = (config['min_weight'] ?? 1.0).toString();
          _maxRadiusController.text = (config['max_radius'] ?? 5.0).toString();
          _minWithdrawController.text = (config['min_withdraw'] ?? 10000)
              .toString();
          _pointRateController.text = (config['point_rate'] ?? 1).toString();

          _jamBukaController.text = config['jam_buka']?.toString() ?? '08:00';
          _jamTutupController.text = config['jam_tutup']?.toString() ?? '17:00';

          _autoAssignPetugas = (config['auto_assign'] ?? 1) == 1;
          _enableWaNotification = (config['wa_notif'] ?? 1) == 1;
          _enablePushNotification = (config['push_notif'] ?? 1) == 1;

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    // Parse numeric values, fallback to defaults if invalid
    double minWeight = double.tryParse(_minWeightController.text) ?? 1.0;
    double maxRadius = double.tryParse(_maxRadiusController.text) ?? 5.0;
    double minWithdraw =
        double.tryParse(_minWithdrawController.text) ?? 10000.0;
    double pointRate = double.tryParse(_pointRateController.text) ?? 1.0;

    final config = {
      'min_weight': minWeight,
      'max_radius': maxRadius,
      'min_withdraw': minWithdraw,
      'point_rate': pointRate,
      'jam_buka': _jamBukaController.text.trim(),
      'jam_tutup': _jamTutupController.text.trim(),
      'auto_assign': _autoAssignPetugas ? 1 : 0,
      'wa_notif': _enableWaNotification ? 1 : 0,
      'push_notif': _enablePushNotification ? 1 : 0,
    };

    try {
      final success = await DatabaseHelper.instance.saveSystemConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Konfigurasi sistem berhasil disimpan!'
                  : 'Gagal menyimpan konfigurasi.',
              style: const TextStyle(fontFamily: 'Segoe UI'),
            ),
            backgroundColor: success ? oldGrassGreen : Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat menyimpan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _minWeightController.dispose();
    _maxRadiusController.dispose();
    _minWithdrawController.dispose();
    _pointRateController.dispose();
    _jamBukaController.dispose();
    _jamTutupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF268B07)),
      );
    }

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Mengikuti background shell dashboard
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfigurasi Sistem',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: baseBlack,
                        fontFamily: 'Segoe UI',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur parameter global aplikasi, aturan penjemputan, integrasi notifikasi, dan rasio poin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGrey,
                        fontFamily: 'Segoe UI',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _loadConfig, // Refresh data ke kondisi awal
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontFamily: 'Segoe UI'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oldGrassGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveConfig,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.save_outlined,
                              color: baseWhite,
                              size: 18,
                            ),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                        style: TextStyle(
                          color: baseWhite,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Segoe UI',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Form Grid (Dua Kolom)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KOLOM KIRI: Parameter Transaksi & Poin
                Expanded(
                  child: Column(
                    children: [
                      _buildCardSection(
                        title: 'Aturan Transaksi & Penjemputan',
                        icon: Icons.tune,
                        children: [
                          _buildInputField(
                            label: 'Minimum Berat Setor Sampah',
                            controller: _minWeightController,
                            suffixText: 'kg',
                            helperText:
                                'Batas minimal timbangan sampah yang dapat diajukan nasabah.',
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            label: 'Radius Maksimal Penjemputan Petugas',
                            controller: _maxRadiusController,
                            suffixText: 'km',
                            helperText:
                                'Jarak maksimal pencarian lokasi penjemputan dari drop point.',
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            label: 'Minimum Penarikan Saldo / Poin',
                            controller: _minWithdrawController,
                            suffixText: 'Rupiah',
                            helperText:
                                'Batas akumulasi poin minimal untuk pengajuan pencairan.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildCardSection(
                        title: 'Nilai Konversi & Poin',
                        icon: Icons.currency_exchange,
                        children: [
                          _buildInputField(
                            label: 'Rasio Konversi Poin ke Rupiah',
                            controller: _pointRateController,
                            prefixText: '1 Poin = Rp ',
                            helperText:
                                'Patokan konversi nilai tukar poin secara global.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // KOLOM KANAN: Otomatisasi, Jam Operasional & Notifikasi
                Expanded(
                  child: Column(
                    children: [
                      _buildCardSection(
                        title: 'Otomatisasi & Operasional',
                        icon: Icons.smart_button_outlined,
                        children: [
                          _buildSwitchTile(
                            title: 'Auto-Assign Petugas Penjemputan',
                            subtitle:
                                'Sistem otomatis memilih petugas terdekat dari lokasi nasabah.',
                            value: _autoAssignPetugas,
                            onChanged: (val) =>
                                setState(() => _autoAssignPetugas = val),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Jam Buka Operasional',
                                  controller: _jamBukaController,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Jam Tutup Operasional',
                                  controller: _jamTutupController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildCardSection(
                        title: 'Integrasi Layanan Notifikasi',
                        icon: Icons.notifications_none_outlined,
                        children: [
                          _buildSwitchTile(
                            title: 'Notifikasi WhatsApp (OTP & Status)',
                            subtitle:
                                'Kirimkan struk & kode verifikasi via WhatsApp Gateway.',
                            value: _enableWaNotification,
                            onChanged: (val) =>
                                setState(() => _enableWaNotification = val),
                          ),
                          const Divider(height: 24),
                          _buildSwitchTile(
                            title: 'Push Notification Aplikasi',
                            subtitle:
                                'Kirim pemberitahuan penjemputan langsung ke HP nasabah & petugas.',
                            value: _enablePushNotification,
                            onChanged: (val) =>
                                setState(() => _enablePushNotification = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Container Kelompok Pengaturan (Card Section)
  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: baseWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: oldGrassGreen, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: baseBlack,
                  fontFamily: 'Segoe UI',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Widget Input Form Standar
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    String? prefixText,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: 'Segoe UI',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 14),
          decoration: InputDecoration(
            prefixText: prefixText,
            suffixText: suffixText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: oldGrassGreen, width: 2),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 11,
              color: textGrey,
              fontFamily: 'Segoe UI',
            ),
          ),
        ],
      ],
    );
  }

  // Widget Toggle Switch
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Segoe UI',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textGrey,
                  fontFamily: 'Segoe UI',
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, activeColor: oldGrassGreen, onChanged: onChanged),
      ],
    );
  }
}
