import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'transaction_service.dart';
import 'db_helper.dart';
import 'session_service.dart';
import 'api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'chat_page.dart';
import 'widgets/barcode_painter.dart';

class PickupScheduleScreen extends StatefulWidget {
  const PickupScheduleScreen({super.key});

  @override
  _PickupScheduleScreenState createState() => _PickupScheduleScreenState();
}

class _PickupScheduleScreenState extends State<PickupScheduleScreen> {
  int selectedDateIndex = 1;
  int selectedTimeIndex = 1;
  int selectedLocationIndex = 0;

  static const List<String> _dayNames = [
    'MIN',
    'SEN',
    'SEL',
    'RAB',
    'KAM',
    'JUM',
    'SAB',
  ];

  static const List<String> _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  List<Map<String, String>> get _dates {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final day = today.add(Duration(days: i));
      String label = '';
      if (i == 0) label = 'Hari ini';
      if (i == 1) label = 'Besok';
      final isoDate =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final formattedDisplay =
          '${_dayNames[day.weekday % 7]}, ${day.day} ${_monthNames[day.month]} ${day.year}';
      return {
        'day': _dayNames[day.weekday % 7],
        'date': day.day.toString(),
        'label': label,
        'iso_date': isoDate,
        'formatted': formattedDisplay,
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

  final MapController _mapController = MapController();
  LatLng? _currentPosition;

  double _minWeight = 1.0;
  double _maxRadius = 5.0;
  String _jamBuka = '08:00';
  String _jamTutup = '17:00';
  bool _waNotif = true;
  List<Map<String, dynamic>> _wasteCategories = [];

  @override
  void initState() {
    super.initState();
    _loadConfigAndCategories();
    _getCurrentLocation();
  }

  Future<void> _loadConfigAndCategories() async {
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
          _minWeight = (config['min_weight'] as num?)?.toDouble() ?? 1.0;
          _maxRadius = (config['max_radius'] as num?)?.toDouble() ?? 5.0;
          _jamBuka = config['jam_buka']?.toString() ?? '08:00';
          _jamTutup = config['jam_tutup']?.toString() ?? '17:00';
          _waNotif = (config['wa_notif'] ?? 1) == 1;
          _wasteCategories = cats;
        });
      }
    } catch (_) {}
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentPosition!, 15.0);
      });
    }
  }

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
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGreen.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ketentuan Operasional Penjemputan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildConfigPill(
                        Icons.access_time_rounded,
                        'Jam Buka',
                        '$_jamBuka - $_jamTutup',
                        primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildConfigPill(
                        Icons.scale_rounded,
                        'Min. Berat',
                        '$_minWeight kg',
                        primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildConfigPill(
                        Icons.radar_rounded,
                        'Maks. Radius',
                        '${_maxRadius.toInt()} km',
                        primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_wasteCategories.isNotEmpty) ...[
            const Text(
              'TARIF POIN & BATAS MINIMAL SAMPAH',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _wasteCategories.map((cat) {
                  final name = cat['name'] ?? '-';
                  final point = cat['point_per_kg'] ?? 0;
                  final minW = (cat['min_weight'] as num?)?.toDouble() ?? 1.0;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.recycling_rounded,
                            size: 16, color: primaryGreen),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$point poin/kg • Min $minW kg',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
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
            const SizedBox(height: 18),
          ],
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
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 130,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _currentPosition ?? const LatLng(-4.0150, 119.6290),
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.bank_sampah',
                  ),
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
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
                    builder: (context) => PickupConfirmationScreen(
                      selectedDay: _dates[selectedDateIndex]['day']!,
                      selectedDate: _dates[selectedDateIndex]['date']!,
                      selectedIsoDate: _dates[selectedDateIndex]['iso_date']!,
                      selectedFormattedDate: _dates[selectedDateIndex]['formatted']!,
                      selectedTime: _times[selectedTimeIndex],
                      note: _noteController.text,
                      minWeight: _minWeight,
                      waNotif: _waNotif,
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

  Widget _buildConfigPill(
    IconData icon,
    String title,
    String val,
    Color primaryGreen,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: primaryGreen),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

class PickupConfirmationScreen extends StatefulWidget {
  final String selectedDay;
  final String selectedDate;
  final String selectedIsoDate;
  final String selectedFormattedDate;
  final String selectedTime;
  final String note;
  final double minWeight;
  final bool waNotif;

  const PickupConfirmationScreen({
    super.key,
    required this.selectedDay,
    required this.selectedDate,
    required this.selectedIsoDate,
    required this.selectedFormattedDate,
    required this.selectedTime,
    required this.note,
    this.minWeight = 1.0,
    this.waNotif = true,
  });

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  XFile? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _photoFile = image;
      });
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
                leading: const Icon(Icons.camera_alt, color: Color(0xFF268B07)),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF268B07),
                ),
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
                            widget.selectedFormattedDate,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.selectedTime + ' WIB',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            SessionService.address.trim().isNotEmpty
                                ? SessionService.address.trim()
                                : (widget.note.trim().isNotEmpty
                                    ? widget.note.trim()
                                    : 'Alamat utama nasabah'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGreen.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.scale_rounded, size: 20, color: primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Batas minimal total penjemputan: ${widget.minWeight} kg.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Jenis sampah dan poin final akan ditentukan setelah petugas melakukan penimbangan di lokasi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                if (widget.waNotif) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: primaryGreen),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Update status penjemputan akan dikirimkan otomatis via WhatsApp.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'FOTO BUKTI SAMPAH',
            context: context,
            content: _photoFile == null
                ? InkWell(
                    onTap: _showImageSourceDialog,
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
                          image: _photoFile != null
                              ? DecorationImage(
                                  image: kIsWeb
                                      ? NetworkImage(_photoFile!.path)
                                      : FileImage(File(_photoFile!.path))
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _photoFile == null
                            ? const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
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
                              _photoFile!.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => setState(() => _photoFile = null),
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
                      if (_photoFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Harap lampirkan foto bukti sampah'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);

                      final txId =
                          'TRX-${DateTime.now().millisecondsSinceEpoch}';
                      final String cleanNote = widget.note.trim();
                      final String userAddr = SessionService.address.trim();
                      String finalAddress = '';
                      if (userAddr.isNotEmpty && cleanNote.isNotEmpty) {
                        finalAddress = '$userAddr (Patokan: $cleanNote)';
                      } else if (cleanNote.isNotEmpty) {
                        finalAddress = cleanNote;
                      } else {
                        finalAddress = userAddr;
                      }

                      final String shortCode = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
                      final String barcodeCode = 'JS-${shortCode.length > 8 ? shortCode.substring(shortCode.length - 8, shortCode.length - 4) + '-' + shortCode.substring(shortCode.length - 4) : shortCode}';

                      final txData = <String, dynamic>{
                        'id': txId,
                        'nasabah_id': SessionService.userId,
                        'full_name': SessionService.fullName,
                        'address': finalAddress,
                        'nasabah_address': finalAddress,
                        'alamat': finalAddress,
                        'pickup_address': finalAddress,
                        'type': 'pickup',
                        'status': 'menunggu',
                        'pickup_date': widget.selectedIsoDate,
                        'pickup_time_slot': widget.selectedTime,
                        'photo_evidence': _photoFile?.name ?? '',
                        'barcode': barcodeCode,
                      };

                      if (finalAddress.isNotEmpty &&
                          SessionService.userId.isNotEmpty) {
                        try {
                          await ApiService.instance.updateUser(
                            SessionService.userId,
                            {'address': finalAddress},
                          );
                          if (SessionService.currentUser != null) {
                            SessionService.currentUser!['address'] =
                                finalAddress;
                          }
                        } catch (_) {}
                        try {
                          await DatabaseHelper.instance.updateUserProfile(
                            SessionService.userId,
                            {'address': finalAddress},
                          );
                        } catch (_) {}
                      }

                      bool ok = false;
                      try {
                        ok = await ApiService.instance.createTransaction(
                          txData,
                        );
                        if (ok && _photoFile != null) {
                          List<int>? bytes;
                          if (kIsWeb) {
                            bytes = await _photoFile!.readAsBytes();
                          }
                          final filename = _photoFile!.name;
                          await ApiService.instance.uploadTransactionPhoto(
                            txId: txId,
                            filePath: _photoFile!.path,
                            imageBytes: bytes,
                            filename: filename,
                          );
                        }
                      } catch (_) {}

                      await DatabaseHelper.instance.createTransaction(
                        txData,
                        [],
                      );

                      TransactionService.addTransaction(
                        title: 'Sampah (Belum ditimbang)',
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
                            barcodeCode: barcodeCode,
                            address: finalAddress,
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
}

class PickupSuccessScreen extends StatelessWidget {
  final String selectedDay;
  final String selectedDate;
  final String selectedTime;
  final String? barcodeCode;
  final String? address;

  const PickupSuccessScreen({
    super.key,
    required this.selectedDay,
    required this.selectedDate,
    required this.selectedTime,
    this.barcodeCode,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF268B07);
    final String finalCode = (barcodeCode != null && barcodeCode!.isNotEmpty)
        ? barcodeCode!
        : 'JS-8X4K-2Q1M';

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
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: primaryGreen,
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
              'Tunjukkan atau tempelkan barcode ini di kemasan\nsampah kamu saat penjemputan oleh petugas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),

            // Barcode container matching Drop-In Mandiri
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryGreen, width: 2),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(painter: BarcodePainter(code: finalCode)),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF9F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    finalCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: finalCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode barcode berhasil disalin!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 16, color: primaryGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildStatusStep('Menunggu', true, primaryGreen, 1),
                ),
                Expanded(
                  child: _buildStatusStep(
                    'Dikonfirmasi',
                    false,
                    primaryGreen,
                    2,
                  ),
                ),
                Expanded(
                  child: _buildStatusStep(
                    'Menuju\nlokasi',
                    false,
                    primaryGreen,
                    3,
                  ),
                ),
                Expanded(
                  child: _buildStatusStep('Selesai', false, primaryGreen, 4),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETAIL PENJEMPUTAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(Icons.calendar_today_rounded, size: 15, color: primaryGreen),
                      SizedBox(width: 8),
                    ],
                  ),
                  Text(
                    '$selectedDay, $selectedDate • $selectedTime',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (address != null && address!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.schedule, size: 16, color: primaryGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Menunggu konfirmasi & penugasan petugas kurir',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                        builder: (context) => const PickupTrackingScreen(
                          petugasName: null,
                          petugasId: null,
                        ),
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

class PickupTrackingScreen extends StatefulWidget {
  final String? petugasName;
  final String? petugasId;
  const PickupTrackingScreen({super.key, this.petugasName, this.petugasId});

  @override
  State<PickupTrackingScreen> createState() => _PickupTrackingScreenState();
}

class _PickupTrackingScreenState extends State<PickupTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  LatLng? _petugasPosition;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);

        _petugasPosition = LatLng(
          position.latitude + 0.005,
          position.longitude - 0.005,
        );

        _mapController.move(_currentPosition!, 13.5);
      });
    }
  }

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
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    _currentPosition ?? const LatLng(-4.0150, 119.6290),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bank_sampah',
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),

                      if (_petugasPosition != null)
                        Marker(
                          point: _petugasPosition!,
                          width: 45,
                          height: 45,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
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
                            widget.petugasName != null
                                ? Icons.person_rounded
                                : Icons.hourglass_empty_rounded,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.petugasName ??
                                    'Belum ada petugas yang sedang menjemput',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: widget.petugasName != null
                                      ? 15
                                      : 13,
                                ),
                              ),
                              if (widget.petugasName != null) ...[
                                const Text(
                                  '⭐ 4.9 • 320 penjemputan',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(
                                  'Motor bak • B 3821 SDK',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
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
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Batalkan',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  peerId: widget.petugasId ?? 'petugas123',
                                  peerName: widget.petugasName ?? 'Petugas',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Hubungi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
