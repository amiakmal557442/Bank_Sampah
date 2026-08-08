import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service untuk berkomunikasi dengan API Backend (PHP + MySQL XAMPP)
/// Ganti BASE_URL jika menjalankan di perangkat Android fisik dengan IP lokal Anda.
class ApiService {
  // =====================================================================
  // KONFIGURASI URL — sesuaikan dengan platform yang Anda gunakan:
  // - Windows Desktop / Web  : http://localhost/bank_sampah_api
  // - Android Emulator       : http://10.0.2.2/bank_sampah_api
  // - Android Fisik (Wi-Fi)  : http://192.168.x.x/bank_sampah_api
  // =====================================================================
  static const String baseUrl = 'https://dreamland-single-counting.ngrok-free.dev/bank_sampah_api';

  static final ApiService instance = ApiService._();
  ApiService._();

  // Header default untuk semua request
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true', // bypass ngrok browser warning page
  };

  // ─────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    Uri uri = Uri.parse('$baseUrl/$endpoint');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    final response = await http.get(uri, headers: _headers);
    return _handle(response);
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> _put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? params,
  }) async {
    Uri uri = Uri.parse('$baseUrl/$endpoint');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> _delete(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    Uri uri = Uri.parse('$baseUrl/$endpoint');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    final response = await http.delete(uri, headers: _headers);
    return _handle(response);
  }

  Map<String, dynamic> _handle(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw Exception(body['message'] ?? 'Terjadi kesalahan');
  }

  // ─────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────

  /// Login: kembalikan data user jika berhasil, null jika gagal
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _post('auth/login.php', {
        'email': email,
        'password': password,
      });
      if (res['success'] == true && res['data'] != null) {
        return res['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────
  // USERS
  // ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    final params = role != null ? {'role': role} : null;
    final res = await _get('users/index.php', params: params);
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    }
    return [];
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    final res = await _post('users/index.php', data);
    return res['success'] == true;
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _put('users/index.php', data, params: {'id': id});
    return res['success'] == true;
  }

  Future<bool> deleteUser(String id) async {
    final res = await _delete('users/index.php', params: {'id': id});
    return res['success'] == true;
  }

  /// Update data profil user (nama, email, no HP, alamat, foto_profil)
  Future<bool> updateUserProfile(String id, Map<String, dynamic> data) async {
    try {
      final res = await _put('users/index.php', data, params: {'id': id});
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Upload foto profil ke XAMPP server via multipart request
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/users/upload_avatar.php');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });
      request.fields['user_id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('profile_picture', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final res = _handle(response);
      if (res['success'] == true) {
        return res['profile_picture'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Helper untuk mendapatkan URL gambar profil lengkap
  static String? getProfileImageUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    if (filename.startsWith('http://') || filename.startsWith('https://')) {
      return filename;
    }
    return '$baseUrl/uploads/profiles/$filename';
  }

  /// Ambil satu user berdasarkan ID dari XAMPP (termasuk point_balance terbaru)
  Future<Map<String, dynamic>?> getUserById(String id) async {
    try {
      final res = await _get('users/index.php', params: {'id': id});
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first);
        } else if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────
  // TRANSACTIONS
  // ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTransactions({
    String? status,
    String? nasabahId,
    String? petugasId,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (nasabahId != null) params['nasabah_id'] = nasabahId;
    if (petugasId != null) params['petugas_id'] = petugasId;
    final res = await _get('transactions/index.php', params: params);
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getTransactionById(String id) async {
    final res = await _get('transactions/index.php', params: {'id': id});
    if (res['success'] == true) {
      return res['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<bool> createTransaction(Map<String, dynamic> data) async {
    final res = await _post('transactions/index.php', data);
    return res['success'] == true;
  }

  Future<bool> updateTransactionStatus(String id, String status) async {
    final res = await _put(
      'transactions/index.php',
      {'status': status},
      params: {'id': id},
    );
    return res['success'] == true;
  }

  Future<bool> updateTransaction(String id, Map<String, dynamic> data) async {
    final res = await _put('transactions/index.php', data, params: {'id': id});
    return res['success'] == true;
  }

  // ─────────────────────────────────────────────────
  // DROP POINTS
  // ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDropPoints() async {
    final res = await _get('drop_points/index.php');
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    }
    return [];
  }

  Future<bool> createDropPoint(Map<String, dynamic> data) async {
    final res = await _post('drop_points/index.php', data);
    return res['success'] == true;
  }

  Future<bool> updateDropPoint(String id, Map<String, dynamic> data) async {
    final res = await _put('drop_points/index.php', data, params: {'id': id});
    return res['success'] == true;
  }

  Future<bool> deleteDropPoint(String id) async {
    final res = await _delete('drop_points/index.php', params: {'id': id});
    return res['success'] == true;
  }

  // ─────────────────────────────────────────────────
  // WASTE CATEGORIES
  // ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWasteCategories() async {
    final res = await _get('waste_categories/index.php');
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    }
    return [];
  }

  Future<bool> createWasteCategory(Map<String, dynamic> data) async {
    final res = await _post('waste_categories/index.php', data);
    return res['success'] == true;
  }

  Future<bool> updateWasteCategory(int id, Map<String, dynamic> data) async {
    final res = await _put(
      'waste_categories/index.php',
      data,
      params: {'id': id.toString()},
    );
    return res['success'] == true;
  }

  Future<bool> deleteWasteCategory(int id) async {
    final res = await _delete(
      'waste_categories/index.php',
      params: {'id': id.toString()},
    );
    return res['success'] == true;
  }

  // ─────────────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final res = await _get('dashboard/stats.php');
      if (res['success'] == true) {
        return res['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────
  // TASKS (Petugas Lapangan)
  // ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingTasks({
    String? petugasId,
    List<String> statuses = const ['dikonfirmasi', 'menuju_lokasi', 'tiba'],
    String? type,
  }) async {
    final params = <String, String>{
      'status': statuses.join(','),
    };
    if (petugasId != null) params['petugas_id'] = petugasId;
    if (type != null && type.isNotEmpty) params['type'] = type;
    final res = await _get('tasks/index.php', params: params);
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    }
    return [];
  }

  Future<bool> updateTaskStatus(String transactionId, String status) async {
    final res = await _put(
      'tasks/index.php',
      {'status': status},
      params: {'id': transactionId},
    );
    return res['success'] == true;
  }

  // ─────────────────────────────────────────────────
  // HEALTH CHECK (tes koneksi ke API)
  // ─────────────────────────────────────────────────

  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/config.php'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
