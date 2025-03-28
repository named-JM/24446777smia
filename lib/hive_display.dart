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
                  return ListTile(
                    title: Text(item['item_name']),
                    subtitle: Text("Quantity: ${item['quantity']}"),
                  );
                },
              ),
    );
  }
}
