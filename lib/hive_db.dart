import 'package:hive/hive.dart';

class HiveDatabase {
  static Future<void> addPendingUpdate(
    String qrCode,
    int quantity,
    String action,
  ) async {
    final box = await Hive.openBox('pendingUpdates');
    await box.add({'qr_code': qrCode, 'quantity': quantity, 'action': action});
  }

  static Future<List<Map<String, dynamic>>> getPendingUpdates() async {
    final box = await Hive.openBox('pendingUpdates');
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> deletePendingUpdate(int index) async {
    final box = await Hive.openBox('pendingUpdates');
    await box.deleteAt(index);
  }
}
