import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Future<void> syncInventory() async {
//   final box = await Hive.openBox('inventory');

//   final response = await http.get(Uri.parse("$BASE_URL/get_items.php"));

//   if (response.statusCode == 200) {
//     List<dynamic> inventoryList = jsonDecode(response.body)['items'];

//     await box.clear(); // Ensure the offline storage is fully updated

//     for (var item in inventoryList) {
//       // Debugging: Print the item and its qr_code_data
//       print('Processing item: $item');
//       final qrCodeData = item['qr_code_data'];

//       if (qrCodeData != null && qrCodeData is String) {
//         box.put(qrCodeData, {
//           'item_name': item['item_name'],
//           'quantity':
//               int.tryParse(item['quantity'].toString()) ??
//               0, // Ensure it's stored as an int
//         });
//       } else {
//         print('Invalid qr_code_data: $qrCodeData');
//       }
//     }

//     print("Inventory synced successfully!");
//   } else {
//     print("Failed to fetch inventory from server.");
//   }
// }

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
    // syncInventory(); // Sync inventory when the page initializes
    printHiveData(); // Print Hive data for debugging
  }

  void printHiveData() async {
    print("Printing Hive data...");

    // Open the Hive box and print its contents
    // This is just for debugging purposes
    final box = await Hive.openBox('inventory');
    print("Hive Inventory Data: ${box.toMap()}");
  }

  Future<void> removeQuantity() async {
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
      int removeQuantity = int.tryParse(quantityController.text) ?? 0;

      if (removeQuantity > 0 && removeQuantity <= currentQuantity) {
        item['quantity'] = currentQuantity - removeQuantity;
        await inventoryBox.put(itemKey, item);

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
            ElevatedButton(
              onPressed: printHiveData,
              child: Text('Print Hive Data'),
            ),
          ],
        ),
      ),
    );
  }
}
