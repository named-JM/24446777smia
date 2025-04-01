import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:qrqragain/Storage/qr.dart';
import 'package:qrqragain/Storage/update.dart';
import 'package:qrqragain/Treatment_Area/remove_item.dart';
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
    syncOfflineUpdates();
    syncOnlineToOffline();
    //clearPendingUpdates();
  }

  Future<void> clearPendingUpdates() async {
    try {
      final pendingUpdatesBox = await Hive.openBox('pending_updates');
      await pendingUpdatesBox.clear(); // Clear all pending updates
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pending updates cleared successfully.')),
      );
      print("Pending updates cleared successfully.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear pending updates: $e')),
      );
      print("Failed to clear pending updates: $e");
    }
  }

  /// Sync offline updates to MySQL
  /// and update Hive database
  /// This function will be called when the app is online
  /// and there are pending updates in the Hive database
  /// It will send the updates to the server and update the Hive database
  /// with the new data
  /// It will also clear the pending updates from the Hive database
  /// and refresh the UI
  Future<void> syncOfflineUpdates() async {
    final pendingUpdatesBox = await Hive.openBox('pending_updates');
    final inventoryBox = await Hive.openBox('inventory');

    if (pendingUpdatesBox.isNotEmpty) {
      Map<String, Map<String, dynamic>> batchedUpdates = {};

      // Group updates by serial_no, qr_code_data, and exp_date
      for (var item in pendingUpdatesBox.values) {
        String key =
            "${item['serial_no']}_${item['qr_code_data']}_${item['exp_date']}";

        if (batchedUpdates.containsKey(key)) {
          batchedUpdates[key]?['quantity'] += item['quantity_added'];
        } else {
          batchedUpdates[key] = {
            'serial_no': item['serial_no'],
            'qr_code_data': item['qr_code_data'],
            'quantity': item['quantity_added'],
            'exp_date': item['exp_date'],
            'brand': item['brand'],
            'category': item['category'],
            'item_name': item['item_name'], // Add missing fields
            'specification': item['specification'],
            'unit': item['unit'],
            'cost': item['cost'],
            'qr_code_image': item['qr_code_image'],
          };
        }
      }

      List<Map<String, dynamic>> updates = batchedUpdates.values.toList();
      print("Final updates being sent: ${jsonEncode({'updates': updates})}");

      try {
        final response = await http.post(
          Uri.parse('$BASE_URL/sync_updates.php'),
          body: jsonEncode({'updates': updates}),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);

          if (result['success']) {
            for (var update in updates) {
              int index = inventoryBox.values.toList().indexWhere(
                (item) =>
                    item['qr_code_data'] == update['qr_code_data'] &&
                    item['exp_date'] == update['exp_date'],
              );

              if (index != -1) {
                var item = inventoryBox.getAt(index);
                item['quantity'] =
                    (item['quantity'] ?? 0) + (update['quantity_added'] ?? 0);
                item['exp_date'] = update['exp_date'];
                item['brand'] = update['brand'];
                item['category'] = update['category'];

                inventoryBox.putAt(index, item);
              }
            }

            await pendingUpdatesBox.clear();
            setState(() {});
            print("Offline updates synced successfully!");
          } else {
            print("Sync failed: ${result['message']}");
          }
        } else {
          print(
            "Failed to sync offline updates. Server response: ${response.body}",
          );
        }
      } catch (e) {
        print("Sync error: $e");
      }
    }
  }

  Future<void> syncOfflineRemovals() async {
    final pendingRemovalsBox = await Hive.openBox('pending_removals');
    final inventoryBox = await Hive.openBox('inventory');

    if (pendingRemovalsBox.isNotEmpty) {
      List<Map<String, dynamic>> removals =
          pendingRemovalsBox.values
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      print("Final removals being sent: ${jsonEncode({'removals': removals})}");

      try {
        final response = await http.post(
          Uri.parse('$BASE_URL/sync_removals.php'),
          body: jsonEncode({'removals': removals}),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);

          if (result['success']) {
            for (var removal in removals) {
              int index = inventoryBox.values.toList().indexWhere(
                (item) =>
                    item['serial_no'] == removal['serial_no'] &&
                    item['exp_date'] == removal['exp_date'],
              );

              if (index != -1) {
                var item = inventoryBox.getAt(index);
                int newQuantity =
                    (item['quantity'] ?? 0) -
                    (removal['quantity_removed'] ?? 0);

                if (newQuantity > 0) {
                  item['quantity'] = newQuantity;
                  inventoryBox.putAt(index, item);
                } else {
                  inventoryBox.deleteAt(
                    index,
                  ); // Remove item if quantity is zero
                }
              }
            }

            await pendingRemovalsBox.clear();
            setState(() {});
            print("Offline removals synced successfully!");
          } else {
            print("Sync failed: ${result['message']}");
          }
        } else {
          print(
            "Failed to sync offline removals. Server response: ${response.body}",
          );
        }
      } catch (e) {
        print("Sync error: $e");
      }
    }
  }

  /// Sync the latest MySQL data to Hive
  /// This function will be called when the app is online
  /// and there are no pending updates in the Hive database
  /// It will fetch the latest data from the server
  /// and update the Hive database with the new data
  /// It will also clear the old data from the Hive database
  /// and refresh the UI
  Future<void> syncOnlineToOffline() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));

      if (response.statusCode == 200) {
        final List<dynamic> onlineItems = jsonDecode(response.body)['items'];
        final box = await Hive.openBox('inventory');

        // **Batch Update: Replace Entire Inventory**
        await box.clear(); // Clear outdated Hive inventory
        await box.addAll(onlineItems); // Add all new items at once

        // **Force UI Refresh**
        setState(() {});

        print("Sync successful: MySQL data updated in Hive!");
      } else {
        print("Failed to fetch online data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error syncing data: $e");
    }
  }

  /// latest
  // Future<void> syncOnlineToOffline() async {
  //   try {
  //     final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));

  //     if (response.statusCode == 200) {
  //       final List<dynamic> onlineItems = jsonDecode(response.body)['items'];
  //       final box = await Hive.openBox('inventory');

  //       for (var item in onlineItems) {
  //         String qrCode = item['qr_code_data'];
  //         int existingIndex = box.values.toList().indexWhere(
  //           (existingItem) => existingItem['qr_code_data'] == qrCode,
  //         );

  //         if (existingIndex != -1) {
  //           box.putAt(existingIndex, item);
  //         } else {
  //           box.add(item);
  //         }
  //       }

  //       // **Force UI Refresh**
  //       setState(() {});

  //       print("Sync successful: MySQL data updated in Hive!");
  //     } else {
  //       print("Failed to fetch online data: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("Error syncing data: $e");
  //   }
  // }

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
    print("Raw Response: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        print("Parsed JSON: $jsonResponse"); // Debugging

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('items')) {
          final itemsData = jsonResponse['items'];

          if (itemsData is List) {
            if (mounted) {
              setState(() {
                items = itemsData;
                filteredItems = items;
                isLoading = false; // Set loading to false
              });
            }
          } else {
            print("Error: 'items' is not a list.");
          }
        } else {
          print("Error: 'items' key not found in the response.");
        }
      } catch (e) {
        print("Error parsing JSON: $e");
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
    // Scan the QR code first
    String? scannedQR = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage(action: 'scan')),
    );

    if (scannedQR != null) {
      // Find the item in the inventory using the scanned QR code
      final item = items.firstWhere(
        (item) => item['qr_code_data'] == scannedQR,
        orElse: () => null, // Return null if not found
      );

      if (item != null) {
        // Show a dialog to choose between Add or Remove
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Select Action'),
              content: const Text('Do you want to add or remove items?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => UpdateItemPage(
                              serialNo: item['serial_no'],
                              qrCodeData: item['qr_code_data'],
                              itemName: item['item_name'],
                              specification: item['specification'],
                              unit: item['unit'],
                              cost: item['cost'].toString(),
                              //  mfgDate: item['mfg_date'],
                              qrCodeImage: item['qr_code_image'],
                            ),
                      ),
                    ).then((_) {
                      // Refresh data after returning from the update page
                      syncOfflineUpdates();
                      syncOnlineToOffline();
                    });
                  },
                  child: const Text('Add Items'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                RemoveQuantityPage(qrCodeData: scannedQR),
                      ),
                    ).then((_) {
                      // Refresh data after returning from the remove page
                      syncOfflineUpdates();
                      syncOnlineToOffline();
                    });
                  },
                  child: const Text('Remove Items'),
                ),
              ],
            );
          },
        );
      } else {
        // Show an error if the scanned QR code does not match any item
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Item not found in inventory')));
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

    // **1️⃣ Request Storage Permission Properly**
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      try {
        // **2️⃣ Get the "Downloads" directory**
        Directory downloadsDirectory = Directory(
          '/storage/emulated/0/Download',
        );

        if (!downloadsDirectory.existsSync()) {
          downloadsDirectory.createSync(recursive: true);
        }

        // **3️⃣ Save the file in the Downloads folder**
        String filePath = "${downloadsDirectory.path}/inventory_data.csv";
        File file = File(filePath);
        await file.writeAsString(
          const ListToCsvConverter().convert([
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
            ...items.map(
              (item) => [
                item['item_name'],
                item['brand'],
                item['category'],
                item['specification'],
                item['unit'],
                item['cost'],
                item['quantity'],
                item['exp_date'] ?? 'N/A',
              ],
            ),
          ]),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ CSV saved to Downloads folder.")),
        );

        print("CSV File saved at: $filePath");
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error saving CSV: $e")));
        print("Error saving CSV: $e");
      }
    } else if (status.isPermanentlyDenied) {
      // **4️⃣ Show Dialog Only if User Permanently Denied**
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Storage Permission Required"),
              content: Text(
                "Please allow storage permission in settings to save CSV files.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings(); // Open settings for permissions
                    Navigator.pop(context);
                  },
                  child: Text("Open Settings"),
                ),
              ],
            ),
      );
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
        title: Center(
          child: Row(
            children: [
              Icon(Icons.inventory),
              SizedBox(width: 10),
              Text('Storage Area'),
            ],
          ),
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
                          SizedBox(width: 10),

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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Edit Button
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: "Edit Item",
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => UpdateItemPage(
                                                  serialNo: item['serial_no'],
                                                  qrCodeData:
                                                      item['qr_code_data'],
                                                  itemName: item['item_name'],
                                                  specification:
                                                      item['specification'],
                                                  unit: item['unit'],
                                                  cost: item['cost'].toString(),
                                                  //   mfgDate: item['mfg_date'],
                                                  qrCodeImage:
                                                      item['qr_code_image'],
                                                ),
                                          ),
                                        ).then((_) {
                                          // Refresh data after returning from the update page
                                          syncOfflineUpdates();
                                          syncOnlineToOffline();
                                        });
                                      },
                                    ),
                                    // QR Code Image or Icon
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
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                        )
                                        : Icon(
                                          Icons.qr_code,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                  ],
                                ),
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
