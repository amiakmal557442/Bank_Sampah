import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'db_helper.dart';

class SessionService {
  static Map<String, dynamic>? currentUser;

  static const String _keyUserId = 'logged_in_user_id';

  // ── Getters ──────────────────────────────────────────────────────────────

  static bool get isLoggedIn => currentUser != null;
  static String get userId => currentUser?['id'] ?? '';
  static String get fullName => currentUser?['full_name'] ?? 'Pengguna';
  static String get email => currentUser?['email'] ?? '';
  static String get phoneNumber => currentUser?['phone_number'] ?? '';
  static String get role => currentUser?['role'] ?? 'nasabah';
  static int get pointBalance => currentUser?['point_balance'] ?? 0;
  static String get address => currentUser?['address'] ?? '';

  // ── Persistensi Sesi ─────────────────────────────────────────────────────

  /// Simpan user ke memori dan simpan ID ke SharedPreferences agar sesi
  /// tetap aktif walaupun app ditutup.
  static Future<void> saveSession(Map<String, dynamic> user) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user['id'].toString());
  }

  /// Coba memuat ulang sesi dari SharedPreferences saat app dibuka.
  /// Mengembalikan true jika sesi ditemukan, false jika tidak.
  static Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_keyUserId);
      if (savedId == null || savedId.isEmpty) return false;

      // Prioritas: ambil dari XAMPP API untuk data paling baru
      try {
        final apiUser = await ApiService.instance.getUserById(savedId);
        if (apiUser != null) {
          currentUser = apiUser;
          return true;
        }
      } catch (_) {}

      // Fallback ke local DB
      final user = await DatabaseHelper.instance.getUserById(savedId);
      if (user == null) {
        await prefs.remove(_keyUserId);
        return false;
      }

      currentUser = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Refresh data user terbaru — prioritas dari XAMPP API agar point_balance
  /// selalu sinkron dengan yang ada di MySQL.
  static Future<void> refresh() async {
    if (userId.isEmpty) return;
    try {
      // Coba ambil dari XAMPP API dulu (poin paling akurat)
      final apiUser = await ApiService.instance.getUserById(userId);
      if (apiUser != null) {
        // Gabungkan dengan currentUser agar field lokal tidak hilang
        currentUser = {...?currentUser, ...apiUser};
        return;
      }
    } catch (_) {}

    // Fallback ke local DB jika API tidak tersedia
    final user = await DatabaseHelper.instance.getUserById(userId);
    if (user != null) {
      currentUser = user;
    }
  }

  /// Logout: hapus sesi dari memori dan SharedPreferences.
  static Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
