import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class RemoveQuantityPageOffline extends StatefulWidget {
  final String qrCodeData;

  RemoveQuantityPageOffline({required this.qrCodeData});

  @override
  _RemoveQuantityPageOfflineState createState() =>
      _RemoveQuantityPageOfflineState();
}

class _RemoveQuantityPageOfflineState extends State<RemoveQuantityPageOffline> {
  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBatchesOffline(); // Call the function to fetch batches
    // syncInventory(); // Sync inventory when the page initializes
    // printHiveData(); // Print Hive data for debugging
  }

  // void printHiveData() async {
  //   print("Printing Hive data...");

  //   // Open the Hive box and print its contents
  //   // This is just for debugging purposes
  //   final box = await Hive.openBox('inventory');
  //   print("Hive Inventory Data: ${box.toMap()}");
  // }

  List<Map<String, dynamic>> batches = [];
  String? selectedExpDate;

  Future<void> fetchBatchesOffline() async {
    final inventoryBox = await Hive.openBox('inventory');

    final inventoryMap = inventoryBox.toMap();
    batches =
        inventoryMap.values
            .where((item) => item['qr_code_data'] == widget.qrCodeData)
            .map(
              (item) => {
                'key': inventoryMap.keys.firstWhere(
                  (key) => inventoryMap[key] == item,
                ),
                'serial_no': item['serial_no'], // Fetch serial_no
                'qr_code_data': item['qr_code_data'],
                'exp_date': item['exp_date'],
                'brand': item['brand'], // Fetch brand
                'category': item['category'], // Fetch category
                'quantity': item['quantity'],
              },
            )
            .toList();

    print('Fetched Batches: $batches'); // Debugging

    if (batches.isNotEmpty) {
      setState(() {
        selectedExpDate =
            batches.firstWhere(
              (batch) => batch['exp_date'] != null,
            )['exp_date'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No batches found for this item.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> removeQuantity() async {
    if (selectedExpDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a batch')));
      return;
    }

    final inventoryBox = await Hive.openBox('inventory');
    final pendingRemovalsBox = await Hive.openBox('pending_removals');

    final batch = batches.firstWhere(
      (batch) => batch['exp_date'] == selectedExpDate,
    );
    final batchKey = batch['key'];
    final currentQuantity = batch['quantity'];
    final removeQuantity = int.tryParse(quantityController.text) ?? 0;

    if (removeQuantity > 0 && removeQuantity <= currentQuantity) {
      // Update inventory
      final updatedBatch = inventoryBox.get(batchKey);
      updatedBatch['quantity'] = currentQuantity - removeQuantity;

      if (updatedBatch['quantity'] > 0) {
        await inventoryBox.put(batchKey, updatedBatch);
      } else {
        await inventoryBox.delete(batchKey); // Remove item if quantity is zero
      }

      // Save to pending_removals
      pendingRemovalsBox.add({
        'serial_no': batch['serial_no'],
        'qr_code_data': widget.qrCodeData,
        'exp_date': selectedExpDate,
        'quantity_removed': removeQuantity,
        'brand': batch['brand'],
        'category': batch['category'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity removed successfully (Offline).')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid quantity')));
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Batches List: $batches');

    return Scaffold(
      appBar: AppBar(title: Text('Remove Quantity (Offline)')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (batches.isNotEmpty)
              DropdownButton<String>(
                value:
                    batches.any((batch) => batch['exp_date'] == selectedExpDate)
                        ? selectedExpDate
                        : null, // Avoids selecting an invalid value
                items:
                    batches
                        .map((batch) => batch['exp_date'])
                        .toSet() // Remove duplicates
                        .map(
                          (expDate) => DropdownMenuItem<String>(
                            value: expDate,
                            child: Text(
                              'Expiry: $expDate | Qty: ${batches.firstWhere((batch) => batch['exp_date'] == expDate)['quantity']}',
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedExpDate = value;
                  });
                },
                hint: Text('Select Expiration Date'),
              )
            else
              Text('Loading batches...'),

            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Quantity to Remove',
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: removeQuantity,
              child: Text('Remove Quantity'),
            ),
          ],
        ),
      ),
    );
  }
}
