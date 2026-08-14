import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'db_helper.dart';
import 'jemput_sampah_page.dart';
import 'session_service.dart';

class MapLocationScreen extends StatefulWidget {
  final bool showBottomNav;
  const MapLocationScreen({Key? key, this.showBottomNav = false})
    : super(key: key);

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Semua jenis',
    'Plastik',
    'Kertas',
    'Kardus',
    'Logam',
  ];

  List<Map<String, dynamic>> _dropPoints = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();

  final LatLng _defaultParepare = const LatLng(-4.0150, 119.6290);
  LatLng? _currentPosition;

  bool _hasActivePickup = false;
  String? _activePetugasName;
  int _estimatedMinutes = 12;
  Timer? _etaTimer;

  bool _hasActiveDropIn = false;
  String? _activeDropInDpId;
  String? _activePetugasId;

  @override
  void initState() {
    super.initState();
    _loadDropPoints();
    _checkActivePickup();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
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

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentPosition!, 13.0);
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkActivePickup() async {
    if (!SessionService.isLoggedIn) return;

    try {
      final txs = await ApiService.instance.getTransactions(
        nasabahId: SessionService.userId,
        status: 'dikonfirmasi,menuju_lokasi,tiba',
      );

      bool foundPickup = false;
      bool foundDropIn = false;

      // Find an active transaction with a petugas assigned
      for (var tx in txs) {
        final type = (tx['tipe_tugas'] ?? tx['type'] ?? '').toString().toLowerCase();
        final isDropIn = type == 'drop-in' || type == 'drop_in';

        if (tx['petugas_id'] != null && tx['petugas_id'].toString().isNotEmpty) {
          if (!isDropIn && !foundPickup) {
            foundPickup = true;
            setState(() {
              _hasActivePickup = true;
              _activePetugasId = tx['petugas_id']?.toString();
              _activePetugasName = tx['petugas_name'] ?? 'Petugas';
              _estimatedMinutes = 12;
            });
            _startEtaTimer();
          } else if (isDropIn && !foundDropIn) {
            foundDropIn = true;
            setState(() {
              _hasActiveDropIn = true;
              _activeDropInDpId = tx['drop_point_id']?.toString();
            });
          }
        }
      }

      if (!foundPickup && mounted) {
        setState(() => _hasActivePickup = false);
        _etaTimer?.cancel();
      }
      if (!foundDropIn && mounted) {
        setState(() => _hasActiveDropIn = false);
      }
    } catch (_) {}
  }

  void _startEtaTimer() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_estimatedMinutes > 1) {
        setState(() {
          _estimatedMinutes--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadDropPoints() async {
    List<Map<String, dynamic>> dps = [];
    try {
      dps = await ApiService.instance.getDropPoints();
    } catch (_) {}
    if (dps.isEmpty) {
      dps = await DatabaseHelper.instance.getDropPoints();
    }
    if (!mounted) return;
    setState(() {
      _dropPoints = dps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        title: const Text(
          'Peta & Lokasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari drop point atau alamat',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Banner Pelacakan Aktif
            if (_hasActivePickup)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Petugas sedang menuju\nlokasimu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimasi tiba ~$_estimatedMinutes menit',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PickupTrackingScreen(
                              petugasName: _activePetugasName,
                              petugasId: _activePetugasId,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: const [
                          Text(
                            'Lacak',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.green,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Banner Drop-in Aktif
            if (_hasActiveDropIn)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'DROP-IN SUDAH SIAP DI JEMPUT',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Flutter Map (Mendukung Desktop & Mobile)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 250, // Slightly taller for better view
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition ?? _defaultParepare,
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.bank_sampah',
                          ),
                          MarkerLayer(
                            markers: [
                              ..._dropPoints.map((dp) {
                                final dpId = dp['id']?.toString();
                                final lat = double.tryParse(dp['latitude'].toString()) ?? -4.0131;
                                final lng = double.tryParse(dp['longitude'].toString()) ?? 119.6250;
                                
                                final isActiveDropIn = _hasActiveDropIn && dpId != null && dpId == _activeDropInDpId;

                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: isActiveDropIn ? 50 : 40,
                                  height: isActiveDropIn ? 50 : 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(dp['name'].toString())),
                                      );
                                    },
                                    child: Icon(
                                      isActiveDropIn ? Icons.person_pin_circle : Icons.location_on, 
                                      color: isActiveDropIn ? Colors.orange : Colors.green, 
                                      size: isActiveDropIn ? 50 : 40,
                                    ),
                                  ),
                                );
                              }),
                              if (_currentPosition != null)
                                Marker(
                                  point: _currentPosition!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Center(
                child: Text(
                  'Belum terhubung API — gunakan daftar di bawah untuk\nsementara',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

            // 3. Filter Kategori Sampah
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  bool isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.green[700],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.green[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 4. Daftar Drop Point Terdekat
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DROP POINT TERDEKAT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_dropPoints.length} lokasi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Item Drop Point
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dropPoints.isEmpty ? 1 : _dropPoints.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  if (_dropPoints.isEmpty) {
                    return _buildDropPointCard(
                      name: 'Drop Point Pusat Parepare',
                      address: 'Jl. Bau Massepe No. 10, Parepare',
                      hours: '08:00–17:00',
                      status: 'aman',
                    );
                  }
                  final dp = _dropPoints[index];
                  return _buildDropPointCard(
                    name: dp['name'] as String,
                    address: dp['address'] as String,
                    hours: (dp['operating_hours'] as String?) ?? '08:00–17:00',
                    status: (dp['capacity_status'] as String?) ?? 'aman',
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      // 5. Bottom Navigation Bar (hanya ditampilkan jika showBottomNav true)
      bottomNavigationBar: widget.showBottomNav
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: 1,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.green[700],
                unselectedItemColor: Colors.grey[400],
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    activeIcon: Icon(Icons.map),
                    label: 'Peta',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.recycling),
                    label: 'Setor',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Riwayat',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildDropPointCard({
    required String name,
    required String address,
    required String hours,
    required String status,
  }) {
    final bool isOpen = status != 'tutup';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: Colors.green, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOpen ? 'Buka' : 'Tutup',
                        style: TextStyle(
                          color: isOpen ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      hours,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMiniChip('Plastik'),
                    _buildMiniChip('Kertas'),
                    _buildMiniChip('Logam'),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Icon(Icons.chevron_right, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      ),
    );
  }
}
