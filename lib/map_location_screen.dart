import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';
import 'db_helper.dart';

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
  GoogleMapController? _mapController;

  final LatLng _defaultCenter = const LatLng(
    -6.200000,
    106.816666,
  ); // Default Jakarta center

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _loadDropPoints();
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Petugas sedang menuju\nlokasimu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Estimasi tiba ~12 menit',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
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

            // 2. Google Maps API
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
                    : GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _dropPoints.isNotEmpty
                              ? LatLng(
                                  double.tryParse(
                                        _dropPoints[0]['latitude'].toString(),
                                      ) ??
                                      -6.200000,
                                  double.tryParse(
                                        _dropPoints[0]['longitude'].toString(),
                                      ) ??
                                      106.816666,
                                )
                              : _defaultCenter,
                          zoom: 12.0,
                        ),
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        markers: _dropPoints.map((dp) {
                          return Marker(
                            markerId: MarkerId(dp['id'].toString()),
                            position: LatLng(
                              double.tryParse(dp['latitude'].toString()) ??
                                  -6.2,
                              double.tryParse(dp['longitude'].toString()) ??
                                  106.8,
                            ),
                            infoWindow: InfoWindow(
                              title: dp['name'].toString(),
                              snippet: dp['address'].toString(),
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                          );
                        }).toSet(),
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
                      name: 'Drop Point Margonda',
                      address: 'Jl. Margonda Raya No. 12, Depok',
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
