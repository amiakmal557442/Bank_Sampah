import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory fallback database for Web (Chrome) & default seed users
  static final List<Map<String, dynamic>> _webUsers = [
    {
      'id': 'budi-uuid-1234-5678',
      'phone_number': '+62 812-3456-7890',
      'email': 'budi@gmail.com',
      'full_name': 'Budi Santoso',
      'password':
          'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
      'role': 'nasabah',
      'address': 'Jl. Mawar No. 12, Jakarta',
      'default_setor_method': 'drop_in',
      'point_balance': 4820,
      'is_active': 1,
    },
    {
      'id': 'petugas-uuid-1234-5678',
      'phone_number': '+62 812-9999-8888',
      'email': 'petugas@gmail.com',
      'full_name': 'Ahmad Petugas',
      'password':
          'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
      'role': 'petugas',
      'address':
          'Zona: Drop Point 01 - Pusat Kota, Armada: Motor Roda 2, Plat: B 1234 ABC',
      'default_setor_method': 'pickup',
      'point_balance': 0,
      'is_active': 1,
    },
    {
      'id': 'admin-uuid-akmal-223',
      'phone_number': '+62 812-1111-2222',
      'email': 'akmalahsan223@gmail.com',
      'full_name': 'Akmal Ahsan',
      'password':
          '808d5293ca7453bfbaa369f8f7c581cbf37f6a0ce85f13de00e67e08feeb45e5',
      'role': 'admin',
      'address': 'Kantor Pusat Bank Sampah',
      'default_setor_method': 'drop_in',
      'point_balance': 99999,
      'is_active': 1,
    },
    {
      'id': 'admin-uuid-fanska-221',
      'phone_number': '+62 812-3333-4444',
      'email': 'fanskawe221@gmail.com',
      'full_name': 'Fanska',
      'password':
          '32062e2d61502920f0207935c0bdd7cc27f1c024c8b49c92ced155f547d37c50',
      'role': 'admin',
      'address': 'Kantor Pusat Bank Sampah',
      'default_setor_method': 'drop_in',
      'point_balance': 99999,
      'is_active': 1,
    },
    {
      'id': 'staf-uuid-andi-001',
      'phone_number': '+62 812-5555-6666',
      'email': 'andi.wijaya@banksampah.id',
      'full_name': 'Andi Wijaya',
      'password':
          '22875a9282a98b312c1a775aaabb4b54fca6caf2fc73762652a3370b583ef32d',
      'role': 'staf_kantor',
      'address': 'Kantor Pusat Bank Sampah',
      'default_setor_method': 'drop_in',
      'point_balance': 0,
      'is_active': 1,
    },
    {
      'id': 'staf-uuid-rina-002',
      'phone_number': '+62 812-7777-8888',
      'email': 'rina.m@banksampah.id',
      'full_name': 'Rina Marlina',
      'password':
          '22875a9282a98b312c1a775aaabb4b54fca6caf2fc73762652a3370b583ef32d',
      'role': 'staf_kantor',
      'address': 'Kantor Pusat Bank Sampah',
      'default_setor_method': 'drop_in',
      'point_balance': 0,
      'is_active': 0,
    },
  ];

  // In-memory permissions for Staf Kantor (web & native fallback)
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

  // In-memory system configuration for Web (Chrome fallback)
  static Map<String, dynamic> _webSystemConfig = {
    'min_weight': 1.0,
    'max_radius': 5.0,
    'min_withdraw': 10000.0,
    'point_rate': 1.0,
    'auto_assign': 1,
    'jam_buka': '08:00',
    'jam_tutup': '17:00',
    'push_notif': 1,
  };

  static final List<Map<String, dynamic>> _webDropPoints = [
    {
      'id': 'dp-1',
      'name': 'Drop Point 01 - Pusat Kota',
      'address': 'Jl. Merdeka No.1, Jakarta Pusat',
      'latitude': -6.1751,
      'longitude': 106.8272,
      'capacity_status': 'aman',
      'operating_hours': '08:00 - 17:00',
    },
    {
      'id': 'dp-2',
      'name': 'Drop Point 02 - Margonda',
      'address': 'Jl. Margonda Raya No. 10',
      'latitude': -6.3732,
      'longitude': 106.8323,
      'capacity_status': 'kritis',
      'operating_hours': '08:00 - 17:00',
    },
  ];

  static final List<Map<String, dynamic>> _webWasteCategories = [
    {
      'id': 1,
      'name': 'Plastik (PET/HDPE)',
      'point_per_kg': 2500,
      'icon_url': 'assets/icons/plastik.png',
      'is_active': 1,
    },
    {
      'id': 2,
      'name': 'Kertas & Karton',
      'point_per_kg': 1500,
      'icon_url': 'assets/icons/kertas.png',
      'is_active': 1,
    },
    {
      'id': 3,
      'name': 'Logam & Besi',
      'point_per_kg': 4000,
      'icon_url': 'assets/icons/logam.png',
      'is_active': 1,
    },
    {
      'id': 4,
      'name': 'Minyak Jelantah',
      'point_per_kg': 3500,
      'icon_url': 'assets/icons/minyak.png',
      'is_active': 1,
    },
  ];

  static final List<Map<String, dynamic>> _webTransactions = [];
  static final List<Map<String, dynamic>> _webTransactionItems = [];

  DatabaseHelper._init();

  // Initialize Web Data from SharedPreferences
  Future<void> initWebStorage() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('web_users');
    if (usersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(usersJson);
        _webUsers.clear();
        _webUsers.addAll(decoded.cast<Map<String, dynamic>>());
      } catch (e) {
        // Fallback to default if decoding fails
      }
    } else {
      // Save default users on first run
      await _saveWebUsers();
    }
  }

  Future<void> _saveWebUsers() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('web_users', jsonEncode(_webUsers));
  }

  Future<Database?> get database async {
    if (kIsWeb) return null; // SQLite is not supported on web
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
      version: 4,
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
      // Add is_active column if upgrading from v1
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1',
        );
        await db.execute('UPDATE users SET is_active = 1');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      // Create system_configs table
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
      // Create audit_logs table
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

        // Insert sample data
        await db.execute('''
          INSERT INTO audit_logs (time, user_name, role, module, action, ip_address, status) 
          VALUES ('04 Aug 2026 - 10:42', 'Akmal Ahsan', 'Administrator', 'Konfigurasi Sistem', 'Mengubah Rasio Poin dari Rp 1 ke Rp 1.2/Poin', '192.168.1.10', 'SUKSES')
        ''');
        await db.execute('''
          INSERT INTO audit_logs (time, user_name, role, module, action, ip_address, status) 
          VALUES ('04 Aug 2026 - 08:30', 'Unknown User', 'Guest', 'Authentication', 'Percobaan Login Gagal (Salah Password 3x)', '180.252.10.4', 'GAGAL')
        ''');
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. Table users
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Table drop_points
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

    // 3. Table waste_categories
    await db.execute('''
      CREATE TABLE waste_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        point_per_kg INTEGER NOT NULL,
        icon_url TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 4. Table transactions
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

    // 5. Table transaction_items
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

    // 6. Table withdrawals
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

    // 7. Table worker_logs
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

    // 8. Table b2b_sales
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

    // 9. Table system_configs
    await db.execute('''
      CREATE TABLE system_configs (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 10. Table audit_logs
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

    // Seed mock audit logs
    for (var log in _webAuditLogs) {
      await db.insert('audit_logs', log);
    }

    // Seeding default users
    for (var u in _webUsers) {
      await db.insert('users', u);
    }
    for (var dp in _webDropPoints) {
      await db.insert('drop_points', dp);
    }
    for (var wc in _webWasteCategories) {
      await db.insert('waste_categories', wc);
    }
  }

  // Helper for password hashing
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User auth and operations
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
    // Hash password before saving
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
      await _saveWebUsers(); // Persist for Web
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.insert('users', userToSave);
      // Record audit log for account creation
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
    if (kIsWeb) {
      final index = _webUsers.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(_webUsers[index]);
        updated['point_balance'] = newBalance;
        _webUsers[index] = updated;
        await _saveWebUsers();
        return 1;
      }
      return 0;
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

  // --- Operasional Lapangan Methods ---

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
      // Mock Data if db is empty
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

  // --- Laporan & Analitik Methods ---

  Future<Map<String, dynamic>> getLaporanAnalitikData({
    int bulan = 0, // 0 = semua
    int tahun = 0,
  }) async {
    // ---- WEB / MOCK FALLBACK ----
    if (kIsWeb) {
      return _getMockLaporanData(bulan, tahun);
    }

    final db = await instance.database;
    if (db == null) return _getMockLaporanData(bulan, tahun);

    // Build WHERE clause
    String whereClause = '';
    if (bulan > 0 && tahun > 0) {
      whereClause =
          "WHERE strftime('%m', created_at) = '${bulan.toString().padLeft(2, '0')}' AND strftime('%Y', created_at) = '$tahun'";
    } else if (tahun > 0) {
      whereClause = "WHERE strftime('%Y', created_at) = '$tahun'";
    }

    // Total transaksi selesai
    final txRes = await db.rawQuery(
      "SELECT COUNT(*) as cnt, SUM(total_actual_points) as total_pts FROM transactions $whereClause AND status = 'selesai'"
          .replaceAll('WHERE  AND', 'WHERE'),
    );
    final totalTx = Sqflite.firstIntValue(txRes) ?? 0;
    final totalPoints = (txRes.first['total_pts'] as int?) ?? 0;

    // Total volume sampah dari transaction_items
    final volRes = await db.rawQuery(
      "SELECT SUM(ti.actual_weight) as total_kg FROM transaction_items ti JOIN transactions t ON ti.transaction_id = t.id ${whereClause.isNotEmpty ? '$whereClause AND t.status' : "WHERE t.status"} = 'selesai'",
    );
    final totalKg = (volRes.first['total_kg'] as double?) ?? 0.0;

    // Nasabah unik yang menyetor
    final nasabahRes = await db.rawQuery(
      "SELECT COUNT(DISTINCT nasabah_id) as cnt FROM transactions $whereClause ${whereClause.isNotEmpty ? 'AND' : 'WHERE'} status = 'selesai'"
          .replaceAll('WHERE  AND', 'WHERE'),
    );
    final totalNasabah = Sqflite.firstIntValue(nasabahRes) ?? 0;

    // Total user nasabah
    final allNasabahRes = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM users WHERE role = 'nasabah'",
    );
    final allNasabah = Sqflite.firstIntValue(allNasabahRes) ?? 1;

    // Volume per kategori sampah
    final catRes = await db.rawQuery('''
      SELECT wc.name, SUM(ti.actual_weight) as total_kg
      FROM transaction_items ti
      JOIN waste_categories wc ON ti.waste_category_id = wc.id
      JOIN transactions t ON ti.transaction_id = t.id
      ${whereClause.isNotEmpty ? "$whereClause AND t.status = 'selesai'" : "WHERE t.status = 'selesai'"}
      GROUP BY wc.name ORDER BY total_kg DESC
    ''');

    // Tren mingguan (ambil 7 hari terakhir)
    final trendRes = await db.rawQuery('''
      SELECT strftime('%d/%m', created_at) as day, SUM(total_actual_points) as pts, COUNT(*) as cnt
      FROM transactions
      WHERE status = 'selesai' AND created_at >= date('now', '-6 days')
      GROUP BY strftime('%d/%m', created_at)
      ORDER BY created_at ASC
    ''');

    // Data rekap per bulan (3 bulan terakhir)
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

    // If DB has no data, use mock
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

  // ── ACCOUNT MANAGEMENT CRUD ─────────────────────────────────────────────

  /// Returns all users, optionally filtered by role.
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

  /// Updates arbitrary fields on a user record.
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

  /// Toggles the active/inactive status of a user.
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    return updateUserProfile(userId, {'is_active': isActive ? 1 : 0});
  }

  /// Updates only the role field of a user.
  Future<bool> updateUserRole(String userId, String newRole) async {
    return updateUserProfile(userId, {'role': newRole});
  }

  /// Permanently deletes a user account.
  Future<bool> deleteUser(String userId) async {
    if (kIsWeb) {
      final idx = _webUsers.indexWhere((u) => u['id'] == userId);
      if (idx == -1) return false;
      _webUsers.removeAt(idx);
      await _saveWebUsers();
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

  // ── STAF KANTOR PERMISSIONS ───────────────────────────────────────────────

  /// Returns the current permission map for Staf Kantor role.
  Future<Map<String, bool>> getStafPermissions() async {
    // Returns a copy so mutations don't affect the source directly
    return Map<String, bool>.from(_webPermissions);
  }

  /// Persists the Staf Kantor permission map (in-memory for web/native).
  Future<bool> saveStafPermissions(Map<String, bool> permissions) async {
    try {
      _webPermissions.addAll(permissions);
      // TODO: persist to a DB table (e.g. staf_permissions) for production
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── SYSTEM CONFIGURATION ──────────────────────────────────────────────────

  /// Fetches system configuration settings
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

      // Try parsing numeric or bool types
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

  /// Saves system configuration settings
  Future<bool> saveSystemConfig(Map<String, dynamic> config) async {
    if (kIsWeb) {
      _webSystemConfig.addAll(config);
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

  // ── AUDIT LOGS ────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _webAuditLogs = [
    {
      'time': '04 Aug 2026 - 10:42',
      'user_name': 'Akmal Ahsan',
      'role': 'Administrator',
      'module': 'Konfigurasi Sistem',
      'action': 'Mengubah Rasio Poin dari Rp 1 ke Rp 1.2/Poin',
      'ip_address': '192.168.1.10',
      'status': 'SUKSES',
    },
    {
      'time': '04 Aug 2026 - 10:15',
      'user_name': 'Budi Santoso',
      'role': 'Staf Kantor',
      'module': 'Master Data',
      'action': 'Menambahkan Harga Sampah Kategori Plastic PET',
      'ip_address': '192.168.1.15',
      'status': 'SUKSES',
    },
    {
      'time': '04 Aug 2026 - 09:50',
      'user_name': 'System Auto',
      'role': 'System',
      'module': 'Operasional',
      'action': 'Penugasan Otomatis Driver (Driver ID: #DRV-09)',
      'ip_address': '127.0.0.1',
      'status': 'SUKSES',
    },
    {
      'time': '04 Aug 2026 - 08:30',
      'user_name': 'Unknown User',
      'role': 'Guest',
      'module': 'Authentication',
      'action': 'Percobaan Login Gagal (Salah Password 3x)',
      'ip_address': '180.252.10.4',
      'status': 'GAGAL',
    },
    {
      'time': '04 Aug 2026 - 08:00',
      'user_name': 'Siti Aminah',
      'role': 'Staf Kantor',
      'module': 'Manajemen Transaksi',
      'action': 'Menyetujui Pencairan Poin Rp 50.000 (#TX-8821)',
      'ip_address': '192.168.1.18',
      'status': 'SUKSES',
    },
  ];

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

    // Apply filters
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
    if (kIsWeb) {
      _webAuditLogs.insert(0, log);
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

  // ── MOCK DATA ─────────────────────────────────────────────────────────────

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

  // ── DROP POINTS CRUD ──────────────────────────────────────────────────────
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

  // ── WASTE CATEGORIES CRUD ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getWasteCategories() async {
    if (kIsWeb) return List.from(_webWasteCategories);
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('waste_categories');
  }

  Future<bool> addWasteCategory(Map<String, dynamic> wc) async {
    if (kIsWeb) {
      if (!wc.containsKey('id')) {
        wc['id'] = _webWasteCategories.length + 1;
      }
      _webWasteCategories.add(wc);
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
        _webWasteCategories[idx] = wc;
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

  // ==========================================
  // TRANSACTIONS
  // ==========================================

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
      await db.transaction((txn) async {
        await txn.insert('transactions', txData);
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
          orElse: () => {'full_name': 'Unknown'},
        );
        return {
          ...tx,
          'nasabah_name': user['full_name'],
          'items': _webTransactionItems
              .where((i) => i['transaction_id'] == tx['id'])
              .toList(),
        };
      }).toList();
    }

    final db = await instance.database;
    if (db == null) return [];

    final List<Map<String, dynamic>> txs = await db.rawQuery('''
      SELECT t.*, u.full_name as nasabah_name 
      FROM transactions t 
      LEFT JOIN users u ON t.nasabah_id = u.id
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
}
