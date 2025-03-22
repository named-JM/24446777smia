import 'package:flutter/material.dart';
import 'package:qrqragain/Storage/inventory.dart';
import 'package:qrqragain/main.dart';

class StorageHome extends StatefulWidget {
  const StorageHome({super.key});

  @override
  State<StorageHome> createState() => _StorageHomeState();
}

class _StorageHomeState extends State<StorageHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Storage")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => QRScannerScreen()),
                );
              },
              child: Text('qrView'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => InventoryPage()),
                );
              },
              child: Text('Inventory'),
            ),
          ],
        ),
      ),
    );
  }
}
