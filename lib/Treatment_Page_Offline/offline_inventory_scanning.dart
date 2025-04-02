import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:qrqragain/Treatment_Area/qr.dart';
import 'package:qrqragain/Treatment_Page_Offline/remove_item_offline.dart';
import 'package:qrqragain/Treatment_Page_Offline/update_item_offline.dart';

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

  void openQRScanner() async {
    // Scan the QR code first
    String? scannedQR = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage(action: 'scan')),
    );

    if (scannedQR != null) {
      // Fetch item details from  Hive based on the scanned QR code
      final box = await Hive.openBox('inventory');
      var matchedItem = box.values.firstWhere(
        (item) => item['qr_code_data'] == scannedQR,
        orElse: () => null,
      );

      if (matchedItem != null) {
        String itemName = matchedItem['item_name'] ?? 'Unknown Item';
        String serialNo = matchedItem['serial_no'] ?? 'N/A';
        String expDate = matchedItem['exp_date'] ?? '';
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
                            (context) => UpdateItemOffline(
                              itemName: itemName,
                              qrCodeData: scannedQR,
                              serialNo: serialNo,
                              expDate: expDate,
                              fromQRScanner:
                                  true, // Indicate navigation from QR Scanner
                            ),
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
                            (context) => RemoveQuantityPageOffline(
                              qrCodeData: scannedQR,
                            ),
                      ),
                    );
                  },
                  child: const Text('Remove Items'),
                ),
              ],
            );
          },
        );
      } else {
        // Show error if no matching item is found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching item found for this QR Code')),
        );
      }
    }
  }

  @override
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
      body:
          items.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'Please be online first to sync it offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     // Add your sync function here
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       SnackBar(content: Text('Syncing data...')),
                    //     );
                    //   },
                    //   child: Text('Sync Now'),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.green,
                    //   ),
                    // ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchMedicines,
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final medicine = items[index];

                          final serialNo = medicine['serial_no'] ?? 'N/A';
                          final itemName =
                              medicine['item_name'] ?? 'Unknown Item';
                          final quantity = medicine['quantity'] ?? 0;
                          final expDate = medicine['exp_date'] ?? 'N/A';
                          final brand = medicine['brand'] ?? 'Unknown Brand';
                          final category =
                              medicine['category'] ?? 'Unknown Category';
                          final qrCodeData =
                              medicine['qr_code_data'] ?? 'Unknown QR Code';

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
                              trailing: IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                tooltip: "Edit Item",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => UpdateItemOffline(
                                            itemName:
                                                itemName, // ✅ Pass item_name
                                            qrCodeData:
                                                qrCodeData, // ✅ Pass qr_code_data
                                            serialNo:
                                                serialNo, // ✅ Pass serial_no
                                            expDate: expDate, // ✅ Pass exp_date
                                            fromQRScanner:
                                                false, // Indicate navigation from QR Scanner
                                          ),
                                    ),
                                  ).then((_) {
                                    fetchMedicines();
                                  });
                                },
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
