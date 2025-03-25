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
