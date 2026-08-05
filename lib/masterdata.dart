import 'package:flutter/material.dart';

// ============================================================================
// Halaman Master Data — Admin Dashboard (Desktop/Web)
// Berdasarkan SRS 3.3.1 Manajemen Master Data:
//   FR-AD-01 — Kelola kategori sampah & harga/poin per kg
//   FR-AD-02 — Kelola lokasi drop point (tambah, edit, jam operasional)
//   FR-AD-03 — Kelola akun user/petugas/staf beserta role & permission
//
// Catatan: halaman ini didesain untuk layar desktop (sesuai SRS 2.1 —
// dashboard web admin/staf), bukan mobile. Konsisten dengan RBAC: akses
// halaman ini hanya untuk role Admin (Staf Kantor tidak bisa masuk ke sini).
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

class WasteCategoryModel {
  final String name;
  final int pointsPerKg;
  final bool isActive;
  IconData icon;

  WasteCategoryModel({
    required this.name,
    required this.pointsPerKg,
    required this.isActive,
    required this.icon,
  });
}

class DropPointModel {
  final String name;
  final String address;
  final String operatingHours;
  final int capacityPercent;
  final bool isActive;

  DropPointModel({
    required this.name,
    required this.address,
    required this.operatingHours,
    required this.capacityPercent,
    required this.isActive,
  });
}

// Icon options for category picker
const Map<String, IconData> categoryIconOptions = {
  'Plastik': Icons.local_drink_rounded,
  'Kertas': Icons.description_rounded,
  'Kardus': Icons.inventory_2_rounded,
  'Logam': Icons.build_rounded,
  'Kaca': Icons.wine_bar_rounded,
  'Elektronik': Icons.devices_rounded,
  'Organik': Icons.eco_rounded,
  'Tekstil': Icons.checkroom_rounded,
  'Minyak': Icons.water_drop_rounded,
  'Lainnya': Icons.category_rounded,
};

// --------------------------------------------------------------------------
// MAIN SCREEN
// --------------------------------------------------------------------------

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = [
    'Kategori Sampah',
    'Drop Point',
  ];

  // Mutable in-memory data lists
  final List<WasteCategoryModel> _categories = [
    WasteCategoryModel(
      name: 'Kardus, Plastik, Kertas & Kaca',
      pointsPerKg: 100,
      isActive: true,
      icon: Icons.recycling_rounded,
    ),
    WasteCategoryModel(
      name: 'Barang Besi',
      pointsPerKg: 250,
      isActive: true,
      icon: Icons.build_rounded,
    ),
    WasteCategoryModel(
      name: 'Sampah Elektronik',
      pointsPerKg: 500,
      isActive: true,
      icon: Icons.devices_rounded,
    ),
  ];

  final List<DropPointModel> _dropPoints = [
    DropPointModel(
      name: 'Drop Point Margonda',
      address: 'Jl. Margonda Raya No. 12, Depok',
      operatingHours: '08.00–17.00',
      capacityPercent: 92,
      isActive: true,
    ),
    DropPointModel(
      name: 'Waste Station Beji',
      address: 'Jl. Kartini No. 5, Beji, Depok',
      operatingHours: '07.00–16.00',
      capacityPercent: 88,
      isActive: true,
    ),
    DropPointModel(
      name: 'Drop Point Kemang Pratama',
      address: 'Jl. Kemang Raya No. 3, Depok',
      operatingHours: '08.00–18.00',
      capacityPercent: 31,
      isActive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _addButtonLabel {
    switch (_tabController.index) {
      case 0:
        return 'Tambah Kategori';
      default:
        return 'Tambah Drop Point';
    }
  }

  // ------------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Master Data',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'FR-AD-01 · FR-AD-02 — kategori sampah dan drop point',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: subtleText,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              switch (_tabController.index) {
                case 0:
                  _showKategoriFormDialog();
                  break;
                case 1:
                  _showDropPointFormDialog();
                  break;
              }
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(_addButtonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SHARED TABLE HELPERS
  // ------------------------------------------------------------------------

  Widget _tableContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 28, 24),
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
      child: Column(children: children),
    );
  }

  Widget _tableHeaderRow(List<String> columns, List<int> flexes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: List.generate(columns.length, (i) {
          return Expanded(
            flex: flexes[i],
            child: Text(
              columns[i],
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtleText,
                letterSpacing: 0.3,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _statusBadge(
    bool isActive, {
    String? activeLabel,
    String? inactiveLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F8E8) : const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? (activeLabel ?? 'Aktif') : (inactiveLabel ?? 'Nonaktif'),
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isActive ? primaryGreen : const Color(0xFF5F5E5A),
        ),
      ),
    );
  }

  Widget _actionButtons({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _iconActionButton(Icons.edit_outlined, onEdit),
        const SizedBox(width: 6),
        _iconActionButton(
          Icons.delete_outline_rounded,
          onDelete,
          isDestructive: true,
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus $title?',
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: subtleText)),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _iconActionButton(
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: pageBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(
          icon,
          size: 15,
          color: isDestructive ? secondaryDarkText : subtleText,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // DIALOG: TAMBAH KATEGORI
  // ------------------------------------------------------------------------

  void _showKategoriFormDialog({WasteCategoryModel? category, int? index}) {
    final isEdit = category != null && index != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final pointsController = TextEditingController(
      text: category?.pointsPerKg.toString() ?? '',
    );
    bool isActive = category?.isActive ?? true;
    IconData selectedIcon = category?.icon ?? Icons.category_rounded;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit
                                ? 'Edit Kategori Sampah'
                                : 'Tambah Kategori Sampah',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(
                            Icons.close_rounded,
                            color: subtleText,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nama Kategori
                    _dialogLabel('Nama Kategori'),
                    const SizedBox(height: 6),
                    _dialogTextField(
                      nameController,
                      'Contoh: Plastik, Kertas, dll.',
                    ),
                    const SizedBox(height: 16),

                    // Poin per Kg
                    _dialogLabel('Poin per Kg'),
                    const SizedBox(height: 6),
                    _dialogTextField(
                      pointsController,
                      'Contoh: 100',
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),

                    // Pilih Ikon
                    _dialogLabel('Ikon'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryIconOptions.entries.map((entry) {
                        final isSelected = selectedIcon == entry.value;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedIcon = entry.value),
                          child: Tooltip(
                            message: entry.key,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryGreen
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryGreen
                                      : borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                entry.value,
                                size: 16,
                                color: isSelected ? Colors.white : subtleText,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Row(
                      children: [
                        _dialogLabel('Status'),
                        const Spacer(),
                        Switch(
                          value: isActive,
                          activeThumbColor: primaryGreen,
                          onChanged: (v) => setDialogState(() => isActive = v),
                        ),
                        Text(
                          isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? primaryGreen : subtleText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _dialogCancelButton(ctx),
                        const SizedBox(width: 10),
                        _dialogSubmitButton(
                          isEdit ? 'Simpan' : 'Tambah Kategori',
                          () {
                            final name = nameController.text.trim();
                            final points = int.tryParse(
                              pointsController.text.trim(),
                            );
                            if (name.isEmpty || points == null || points <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mohon isi nama kategori dan poin per kg dengan benar.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              final model = WasteCategoryModel(
                                name: name,
                                pointsPerKg: points,
                                isActive: isActive,
                                icon: selectedIcon,
                              );
                              if (isEdit) {
                                _categories[index] = model;
                              } else {
                                _categories.add(model);
                              }
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Kategori "$name" berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}!',
                                ),
                                backgroundColor: primaryGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------------------
  // DIALOG: TAMBAH DROP POINT
  // ------------------------------------------------------------------------

  void _showDropPointFormDialog({DropPointModel? dropPoint, int? index}) {
    final isEdit = dropPoint != null && index != null;
    final nameController = TextEditingController(text: dropPoint?.name ?? '');
    final addressController = TextEditingController(
      text: dropPoint?.address ?? '',
    );
    final hoursController = TextEditingController(
      text: dropPoint?.operatingHours ?? '',
    );
    final capacityController = TextEditingController(
      text: dropPoint?.capacityPercent.toString() ?? '0',
    );
    bool isActive = dropPoint?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8E8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_location_alt_rounded,
                              color: primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEdit ? 'Edit Drop Point' : 'Tambah Drop Point',
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close_rounded,
                              color: subtleText,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Nama Lokasi
                      _dialogLabel('Nama Lokasi'),
                      const SizedBox(height: 6),
                      _dialogTextField(
                        nameController,
                        'Contoh: Drop Point Margonda',
                      ),
                      const SizedBox(height: 16),

                      // Alamat
                      _dialogLabel('Alamat'),
                      const SizedBox(height: 6),
                      _dialogTextField(
                        addressController,
                        'Contoh: Jl. Margonda Raya No. 12, Depok',
                      ),
                      const SizedBox(height: 16),

                      // Jam Operasional
                      _dialogLabel('Jam Operasional'),
                      const SizedBox(height: 6),
                      _dialogTextField(hoursController, 'Contoh: 08.00–17.00'),
                      const SizedBox(height: 16),

                      // Kapasitas
                      _dialogLabel('Kapasitas (%)'),
                      const SizedBox(height: 6),
                      _dialogTextField(
                        capacityController,
                        'Contoh: 50',
                        isNumber: true,
                      ),
                      const SizedBox(height: 16),

                      // Status
                      Row(
                        children: [
                          _dialogLabel('Status'),
                          const Spacer(),
                          Switch(
                            value: isActive,
                            activeThumbColor: primaryGreen,
                            onChanged: (v) =>
                                setDialogState(() => isActive = v),
                          ),
                          Text(
                            isActive ? 'Buka' : 'Tutup',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? primaryGreen : subtleText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _dialogCancelButton(ctx),
                          const SizedBox(width: 10),
                          _dialogSubmitButton('Tambah Drop Point', () {
                            final name = nameController.text.trim();
                            final address = addressController.text.trim();
                            final hours = hoursController.text.trim();
                            final capacity =
                                int.tryParse(capacityController.text.trim()) ??
                                0;
                            if (name.isEmpty ||
                                address.isEmpty ||
                                hours.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mohon isi semua field yang diperlukan.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _dropPoints.add(
                                DropPointModel(
                                  name: name,
                                  address: address,
                                  operatingHours: hours,
                                  capacityPercent: capacity.clamp(0, 100),
                                  isActive: isActive,
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Drop Point "$name" berhasil ditambahkan!',
                                ),
                                backgroundColor: primaryGreen,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------------------
  // DIALOG SHARED WIDGETS
  // ------------------------------------------------------------------------

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryDarkText,
      ),
    );
  }

  Widget _dialogTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 13,
        color: darkText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          color: mutedText,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _dialogCancelButton(BuildContext ctx) {
    return TextButton(
      onPressed: () => Navigator.pop(ctx),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderColor),
        ),
      ),
      child: const Text(
        'Batal',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: subtleText,
        ),
      ),
    );
  }

  Widget _dialogSubmitButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 1: KATEGORI SAMPAH (FR-AD-01)
  // ------------------------------------------------------------------------

  Widget _buildKategoriSampahTab() {
    return SingleChildScrollView(
      child: _tableContainer(
        children: [
          _tableHeaderRow(
            ['Kategori', 'Poin per kg', 'Status', 'Aksi'],
            [3, 2, 2, 2],
          ),
          ..._categories.map(
            (cat) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, size: 15, color: primaryGreen),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cat.name,
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${cat.pointsPerKg} poin/kg',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: _statusBadge(cat.isActive)),
                  Expanded(
                    flex: 2,
                    child: _actionButtons(
                      onEdit: () {
                        _showKategoriFormDialog(
                          category: cat,
                          index: _categories.indexOf(cat),
                        );
                      },
                      onDelete: () {
                        _showDeleteConfirmation(cat.name, () {
                          setState(() {
                            _categories.remove(cat);
                          });
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // TAB 2: DROP POINT (FR-AD-02)
  // ------------------------------------------------------------------------

  Widget _buildDropPointTab() {
    return SingleChildScrollView(
      child: _tableContainer(
        children: [
          _tableHeaderRow(
            [
              'Nama Lokasi',
              'Alamat',
              'Jam Operasional',
              'Kapasitas',
              'Status',
              'Aksi',
            ],
            [2, 3, 2, 2, 1, 2],
          ),
          ..._dropPoints.map(
            (dp) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      dp.name,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      dp.address,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: subtleText,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      dp.operatingHours,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: subtleText,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: dp.capacityPercent / 100,
                              minHeight: 5,
                              backgroundColor: pageBackground,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                dp.capacityPercent > 85
                                    ? primaryGreen
                                    : limeGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${dp.capacityPercent}%',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _statusBadge(
                      dp.isActive,
                      activeLabel: 'Buka',
                      inactiveLabel: 'Tutup',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _actionButtons(
                      onEdit: () {
                        _showDropPointFormDialog(
                          dropPoint: dp,
                          index: _dropPoints.indexOf(dp),
                        );
                      },
                      onDelete: () {
                        _showDeleteConfirmation(dp.name, () {
                          setState(() {
                            _dropPoints.remove(dp);
                          });
                        });
                      },
                    ),
                  ),
                ],
              ),
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
                _buildKategoriSampahTab(),
                _buildDropPointTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
