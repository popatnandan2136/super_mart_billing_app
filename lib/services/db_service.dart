import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';

class DbService {
  static Database? _database;

  static Future<Database?> get database async {
    try {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint("SQLite Database initialization skipped/failed: $e");
      return null;
    }
  }

  static Future<Database?> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'super_mart_billing.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE products (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              price REAL NOT NULL,
              unit TEXT NOT NULL,
              iconCodePoint INTEGER NOT NULL,
              colorValue INTEGER NOT NULL,
              isCustom INTEGER NOT NULL
            )
          ''');

          // Pre-populate default products as required
          final defaultProducts = [
            const Product(
              id: 'p1',
              name: 'Milk',
              price: 35.0,
              unit: 'pack',
              icon: Icons.water_drop_rounded,
              color: Color(0xFF1E88E5),
            ),
            const Product(
              id: 'p2',
              name: 'Bread',
              price: 40.0,
              unit: 'pack',
              icon: Icons.bakery_dining_rounded,
              color: Color(0xFFFFB300),
            ),
            const Product(
              id: 'p3',
              name: 'Butter',
              price: 60.0,
              unit: 'pack',
              icon: Icons.kitchen_rounded,
              color: Color(0xFFFB8C00),
            ),
            const Product(
              id: 'p4',
              name: 'Rice',
              price: 90.0,
              unit: 'kg',
              icon: Icons.rice_bowl_rounded,
              color: Color(0xFF7CB342),
            ),
            const Product(
              id: 'p5',
              name: 'Sugar',
              price: 50.0,
              unit: 'kg',
              icon: Icons.grain_rounded,
              color: Color(0xFF00ACC1),
            ),
            const Product(
              id: 'p6',
              name: 'Tea',
              price: 120.0,
              unit: 'pack',
              icon: Icons.emoji_food_beverage_rounded,
              color: Color(0xFF8D6E63),
            ),
          ];

          for (final product in defaultProducts) {
            await db.insert('products', product.toMap());
          }
        },
      );
    } catch (e) {
      debugPrint("SQLite _initDatabase error: $e");
      return null;
    }
  }

  static Future<List<Product>> getProducts() async {
    try {
      final db = await database;
      if (db == null) return [];

      final List<Map<String, dynamic>> maps = await db.query('products');
      if (maps.isEmpty) return [];

      return maps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error fetching products from DB: $e");
      return [];
    }
  }

  static Future<void> insertProduct(Product product) async {
    try {
      final db = await database;
      if (db == null) return;

      await db.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint("Error inserting product into DB: $e");
    }
  }

  static Future<void> deleteProduct(String id) async {
    try {
      final db = await database;
      if (db == null) return;

      await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint("Error deleting product from DB: $e");
    }
  }
}
