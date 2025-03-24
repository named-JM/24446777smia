import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Storage/qr.dart';
import 'package:qrqragain/Storage/update.dart';
import 'package:qrqragain/constants.dart';

class InventoryPage extends StatefulWidget {
  final List<dynamic> lowStockItems;

  InventoryPage({this.lowStockItems = const []});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<dynamic> items = [];
  List<dynamic> filteredItems = [];
  String searchQuery = '';
  String sortBy = 'name';

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));
    if (response.statusCode == 200) {
      setState(() {
        items = jsonDecode(response.body)['items'];
        filteredItems = items;
      });
    }
  }

  void filterItems(String query) {
    setState(() {
      searchQuery = query;
      filteredItems =
          items
              .where(
                (item) =>
                    item['item_name'].toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    item['category'].toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    });
  }

  void sortItems(String criteria) {
    setState(() {
      sortBy = criteria;
      filteredItems.sort((a, b) {
        if (criteria == 'name') {
          return a['item_name'].compareTo(b['item_name']);
        } else if (criteria == 'quantity') {
          return int.parse(a['quantity']).compareTo(int.parse(b['quantity']));
        } else if (criteria == 'date_added') {
          return a['date_added'].compareTo(b['date_added']);
        }
        return 0;
      });
    });
  }

  void openQRScanner() async {
    String? scannedQR = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );

    if (scannedQR != null) {
      bool? updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateItemPage(qrCodeData: scannedQR),
        ),
      );

      // If an item was updated, refresh the inventory
      if (updated == true) {
        fetchItems();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: filterItems,
            ),
            SizedBox(height: 10),

            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchItems, // Pull-to-refresh
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['item_name']),
                        subtitle: Text(
                          'Category: ${item['category']} \n'
                          'Quantity: ${item['quantity']} \n'
                          'Exp Date: ${item['exp_date'] ?? 'N/A'}', // Display expiration date
                        ),
                        onTap:
                            openQRScanner, // Open scanner when tapping an item
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
