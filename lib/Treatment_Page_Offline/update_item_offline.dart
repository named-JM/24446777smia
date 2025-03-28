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

    // Fetch the item from the inventory box using the QR code
    var item = inventoryBox.get(widget.qrCodeData);

    if (item != null) {
      int currentQuantity =
          int.tryParse(item['quantity'].toString()) ??
          0; // Parse current quantity
      int addQuantity =
          int.tryParse(quantityController.text) ?? 0; // Parse input quantity

      if (addQuantity > 0) {
        // Update the quantity
        item['quantity'] = currentQuantity + addQuantity;
        await inventoryBox.put(widget.qrCodeData, item);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity added successfully (Offline).')),
        );
        Navigator.pop(context, true); // Return to the previous page
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
