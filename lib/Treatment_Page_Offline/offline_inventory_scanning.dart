import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Treatment_Area/qr.dart';
import 'package:qrqragain/Treatment_Page_Offline/remove_item_offline.dart';
import 'package:qrqragain/Treatment_Page_Offline/update_item_offline.dart';
import 'package:qrqragain/constants.dart';

class OfflineScanningPage extends StatefulWidget {
  @override
  _OfflineScanningPageState createState() => _OfflineScanningPageState();
}

class _OfflineScanningPageState extends State<OfflineScanningPage> {
  List<Map<String, dynamic>> items = [];

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
        await box.clear(); // Clear old data before inserting new data

        for (var item in onlineItems) {
          await box.add(item);
        }

        print("Sync successful: MySQL data updated in Hive!");
        fetchMedicines(); // Refresh UI with updated data
      } else {
        print("Failed to fetch online data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error syncing data: $e");
    }
  }

  void openQRScanner() async {
    // Scan the QR code first
    String? scannedQR = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage(action: 'scan')),
    );

    if (scannedQR != null) {
      // Show a dialog to choose between Add or Remove
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Action'),
            content: const Text('Do you want to add or remove items?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  // Navigate to UpdateItemPage for adding items
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => UpdateItemOffline(qrCodeData: scannedQR),
                    ),
                  );
                },
                child: const Text('Add Items'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  // Navigate to RemoveQuantityPage for removing items
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              RemoveQuantityPageOffline(qrCodeData: scannedQR),
                    ),
                  );
                },
                child: const Text('Remove Items'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Scanning (Offline)'),
        backgroundColor: Colors.lightGreen, // Green app bar color
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            iconSize: 40,
            onPressed: () {
              openQRScanner(); // Sync online data to offline
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ElevatedButton(
          //   onPressed: openQRScanner,
          //   child: const Text('Scan QR', style: TextStyle(color: Colors.white)),
          //   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          // ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMedicines,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final medicine = items[index];

                  final itemName = medicine['item_name'] ?? 'Unknown Item';
                  final quantity = medicine['quantity'] ?? 0;
                  final expDate = medicine['exp_date'];
                  final brand = medicine['brand'];
                  final category = medicine['category'] ?? 'Unknown Category';

                  return Card(
                    child: ListTile(
                      title: Text(itemName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Quantity: $quantity"),
                          Text("Expiration Date: $expDate"),
                          Text("Brand: $brand"),
                          Text("Category: $category"),
                        ],
                      ),
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
