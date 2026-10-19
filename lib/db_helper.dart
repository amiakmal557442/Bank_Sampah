import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static final List<Map<String, dynamic>> _webUsers = [
    {
      'id': 'USR-001',
      'phone_number': '081234567890',
      'email': 'admin@banksampah.com',
      'full_name': 'Akmal Ahsan',
      'password':
          '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
      'role': 'admin',
      'address': 'Kantor Pusat Bank Sampah',
      'default_setor_method': null,
      'point_balance': 0,
      'is_active': 1,
      'profile_picture': null,
    },
    {
      'id': 'USR-002',
      'phone_number': '081987654321',
      'email': 'tokan@banksampah.com',
      'full_name': 'Tokan Shimada',
      'password':
          '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
      'role': 'petugas',
      'address': 'Jl. Petugas No. 1',
      'default_setor_method': null,
      'point_balance': 0,
      'is_active': 1,
      'profile_picture': null,
    },
  ];

  static final Map<String, bool> _webPermissions = {
    'Overview': true,
    'Master Data': false,
    'Manajemen Transaksi': true,
    'Operasional Lapangan': false,
    'Laporan & Analitik': false,
    'Konfigurasi Sistem': false,
    'Kelola Akun & Role': false,
    'Audit Log': false,
  };

  static Map<String, dynamic> _webSystemConfig = {
    'min_weight': 1.0,
    'max_radius': 5.0,
    'min_withdraw': 10000.0,
    'point_rate': 1.0,
    'auto_assign': 1,
    'jam_buka': '08:00',
    'jam_tutup': '17:00',
    'wa_notif': 1,
    'push_notif': 1,
  };

  static final List<Map<String, dynamic>> _webDropPoints = [
    {
      'id': 'DP-001',
      'name': 'Drop Point Pasar Lakessi',
      'address': 'Jl. Lasinrang No. 12, Pasar Lakessi, Parepare',
      'latitude': -4.0045,
      'longitude': 119.6240,
      'capacity_status': 'aman',
      'operating_hours': '07:00 - 17:00',
    },
    {
      'id': 'DP-002',
      'name': 'Drop Point Lumpue',
      'address': 'Jl. H.A.M. Arsyad, Lumpue, Bacukiki Barat, Parepare',
      'latitude': -4.0410,
      'longitude': 119.6280,
      'capacity_status': 'aman',
      'operating_hours': '08:00 - 17:00',
    },
    {
      'id': 'DP-003',
      'name': 'Drop Point Pusat Parepare',
      'address': 'Jl. Bau Massepe No. 10, Ujung, Parepare',
      'latitude': -4.0150,
      'longitude': 119.6290,
      'capacity_status': 'aman',
      'operating_hours': '08:00 - 17:00',
    },
    {
      'id': 'DP-004',
      'name': 'Drop Point Soreang',
      'address': 'Jl. Jendral Sudirman No. 5, Soreang, Parepare',
      'latitude': -3.9868,
      'longitude': 119.6341,
      'capacity_status': 'aman',
      'operating_hours': '09:00 - 15:00',
    },
  ];

  static final List<Map<String, dynamic>> _webWasteCategories = [
    {
      'id': 1,
      'name': 'Plastik',
      'point_per_kg': 2000,
      'min_weight': 1.0,
      'icon_url': 'icon_plastik.png',
      'is_active': 1,
    },
    {
      'id': 2,
      'name': 'Kertas & Kardus',
      'point_per_kg': 1500,
      'min_weight': 1.0,
      'icon_url': 'icon_kertas.png',
      'is_active': 1,
    },
    {
      'id': 3,
      'name': 'Besi & Logam',
      'point_per_kg': 3500,
      'min_weight': 1.0,
      'icon_url': 'icon_besi.png',
      'is_active': 1,
    },
    {
      'id': 4,
      'name': 'Elektronik Bekas',
      'point_per_kg': 5000,
      'min_weight': 1.0,
      'icon_url': 'icon_elektronik.png',
      'is_active': 1,
    },
  ];

  static final List<Map<String, dynamic>> _webTransactions = [];

  static final List<Map<String, dynamic>> _webTransactionItems = [];

  static final List<Map<String, dynamic>> _webWithdrawals = [];

  DatabaseHelper._init();

  Future<void> initWebStorage() async {
    if (!kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final usersJson = prefs.getString('web_users');
      if (usersJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(usersJson);
          _webUsers.clear();
          _webUsers.addAll(decoded.cast<Map<String, dynamic>>());
        } catch (e) {}
      } else {
        await _saveWebUsers();
      }

      final configJson = prefs.getString('web_system_config');
      if (configJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(configJson);
          _webSystemConfig.addAll(decoded);
        } catch (e) {}
      } else {
        await _saveWebSystemConfig();
      }

      final wasteCatsJson = prefs.getString('web_waste_categories');
      if (wasteCatsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(wasteCatsJson);
          _webWasteCategories.clear();
          _webWasteCategories.addAll(decoded.cast<Map<String, dynamic>>());
        } catch (e) {}
      } else {
        await _saveWebWasteCategories();
      }

      final logsJson = prefs.getString('web_audit_logs');
      if (logsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(logsJson);
          _webAuditLogs.clear();
          _webAuditLogs.addAll(decoded.cast<Map<String, dynamic>>());
        } catch (e) {}
      } else {
        _webAuditLogs.addAll([
          {
            'time': DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toString()
                .substring(0, 16),
            'user_name': 'Akmal Ahsan',
            'role': 'Administrator',
            'module': 'Authentication',
            'action': 'Login ke dalam sistem',
            'ip_address': '192.168.1.5',
            'status': 'BERHASIL',
          },
        ]);
        await _saveWebAuditLogs();
      }
    } catch (e) {}
  }

  Future<void> _saveWebUsers() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('web_users', jsonEncode(_webUsers));
  }

  Future<void> _saveWebSystemConfig() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('web_system_config', jsonEncode(_webSystemConfig));
  }

  Future<void> _saveWebWasteCategories() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'web_waste_categories',
      jsonEncode(_webWasteCategories),
    );
  }

  Future<void> _saveWebAuditLogs() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('web_audit_logs', jsonEncode(_webAuditLogs));
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('bank_sampah.db');
    return _database!;
  }

  Future<Database?> _initDB(String filePath) async {
    if (kIsWeb) return null;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );

    await _ensureDefaultAccounts(db);

    return db;
  }

  Future<void> _ensureDefaultAccounts(Database db) async {
    for (var u in _webUsers) {
      await db.insert('users', u, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1',
        );
        await db.execute('UPDATE users SET is_active = 1');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE system_configs (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time TEXT NOT NULL,
            user_name TEXT NOT NULL,
            role TEXT NOT NULL,
            module TEXT NOT NULL,
            action TEXT NOT NULL,
            ip_address TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');

        await db.execute('''
          INSERT INTO audit_logs (time, user_name, role, module, action, ip_address, status)
          VALUES ('04 Aug 2026 - 10:42', 'Akmal Ahsan', 'Administrator', 'Konfigurasi Sistem', 'Mengubah Rasio Poin dari Rp 1 ke Rp 1.2/Poin', '192.168.1.10', 'SUKSES')
        ''');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profile_picture TEXT');
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        phone_number TEXT UNIQUE,
        email TEXT UNIQUE,
        full_name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'nasabah',
        address TEXT,
        default_setor_method TEXT,
        point_balance INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        profile_picture TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE drop_points (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        capacity_status TEXT DEFAULT 'aman',
        operating_hours TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE waste_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        point_per_kg INTEGER NOT NULL,
        icon_url TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        nasabah_id TEXT NOT NULL,
        petugas_id TEXT,
        drop_point_id TEXT,
        type TEXT NOT NULL,
        status TEXT DEFAULT 'menunggu',
        pickup_date TEXT,
        pickup_time_slot TEXT,
        pickup_lat REAL,
        pickup_lng REAL,
        total_est_points INTEGER DEFAULT 0,
        total_actual_points INTEGER DEFAULT 0,
        photo_evidence TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nasabah_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (petugas_id) REFERENCES users (id) ON DELETE SET NULL,
        FOREIGN KEY (drop_point_id) REFERENCES drop_points (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        waste_category_id INTEGER NOT NULL,
        estimated_weight REAL,
        actual_weight REAL,
        final_points INTEGER,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (waste_category_id) REFERENCES waste_categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE withdrawals (
        id TEXT PRIMARY KEY,
        nasabah_id TEXT NOT NULL,
        points_deducted INTEGER NOT NULL,
        method TEXT NOT NULL,
        account_details TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nasabah_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE worker_logs (
        id TEXT PRIMARY KEY,
        petugas_id TEXT NOT NULL,
        log_type TEXT,
        location_lat REAL,
        location_lng REAL,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (petugas_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE b2b_sales (
        id TEXT PRIMARY KEY,
        partner_name TEXT NOT NULL,
        total_weight REAL NOT NULL,
        total_margin REAL NOT NULL,
        sale_date TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE system_configs (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time TEXT NOT NULL,
        user_name TEXT NOT NULL,
        role TEXT NOT NULL,
        module TEXT NOT NULL,
        action TEXT NOT NULL,
        ip_address TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    for (var log in _webAuditLogs) {
      await db.insert('audit_logs', log);
    }

    for (var u in _webUsers) {
      await db.insert('users', u);
    }
    for (var dp in _webDropPoints) {
      await db.insert('drop_points', dp);
    }
    for (var wc in _webWasteCategories) {
      await db.insert('waste_categories', wc);
    }
    for (var trx in _webTransactions) {
      await db.insert('transactions', trx);
    }
    for (var item in _webTransactionItems) {
      await db.insert('transaction_items', item);
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verifyAdminPassword(String email, String password) async {
    final List<Map<String, dynamic>> res = await _webUsers
        .where(
          (u) =>
              u['email'] == email &&
              u['password'] == password &&
              u['role'] == 'admin',
        )
        .toList();
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getChatMessages(
    String user1,
    String user2,
  ) async {
    if (kIsWeb) {
      return [];
    }
    final db = await instance.database;
    if (db == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where:
          '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [user1, user2, user2, user1],
      orderBy: 'created_at ASC',
    );
    return maps;
  }

  Future<bool> insertChatMessage(
    String senderId,
    String receiverId,
    String message,
  ) async {
    if (kIsWeb) return false;
    final db = await instance.database;
    if (db == null) return false;

    final int res = await db.insert('chat_messages', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
    });
    return res > 0;
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final hashedPassword = _hashPassword(password);

    if (kIsWeb) {
      try {
        return _webUsers.firstWhere(
          (u) =>
              u['email'].toString().toLowerCase() == cleanEmail &&
              u['password'] == hashedPassword,
        );
      } catch (e) {
        return null;
      }
    }

    final db = await instance.database;
    if (db == null) return null;
    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [cleanEmail, hashedPassword],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<bool> registerUser(Map<String, dynamic> user) async {
    final userToSave = Map<String, dynamic>.from(user);
    if (userToSave.containsKey('password')) {
      userToSave['password'] = _hashPassword(userToSave['password']);
    }

    if (kIsWeb) {
      final email = userToSave['email']?.toString().toLowerCase();
      final phone = userToSave['phone_number']?.toString();

      final exists = _webUsers.any(
        (u) =>
            (email != null && u['email'].toString().toLowerCase() == email) ||
            (phone != null && u['phone_number']?.toString() == phone),
      );

      if (exists) return false;

      _webUsers.add(userToSave);
      await _saveWebUsers();
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.insert('users', userToSave);

      final auditLog = {
        'time':
            '${DateTime.now().day.toString().padLeft(2, '0')} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year} - ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'user_name': userToSave['full_name'] ?? 'Unknown User',
        'role': userToSave['role'] ?? 'Nasabah',
        'module': 'Authentication',
        'action': 'Pembuatan Akun Baru',
        'ip_address': 'Aplikasi Mobile',
        'status': 'SUKSES',
      };
      await db.insert('audit_logs', auditLog);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<bool> isEmailRegistered(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      return _webUsers.any(
        (u) => u['email'].toString().toLowerCase() == cleanEmail,
      );
    }

    final db = await instance.database;
    if (db == null) return false;
    final result = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
    );
    return result.isNotEmpty;
  }

  Future<bool> isPhoneRegistered(String phone) async {
    final cleanPhone = phone.trim();

    if (kIsWeb) {
      return _webUsers.any((u) => u['phone_number']?.toString() == cleanPhone);
    }

    final db = await instance.database;
    if (db == null) return false;
    final result = await db.query(
      'users',
      where: 'phone_number = ?',
      whereArgs: [cleanPhone],
    );
    return result.isNotEmpty;
  }

  Future<int> updateUserPointBalance(String userId, int newBalance) async {
    try {
      await ApiService.instance.updateUser(userId, {
        'point_balance': newBalance,
      });
    } catch (_) {}

    if (kIsWeb) {
      final index = _webUsers.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(_webUsers[index]);
        updated['point_balance'] = newBalance;
        _webUsers[index] = updated;
        return 1;
      }
      return 1;
    }

    final db = await instance.database;
    if (db == null) return 0;
    return await db.update(
      'users',
      {'point_balance': newBalance},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    if (kIsWeb) {
      try {
        return _webUsers.firstWhere((u) => u['id'] == id);
      } catch (e) {
        return null;
      }
    }

    final db = await instance.database;
    if (db == null) return null;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<bool> requestWithdrawal({
    required String nasabahId,
    required int pointsDeducted,
    required String method,
    required String accountDetails,
  }) async {
    if (kIsWeb) {
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;

    try {
      await db.insert('withdrawals', {
        'id': 'WD-${DateTime.now().millisecondsSinceEpoch}',
        'nasabah_id': nasabahId,
        'points_deducted': pointsDeducted,
        'method': method,
        'account_details': accountDetails,
        'status': 'menunggu',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getOperasionalSummary() async {
    int totalPetugas = 0;
    int petugasAktif = 0;
    int dropPointKritis = 0;
    int tugasSelesai = 0;
    int tugasAntrean = 0;

    if (kIsWeb) {
      totalPetugas = _webUsers.where((u) => u['role'] == 'petugas').length;
      petugasAktif = totalPetugas > 0 ? (totalPetugas * 0.8).round() : 0;
      dropPointKritis = 1;
      tugasSelesai = 15;
      tugasAntrean = 5;
    } else {
      final db = await instance.database;
      if (db != null) {
        final resPetugas = await db.rawQuery(
          "SELECT COUNT(*) as count FROM users WHERE role = 'petugas'",
        );
        totalPetugas = Sqflite.firstIntValue(resPetugas) ?? 0;
        petugasAktif = totalPetugas > 0 ? (totalPetugas * 0.8).round() : 0;

        final resDp = await db.rawQuery(
          "SELECT COUNT(*) as count FROM drop_points WHERE capacity_status = 'kritis'",
        );
        dropPointKritis = Sqflite.firstIntValue(resDp) ?? 0;

        final resTugasSelesai = await db.rawQuery(
          "SELECT COUNT(*) as count FROM transactions WHERE type = 'pickup' AND status = 'selesai'",
        );
        tugasSelesai = Sqflite.firstIntValue(resTugasSelesai) ?? 0;

        final resTugasAntre = await db.rawQuery(
          "SELECT COUNT(*) as count FROM transactions WHERE type = 'pickup' AND status = 'menunggu'",
        );
        tugasAntrean = Sqflite.firstIntValue(resTugasAntre) ?? 0;
      }
    }

    return {
      'totalPetugas': totalPetugas,
      'petugasAktif': petugasAktif,
      'petugasIstirahat': totalPetugas - petugasAktif,
      'dropPointKritis': dropPointKritis,
      'tugasSelesai': tugasSelesai,
      'tugasAntrean': tugasAntrean,
    };
  }

  Future<List<Map<String, dynamic>>> getDropPointCapacities() async {
    if (kIsWeb) {
      return [
        {'name': 'DP Margonda', 'capacityPercent': 92, 'isCritical': true},
        {'name': 'DP Kemang', 'capacityPercent': 88, 'isCritical': true},
        {'name': 'WS Beji', 'capacityPercent': 54, 'isCritical': false},
      ];
    }

    final db = await instance.database;
    if (db == null) return [];
    final res = await db.query('drop_points');
    if (res.isEmpty) {
      return [
        {'name': 'DP Margonda', 'capacityPercent': 92, 'isCritical': true},
        {'name': 'DP Kemang', 'capacityPercent': 88, 'isCritical': true},
        {'name': 'WS Beji', 'capacityPercent': 54, 'isCritical': false},
      ];
    }

    return res.map((dp) {
      int percent = 50;
      if (dp['capacity_status'] == 'kritis') percent = 90;
      if (dp['capacity_status'] == 'aman') percent = 30;
      int idHash = dp['id'].hashCode;
      percent = (percent + (idHash % 20)) % 100;

      return {
        'name': dp['name'],
        'capacityPercent': percent,
        'isCritical': percent >= 80,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getLiveWorkerStatus() async {
    if (kIsWeb) {
      return [
        {
          'petugas_name': 'Ahmad Petugas',
          'vehicle': 'Motor Roda 2',
          'location': 'Pusat Kota',
          'task': 'Pickup',
          'status': 'Menuju Lokasi',
        },
      ];
    }

    final db = await instance.database;
    if (db == null) return [];

    final query = '''
      SELECT
        u.full_name as petugas_name,
        u.address as vehicle_info,
        t.pickup_lat, t.pickup_lng,
        t.id as task_id,
        t.status as task_status,
        t.type as task_type,
        dp.name as dp_name
      FROM transactions t
      JOIN users u ON t.petugas_id = u.id
      LEFT JOIN drop_points dp ON t.drop_point_id = dp.id
      WHERE t.status != 'selesai'
    ''';
    final res = await db.rawQuery(query);

    if (res.isEmpty) {
      return [
        {
          'petugas_name': 'Agus Prasetyo',
          'vehicle': 'Truk 01',
          'location': 'Jl. Margonda Raya',
          'task': 'Pickup WJ-5T2N',
          'status': 'Menuju Lokasi',
        },
        {
          'petugas_name': 'Rendi Utama',
          'vehicle': 'Motor 03',
          'location': 'Kebayoran Baru',
          'task': 'Pickup WJ-9K7L',
          'status': 'Tiba di Lokasi',
        },
        {
          'petugas_name': 'Budi Santoso',
          'vehicle': 'Truk 02',
          'location': 'Drop Point Kemang',
          'task': 'Pengangkutan TPA',
          'status': 'Proses Muat',
        },
      ];
    }

    return res.map((row) {
      String vehicle = 'Kendaraan';
      if (row['vehicle_info'] != null) {
        String info = row['vehicle_info'].toString();
        if (info.contains('Armada:')) {
          var parts = info.split('Armada:');
          if (parts.length > 1) {
            vehicle = parts[1].split(',')[0].trim();
          }
        }
      }
      String taskIdStr = row['task_id'].toString();

      return {
        'petugas_name': row['petugas_name'],
        'vehicle': vehicle,
        'location': row['dp_name'] ?? 'Lokasi Nasabah',
        'task': row['task_type'] == 'pickup'
            ? 'Pickup #${taskIdStr.length > 4 ? taskIdStr.substring(0, 4) : taskIdStr}'
            : 'Pengangkutan',
        'status': row['task_status'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>> getLaporanAnalitikData({
    int bulan = 0,
    int tahun = 0,
  }) async {
    if (kIsWeb) {
      return _getMockLaporanData(bulan, tahun);
    }

    final db = await instance.database;
    if (db == null) return _getMockLaporanData(bulan, tahun);

    String whereClause = '';
    if (bulan > 0 && tahun > 0) {
      whereClause =
          "WHERE strftime('%m', created_at) = '${bulan.toString().padLeft(2, '0')}' AND strftime('%Y', created_at) = '$tahun'";
    } else if (tahun > 0) {
      whereClause = "WHERE strftime('%Y', created_at) = '$tahun'";
    }

    final txRes = await db.rawQuery(
      "SELECT COUNT(*) as cnt, SUM(total_actual_points) as total_pts FROM transactions $whereClause AND status = 'selesai'"
          .replaceAll('WHERE  AND', 'WHERE'),
    );
    final totalTx = Sqflite.firstIntValue(txRes) ?? 0;
    final totalPoints = (txRes.first['total_pts'] as int?) ?? 0;

    final volRes = await db.rawQuery(
      "SELECT SUM(ti.actual_weight) as total_kg FROM transaction_items ti JOIN transactions t ON ti.transaction_id = t.id ${whereClause.isNotEmpty ? '$whereClause AND t.status' : "WHERE t.status"} = 'selesai'",
    );
    final totalKg = (volRes.first['total_kg'] as double?) ?? 0.0;

    final nasabahRes = await db.rawQuery(
      "SELECT COUNT(DISTINCT nasabah_id) as cnt FROM transactions $whereClause ${whereClause.isNotEmpty ? 'AND' : 'WHERE'} status = 'selesai'"
          .replaceAll('WHERE  AND', 'WHERE'),
    );
    final totalNasabah = Sqflite.firstIntValue(nasabahRes) ?? 0;

    final allNasabahRes = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM users WHERE role = 'nasabah'",
    );
    final allNasabah = Sqflite.firstIntValue(allNasabahRes) ?? 1;

    final catRes = await db.rawQuery('''
      SELECT wc.name, SUM(ti.actual_weight) as total_kg
      FROM transaction_items ti
      JOIN waste_categories wc ON ti.waste_category_id = wc.id
      JOIN transactions t ON ti.transaction_id = t.id
      ${whereClause.isNotEmpty ? "$whereClause AND t.status = 'selesai'" : "WHERE t.status = 'selesai'"}
      GROUP BY wc.name ORDER BY total_kg DESC
    ''');

    final trendRes = await db.rawQuery('''
      SELECT strftime('%d/%m', created_at) as day, SUM(total_actual_points) as pts, COUNT(*) as cnt
      FROM transactions
      WHERE status = 'selesai' AND created_at >= date('now', '-6 days')
      GROUP BY strftime('%d/%m', created_at)
      ORDER BY created_at ASC
    ''');

    final rekapRes = await db.rawQuery('''
      SELECT
        strftime('%m/%Y', created_at) as periode,
        COUNT(*) as total_tx,
        SUM(total_actual_points) as total_pts
      FROM transactions
      WHERE status = 'selesai'
      GROUP BY strftime('%Y-%m', created_at)
      ORDER BY created_at DESC
      LIMIT 6
    ''');

    final double recyclePct = totalKg > 0
        ? (totalKg / (totalKg * 1.06)) * 100
        : 0;

    if (totalTx == 0) return _getMockLaporanData(bulan, tahun);

    List<Map<String, dynamic>> kategoriData = catRes.isEmpty
        ? _mockKategoriData()
        : catRes.map((r) => {'name': r['name'], 'kg': r['total_kg']}).toList();

    List<Map<String, dynamic>> trendData = trendRes.isEmpty
        ? _mockTrendData()
        : trendRes
              .map((r) => {'label': r['day'], 'pts': r['pts'], 'cnt': r['cnt']})
              .toList();

    List<Map<String, dynamic>> rekapData = rekapRes.isEmpty
        ? _mockRekapData()
        : rekapRes
              .map(
                (r) => {
                  'periode': r['periode'],
                  'totalTx': r['total_tx'],
                  'totalPts': r['total_pts'],
                },
              )
              .toList();

    return {
      'totalKg': totalKg,
      'totalPoints': totalPoints,
      'totalNasabah': totalNasabah,
      'allNasabah': allNasabah,
      'totalTx': totalTx,
      'recyclePct': recyclePct,
      'kategoriData': kategoriData,
      'trendData': trendData,
      'rekapData': rekapData,
    };
  }

  Map<String, dynamic> _getMockLaporanData(int bulan, int tahun) {
    return {
      'totalKg': 12450.0,
      'totalPoints': 48500000,
      'totalNasabah': 1280,
      'allNasabah': 2100,
      'totalTx': 1420,
      'recyclePct': 94.2,
      'kategoriData': _mockKategoriData(),
      'trendData': _mockTrendData(),
      'rekapData': _mockRekapData(),
    };
  }

  List<Map<String, dynamic>> _mockKategoriData() => [
    {'name': 'Plastik (PET/HDPE)', 'kg': 5229.0},
    {'name': 'Kertas & Karton', 'kg': 3486.0},
    {'name': 'Logam & Kaleng', 'kg': 2241.0},
    {'name': 'Kaca & Lainnya', 'kg': 1494.0},
  ];

  List<Map<String, dynamic>> _mockTrendData() => [
    {'label': 'Sen', 'pts': 3200, 'cnt': 45},
    {'label': 'Sel', 'pts': 4100, 'cnt': 58},
    {'label': 'Rab', 'pts': 2800, 'cnt': 39},
    {'label': 'Kam', 'pts': 5600, 'cnt': 72},
    {'label': 'Jum', 'pts': 4900, 'cnt': 61},
    {'label': 'Sab', 'pts': 6200, 'cnt': 84},
    {'label': 'Min', 'pts': 3900, 'cnt': 55},
  ];

  Future<List<Map<String, dynamic>>> getAllUsers({String? roleFilter}) async {
    if (kIsWeb) {
      final list = roleFilter == null
          ? List<Map<String, dynamic>>.from(_webUsers)
          : _webUsers.where((u) => u['role'] == roleFilter).toList();
      return list;
    }

    final db = await instance.database;
    if (db == null) return [];

    if (roleFilter != null) {
      return await db.query(
        'users',
        where: 'role = ?',
        whereArgs: [roleFilter],
        orderBy: 'full_name ASC',
      );
    }
    return await db.query('users', orderBy: 'role ASC, full_name ASC');
  }

  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (kIsWeb) {
      final idx = _webUsers.indexWhere((u) => u['id'] == userId);
      if (idx == -1) return false;
      final updated = Map<String, dynamic>.from(_webUsers[idx]);
      updated.addAll(data);
      _webUsers[idx] = updated;
      await _saveWebUsers();
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;
    try {
      final rows = await db.update(
        'users',
        data,
        where: 'id = ?',
        whereArgs: [userId],
      );
      return rows > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    return updateUserProfile(userId, {'is_active': isActive ? 1 : 0});
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    return updateUserProfile(userId, {'role': newRole});
  }

  Future<bool> deleteUser(String userId) async {
    if (kIsWeb) {
      final idx = _webUsers.indexWhere((u) => u['id'] == userId);
      if (idx == -1) return false;
      _webUsers.removeAt(idx);
      await _saveWebUsers();

      try {
        final prefs = await SharedPreferences.getInstance();

        final deleted = prefs.getStringList('deleted_user_ids') ?? [];
        deleted.add(userId);
        await prefs.setStringList('deleted_user_ids', deleted);
      } catch (_) {}
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;
    try {
      final rows = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return rows > 0;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, bool>> getStafPermissions() async {
    return Map<String, bool>.from(_webPermissions);
  }

  Future<bool> saveStafPermissions(Map<String, bool> permissions) async {
    try {
      _webPermissions.addAll(permissions);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getSystemConfig() async {
    if (kIsWeb) {
      return Map<String, dynamic>.from(_webSystemConfig);
    }

    final db = await instance.database;
    if (db == null) return Map<String, dynamic>.from(_webSystemConfig);

    final res = await db.query('system_configs');
    if (res.isEmpty) {
      return Map<String, dynamic>.from(_webSystemConfig);
    }

    Map<String, dynamic> config = Map<String, dynamic>.from(_webSystemConfig);
    for (var row in res) {
      String key = row['key'] as String;
      String valStr = row['value'] as String;

      if (['jam_buka', 'jam_tutup'].contains(key)) {
        config[key] = valStr;
      } else if (['auto_assign', 'wa_notif', 'push_notif'].contains(key)) {
        config[key] = int.tryParse(valStr) ?? 1;
      } else {
        config[key] = double.tryParse(valStr) ?? _webSystemConfig[key];
      }
    }
    return config;
  }

  Future<bool> saveSystemConfig(Map<String, dynamic> config) async {
    await insertAuditLog({
      'time': DateTime.now().toString().substring(0, 16),
      'user_name': 'Administrator',
      'role': 'Admin',
      'module': 'Konfigurasi Sistem',
      'action': 'Mengubah konfigurasi sistem dan limit poin',
      'ip_address': '127.0.0.1',
      'status': 'BERHASIL',
    });

    if (kIsWeb) {
      _webSystemConfig.addAll(config);
      await _saveWebSystemConfig();
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;

    try {
      await db.transaction((txn) async {
        for (var entry in config.entries) {
          await txn.insert('system_configs', {
            'key': entry.key,
            'value': entry.value.toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static final List<Map<String, dynamic>> _webAuditLogs = [];

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? modul,
    String query = '',
  }) async {
    List<Map<String, dynamic>> logs = [];
    if (kIsWeb) {
      logs = List<Map<String, dynamic>>.from(_webAuditLogs);
    } else {
      final db = await instance.database;
      if (db != null) {
        logs = await db.query('audit_logs', orderBy: 'id DESC');
      }
    }

    if (modul != null && modul != 'Semua Modul') {
      logs = logs.where((log) => log['module'] == modul).toList();
    }

    if (query.trim().isNotEmpty) {
      String q = query.toLowerCase();
      logs = logs.where((log) {
        return (log['user_name'] ?? '').toString().toLowerCase().contains(q) ||
            (log['action'] ?? '').toString().toLowerCase().contains(q) ||
            (log['role'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }

    return logs;
  }

  Future<bool> insertAuditLog(Map<String, dynamic> log) async {
    bool apiSuccess = await ApiService.instance.insertAuditLog(log);
    if (apiSuccess) {
      return true;
    }

    if (kIsWeb) {
      _webAuditLogs.insert(0, log);
      await _saveWebAuditLogs();
      return true;
    }
    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.insert('audit_logs', log);
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Map<String, dynamic>> _mockRekapData() => [
    {
      'periode': 'Agustus 2026',
      'totalTx': 210,
      'totalKg': 2100.0,
      'totalPts': 7350000,
    },
    {
      'periode': 'Juli 2026',
      'totalTx': 1420,
      'totalKg': 11850.0,
      'totalPts': 46200000,
    },
    {
      'periode': 'Juni 2026',
      'totalTx': 1290,
      'totalKg': 10400.0,
      'totalPts': 41500000,
    },
    {
      'periode': 'Mei 2026',
      'totalTx': 1150,
      'totalKg': 9800.0,
      'totalPts': 38000000,
    },
  ];

  Future<List<Map<String, dynamic>>> getDropPoints() async {
    if (kIsWeb) return List.from(_webDropPoints);
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('drop_points');
  }

  Future<bool> addDropPoint(Map<String, dynamic> dp) async {
    if (kIsWeb) {
      _webDropPoints.add(dp);
      return true;
    }
    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.insert('drop_points', dp);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateDropPoint(String id, Map<String, dynamic> dp) async {
    if (kIsWeb) {
      final idx = _webDropPoints.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _webDropPoints[idx] = dp;
        return true;
      }
      return false;
    }
    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.update('drop_points', dp, where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDropPoint(String id) async {
    if (kIsWeb) {
      _webDropPoints.removeWhere((e) => e['id'] == id);
      return true;
    }
    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.delete('drop_points', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getWasteCategories() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(
        _webWasteCategories.map((c) {
          final copy = Map<String, dynamic>.from(c);
          copy['min_weight'] ??= 1.0;
          return copy;
        }),
      );
    }
    final db = await instance.database;
    if (db == null) return [];
    final res = await db.query('waste_categories');
    return res.map((r) {
      final copy = Map<String, dynamic>.from(r);
      copy['min_weight'] ??= 1.0;
      return copy;
    }).toList();
  }

  Future<bool> addWasteCategory(Map<String, dynamic> wc) async {
    if (kIsWeb) {
      if (!wc.containsKey('id')) {
        wc['id'] = _webWasteCategories.length + 1;
      }
      _webWasteCategories.add(wc);
      await _saveWebWasteCategories();
      return true;
    }
    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.insert('waste_categories', wc);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateWasteCategory(int id, Map<String, dynamic> wc) async {
    if (kIsWeb) {
      final idx = _webWasteCategories.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _webWasteCategories[idx].addAll(wc);
        await _saveWebWasteCategories();
        return true;
      }
      return false;
    }
    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.update('waste_categories', wc, where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteWasteCategory(int id) async {
    if (kIsWeb) {
      _webWasteCategories.removeWhere((e) => e['id'] == id);
      return true;
    }
    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.delete('waste_categories', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createTransaction(
    Map<String, dynamic> txData,
    List<Map<String, dynamic>> items,
  ) async {
    if (kIsWeb) {
      _webTransactions.add(txData);
      for (var item in items) {
        _webTransactionItems.add(item);
      }
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;

    try {
      final validCols = [
        'id',
        'nasabah_id',
        'petugas_id',
        'drop_point_id',
        'type',
        'status',
        'pickup_date',
        'pickup_time_slot',
        'pickup_lat',
        'pickup_lng',
        'total_est_points',
        'total_actual_points',
        'photo_evidence',
        'created_at',
      ];
      final filteredTxData = Map<String, dynamic>.from(txData)
        ..removeWhere((key, value) => !validCols.contains(key));

      await db.transaction((txn) async {
        await txn.insert('transactions', filteredTxData);
        for (var item in items) {
          await txn.insert('transaction_items', item);
        }
      });
      return true;
    } catch (e) {
      print('Error creating transaction: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    if (kIsWeb) {
      return _webTransactions.map((tx) {
        final user = _webUsers.firstWhere(
          (u) => u['id'] == tx['nasabah_id'],
          orElse: () => {
            'full_name': tx['full_name'] ?? 'Unknown',
            'address': tx['address'] ?? '',
          },
        );
        final dropPoint = _webDropPoints.firstWhere(
          (dp) => dp['id'] == tx['drop_point_id'],
          orElse: () => {},
        );
        return {
          ...tx,
          'nasabah_name': user['full_name'] ?? tx['full_name'] ?? 'Unknown',
          'nasabah_address': tx['address'] ?? tx['pickup_address'] ?? user['address'] ?? '',
          'drop_point_name': tx['drop_point_name'] ?? dropPoint['name'],
          'drop_point_address': tx['drop_point_address'] ?? dropPoint['address'],
          'items': _webTransactionItems
              .where((i) => i['transaction_id'] == tx['id'])
              .toList(),
        };
      }).toList();
    }

    final db = await instance.database;
    if (db == null) return [];

    final List<Map<String, dynamic>> txs = await db.rawQuery('''
      SELECT t.*, u.full_name as nasabah_name,
             COALESCE(t.pickup_address, t.address, u.address, '') as nasabah_address,
             dp.name as drop_point_name, dp.address as drop_point_address
      FROM transactions t
      LEFT JOIN users u ON t.nasabah_id = u.id
      LEFT JOIN drop_points dp ON t.drop_point_id = dp.id
      ORDER BY t.created_at DESC
    ''');

    List<Map<String, dynamic>> result = [];
    for (var tx in txs) {
      final items = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [tx['id']],
      );
      Map<String, dynamic> txMap = Map<String, dynamic>.from(tx);
      txMap['items'] = items;
      result.add(txMap);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getUserTransactions(
    String nasabahId,
  ) async {
    if (kIsWeb) {
      return _webTransactions.where((tx) => tx['nasabah_id'] == nasabahId).map((
        tx,
      ) {
        return {
          ...tx,
          'items': _webTransactionItems
              .where((i) => i['transaction_id'] == tx['id'])
              .map((item) {
                final catId = item['waste_category_id'];
                final cat = _webWasteCategories.firstWhere(
                  (c) => c['id'] == catId,
                  orElse: () => {'name': 'Sampah'},
                );
                return {...item, 'category_name': cat['name']};
              })
              .toList(),
        };
      }).toList();
    }

    final db = await instance.database;
    if (db == null) return [];

    final List<Map<String, dynamic>> txs = await db.query(
      'transactions',
      where: 'nasabah_id = ?',
      whereArgs: [nasabahId],
      orderBy: 'created_at DESC',
    );

    List<Map<String, dynamic>> result = [];
    for (var tx in txs) {
      final items = await db.rawQuery(
        '''
        SELECT ti.*, wc.name as name
        FROM transaction_items ti
        LEFT JOIN waste_categories wc ON ti.waste_category_id = wc.id
        WHERE ti.transaction_id = ?
        ''',
        [tx['id']],
      );
      Map<String, dynamic> txMap = Map<String, dynamic>.from(tx);
      txMap['items'] = items;
      result.add(txMap);
    }
    return result;
  }

  Future<bool> updateTransactionStatus(String id, String status) async {
    if (kIsWeb) {
      final idx = _webTransactions.indexWhere((tx) => tx['id'] == id);
      if (idx != -1) {
        _webTransactions[idx]['status'] = status;
        return true;
      }
      return false;
    }

    final db = await instance.database;
    if (db == null) return false;

    try {
      await db.update(
        'transactions',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeTransaction(
    String id,
    int earnedPoints, {
    List<Map<String, dynamic>> items = const [],
  }) async {
    if (kIsWeb) {
      final txIdx = _webTransactions.indexWhere((tx) => tx['id'] == id);
      if (txIdx != -1) {
        _webTransactions[txIdx]['status'] = 'selesai';
        _webTransactions[txIdx]['total_actual_points'] = earnedPoints;
        if (items.isNotEmpty) {
          _webTransactions[txIdx]['items'] = items;

          _webTransactionItems.removeWhere((i) => i['transaction_id'] == id);

          for (var item in items) {
            final dbItem = Map<String, dynamic>.from(item);
            dbItem.remove('name');
            _webTransactionItems.add(dbItem);
          }
        }

        final userId = _webTransactions[txIdx]['nasabah_id'];
        final userIdx = _webUsers.indexWhere((u) => u['id'] == userId);
        if (userIdx != -1) {
          final currentPts =
              (_webUsers[userIdx]['point_balance'] as num?)?.toInt() ?? 0;
          _webUsers[userIdx]['point_balance'] = currentPts + earnedPoints;
          await _saveWebUsers();
        }
        return true;
      }

      return true;
    }

    final db = await instance.database;
    if (db == null) return false;

    try {
      await db.transaction((txn) async {
        await txn.update(
          'transactions',
          {'status': 'selesai', 'total_actual_points': earnedPoints},
          where: 'id = ?',
          whereArgs: [id],
        );

        if (items.isNotEmpty) {
          await txn.delete(
            'transaction_items',
            where: 'transaction_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            final dbItem = Map<String, dynamic>.from(item);
            dbItem.remove('name');
            await txn.insert('transaction_items', dbItem);
          }
        }

        final txRes = await txn.query(
          'transactions',
          columns: ['nasabah_id'],
          where: 'id = ?',
          whereArgs: [id],
        );

        if (txRes.isNotEmpty) {
          final userId = txRes.first['nasabah_id'] as String?;
          if (userId != null) {
            await txn.rawUpdate(
              'UPDATE users SET point_balance = point_balance + ? WHERE id = ?',
              [earnedPoints, userId],
            );
          }
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingPickupTasks({
    String? type,
  }) async {
    if (kIsWeb) {
      final pendingTxs = _webTransactions
          .where(
            (tx) =>
                (type != null
                    ? tx['type'] == type
                    : (tx['type'] == 'pickup' || tx['type'] == 'drop_in')) &&
                (tx['status'] == 'dikonfirmasi' ||
                    tx['status'] == 'menuju_lokasi' ||
                    tx['status'] == 'tiba'),
          )
          .toList();

      List<Map<String, dynamic>> result = [];
      for (var tx in pendingTxs) {
        final userIndex = _webUsers.indexWhere(
          (u) => u['id'] == tx['nasabah_id'],
        );
        if (userIndex == -1) {
          continue;
        }
        final user = _webUsers[userIndex];
        final items = _webTransactionItems
            .where((i) => i['transaction_id'] == tx['id'])
            .toList();

        double estWeight = 0.0;
        List<String> categories = [];
        for (var item in items) {
          estWeight += (item['estimated_weight'] as num?)?.toDouble() ?? 0.0;
          final catId = item['waste_category_id'];
          final catName = _webWasteCategories.firstWhere(
            (c) => c['id'] == catId,
            orElse: () => {'name': 'Lainnya'},
          )['name'];
          if (!categories.contains(catName)) {
            categories.add(catName.toString());
          }
        }

        String alamat = (tx['address'] != null &&
                tx['address'].toString().trim().isNotEmpty)
            ? tx['address'].toString().trim()
            : ((tx['alamat'] != null &&
                    tx['alamat'].toString().trim().isNotEmpty)
                ? tx['alamat'].toString().trim()
                : (user['address'] ?? 'Alamat tidak tersedia'));
        if (tx['type'] == 'drop_in') {
          final dropPoint = _webDropPoints.firstWhere(
            (dp) => dp['id'] == tx['drop_point_id'],
            orElse: () => {'name': 'Drop Point', 'address': '-'},
          );
          alamat = '${dropPoint['name']} — ${dropPoint['address']}';
        }

        result.add({
          'id_transaksi': tx['id'],
          'nama_nasabah': user['full_name'],
          'alamat': alamat,
          'estimasi_berat': '${estWeight.toStringAsFixed(1)} kg',
          'jenis_sampah': categories.isEmpty
              ? 'Belum diisi'
              : categories.join(', '),
          'status': tx['status'],
          'type': tx['type'],
          'tipe_tugas': tx['type'] == 'drop_in' ? 'Drop-in' : 'Jemput',
          'jarak': tx['type'] == 'drop_in' ? 'Di drop point' : 'Menghitung...',
        });
      }
      return result;
    }

    final db = await instance.database;
    if (db == null) return [];

    final String typeClause = type != null
        ? "t.type = '$type'"
        : "t.type IN ('pickup', 'drop_in')";
    final List<Map<String, dynamic>> txs = await db.rawQuery('''
      SELECT
        t.id, t.type, t.status,
        u.full_name, u.address,
        dp.name as drop_point_name, dp.address as drop_point_address
      FROM transactions t
      LEFT JOIN users u ON t.nasabah_id = u.id
      LEFT JOIN drop_points dp ON t.drop_point_id = dp.id
      WHERE $typeClause
        AND t.status IN ('dikonfirmasi', 'menuju_lokasi', 'tiba')
      ORDER BY t.created_at DESC
    ''');

    List<Map<String, dynamic>> result = [];
    for (var tx in txs) {
      if (tx['full_name'] == null) {
        continue;
      }
      final items = await db.rawQuery(
        '''
        SELECT ti.estimated_weight, wc.name as category_name
        FROM transaction_items ti
        LEFT JOIN waste_categories wc ON ti.waste_category_id = wc.id
        WHERE ti.transaction_id = ?
      ''',
        [tx['id']],
      );

      double estWeight = 0.0;
      List<String> categories = [];
      for (var item in items) {
        estWeight += (item['estimated_weight'] as num?)?.toDouble() ?? 0.0;
        final catName = item['category_name']?.toString() ?? 'Lainnya';
        if (!categories.contains(catName)) {
          categories.add(catName);
        }
      }

      final bool isDropIn = tx['type']?.toString() == 'drop_in';
      final String alamat = isDropIn
          ? '${tx['drop_point_name'] ?? 'Drop Point'} — ${tx['drop_point_address'] ?? '-'}'
          : tx['address']?.toString() ?? 'Unknown';

      result.add({
        'id_transaksi': tx['id'],
        'nama_nasabah': tx['full_name'] ?? 'Unknown',
        'alamat': alamat,
        'estimasi_berat': '${estWeight.toStringAsFixed(1)} kg',
        'jenis_sampah': categories.isEmpty
            ? 'Belum diisi'
            : categories.join(', '),
        'status': tx['status'],
        'type': tx['type'],
        'tipe_tugas': isDropIn ? 'Drop-in' : 'Jemput',
        'jarak': isDropIn ? 'Di drop point' : 'Menghitung...',
      });
    }
    return result;
  }

  Future<void> insertWithdrawal(
    String nasabahId,
    int pointsDeducted,
    String method,
    String accountDetails,
  ) async {
    final String newId = 'WD-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    if (kIsWeb) {
      _webWithdrawals.add({
        'id': newId,
        'nasabah_id': nasabahId,
        'points_deducted': pointsDeducted,
        'method': method,
        'account_details': accountDetails,
        'status': 'pending',
        'created_at': now,
      });

      var userIndex = _webUsers.indexWhere((u) => u['id'] == nasabahId);
      if (userIndex != -1) {
        _webUsers[userIndex]['point_balance'] =
            ((_webUsers[userIndex]['point_balance'] as num?)?.toInt() ?? 0) -
            pointsDeducted;
      }
      return;
    }

    final db = await instance.database;
    if (db == null) return;

    await db.insert('withdrawals', {
      'id': newId,
      'nasabah_id': nasabahId,
      'points_deducted': pointsDeducted,
      'method': method,
      'account_details': accountDetails,
      'status': 'pending',
    });

    final user = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [nasabahId],
    );
    if (user.isNotEmpty) {
      int currentPoints = (user.first['point_balance'] as num?)?.toInt() ?? 0;
      await db.update(
        'users',
        {'point_balance': currentPoints - pointsDeducted},
        where: 'id = ?',
        whereArgs: [nasabahId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getWithdrawals({String? status}) async {
    if (kIsWeb) {
      var filtered = _webWithdrawals;
      if (status != null) {
        filtered = filtered.where((w) => w['status'] == status).toList();
      }

      List<Map<String, dynamic>> result = [];
      for (var w in filtered) {
        var user = _webUsers.firstWhere(
          (u) => u['id'] == w['nasabah_id'],
          orElse: () => {},
        );
        result.add({
          ...w,
          'full_name': user['full_name'] ?? 'Unknown',
          'phone_number': user['phone_number'] ?? 'Unknown',
        });
      }
      return result;
    }

    final db = await instance.database;
    if (db == null) return [];

    String query = '''
      SELECT w.*, u.full_name, u.phone_number
      FROM withdrawals w
      LEFT JOIN users u ON w.nasabah_id = u.id
    ''';
    List<dynamic> args = [];

    if (status != null) {
      query += ' WHERE w.status = ?';
      args.add(status);
    }

    query += ' ORDER BY w.created_at DESC';

    return await db.rawQuery(query, args);
  }

  Future<bool> updateWithdrawalStatus(
    String id,
    String newStatus, {
    int? pointsToRefund,
    String? nasabahId,
    String? reason,
  }) async {
    if (kIsWeb) {
      var index = _webWithdrawals.indexWhere((w) => w['id'] == id);
      if (index != -1) {
        _webWithdrawals[index]['status'] = newStatus;
        if (newStatus == 'rejected') {
          if (reason != null) {
            _webWithdrawals[index]['account_details'] =
                '${_webWithdrawals[index]['account_details']} (Ditolak: $reason)';
          }
          if (pointsToRefund != null && nasabahId != null) {
            var userIndex = _webUsers.indexWhere((u) => u['id'] == nasabahId);
            if (userIndex != -1) {
              _webUsers[userIndex]['point_balance'] =
                  ((_webUsers[userIndex]['point_balance'] as num?)?.toInt() ??
                      0) +
                  pointsToRefund;
            }
          }
        }
        return true;
      }
      return false;
    }

    final db = await instance.database;
    if (db == null) return false;

    await db.update(
      'withdrawals',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (newStatus == 'rejected') {
      if (reason != null) {
        final wd = await db.query(
          'withdrawals',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (wd.isNotEmpty) {
          await db.update(
            'withdrawals',
            {
              'account_details':
                  '${wd.first['account_details']} (Ditolak: $reason)',
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      if (pointsToRefund != null && nasabahId != null) {
        final user = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [nasabahId],
        );
        if (user.isNotEmpty) {
          int currentPoints =
              (user.first['point_balance'] as num?)?.toInt() ?? 0;
          await db.update(
            'users',
            {'point_balance': currentPoints + pointsToRefund},
            where: 'id = ?',
            whereArgs: [nasabahId],
          );
        }
      }
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> getTitipanKurir() async {
    if (kIsWeb) {
      var filtered = _webWithdrawals
          .where(
            (w) =>
                w['status'] == 'approved' &&
                w['account_details']?.toString().contains('(Titip Kurir)') ==
                    true,
          )
          .toList();

      List<Map<String, dynamic>> result = [];
      for (var w in filtered) {
        var user = _webUsers.firstWhere(
          (u) => u['id'] == w['nasabah_id'],
          orElse: () => {},
        );
        result.add({
          ...w,
          'full_name': user['full_name'] ?? 'Unknown',
          'phone_number': user['phone_number'] ?? 'Unknown',
          'nasabah_address': user['address'] ?? '-',
        });
      }
      return result;
    }

    final db = await instance.database;
    if (db == null) return [];

    String query = '''
      SELECT w.*, u.full_name, u.phone_number, u.address as nasabah_address
      FROM withdrawals w
      LEFT JOIN users u ON w.nasabah_id = u.id
      WHERE w.status = 'approved' AND w.account_details LIKE '%(Titip Kurir)%'
      ORDER BY w.created_at DESC
    ''';

    return await db.rawQuery(query);
  }
}
