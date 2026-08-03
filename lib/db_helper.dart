import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
      'password': 'password123',
      'role': 'nasabah',
      'address': 'Jl. Mawar No. 12, Jakarta',
      'default_setor_method': 'drop_in',
      'point_balance': 4820,
    },
    {
      'id': 'petugas-uuid-1234-5678',
      'phone_number': '+62 812-9999-8888',
      'email': 'petugas@gmail.com',
      'full_name': 'Ahmad Petugas',
      'password': 'password123',
      'role': 'petugas',
      'address':
          'Zona: Drop Point 01 - Pusat Kota, Armada: Motor Roda 2, Plat: B 1234 ABC',
      'default_setor_method': 'pickup',
      'point_balance': 0,
    },
    {
      'id': 'admin-uuid-akmal-223',
      'phone_number': '+62 812-1111-2222',
      'email': 'akmalahsan223@gmail.com',
      'full_name': 'Akmal Ahsan',
      'password': 'jasadidas557442',
      'role': 'admin',
      'address': 'Kantor Pusat Bank Sampah',
      'default_setor_method': 'drop_in',
      'point_balance': 99999,
    },
    {
      'id': 'admin-uuid-fanska-221',
      'phone_number': '+62 812-3333-4444',
      'email': 'fanskawe221@gmail.com',
      'full_name': 'Fanska',
      'password': '557442337554',
      'role': 'admin',
      'address': 'Kantor Pusat Bank Sampah',
      'default_setor_method': 'drop_in',
      'point_balance': 99999,
    },
  ];

  DatabaseHelper._init();

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
      version: 1,
      onCreate: _createDB,
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

    // Seeding default users
    for (var u in _webUsers) {
      await db.insert('users', u);
    }
  }

  // User auth and operations
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      try {
        return _webUsers.firstWhere(
          (u) =>
              u['email'].toString().toLowerCase() == cleanEmail &&
              u['password'] == password,
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
      whereArgs: [cleanEmail, password],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<bool> registerUser(Map<String, dynamic> user) async {
    if (kIsWeb) {
      final email = user['email']?.toString().toLowerCase();
      final phone = user['phone_number']?.toString();

      final exists = _webUsers.any(
        (u) =>
            (email != null && u['email'].toString().toLowerCase() == email) ||
            (phone != null && u['phone_number']?.toString() == phone),
      );

      if (exists) return false;

      _webUsers.add(user);
      return true;
    }

    final db = await instance.database;
    if (db == null) return false;
    try {
      await db.insert('users', user);
      return true;
    } catch (e) {
      return false;
    }
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
      String shortId = taskIdStr.length > 4
          ? taskIdStr.substring(0, 4)
          : taskIdStr;

      return {
        'petugas_name': row['petugas_name'],
        'vehicle': vehicle,
        'location': row['dp_name'] ?? 'Lokasi Nasabah',
        'task': row['task_type'] == 'pickup'
            ? 'Pickup \$shortId'
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
}
