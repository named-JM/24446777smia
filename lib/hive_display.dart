import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HiveDisplay extends StatefulWidget {
  @override
  _HiveDisplayState createState() => _HiveDisplayState();
}

class _HiveDisplayState extends State<HiveDisplay> {
  late Box inventoryBox;
  bool isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    openBox();
  }

  Future<void> openBox() async {
    inventoryBox = await Hive.openBox('inventory');
    setState(() {
      isLoading = false; // Set loading to false after the box is opened
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Offline Inventory')),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : ListView.builder(
                itemCount: inventoryBox.length,
                itemBuilder: (context, index) {
                  final key = inventoryBox.keyAt(index);
                  final item = inventoryBox.get(key);

                  // Safely retrieve fields from the item
                  final qrCodeData = item['qr_code_data'] ?? 'N/A';
                  final itemId = item['item_id'] ?? 'N/A';
                  final serialNo = item['serial_no'] ?? 'N/A';
                  final itemName = item['item_name'] ?? 'Unknown Item';
                  final quantity = item['quantity'] ?? 0;
                  final expDate = item['exp_date'] ?? 'N/A';
                  final brand = item['brand'] ?? 'Unknown Brand';
                  final category = item['category'] ?? 'Unknown Category';

                  return ListTile(
                    title: Text(itemName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("QR Code Data: $qrCodeData"),
                        Text("Item ID: $itemId"),
                        Text("Serial No: $serialNo"),
                        Text("Quantity: $quantity"),
                        Text("Expiration Date: $expDate"),
                        Text("Brand: $brand"),
                        Text("Category: $category"),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
