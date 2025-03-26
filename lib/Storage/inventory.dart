import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
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
  List<dynamic> categories = [];
  String selectedCategory = 'All Categories';
  bool isLoading = true; // Add isLoading variable

  //load when the page opens
  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('$BASE_URL/get_categories.php'));
    if (response.statusCode == 200) {
      List<dynamic> fetchedCategories = jsonDecode(response.body)["categories"];

      setState(() {
        // Convert to List<Map<String, String>>
        categories = [
          {"name": "All Categories"}, // Ensure only one "All Categories"
        ];

        categories.addAll(
          fetchedCategories.map(
            (category) => {"name": category["name"].toString()},
          ),
        );

        selectedCategory = "All Categories"; // ✅ Always reset after fetching
      });
    } else {
      print("Error fetching categories: ${response.statusCode}");
    }
  }

  Future<void> fetchItems() async {
    final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse.containsKey('items')) {
        final itemsData = jsonResponse['items'];

        if (itemsData is List) {
          setState(() {
            items = itemsData;
            filteredItems = items;
            isLoading = false; // Set loading to false
          });
        } else {
          print("Error: 'items' is not a list.");
        }
      } else {
        print("Error: 'items' key not found in the response.");
      }
    } else {
      print(
        "Error: Failed to fetch items. Status code: ${response.statusCode}",
      );
    }
  }

  void filterItems(String query) {
    setState(() {
      searchQuery = query;
      filteredItems =
          items.where((item) {
            return item['item_name'].toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                item['category'].toLowerCase().contains(query.toLowerCase());
          }).toList();
    });
  }

  void filterByCategory(String category) {
    setState(() {
      if (category == 'Select Category' || category == 'All Categories') {
        filteredItems = items; // Show all items
      } else {
        filteredItems =
            items
                .where(
                  (item) =>
                      item['category'].toLowerCase() == category.toLowerCase(),
                )
                .toList();
      }
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

      if (updated == true) {
        fetchItems();
      }
    }
  }

  Future<void> downloadCSV(BuildContext context, List<dynamic> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No data available for CSV download.")),
      );
      return;
    }

    // **1️⃣ Prepare CSV Data**
    List<List<dynamic>> csvData = [
      [
        "Item Name",
        "Brand",
        "Category",
        "Specification",
        "Unit",
        "Cost",
        "Quantity",
        "Exp Date",
      ],
    ];

    for (var item in items) {
      csvData.add([
        item['item_name'],
        item['brand'],
        item['category'],
        item['specification'],
        item['unit'],
        item['cost'],
        item['quantity'],
        item['exp_date'] ?? 'N/A',
      ]);
    }

    // Convert CSV data to a String
    String csvString = const ListToCsvConverter().convert(csvData);

    // **2️⃣ Request Storage Permission (Android 10 and below)**
    if (await Permission.storage.request().isGranted) {
      try {
        // **3️⃣ Get the "Downloads" directory**
        Directory downloadsDirectory = Directory(
          '/storage/emulated/0/Download',
        );

        if (!downloadsDirectory.existsSync()) {
          downloadsDirectory.createSync(recursive: true);
        }

        // **4️⃣ Save the file in the Downloads folder**
        String filePath = "${downloadsDirectory.path}/inventory_data.csv";
        File file = File(filePath);
        await file.writeAsString(csvString);

        // **5️⃣ Show success message**
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ CSV saved to Downloads folder: inventory_data.csv",
            ),
          ),
        );

        print("CSV File saved at: $filePath");
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error saving CSV: $e")));
        print("Error saving CSV: $e");
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Storage permission denied!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247),
      // backgroundColor: const Color.fromARGB(255, 242, 241, 241),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Text('📦', style: TextStyle(fontSize: 30)),
            SizedBox(width: 10),
            Text('Storage Area'),
          ],
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : Padding(
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

                    // Buttons with full width and margin
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(
                        horizontal: 16,
                      ), // ✅ Adds margin both sides
                      child: Row(
                        children: [
                          // Dropdown with full width
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ), // ✅ Padding inside
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.green.shade900,
                                  width: 1,
                                ), // ✅ Border for dropdown
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true, // ✅ Full width
                                  value: selectedCategory,
                                  icon: const Icon(Icons.arrow_downward),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: const TextStyle(color: Colors.black),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedCategory = newValue;
                                        filterByCategory(selectedCategory);
                                      });
                                    }
                                  },
                                  items:
                                      categories.map<DropdownMenuItem<String>>((
                                        category,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: category["name"],
                                          child: Text(category["name"]),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ), // ✅ Space between dropdown & buttons
                          // QR Scanner Icon Button
                          IconButton(
                            onPressed: openQRScanner,
                            icon: Icon(
                              Icons.qr_code_scanner,
                              size: 30,
                              color: Colors.green[900],
                            ),
                            tooltip: "Scan QR Code",
                          ),

                          // Download Icon Button
                          IconButton(
                            onPressed: () {
                              downloadCSV(context, filteredItems);
                            },
                            icon: Icon(
                              Icons.download,
                              size: 30,
                              color: Colors.green[900],
                            ),
                            tooltip: "Download CSV",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchItems,
                        child: ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];

                            return Card(
                              color: Colors.white,
                              child: ListTile(
                                title: Text(
                                  item['item_name'],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Brand: ${item['brand']} \n'
                                      'Category: ${item['category']} \n'
                                      'Specification: ${item['specification']} \n'
                                      'Unit: ${item['unit']} \n'
                                      'Cost: ${item['cost']} \n'
                                      'Quantity: ${item['quantity']} \n'
                                      'Exp Date: ${item['exp_date'] ?? 'N/A'}',
                                    ),
                                    SizedBox(height: 5),
                                    _buildStatusChips(
                                      item['statuses'],
                                    ), // Display status badges
                                  ],
                                ),
                                trailing:
                                    item['qr_code_image'] != null &&
                                            item['qr_code_image'].startsWith(
                                              'http',
                                            )
                                        ? Image.network(
                                          item['qr_code_image'],
                                          width: 50,
                                          height: 50,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.qr_code,
                                                    size: 100,
                                                    color: Colors.grey,
                                                  ),
                                        )
                                        : Icon(
                                          Icons.qr_code,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                onTap: openQRScanner,
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

  // Display multiple statuses as colored badges
  Widget _buildStatusChips(List<dynamic>? statuses) {
    if (statuses == null || statuses.isEmpty)
      return SizedBox.shrink(); // No status

    return Wrap(
      spacing: 2,
      children:
          statuses.map((status) {
            Color chipColor;
            String statusText;

            switch (status) {
              case "low_stock":
                chipColor = Colors.red[800]!;
                statusText = "Low Stock";
                break;
              case "warning":
                chipColor = Colors.yellow[800]!;
                statusText = "3 Months Before Expiry";
                break;
              case "near_expiry":
                chipColor = Colors.orange[800]!;
                statusText = "Nearly Expired";
                break;
              case "expired":
                chipColor = Colors.red[900]!;
                statusText = "Expired";
                break;
              default:
                chipColor = Colors.grey;
                statusText = "Unknown";
            }

            return Chip(
              label: Text(
                statusText,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: chipColor,
              padding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            );
          }).toList(),
    );
  }
}
