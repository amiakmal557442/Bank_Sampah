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
}
