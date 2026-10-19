import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'db_helper.dart';

class SessionService {
  static Map<String, dynamic>? currentUser;

  static const String _keyUserId = 'logged_in_user_id';
  static const String _keyToken = 'jwt_token';

  static bool get isLoggedIn => currentUser != null;
  static String get userId => currentUser?['id'] ?? '';
  static String get fullName => currentUser?['full_name'] ?? 'Pengguna';
  static String get email => currentUser?['email'] ?? '';
  static String get phoneNumber => currentUser?['phone_number'] ?? '';
  static String get role => currentUser?['role'] ?? 'nasabah';
  static int get pointBalance {
    final val = currentUser?['point_balance'];
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
  static String get address => currentUser?['address'] ?? '';
  static String get profilePicture => currentUser?['profile_picture'] ?? '';

  static Future<void> saveSession(Map<String, dynamic> user) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user['id'].toString());

    if (user.containsKey('token')) {
      await prefs.setString(_keyToken, user['token']);
      ApiService.setToken(user['token']);
    }
  }

  static Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_keyUserId);
      final savedToken = prefs.getString(_keyToken);

      if (savedId == null || savedId.isEmpty) return false;

      if (savedToken != null && savedToken.isNotEmpty) {
        ApiService.setToken(savedToken);
      }

      try {
        final apiUser = await ApiService.instance.getUserById(savedId);
        if (apiUser != null) {
          currentUser = apiUser;
          return true;
        }
      } catch (_) {}

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

  static Future<void> refresh() async {
    if (userId.isEmpty) return;
    try {
      final apiUser = await ApiService.instance.getUserById(userId);
      if (apiUser != null) {
        currentUser = {...?currentUser, ...apiUser};
        return;
      }
    } catch (_) {}

    final user = await DatabaseHelper.instance.getUserById(userId);
    if (user != null) {
      currentUser = user;
    }
  }

  static Future<void> logout() async {
    currentUser = null;
    ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyToken);
  }
}
