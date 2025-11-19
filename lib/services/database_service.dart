import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/baby_profile.dart';
import '../models/reading.dart';

// Database Service with CRUD operations
class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _db;

  DatabaseService._constructor();

  // Singleton pattern - get or create database
  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "baby_profiles.db");
    
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: _onCreateDB,
    );
    
    return database;
  }

  // Create database tables
  Future<void> _onCreateDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        gestational_age INTEGER,
        weight REAL,
        gender TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        baby_profile_id INTEGER NOT NULL,
        heart_rate INTEGER NOT NULL,
        spo2 INTEGER NOT NULL,
        breathing_rate INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (baby_profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');
  }

  // CREATE - Add a new baby profile
  Future<int> addProfile(BabyProfile profile) async {
    final db = await database;
    final id = await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // READ - Get all profiles
  Future<List<BabyProfile>> getAllProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return BabyProfile.fromMap(maps[i]);
    });
  }

  // READ - Get a single profile by ID
  Future<BabyProfile?> getProfileById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return BabyProfile.fromMap(maps.first);
  }

  // READ - Search profiles by name
  Future<List<BabyProfile>> searchProfiles(String searchTerm) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'first_name LIKE ? OR last_name LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return BabyProfile.fromMap(maps[i]);
    });
  }

  // UPDATE - Update an existing profile
  Future<int> updateProfile(BabyProfile profile) async {
    final db = await database;
    final rowsAffected = await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
    return rowsAffected;
  }

  // DELETE - Delete a profile by ID
  Future<int> deleteProfile(int id) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rowsDeleted;
  }

  // DELETE - Delete all profiles (use with caution!)
  Future<int> deleteAllProfiles() async {
    final db = await database;
    final rowsDeleted = await db.delete('profiles');
    return rowsDeleted;
  }

  // UTILITY - Get total count of profiles
  Future<int> getProfileCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM profiles');
    final count = Sqflite.firstIntValue(result);
    return count ?? 0;
  }

  // ==================== READINGS OPERATIONS ====================

  // CREATE - Add a new reading
  Future<int> addReading(Reading reading) async {
    final db = await database;
    final id = await db.insert(
      'readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // READ - Get all readings for a baby profile
  Future<List<Reading>> getReadingsByProfileId(int babyProfileId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'baby_profile_id = ?',
      whereArgs: [babyProfileId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return Reading.fromMap(maps[i]);
    });
  }

  // READ - Get readings for a baby profile within a date range
  Future<List<Reading>> getReadingsByDateRange(
    int babyProfileId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'baby_profile_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        babyProfileId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return Reading.fromMap(maps[i]);
    });
  }

  // READ - Get latest N readings for a baby profile
  Future<List<Reading>> getLatestReadings(int babyProfileId, int limit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'baby_profile_id = ?',
      whereArgs: [babyProfileId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Reading.fromMap(maps[i]);
    }).reversed.toList();
  }

  // READ - Get a single reading by ID
  Future<Reading?> getReadingById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Reading.fromMap(maps.first);
  }

  // UPDATE - Update a reading
  Future<int> updateReading(Reading reading) async {
    final db = await database;
    final rowsAffected = await db.update(
      'readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
    return rowsAffected;
  }

  // DELETE - Delete a reading by ID
  Future<int> deleteReading(int id) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'readings',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rowsDeleted;
  }

  // DELETE - Delete all readings for a baby profile
  Future<int> deleteReadingsByProfileId(int babyProfileId) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'readings',
      where: 'baby_profile_id = ?',
      whereArgs: [babyProfileId],
    );
    return rowsDeleted;
  }

  // UTILITY - Get reading count for a baby profile
  Future<int> getReadingCount(int babyProfileId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM readings WHERE baby_profile_id = ?',
      [babyProfileId],
    );
    final count = Sqflite.firstIntValue(result);
    return count ?? 0;
  }

  // UTILITY - Get session statistics (for session summary)
  Future<Map<String, double>> getSessionStatistics(
    int babyProfileId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final readings = await getReadingsByDateRange(
      babyProfileId,
      startTime,
      endTime,
    );

    if (readings.isEmpty) {
      return {
        'avgHeartRate': 0,
        'avgSpO2': 0,
        'avgBreathingRate': 0,
        'minHeartRate': 0,
        'maxHeartRate': 0,
        'minSpO2': 0,
        'maxSpO2': 0,
        'minBreathingRate': 0,
        'maxBreathingRate': 0,
        'readingCount': 0,
      };
    }

    final heartRates = readings.map((r) => r.heartRate.toDouble()).toList();
    final spO2Values = readings.map((r) => r.spO2.toDouble()).toList();
    final breathingRates = readings.map((r) => r.breathingRate.toDouble()).toList();

    return {
      'avgHeartRate': heartRates.reduce((a, b) => a + b) / heartRates.length,
      'avgSpO2': spO2Values.reduce((a, b) => a + b) / spO2Values.length,
      'avgBreathingRate': breathingRates.reduce((a, b) => a + b) / breathingRates.length,
      'minHeartRate': heartRates.reduce((a, b) => a < b ? a : b),
      'maxHeartRate': heartRates.reduce((a, b) => a > b ? a : b),
      'minSpO2': spO2Values.reduce((a, b) => a < b ? a : b),
      'maxSpO2': spO2Values.reduce((a, b) => a > b ? a : b),
      'minBreathingRate': breathingRates.reduce((a, b) => a < b ? a : b),
      'maxBreathingRate': breathingRates.reduce((a, b) => a > b ? a : b),
      'readingCount': readings.length.toDouble(),
    };
  }

  // UTILITY - Close database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}