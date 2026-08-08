import 'package:flutter/material.dart';
import 'session_service.dart';
import 'api_service.dart';

class AlamatPenjemputanPage extends StatefulWidget {
  const AlamatPenjemputanPage({super.key});

  @override
  State<AlamatPenjemputanPage> createState() => _AlamatPenjemputanPageState();
}

class _AlamatPenjemputanPageState extends State<AlamatPenjemputanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF16A34A);
  final Color darkGreen = const Color(0xFF14532D);

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: SessionService.address);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final Map<String, dynamic> updateData = {
        'address': _addressController.text.trim(),
      };
      
      final success = await ApiService.instance.updateUserProfile(
        SessionService.userId,
        updateData,
      );
      
      if (success) {
        await SessionService.refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alamat penjemputan berhasil diperbarui!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Gagal menyimpan alamat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Alamat Penjemputan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryGreen),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Alamat ini akan digunakan sebagai lokasi default saat Anda meminta penjemputan sampah oleh petugas.',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Detail Alamat Lengkap',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Contoh: Jl. Sudirman No. 123, RT 01/RW 02, Kec. Melati, Kota Hijau',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryGreen, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat tidak boleh kosong';
                  }
                  if (value.trim().length < 10) {
                    return 'Alamat terlalu singkat, mohon isi lebih detail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Simpan Alamat',
                          style: TextStyle(
                            fontSize: 16,
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
}
