import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'session_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  XFile? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final Color primaryGreen = const Color(0xFF16A34A);
  final Color lightGreenBg = const Color(0xFFDCFCE7);

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: SessionService.fullName);
    _emailController = TextEditingController(text: SessionService.email);
    _addressController =
        TextEditingController(text: SessionService.address);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: lightGreenBg,
                    child: Icon(Icons.photo_library_rounded,
                        color: primaryGreen),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: lightGreenBg,
                    child:
                        Icon(Icons.camera_alt_rounded, color: primaryGreen),
                  ),
                  title: const Text('Ambil Foto Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_selectedImage != null ||
                    SessionService.profilePicture.isNotEmpty)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEE2E2),
                      child:
                          Icon(Icons.delete_outline_rounded, color: Colors.red),
                    ),
                    title: const Text(
                      'Hapus Foto Profil',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? updatedPhotoName;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        String filename = _selectedImage!.name;
        if (!filename.contains('.')) {
          filename += '.jpg';
        }
        updatedPhotoName = await ApiService.instance.uploadProfilePicture(
          SessionService.userId,
          bytes,
          filename,
        );
      }

      // 2. Prepare payload update profil
      final Map<String, dynamic> updateData = {
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (updatedPhotoName != null) {
        updateData['profile_picture'] = updatedPhotoName;
      }

      // 3. Simpan perubahan ke API MySQL
      final success = await ApiService.instance.updateUserProfile(
        SessionService.userId,
        updateData,
      );

      if (success) {
        await SessionService.refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Gagal menyimpan perubahan ke server.');
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatarImage() {
    if (_selectedImage != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 54,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return _buildInitialAvatar();
        },
      );
    }

    final String profilePic = SessionService.profilePicture;
    final String? imageUrl = ApiService.getProfileImageUrl(profilePic);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 108,
          height: 108,
          fit: BoxFit.cover,
          headers: const {'ngrok-skip-browser-warning': 'true'},
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialAvatar();
          },
        ),
      );
    }

    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    final names = SessionService.fullName.split(' ');
    String initial = 'US';
    if (names.length >= 2) {
      initial = (names[0].isNotEmpty ? names[0][0] : '') +
          (names[1].isNotEmpty ? names[1][0] : '');
    } else if (names.isNotEmpty && names[0].isNotEmpty) {
      initial = names[0][0];
    }

    return CircleAvatar(
      radius: 54,
      backgroundColor: lightGreenBg,
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Ubah Profil',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),

              // --- AVATAR FOTO PROFIL & PENCIL OVERLAY ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryGreen.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: _buildAvatarImage(),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showImagePickerModal,
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // --- FORM ISIAN DATA PROFIL ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Alamat Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!val.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Alamat Tempat Tinggal',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- BUTTON SIMPAN PERUBAHAN ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
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
                          'Simpan Perubahan',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }
}
