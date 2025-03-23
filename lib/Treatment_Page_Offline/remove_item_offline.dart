import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';

Future<void> syncInventory() async {
  final box = await Hive.openBox('inventory');

  // Check if Hive already has data
  if (box.isNotEmpty) {
    print("Offline inventory already exists.");
    return;
  }

  final response = await http.get(Uri.parse("$BASE_URL/get_items.php"));

  if (response.statusCode == 200) {
    List<dynamic> inventoryList = jsonDecode(response.body);

    for (var item in inventoryList) {
      box.put(item['qr_code_data'], {
        'item_name': item['item_name'],
        'quantity': item['quantity'],
      });
    }

    print("Inventory synced successfully!");
  } else {
    print("Failed to fetch inventory from server.");
  }
}

class RemoveQuantityPageOffline extends StatefulWidget {
  final String qrCodeData;

  RemoveQuantityPageOffline({required this.qrCodeData});

  @override
  _RemoveQuantityPageOfflineState createState() =>
      _RemoveQuantityPageOfflineState();
}

class _RemoveQuantityPageOfflineState extends State<RemoveQuantityPageOffline> {
  final TextEditingController quantityController = TextEditingController();

  Future<void> removeQuantity() async {
    final inventoryBox = await Hive.openBox('inventory');
    final pendingUpdatesBox = await Hive.openBox('pending_updates');

    var item = inventoryBox.get(widget.qrCodeData);
    if (item != null) {
      int currentQuantity = item['quantity'];
      int removeQuantity = int.tryParse(quantityController.text) ?? 0;

      if (removeQuantity > 0 && removeQuantity <= currentQuantity) {
        item['quantity'] = currentQuantity - removeQuantity;
        await inventoryBox.put(widget.qrCodeData, item);

        // Save to pending_updates for later sync
        pendingUpdatesBox.add({
          'qr_code_data': widget.qrCodeData,
          'quantity_removed': removeQuantity,
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item not found in offline storage.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Remove Quantity (Offline)')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
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
