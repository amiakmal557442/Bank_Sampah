import 'package:flutter/material.dart';
import '../api_service.dart';

class ImageViewerDialog extends StatelessWidget {
  final String photoEvidence;

  const ImageViewerDialog({
    Key? key,
    required this.photoEvidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Bersihkan data dari spasi dan pecah jika ada multi file
    final files = photoEvidence
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (files.isEmpty) {
      return AlertDialog(
        title: const Text('Kesalahan'),
        content: const Text('Data foto tidak valid atau kosong.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final url = '${ApiService.baseUrl}/uploads/transactions/${files[index]}';
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image, color: Colors.grey, size: 60),
                              const SizedBox(height: 16),
                              const Text(
                                'Gambar gagal dimuat.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'URL:\n$url',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (files.length > 1)
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Geser untuk melihat gambar lain (${files.length} foto)',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Helper untuk menampilkan dialog dengan mudah
  static void show(BuildContext context, String? photoEvidence) {
    if (photoEvidence == null || photoEvidence.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada foto bukti.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => ImageViewerDialog(photoEvidence: photoEvidence),
    );
  }
}
