import 'package:flutter/material.dart';
import 'transaction_service.dart';
import 'session_service.dart';
import 'db_helper.dart';
import 'api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

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

  // Step 1 Data: Drop Points (loaded from DB)
  int _selectedDropPointIndex = 0;
  List<DropPoint> _dropPoints = [];

  // Step 2 Data: Waste Items (loaded from DB)
  List<WasteCategory> _wasteCategories = [];
  bool _isLoadingData = true;

  // Step 3 Data: Photos
  final List<XFile> _uploadedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _uploadedPhotos.add(image);
      });
      _showToast('Foto baru berhasil ditambahkan!');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: _primaryGreen),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: _primaryGreen),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _goToNextStep() async {
    if (_currentStep == 0 && _selectedDropPointIndex < 0) {
      _showToast('Silakan pilih drop point terlebih dahulu');
      return;
    }
    bool success = true;
    if (_currentStep == 2) {
      try {
        final txId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
        final txData = <String, dynamic>{
          'id': txId,
          'nasabah_id': SessionService.userId,
          'full_name': SessionService.fullName,
          'address': SessionService.address,
          'drop_point_id': _dropPoints[_selectedDropPointIndex].id,
          'type': 'drop_in',
          'status': 'menunggu',
        };

        bool ok = false;
        try {
          ok = await ApiService.instance.createTransaction(txData);
          if (ok) {
            for (var photoFile in _uploadedPhotos) {
              final bytes = await photoFile.readAsBytes();
              final filename = photoFile.name;
              await ApiService.instance.uploadTransactionPhoto(txId, bytes, filename);
            }
          }
        } catch (_) {}

        await DatabaseHelper.instance.createTransaction(txData, []);

        TransactionService.addTransaction(
          title: 'Sampah (Belum ditimbang)',
          type: 'Drop-in',
        );
      } catch (e, stack) {
        success = false;
        _showToast('Error: $e');
        debugPrint('Error adding transaction: $e');
        debugPrint(stack.toString());
      }
    }
    if (success && _currentStep < 3) {
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
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbDps = await DatabaseHelper.instance.getDropPoints();
    final dbCats = await DatabaseHelper.instance.getWasteCategories();
    if (!mounted) return;
    setState(() {
      _dropPoints = dbDps
          .map(
            (m) => DropPoint(
              id: m['id']?.toString() ?? '',
              name: m['name'] as String,
              address: m['address'] as String,
              hours: 'Buka ${m['operating_hours'] ?? '08:00-17:00'}',
              distance: '~-',
              categories: ['Semua Jenis'],
            ),
          )
          .toList();
      _wasteCategories = dbCats
          .map(
            (m) => WasteCategory(
              id: m['id'].toString(),
              name: m['name'] as String,
              pointsPerKg: (m['point_per_kg'] as int?) ?? 0,
              icon: Icons.recycling_outlined,
            ),
          )
          .toList();
      _isLoadingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF268B07)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar (Hide back button on Success screen)
            if (_currentStep < 3) _buildHeader(),

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
            if (_currentStep < 3) _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final List<String> stepTitles = [
      'Drop-in Mandiri',
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
          // Step Progress Bar (3 Segments)
          Row(
            children: List.generate(3, (index) {
              final bool isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
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
        return _buildStep2UploadPhoto();
      case 2:
        return _buildStep3Confirmation();
      case 3:
        return _buildStep4Success();
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

  Widget _buildStep2UploadPhoto() {
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
          onTap: _showImageSourceDialog,
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
                      image: DecorationImage(
                        image: kIsWeb ? NetworkImage(_uploadedPhotos[index].path) : FileImage(File(_uploadedPhotos[index].path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
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
              onTap: _showImageSourceDialog,
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

  Widget _buildStep3Confirmation() {
    final selectedDp = _dropPoints[_selectedDropPointIndex];

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

        // Foto Sampah Card
        _buildConfirmationCard(
          title: 'FOTO SAMPAH',
          onEdit: () => setState(() => _currentStep = 1),
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
                  'Jenis sampah dan poin akan ditentukan oleh petugas saat penimbangan di drop point.',
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

  Widget _buildStep4Success() {
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
    final String buttonText = _currentStep == 2 ? 'Konfirmasi Setor' : 'Lanjut';

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
              onPressed: () async => await _goToNextStep(),
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
