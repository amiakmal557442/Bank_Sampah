import 'package:flutter/material.dart';
import 'transaction_service.dart';

class DropPoint {
  final String id;
  final String name;
  final String address;
  final String hours;
  final String distance;
  final List<String> categories;

  DropPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.hours,
    required this.distance,
    required this.categories,
  });
}

class WasteCategory {
  final String id;
  final String name;
  final int pointsPerKg;
  final IconData icon;
  bool isSelected;

  WasteCategory({
    required this.id,
    required this.name,
    required this.pointsPerKg,
    required this.icon,
    this.isSelected = false,
  });
}

class DropInMandiriScreen extends StatefulWidget {
  const DropInMandiriScreen({super.key});

  @override
  State<DropInMandiriScreen> createState() => _DropInMandiriScreenState();
}

class _DropInMandiriScreenState extends State<DropInMandiriScreen> {
  // Navigation State (0: DropPoint, 1: DetailSampah, 2: FotoSampah, 3: Konfirmasi, 4: Sukses)
  int _currentStep = 0;

  // Primary Theme Colors
  final Color _primaryGreen = const Color(0xFF268B07);
  final Color _lightGreenBg = const Color(0xFFE8F5E9);

  // Search controller for Drop Points
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Step 1 Data: Drop Points
  int _selectedDropPointIndex = 0;
  final List<DropPoint> _dropPoints = [
    DropPoint(
      id: 'dp1',
      name: 'Drop Point Margonda',
      address: 'Jl. Margonda Raya No. 12, Depok',
      hours: 'Buka 08.00–17.00',
      distance: '~1,2 km',
      categories: ['Plastik', 'Kertas', 'Logam'],
    ),
    DropPoint(
      id: 'dp2',
      name: 'Waste Station Beji',
      address: 'Jl. Kartini No. 5, Beji, Depok',
      hours: 'Buka 07.00–16.00',
      distance: '~2,8 km',
      categories: ['Plastik', 'Kertas', 'Kaca', 'Elektronik'],
    ),
    DropPoint(
      id: 'dp3',
      name: 'Bank Sampah Pancoran Mas',
      address: 'Jl. Pitara Raya No. 88, Depok',
      hours: 'Buka 08.00–15.00',
      distance: '~4,1 km',
      categories: ['Plastik', 'Kertas', 'Logam', 'Minyak'],
    ),
  ];

  // Step 2 Data: Waste Items
  final List<WasteCategory> _wasteCategories = [
    WasteCategory(
      id: 'w1',
      name: 'Kardus, Plastik, Kertas & Kaca',
      pointsPerKg: 100,
      icon: Icons.recycling_outlined,
      isSelected: true,
    ),
    WasteCategory(
      id: 'w2',
      name: 'Barang Besi',
      pointsPerKg: 250,
      icon: Icons.build_outlined,
      isSelected: false,
    ),
    WasteCategory(
      id: 'w3',
      name: 'Sampah Elektronik',
      pointsPerKg: 500,
      icon: Icons.devices_outlined,
      isSelected: false,
    ),
  ];

  // Step 3 Data: Simulated Photos
  final List<String> _uploadedPhotos = ['photo_1.jpg'];

  void _goToNextStep() {
    if (_currentStep == 0 && _selectedDropPointIndex < 0) {
      _showToast('Silakan pilih drop point terlebih dahulu');
      return;
    }
    if (_currentStep == 1 && _wasteCategories.every((e) => !e.isSelected)) {
      _showToast('Pilih setidaknya 1 jenis sampah');
      return;
    }
    bool success = true;
    if (_currentStep == 3) {
      try {
        final selectedNames = _wasteCategories
            .where((e) => e.isSelected)
            .map((e) => e.name)
            .join(' dan ');

        TransactionService.addTransaction(
          title: selectedNames,
          type: 'Drop-in',
        );
      } catch (e, stack) {
        success = false;
        _showToast('Error: $e');
        debugPrint('Error adding transaction: $e');
        debugPrint(stack.toString());
      }
    }
    if (success && _currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar (Hide back button on Success screen)
            if (_currentStep < 4) _buildHeader(),

            // Screen Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _buildCurrentStepView(),
              ),
            ),

            // Bottom Fixed Action Bar
            if (_currentStep < 4) _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final List<String> stepTitles = [
      'Drop-in Mandiri',
      'Isi Detail Sampah',
      'Foto Sampah',
      'Konfirmasi Setor',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stepTitles[_currentStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Step Progress Bar (4 Segments)
          Row(
            children: List.generate(4, (index) {
              final bool isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectDropPoint();
      case 1:
        return _buildStep2WasteDetails();
      case 2:
        return _buildStep3UploadPhoto();
      case 3:
        return _buildStep4Confirmation();
      case 4:
        return _buildStep5Success();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1SelectDropPoint() {
    final filteredDropPoints = _dropPoints
        .where(
          (dp) =>
              dp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              dp.address.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              icon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              hintText: 'Cari nama atau alamat drop point',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Map Placeholder Box
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2FBF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _primaryGreen.withOpacity(0.4),
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 38, color: _primaryGreen),
                    const SizedBox(height: 6),
                    Text(
                      'Peta interaktif (Google Maps API)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Placeholder — menunggu integrasi API',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 14,
                        color: _primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lokasi saya',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Pin lokasi drop point akan tampil di sini setelah API terpasang',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // List Header
        const Text(
          'DROP POINT TERDEKAT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // Drop Points List
        ...List.generate(filteredDropPoints.length, (index) {
          final dp = filteredDropPoints[index];
          final originalIndex = _dropPoints.indexOf(dp);
          final bool isSelected = _selectedDropPointIndex == originalIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDropPointIndex = originalIndex;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _primaryGreen : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _lightGreenBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dp.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dp.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${dp.hours} · ${dp.distance}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: dp.categories.map((cat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Radio<int>(
                    value: originalIndex,
                    groupValue: _selectedDropPointIndex,
                    activeColor: _primaryGreen,
                    onChanged: (value) {
                      setState(() {
                        _selectedDropPointIndex = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2WasteDetails() {
    final selectedDp = _dropPoints[_selectedDropPointIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Selected Drop Point Header Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDp.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentStep = 0),
                child: Text(
                  'Ubah',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'PILIH JENIS SAMPAH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),

        // List of Waste Items with Weight Stepper
        ...List.generate(_wasteCategories.length, (index) {
          final item = _wasteCategories[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isSelected
                    ? _primaryGreen
                    : const Color(0xFFE2E8F0),
                width: item.isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Checkbox
                    Checkbox(
                      value: item.isSelected,
                      activeColor: _primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() {
                          item.isSelected = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _lightGreenBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: _primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Name
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // Rate per kg
                    Text(
                      '${item.pointsPerKg} poin/kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Info Banner Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF9F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: _primaryGreen),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Berat & poin final akan ditentukan petugas saat penimbangan di lokasi drop point.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3UploadPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto sampah kamu sebelum berangkat ke drop point. Ini membantu petugas memverifikasi lebih cepat saat kamu tiba.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 20),

        // Upload Drop Box Area
        GestureDetector(
          onTap: () {
            setState(() {
              _uploadedPhotos.add('photo_${_uploadedPhotos.length + 1}.jpg');
            });
            _showToast('Foto baru berhasil ditambahkan!');
          },
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _primaryGreen,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 36, color: _primaryGreen),
                const SizedBox(height: 8),
                Text(
                  'Ambil atau unggah foto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG/PNG, maks. 10MB',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Thumbnail Preview List
        Row(
          children: [
            ...List.generate(_uploadedPhotos.length, (index) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _lightGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: _primaryGreen,
                      size: 30,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _uploadedPhotos.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // Add (+) Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _uploadedPhotos.add(
                    'photo_${_uploadedPhotos.length + 1}.jpg',
                  );
                });
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tips Section Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TIPS FOTO YANG BAIK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              _buildTipItem('Pastikan pencahayaan cukup terang'),
              const SizedBox(height: 6),
              _buildTipItem('Sampah sudah dipilah sesuai kategori'),
              const SizedBox(height: 6),
              _buildTipItem('Seluruh sampah terlihat jelas dalam foto'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Row(
      children: [
        Icon(Icons.check, size: 16, color: _primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Confirmation() {
    final selectedDp = _dropPoints[_selectedDropPointIndex];
    final selectedItems = _wasteCategories.where((e) => e.isSelected).toList();

    return Column(
      children: [
        // Drop Point Card
        _buildConfirmationCard(
          title: 'DROP POINT',
          onEdit: () => setState(() => _currentStep = 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedDp.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${selectedDp.address} · ${selectedDp.hours}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Jenis Sampah Card
        _buildConfirmationCard(
          title: 'JENIS SAMPAH',
          onEdit: () => setState(() => _currentStep = 1),
          child: Column(
            children: List.generate(selectedItems.length, (index) {
              final item = selectedItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${item.pointsPerKg} poin/kg',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // Foto Sampah Card
        _buildConfirmationCard(
          title: 'FOTO SAMPAH',
          onEdit: () => setState(() => _currentStep = 2),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _lightGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: _primaryGreen,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF9F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: _primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Poin akan dihitung dan ditambahkan otomatis setelah petugas menimbang sampah di drop point.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationCard({
    required String title,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  'Ubah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildStep5Success() {
    final selectedDp = _dropPoints[_selectedDropPointIndex];

    return Column(
      children: [
        const SizedBox(height: 20),
        // Success Green Check Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),

        const Text(
          'Setor berhasil dibuat!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tunjukkan atau tempelkan kode ini di kemasan\nsampah kamu saat tiba di drop point',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 24),

        // Simulated Barcode / QR Code Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryGreen, width: 2),
          ),
          child: Column(
            children: [
              // Stylized Barcode Graphic
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(painter: _BarcodePainter()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Code Box Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF9F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'WS-8X4K-2Q1M',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: _primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Next Steps Info Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LANGKAH SELANJUTNYA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bawa sampah ke ${selectedDp.name}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tunjukkan kode ini ke petugas untuk verifikasi',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Poin masuk otomatis setelah berat dikonfirmasi',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Action Buttons
        OutlinedButton(
          onPressed: () {
            _showToast('Membuka status transaksi...');
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Lihat status transaksi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 10),

        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Kembali ke Beranda',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    final String buttonText = _currentStep == 3 ? 'Konfirmasi Setor' : 'Lanjut';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStep == 0) ...[
            Text(
              'Dipilih: ${_dropPoints[_selectedDropPointIndex].name}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _goToNextStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3;

    double x = 10;
    int i = 0;
    while (x < size.width - 10) {
      final double width = (i % 3 == 0)
          ? 5
          : (i % 2 == 0)
          ? 2
          : 3;
      canvas.drawRect(Rect.fromLTWH(x, 10, width, size.height - 20), paint);
      x += width + ((i % 4 == 0) ? 6 : 3);
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
