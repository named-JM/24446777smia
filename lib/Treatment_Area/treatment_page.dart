import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Treatment_Area/qr.dart';
import 'package:qrqragain/Treatment_Area/remove_item.dart';
import 'package:qrqragain/constants.dart';

class TreatmentPage extends StatefulWidget {
  @override
  _TreatmentPageState createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    checkInternetAndSync(); // Ensure sync runs when app starts
    fetchMedicines();
  }

  Future<void> checkInternetAndSync() async {
    try {
      final response = await http.get(
        Uri.parse("$BASE_URL/check_connection.php"),
      );
      if (response.statusCode == 200) {
        await syncPendingUpdates(); // Sync offline changes when online
      }
    } catch (e) {
      print("No internet connection");
    }
  }

  Future<void> syncPendingUpdates() async {
    final pendingUpdatesBox = await Hive.openBox('pending_updates');
    List<Map<String, dynamic>> updates = [];

    for (var update in pendingUpdatesBox.values) {
      updates.add(update);
    }

    if (updates.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$BASE_URL/sync_offline.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'updates': updates}),
        );

        if (response.statusCode == 200) {
          print("Offline updates synced successfully!");
          await pendingUpdatesBox.clear(); // Clear only on success
        } else {
          print(
            "Failed to sync offline updates. Server Response: ${response.body}",
          );
        }
      } catch (e) {
        print("Error syncing offline updates: $e");
      }
    }
  }

  Future<void> fetchMedicines() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));

      if (response.statusCode == 200) {
        setState(() {
          items = jsonDecode(response.body)['items'];
        });
      } else {
        print("Failed to load items. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching medicines: $e");
    }
  }

  void openQRScanner() async {
    String? scannedQR = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );

    if (scannedQR != null) {
      bool? updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RemoveQuantityPage(qrCodeData: scannedQR),
        ),
      );

      if (updated == true) {
        fetchMedicines(); // Refresh inventory if an item was updated
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treatment Area')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: openQRScanner,
            child: const Text('Scan QR'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMedicines,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final medicine = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(medicine['item_name']),
                      subtitle: Text('Quantity: ${medicine['quantity']}'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
