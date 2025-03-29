import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UpdateItemOffline extends StatefulWidget {
  final String qrCodeData;

  UpdateItemOffline({required this.qrCodeData});

  @override
  State<UpdateItemOffline> createState() => _UpdateItemOfflineState();
}

class _UpdateItemOfflineState extends State<UpdateItemOffline> {
  final TextEditingController quantityController = TextEditingController();

  Future<void> addQuantity() async {
    final inventoryBox = await Hive.openBox('inventory');
    final pendingUpdatesBox = await Hive.openBox('pending_updates');

    Map<dynamic, dynamic> inventoryMap = inventoryBox.toMap();
    var itemKey;
    var item;
    print("Scanned QR Code Data: ${widget.qrCodeData}");

    // Search for the correct item by matching qr_code_data
    for (var key in inventoryMap.keys) {
      var currentItem = inventoryMap[key];
      if (currentItem['qr_code_data'] == widget.qrCodeData) {
        item = currentItem;
        itemKey = key;
        break;
      }
    }

    if (item != null) {
      int currentQuantity = int.tryParse(item['quantity'].toString()) ?? 0;
      int addQuantity = int.tryParse(quantityController.text) ?? 0;

      if (addQuantity > 0) {
        item['quantity'] = currentQuantity + addQuantity;
        await inventoryBox.put(itemKey, item);

        // Save the addition to pending updates for later sync
        pendingUpdatesBox.add({
          'qr_code_data': widget.qrCodeData,
          'quantity_added': addQuantity,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity added successfully (Offline).')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid quantity entered.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item not found in offline storage.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Quantity (Offline)')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter Quantity to Add'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: addQuantity, child: Text('Add Quantity')),
          ],
        ),
      ),
    );
  }
}
