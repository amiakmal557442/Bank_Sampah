class SessionService {
  static Map<String, dynamic>? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static String get userId => currentUser?['id'] ?? '';
  static String get fullName => currentUser?['full_name'] ?? 'Budi Santoso';
  static String get email => currentUser?['email'] ?? 'budi@gmail.com';
  static String get phoneNumber =>
      currentUser?['phone_number'] ?? '+62 812-3456-7890';
  static String get role => currentUser?['role'] ?? 'nasabah';
  static int get pointBalance => currentUser?['point_balance'] ?? 4820;

  static void logout() {
    currentUser = null;
  }
}
