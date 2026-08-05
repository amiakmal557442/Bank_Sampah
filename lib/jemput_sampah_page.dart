import 'package:flutter/material.dart';
import 'transaction_service.dart';
import 'db_helper.dart';
import 'session_service.dart';

// ============================================================================
// 1. HALAMAN JADWAL & LOKASI PENJEMPUTAN
// ============================================================================
class PickupScheduleScreen extends StatefulWidget {
  const PickupScheduleScreen({super.key});

  @override
  _PickupScheduleScreenState createState() => _PickupScheduleScreenState();
}

class _PickupScheduleScreenState extends State<PickupScheduleScreen> {
  // Index 1 = besok (default terpilih)
  int selectedDateIndex = 1;
  int selectedTimeIndex = 1;
  int selectedLocationIndex = 0;

  // Nama hari dalam bahasa Indonesia
  static const List<String> _dayNames = [
    'MIN',
    'SEN',
    'SEL',
    'RAB',
    'KAM',
    'JUM',
    'SAB',
  ];

  // Generate tanggal dinamis: hari ini + 3 hari ke depan (total 4 hari)
  List<Map<String, String>> get _dates {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final day = today.add(Duration(days: i));
      String label = '';
      if (i == 0) label = 'Hari ini';
      if (i == 1) label = 'Besok';
      return {
        'day': _dayNames[day.weekday % 7],
        'date': day.day.toString(),
        'label': label,
      };
    });
  }

  final List<String> _times = [
    '08.00 - 10.00',
    '10.00 - 12.00',
    '13.00 - 15.00',
    '15.00 - 17.00',
  ];

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF268B07);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text(
          'Jemput Sampah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: 0.33,
            backgroundColor: const Color(0xFF1a6305),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.lightGreenAccent,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'PILIH TANGGAL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_dates.length, (index) {
                bool isSelected = index == selectedDateIndex;
                final d = _dates[index];
                return GestureDetector(
                  onTap: () => setState(() => selectedDateIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryGreen : Colors.white,
                      border: Border.all(
                        color: isSelected ? primaryGreen : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          d['day']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d['date']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (d['label']!.isNotEmpty)
                          Text(
                            d['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PILIH WAKTU',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: List.generate(
              _times.length,
              (i) => _buildTimeOption(i, _times[i], primaryGreen),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'LOKASI PENJEMPUTAN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildLocationChip(0, Icons.home_rounded, 'Rumah', primaryGreen),
              const SizedBox(width: 8),
              _buildLocationChip(
                1,
                Icons.business_rounded,
                'Kantor',
                primaryGreen,
              ),
              const SizedBox(width: 8),
              _buildLocationChip(
                2,
                Icons.add_circle_outline,
                'Baru',
                primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGreen, width: 1.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, color: primaryGreen, size: 36),
                  const SizedBox(height: 6),
                  Text(
                    'Peta interaktif (Google Maps API)',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Drag pin untuk atur titik jemput secara presisi',
                    style: TextStyle(
                      color: primaryGreen.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag pin untuk sesuaikan titik jemput secara presisi',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Catatan patokan alamat (Opsional)',
              hintText: 'Cth: Rumah pagar hitam depan warung',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryGreen, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PickupWasteScreen(
                      selectedDay: _dates[selectedDateIndex]['day']!,
                      selectedDate: _dates[selectedDateIndex]['date']!,
                      selectedTime: _times[selectedTimeIndex],
                      note: _noteController.text,
                    ),
                  ),
                );
              },
              child: const Text(
                'Lanjut',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(int index, String text, Color primaryGreen) {
    bool isSelected = index == selectedTimeIndex;
    return GestureDetector(
      onTap: () => setState(() => selectedTimeIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? primaryGreen : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationChip(
    int index,
    IconData icon,
    String label,
    Color primaryGreen,
  ) {
    bool isSelected = index == selectedLocationIndex;
    return GestureDetector(
      onTap: () => setState(() => selectedLocationIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. HALAMAN JENIS & ESTIMASI SAMPAH
// ============================================================================
class PickupWasteScreen extends StatefulWidget {
  final String selectedDay;
  final String selectedDate;
  final String selectedTime;
  final String note;

  const PickupWasteScreen({
    super.key,
    required this.selectedDay,
    required this.selectedDate,
    required this.selectedTime,
    required this.note,
  });

  @override
  _PickupWasteScreenState createState() => _PickupWasteScreenState();
}

class _PickupWasteScreenState extends State<PickupWasteScreen> {
  List<Map<String, dynamic>> _wasteCategories = [];
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getWasteCategories();
    if (!mounted) return;
    setState(() {
      _wasteCategories = cats
          .where((c) => (c['is_active'] as int?) == 1)
          .toList();
      // Default: first category selected
      if (_wasteCategories.isNotEmpty) _selectedIndices.add(0);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF268B07);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text(
          'Jenis Sampah Dijemput',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: 0.66,
            backgroundColor: const Color(0xFF1a6305),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.lightGreenAccent,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.selectedDay}, ${widget.selectedDate} Jul • ${widget.selectedTime} • Jl. Kartini No. 8',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PILIH JENIS SAMPAH',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih kategori sampah — penimbangan dilakukan petugas di lokasi',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF268B07)),
            )
          else
            ..._wasteCategories.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final isSelected = _selectedIndices.contains(i);
              return _buildWasteCard(
                title: cat['name'] as String,
                subtitle: '${cat['point_per_kg']} poin/kg',
                icon: Icons.recycling_rounded,
                isSelected: isSelected,
                primaryGreen: const Color(0xFF268B07),
                onToggle: () => setState(() {
                  if (isSelected) {
                    _selectedIndices.remove(i);
                  } else {
                    _selectedIndices.add(i);
                  }
                }),
              );
            }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Berat & poin final ditentukan petugas saat penimbangan di lokasi',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Build selected waste items list
                    final List<Map<String, dynamic>> items = [];
                    for (final i in _selectedIndices) {
                      final cat = _wasteCategories[i];
                      items.add({
                        'name': cat['name'],
                        'rate': '${cat['point_per_kg']} poin/kg',
                      });
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PickupConfirmationScreen(
                          selectedDay: widget.selectedDay,
                          selectedDate: widget.selectedDate,
                          selectedTime: widget.selectedTime,
                          note: widget.note,
                          wasteItems: items,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Lanjut',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWasteCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color primaryGreen,
    required VoidCallback onToggle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? primaryGreen : Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
        color: isSelected ? primaryGreen.withOpacity(0.05) : Colors.white,
      ),
      child: GestureDetector(
        onTap: onToggle,
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: isSelected ? primaryGreen : Colors.grey,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryGreen.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryGreen : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. HALAMAN KONFIRMASI & RINGKASAN
// ============================================================================
// ============================================================================
// 3. HALAMAN KONFIRMASI & RINGKASAN
// ============================================================================
class PickupConfirmationScreen extends StatefulWidget {
  final String selectedDay;
  final String selectedDate;
  final String selectedTime;
  final String note;
  final List<Map<String, dynamic>> wasteItems;

  const PickupConfirmationScreen({
    super.key,
    required this.selectedDay,
    required this.selectedDate,
    required this.selectedTime,
    required this.note,
    required this.wasteItems,
  });

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  String? _photoPath;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF268B07);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text(
          'Konfirmasi Jemput',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: const Color(0xFF1a6305),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.lightGreenAccent,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionCard(
            title: 'JADWAL & LOKASI',
            context: context,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.selectedDay}, ${widget.selectedDate} Juli 2026',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.selectedTime + ' WIB',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Jl. Kartini No. 8, Beji, Depok',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Lokasi: Rumah',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"${widget.note}"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'JENIS SAMPAH',
            context: context,
            content: Column(
              children: widget.wasteItems
                  .asMap()
                  .entries
                  .map(
                    (entry) => Column(
                      children: [
                        if (entry.key > 0) const Divider(),
                        _buildWasteRow(
                          entry.value['name'],
                          entry.value['rate'] ?? '',
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Poin final ditentukan setelah petugas menimbang berat aktual di lokasi.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'FOTO BUKTI SAMPAH',
            context: context,
            content: _photoPath == null
                ? InkWell(
                    onTap: () async {
                      // Simulasi ambil foto
                      await Future.delayed(const Duration(milliseconds: 500));
                      setState(() {
                        _photoPath = 'simulated_photo_path.jpg';
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.05),
                        border: Border.all(
                          color: primaryGreen.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: primaryGreen,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ambil Foto Bukti',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Foto tersimpan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _photoPath!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => setState(() => _photoPath = null),
                              child: Text(
                                'Ubah Foto',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kode Waste-ID kamu akan dibuat setelah permintaan ini diajukan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_photoPath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Harap lampirkan foto bukti sampah'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);

                      // Prepare Data for DB
                      final txId =
                          'TRX-${DateTime.now().millisecondsSinceEpoch}';
                      final txData = {
                        'id': txId,
                        'nasabah_id':
                            SessionService.userId, // using active session
                        'type': 'pickup',
                        'status': 'menunggu',
                        'pickup_date':
                            '${widget.selectedDay}, ${widget.selectedDate} Juli 2026',
                        'pickup_time_slot': widget.selectedTime,
                        'photo_evidence': _photoPath,
                      };

                      final itemsData = widget.wasteItems
                          .map(
                            (item) => {
                              'id':
                                  'ITI-${DateTime.now().microsecondsSinceEpoch}',
                              'transaction_id': txId,
                              'waste_category_id':
                                  0, // Using 0 as mock ID for text categories, normally map this correctly
                              'estimated_weight': 0.0,
                              'actual_weight': 0.0,
                              'final_points': 0,
                            },
                          )
                          .toList();

                      await DatabaseHelper.instance.createTransaction(
                        txData,
                        itemsData,
                      );

                      // Keep the UI logic for transaction history (if any remains)
                      final names = widget.wasteItems
                          .map((e) => e['name'] as String)
                          .join(' dan ');
                      TransactionService.addTransaction(
                        title: names,
                        type: 'Jemput',
                      );

                      if (!mounted) return;
                      setState(() => _isSubmitting = false);

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PickupSuccessScreen(
                            selectedDay: widget.selectedDay,
                            selectedDate: widget.selectedDate,
                            selectedTime: widget.selectedTime,
                          ),
                        ),
                        (route) => route.isFirst,
                      );
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text(
                      'Ajukan Permintaan Jemput',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget content,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    color: Color(0xFF268B07),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildWasteRow(String name, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 15)),
          Text(
            detail,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. HASIL: PERMINTAAN BERHASIL DIBUAT
// ============================================================================
class PickupSuccessScreen extends StatelessWidget {
  final String selectedDay;
  final String selectedDate;
  final String selectedTime;

  const PickupSuccessScreen({
    super.key,
    required this.selectedDay,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF268B07);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Permintaan jemput dibuat!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tunjukkan kode ini ke petugas saat tiba\ndi lokasi untuk verifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: primaryGreen, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, size: 110, color: Colors.black87),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'WJ-5T2N-9K7L',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Status Steps
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusStep('Menunggu', true, primaryGreen, 1),
                _buildStatusStep('Dikonfirmasi', false, primaryGreen, 2),
                _buildStatusStep('Menuju\nlokasi', false, primaryGreen, 3),
                _buildStatusStep('Selesai', false, primaryGreen, 4),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS SAAT INI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: primaryGreen),
                      const SizedBox(width: 8),
                      const Text('Menunggu konfirmasi & penugasan petugas'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Kamu akan dapat notifikasi saat petugas ditugaskan',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PickupTrackingScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Lacak status penjemputan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStep(
    String title,
    bool isActive,
    Color primaryGreen,
    int step,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? primaryGreen : Colors.grey.shade300,
          child: isActive
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '$step',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? primaryGreen : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 5. TRACKING REAL-TIME PETUGAS
// ============================================================================
class PickupTrackingScreen extends StatelessWidget {
  const PickupTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF268B07);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text(
          'Lacak Petugas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a6305),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.redAccent, size: 10),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Peta interaktif (Google Maps API)',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Posisi petugas ter-update tiap 5-10 detik',
                    style: TextStyle(
                      color: primaryGreen.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: primaryGreen),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tiba dalam ~12 menit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Jarak 2,4 km dari lokasimu',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: primaryGreen.withOpacity(0.1),
                          child: Icon(
                            Icons.person_rounded,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dedi Kurniawan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '⭐ 4.9 • 320 penjemputan',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Motor bak • B 3821 SDK',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.phone_rounded, color: primaryGreen),
                          style: IconButton.styleFrom(
                            backgroundColor: primaryGreen.withOpacity(0.08),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: primaryGreen,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: primaryGreen.withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Waste-ID kamu',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'WJ-5T2N-9K7L',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Batalkan',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Chat Petugas',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
