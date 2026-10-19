import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'api_service.dart';

class KonfigurasiSistemScreen extends StatefulWidget {
  const KonfigurasiSistemScreen({super.key});

  @override
  State<KonfigurasiSistemScreen> createState() =>
      _KonfigurasiSistemScreenState();
}

class _KonfigurasiSistemScreenState extends State<KonfigurasiSistemScreen> {
  final Color oldGrassGreen = const Color(0xFF268B07);
  final Color limeGreen = const Color(0xFF32CD32);
  final Color baseBlack = const Color(0xFF000000);
  final Color baseWhite = const Color(0xFFFFFFFF);
  final Color textGrey = const Color(0xFF5F6368);
  final Color borderGrey = const Color(0xFFE0E0E0);

  final TextEditingController _minWeightController = TextEditingController();
  final TextEditingController _maxRadiusController = TextEditingController();
  final TextEditingController _minWithdrawController = TextEditingController();
  final TextEditingController _pointRateController = TextEditingController();
  final TextEditingController _jamBukaController = TextEditingController();
  final TextEditingController _jamTutupController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  final Map<int, TextEditingController> _pointControllers = {};
  final Map<int, TextEditingController> _minWeightControllers = {};

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

      List<Map<String, dynamic>> cats = [];
      try {
        cats = await ApiService.instance.getWasteCategories();
      } catch (_) {}
      if (cats.isEmpty) {
        cats = await DatabaseHelper.instance.getWasteCategories();
      }

      if (mounted) {
        setState(() {
          _minWeightController.text = (config['min_weight'] ?? 1.0).toString();
          _maxRadiusController.text = (config['max_radius'] ?? 5.0).toString();
          _minWithdrawController.text =
              (config['min_withdraw'] ?? 100).toString();
          _pointRateController.text = (config['point_rate'] ?? 1).toString();

          _jamBukaController.text = config['jam_buka']?.toString() ?? '08:00';
          _jamTutupController.text = config['jam_tutup']?.toString() ?? '17:00';

          _autoAssignPetugas = (config['auto_assign'] ?? 1) == 1;
          _enableWaNotification = (config['wa_notif'] ?? 1) == 1;
          _enablePushNotification = (config['push_notif'] ?? 1) == 1;

          _categories = cats;
          _pointControllers.forEach((_, c) => c.dispose());
          _minWeightControllers.forEach((_, c) => c.dispose());
          _pointControllers.clear();
          _minWeightControllers.clear();

          for (var c in cats) {
            final id = (c['id'] as num).toInt();
            _pointControllers[id] = TextEditingController(
              text: (c['point_per_kg'] ?? 0).toString(),
            );
            _minWeightControllers[id] = TextEditingController(
              text: ((c['min_weight'] as num?)?.toDouble() ?? 1.0).toString(),
            );
          }

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    double minWeight = double.tryParse(_minWeightController.text) ?? 1.0;
    double maxRadius = double.tryParse(_maxRadiusController.text) ?? 5.0;
    double minWithdraw =
        double.tryParse(_minWithdrawController.text) ?? 100.0;
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

      // Save each waste category with point_per_kg and min_weight
      for (var cat in _categories) {
        final id = (cat['id'] as num).toInt();
        final point = int.tryParse(_pointControllers[id]?.text ?? '') ??
            (cat['point_per_kg'] as num).toInt();
        final minW = double.tryParse(_minWeightControllers[id]?.text ?? '') ??
            ((cat['min_weight'] as num?)?.toDouble() ?? 1.0);

        final updateData = {
          'name': cat['name'],
          'point_per_kg': point,
          'min_weight': minW,
          'icon_url': cat['icon_url'] ?? 'icon_default.png',
          'is_active': cat['is_active'] ?? 1,
        };

        await DatabaseHelper.instance.updateWasteCategory(id, updateData);
        try {
          await ApiService.instance.updateWasteCategory(id, updateData);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Konfigurasi sistem & tarif kategori berhasil disimpan!'
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
    _pointControllers.forEach((_, c) => c.dispose());
    _minWeightControllers.forEach((_, c) => c.dispose());
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
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      onPressed: _loadConfig,
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

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        title: 'Tarif Poin & Batas Minimal per Kategori Sampah',
                        icon: Icons.scale_rounded,
                        children: [
                          Text(
                            'Atur poin per kg dan batas minimal berat untuk setiap jenis sampah. Nilai ini otomatis sinkron ke menu Timbang Manual Petugas dan Aplikasi Nasabah.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textGrey,
                              height: 1.4,
                              fontFamily: 'Segoe UI',
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_categories.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Tidak ada data kategori sampah.'),
                              ),
                            )
                          else
                            ..._categories.map((cat) {
                              final id = (cat['id'] as num).toInt();
                              final name = cat['name']?.toString() ?? 'Sampah';
                              final pCtrl = _pointControllers[id];
                              final wCtrl = _minWeightControllers[id];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderGrey),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: oldGrassGreen
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.recycling_rounded,
                                            size: 18,
                                            color: oldGrassGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: baseBlack,
                                              fontFamily: 'Segoe UI',
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            'Timbang Manual',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: oldGrassGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'Poin / kg',
                                            controller: pCtrl ??
                                                TextEditingController(),
                                            suffixText: 'poin',
                                            helperText: 'Tarif per 1 kg',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'Minimum Berat',
                                            controller: wCtrl ??
                                                TextEditingController(),
                                            suffixText: 'kg',
                                            helperText:
                                                'Batas minimal timbang',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: baseBlack,
                    fontFamily: 'Segoe UI',
                  ),
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
