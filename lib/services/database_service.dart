import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/baby_profile.dart';

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

  // UTILITY - Close database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}