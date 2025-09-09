import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/address.dart';
import '../models/route.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'hod.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE addresses (
        id TEXT PRIMARY KEY,
        street TEXT NOT NULL,
        houseNumber TEXT NOT NULL,
        apartment TEXT,
        plotNumber TEXT,
        latitude REAL,
        longitude REAL,
        isVisited INTEGER NOT NULL DEFAULT 0,
        comment TEXT,
        createdAt INTEGER NOT NULL,
        visitedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        completedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE route_addresses (
        routeId TEXT NOT NULL,
        addressId TEXT NOT NULL,
        PRIMARY KEY (routeId, addressId),
        FOREIGN KEY (routeId) REFERENCES routes (id) ON DELETE CASCADE,
        FOREIGN KEY (addressId) REFERENCES addresses (id) ON DELETE CASCADE
      )
    ''');
  }

  // Address operations
  Future<String> insertAddress(Address address) async {
    final db = await database;
    await db.insert('addresses', address.toMap());
    return address.id;
  }

  Future<List<Address>> getAllAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'addresses',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Address.fromMap(maps[i]);
    });
  }

  Future<Address?> getAddress(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Address.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateAddress(Address address) async {
    final db = await database;
    await db.update(
      'addresses',
      address.toMap(),
      where: 'id = ?',
      whereArgs: [address.id],
    );
  }

  Future<void> deleteAddress(String id) async {
    final db = await database;
    await db.delete(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Route operations
  Future<String> insertRoute(Route route) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('routes', route.toMap());
      
      for (final address in route.addresses) {
        await txn.insert('route_addresses', {
          'routeId': route.id,
          'addressId': address.id,
        });
      }
    });
    return route.id;
  }

  Future<List<Route>> getAllRoutes() async {
    final db = await database;
    final List<Map<String, dynamic>> routeMaps = await db.query(
      'routes',
      orderBy: 'createdAt DESC',
    );

    final List<Route> routes = [];
    for (final routeMap in routeMaps) {
      final routeId = routeMap['id'];
      
      // Get addresses for this route
      final List<Map<String, dynamic>> addressMaps = await db.rawQuery('''
        SELECT a.* FROM addresses a
        INNER JOIN route_addresses ra ON a.id = ra.addressId
        WHERE ra.routeId = ?
        ORDER BY a.createdAt
      ''', [routeId]);

      final addresses = addressMaps.map((map) => Address.fromMap(map)).toList();
      routes.add(Route.fromMap(routeMap, addresses));
    }

    return routes;
  }

  Future<Route?> getRoute(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> routeMaps = await db.query(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (routeMaps.isNotEmpty) {
      final routeMap = routeMaps.first;
      final routeId = routeMap['id'];
      
      // Get addresses for this route
      final List<Map<String, dynamic>> addressMaps = await db.rawQuery('''
        SELECT a.* FROM addresses a
        INNER JOIN route_addresses ra ON a.id = ra.addressId
        WHERE ra.routeId = ?
        ORDER BY a.createdAt
      ''', [routeId]);

      final addresses = addressMaps.map((map) => Address.fromMap(map)).toList();
      return Route.fromMap(routeMap, addresses);
    }
    return null;
  }

  Future<void> updateRoute(Route route) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'routes',
        route.toMap(),
        where: 'id = ?',
        whereArgs: [route.id],
      );

      // Update route addresses
      await txn.delete(
        'route_addresses',
        where: 'routeId = ?',
        whereArgs: [route.id],
      );

      for (final address in route.addresses) {
        await txn.insert('route_addresses', {
          'routeId': route.id,
          'addressId': address.id,
        });
      }
    });
  }

  Future<void> deleteRoute(String id) async {
    final db = await database;
    await db.delete(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
