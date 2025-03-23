import 'package:hive/hive.dart';

class LocalDatabase {
  static Future<void> addPendingUpdate(
    String qrCode,
    int quantity,
    String action,
  ) async {
    var box = await Hive.openBox('pending_updates');
    await box.add({'qr_code': qrCode, 'quantity': quantity, 'action': action});
  }

  static Future<List<Map<String, dynamic>>> getPendingUpdates() async {
    var box = await Hive.openBox('pending_updates');
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> deletePendingUpdate(int index) async {
    var box = await Hive.openBox('pending_updates');
    await box.deleteAt(index);
  }
}

// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';

// class LocalDatabase {
//   static Database? _database;

//   static Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB();
//     return _database!;
//   }

//   static Future<Database> _initDB() async {
//     final path = join(await getDatabasesPath(), 'inventory.db');
//     return openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE pending_updates (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             qr_code TEXT,
//             quantity INTEGER,
//             action TEXT
//           )
//         ''');
//       },
//     );
//   }

//   static Future<void> addPendingUpdate(
//     String qrCode,
//     int quantity,
//     String action,
//   ) async {
//     final db = await database;
//     await db.insert('pending_updates', {
//       'qr_code': qrCode,
//       'quantity': quantity,
//       'action': action,
//     });
//   }

//   static Future<List<Map<String, dynamic>>> getPendingUpdates() async {
//     final db = await database;
//     return db.query('pending_updates');
//   }

//   static Future<void> deletePendingUpdate(int id) async {
//     final db = await database;
//     await db.delete('pending_updates', where: 'id = ?', whereArgs: [id]);
//   }
// }
