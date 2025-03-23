import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Treatment_Area/qr.dart';
import 'package:qrqragain/Treatment_Page_Offline/remove_item_offline.dart';
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/login/create/login.dart';

class TreatmentPageOffline extends StatefulWidget {
  @override
  _TreatmentPageOfflineState createState() => _TreatmentPageOfflineState();
}

class _TreatmentPageOfflineState extends State<TreatmentPageOffline> {
  List<Map<String, dynamic>> items = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  /// Fetch items from Hive (Offline Database)
  Future<void> fetchMedicines() async {
    final box = await Hive.openBox('inventory');
    setState(() {
      items = box.values.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  /// Sync the latest MySQL data to Hive
  Future<void> syncOnlineToOffline() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));

      if (response.statusCode == 200) {
        final List<dynamic> onlineItems = jsonDecode(response.body)['items'];

        final box = await Hive.openBox('inventory');
        await box.clear(); // Always clear old data before inserting new data

        for (var item in onlineItems) {
          await box.put(item['qr_code_data'], {
            // Store using qr_code_data as key
            'item_name': item['item_name'],
            'quantity': item['quantity'],
          });
        }

        print("Sync successful: MySQL data updated in Hive!");
        fetchMedicines(); // Refresh inventory after sync
      } else {
        print("Failed to fetch online data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error syncing data: $e");
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
          builder:
              (context) => RemoveQuantityPageOffline(qrCodeData: scannedQR),
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
      appBar: AppBar(
        title: const Text('Treatment Area (Offline)'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), // Reload button
            onPressed: () {
              _refreshIndicatorKey.currentState
                  ?.show(); // Trigger refresh indicator
              syncOnlineToOffline(); // Sync MySQL data to Hive
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: openQRScanner,
            child: const Text('Scan QR'),
          ),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
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
