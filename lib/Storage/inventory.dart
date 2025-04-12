import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qrqragain/Offline_Page.dart';
import 'package:qrqragain/Storage/qr.dart';
import 'package:qrqragain/Storage/update.dart';
import 'package:qrqragain/Treatment_Area/remove_item.dart';
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/user_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

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

  final TextEditingController searchController = TextEditingController();
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
      // print("Final updates being sent: ${jsonEncode({'updates': updates})}");

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

      //  print("Final removals being sent: ${jsonEncode({'removals': removals})}");

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

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/get_categories.php'),
      );

      if (response.statusCode == 200) {
        List<dynamic> fetchedCategories =
            jsonDecode(response.body)["categories"];

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
    } catch (e) {
      print("Error fetching categories: $e");

      // Show a dialog to prompt the user to switch to offline mode
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Network Error"),
            content: Text(
              "Failed to fetch categories. Please check your internet connection or switch to offline mode.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text("Retry"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  // Navigate to offline mode
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OfflineHomePage()),
                  );
                },
                child: Text("Go Offline"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> fetchItems() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));
      //  print("Raw Response: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          //   print("Parsed JSON: $jsonResponse"); // Debugging

          if (jsonResponse is Map<String, dynamic> &&
              jsonResponse.containsKey('items')) {
            final itemsData = jsonResponse['items'];

            if (itemsData is List) {
              if (mounted) {
                setState(() {
                  items = itemsData;
                  filteredItems = items;
                  searchQuery = ''; // Reset search query
                  selectedCategory =
                      'All Categories'; // Reset category dropdown
                  searchController.clear(); // Clear the search bar input
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
    } catch (e) {
      print("Error fetching items: $e");

      // Show a dialog to prompt the user to switch to offline mode
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Network Error"),
            content: Text(
              "Failed to connect to the server. Please check your internet connection or switch to offline mode.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text("Retry"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  // Navigate to offline mode
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OfflineHomePage()),
                  );
                },
                child: Text("Go Offline"),
              ),
            ],
          );
        },
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
                              expDate: item['exp_date'] ?? '',
                              //  mfgDate: item['mfg_date'],
                              qrCodeImage: item['qr_code_image'],
                              fromQRScanner:
                                  true, // Indicate navigation from QR Scanner
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

  Future<void> downloadExcel(BuildContext context, List<dynamic> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No data available for Excel download.")),
      );
      return;
    }

    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Storage permission denied! Please allow it in settings.",
          ),
        ),
      );
      return;
    }

    try {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Inventory';

      final Set<String> allUsers = {};
      final Set<String> allDates = {};

      for (var item in items) {
        final logs = item['removal_logs'] as List<dynamic>? ?? [];
        for (var log in logs) {
          final user = log['user_name'] ?? 'Unknown User';
          final date = log['removal_date'] ?? '';
          allUsers.add(user);
          allDates.add(date);
        }
      }

      final userList = allUsers.toList()..sort();
      final dateList = allDates.toList()..sort();
      // Calculate the range of removal dates
      DateTime? minDate;
      DateTime? maxDate;

      for (var item in items) {
        final removalLogs = item['removal_logs'] as List<dynamic>? ?? [];
        for (var log in removalLogs) {
          final dateStr = log['removal_date'];
          if (dateStr != null && dateStr.isNotEmpty) {
            final date = DateTime.tryParse(dateStr);
            if (date != null) {
              if (minDate == null || date.isBefore(minDate)) {
                minDate = date;
              }
              if (maxDate == null || date.isAfter(maxDate)) {
                maxDate = date;
              }
            }
          }
        }
      }

      // Format the date range
      String dateRange = '';
      if (minDate != null && maxDate != null) {
        if (minDate == maxDate) {
          dateRange = DateFormat.yMMMMd().format(minDate); // Single date
        } else {
          dateRange =
              "${DateFormat.yMMMMd().format(minDate)} - ${DateFormat.yMMMMd().format(maxDate)}"; // Date range
        }
      } else {
        dateRange = "No removal dates available"; // Fallback if no dates exist
      }

      // Title rows
      final List<String> titles = [
        "Provincial Government of Bulacan",
        "Governor's Office Extension Warehouse",
        "City of Malolos, Bulacan",
        "DSBTO PGB PHARMACYSTOCK INVENTORY",
        "Inventory Report of Drugs and Medicines",
        // Use the calculated date range
        "Date: $dateRange",
      ];

      final endCol = 4 + userList.length * dateList.length;
      final endColLetter = _getExcelColumnName(endCol);

      int titleRow = 1;
      for (final text in titles) {
        final range = sheet.getRangeByName(
          'A$titleRow:${endColLetter}$titleRow',
        );
        range.merge();
        range.setText(text);
        range.cellStyle.bold = true;
        range.cellStyle.fontSize = 14;
        range.cellStyle.hAlign = xlsio.HAlignType.center;
        titleRow++;
      }

      // Header Rows
      List<String> headerRow1 = [
        'Item Name', // Concatenated column
        'Aizen Inventory', // Second column
      ];
      List<String> headerRow2 = ['', ''];

      // Add user-related headers dynamically
      for (var user in userList) {
        for (var date in dateList) {
          headerRow1.add("$user");
          headerRow2.add(date);
        }
      }

      // Add Total Inventory and Status columns
      headerRow1.add('Total Inventory');
      headerRow1.add('Status');
      headerRow2.add('');
      headerRow2.add('');

      // Import headers into the sheet
      sheet.importList(headerRow1, titleRow, 1, false);
      sheet.importList(headerRow2, titleRow + 1, 1, false);

      int currentRow = titleRow + 2;

      for (var item in items) {
        final removalLogs = item['removal_logs'] as List<dynamic>? ?? [];
        final Map<String, Map<String, int>> userDateQty = {};

        for (var log in removalLogs) {
          final user = log['user_name'] ?? 'Unknown User';
          final date = log['removal_date'] ?? '';
          final qty = log['quantity_removed'] ?? 0;
          final intQty = qty is int ? qty : int.tryParse(qty.toString()) ?? 0;

          userDateQty[user] ??= {};
          userDateQty[user]![date] = (userDateQty[user]![date] ?? 0) + intQty;
        }

        // Build the row
        List<String> row = [
          '${item['item_name'] ?? ''} (${item['unit'] ?? ''})', // Concatenated Item Name + Unit
          item['origin_quantity'].toString(), // Aizen Inventory
        ];

        // Add user-related data dynamically
        for (var user in userList) {
          for (var date in dateList) {
            final qty = userDateQty[user]?[date] ?? 0;
            row.add(qty == 0 ? '' : qty.toString());
          }
        }

        // Add Total Inventory and Status
        row.add(item['quantity'].toString()); // Total Inventory
        row.add(item['exp_date'] ?? ''); // Status

        // Import the row into the sheet
        sheet.importList(row, currentRow, 1, false);
        currentRow++;
      }

      // Add Footer with Date of Print
      final footerRow = currentRow + 2; // Leave one blank row after the table
      final footerRange = sheet.getRangeByName('A$footerRow'); // Only column A
      footerRange.setText("Date of Print");
      footerRange.cellStyle.bold = true;
      footerRange.cellStyle.fontSize = 12;
      footerRange.cellStyle.hAlign = xlsio.HAlignType.left; // Align to the left

      // Add merged row for the actual date of print
      final footerValueRow = footerRow + 1; // Row below "Date of Print"
      final footerValueRange = sheet.getRangeByName(
        'A$footerValueRow:B$footerValueRow',
      ); // Merge columns A and B
      footerValueRange.merge();
      footerValueRange.setText(
        DateFormat.yMMMMd().format(DateTime.now()),
      ); // Set the current date
      footerValueRange.cellStyle.bold = true;
      footerValueRange.cellStyle.fontSize = 12;
      footerValueRange.cellStyle.hAlign =
          xlsio.HAlignType.center; // Align to the center

      // // Add Signature Section
      // final signatureRow =
      //     footerValueRow + 4; // 4 rows below the "Date of Print"
      // final signatureLabelRange = sheet.getRangeByName(
      //   'A$signatureRow',
      // ); // Only column A

      // Add Signature Section
      final signatureRow =
          footerValueRow + 4; // 4 rows below the "Date of Print"

      // First Signature (Timothy Brian A. Hernandez)
      final signatureValueRange1 = sheet.getRangeByName(
        'A$signatureRow:B$signatureRow',
      ); // Merge columns A and B
      signatureValueRange1.merge();
      signatureValueRange1.setText("Timothy Brian A. Hernandez");
      signatureValueRange1.cellStyle.bold = true;
      signatureValueRange1.cellStyle.fontSize = 12;
      signatureValueRange1.cellStyle.hAlign =
          xlsio.HAlignType.center; // Align to the center

      // Second Signature (Iceacris A. Garcia)
      final signatureValueRange2 = sheet.getRangeByName(
        'C$signatureRow:D$signatureRow',
      ); // Merge columns C and D
      signatureValueRange2.merge();
      signatureValueRange2.setText("Iceacris A. Garcia");
      signatureValueRange2.cellStyle.bold = true;
      signatureValueRange2.cellStyle.fontSize = 12;
      signatureValueRange2.cellStyle.hAlign =
          xlsio.HAlignType.center; // Align to the center

      // Add Position for First Signature
      final positionRow1 = signatureRow + 1; // Row below the first signature
      final positionRange1 = sheet.getRangeByName(
        'A$positionRow1:B$positionRow1',
      ); // Merge columns A and B
      positionRange1.merge();
      positionRange1.setText("Pharmacist II");
      positionRange1.cellStyle.bold = true;
      positionRange1.cellStyle.fontSize = 12;
      positionRange1.cellStyle.hAlign =
          xlsio.HAlignType.center; // Align to the center

      // Add Position for Second Signature
      final positionRow2 = signatureRow + 1; // Row below the second signature
      final positionRange2 = sheet.getRangeByName(
        'C$positionRow2:D$positionRow2',
      ); // Merge columns C and D
      positionRange2.merge();
      positionRange2.setText("Administrative Officer");
      positionRange2.cellStyle.bold = true;
      positionRange2.cellStyle.fontSize = 12;
      positionRange2.cellStyle.hAlign =
          xlsio.HAlignType.center; // Align to the center
      // Auto-fit and style
      for (int i = 1; i <= endCol; i++) {
        sheet.autoFitColumn(i);
      }

      final xlsio.Style borderStyle = workbook.styles.add('BorderStyle');
      borderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      final fullRange = sheet.getRangeByName(
        'A${titleRow}:${endColLetter}$currentRow',
      );
      fullRange.cellStyle = borderStyle;

      // Save
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final downloadsDir = Directory('/storage/emulated/0/Download');
      final filePath = '${downloadsDir.path}/inventory_data.xlsx';
      final file = File(filePath);
      file.createSync(recursive: true);
      file.writeAsBytesSync(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Excel saved to Downloads folder.")),
      );

      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error saving or opening Excel: $e")),
      );
      print("Error: $e");
    }
  }

  // Helper to convert column index to Excel letter (e.g. 1 => A, 27 => AA)
  String _getExcelColumnName(int index) {
    String colName = '';
    while (index > 0) {
      int mod = (index - 1) % 26;
      colName = String.fromCharCode(65 + mod) + colName;
      index = (index - mod - 1) ~/ 26;
    }
    return colName;
  }

  Future<void> downloadCSV(BuildContext context, List<dynamic> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No data available for CSV download.")),
      );
      return;
    }

    // Request Storage Permission
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      try {
        // Get the "Downloads" directory
        Directory downloadsDirectory = Directory(
          '/storage/emulated/0/Download',
        );

        if (!downloadsDirectory.existsSync()) {
          downloadsDirectory.createSync(recursive: true);
        }

        // Save the file in the Downloads folder
        String filePath = "${downloadsDirectory.path}/inventory_data.csv";
        File file = File(filePath);

        await file.writeAsString(
          const ListToCsvConverter().convert(() {
            final Set<String> allUsers = {};
            final Set<String> allDates = {};

            // Step 1: Collect unique users and dates
            for (var item in items) {
              final logs = item['removal_logs'] as List<dynamic>? ?? [];
              for (var log in logs) {
                final user = log['user_name'] ?? 'Unknown User';
                final date = log['removal_date'] ?? '';
                allUsers.add(user);
                allDates.add(date);
              }
            }

            final userList = allUsers.toList()..sort();
            final dateList = allDates.toList()..sort();

            // Step 2: Build two header rows
            final List<String> headerRow1 = [
              "Item Name",
              "Unit",
              "Origin Quantity",
              "Exp Date",
            ];

            final List<String> headerRow2 = List.filled(
              headerRow1.length,
              "",
              growable: true,
            );

            for (var user in userList) {
              for (var date in dateList) {
                headerRow1.add("Removed by $user");
                headerRow2.add(date);
              }
            }
            headerRow1.add("Total Quantity Removed");
            headerRow2.add(""); // for total

            // Step 3: Build the rows
            final List<List<String>> csvRows = [headerRow1, headerRow2];

            for (var item in items) {
              final removalLogs = item['removal_logs'] as List<dynamic>? ?? [];

              // Create a nested map: user -> date -> qty
              final Map<String, Map<String, int>> userDateQty = {};
              for (var log in removalLogs) {
                final user = log['user_name'] ?? 'Unknown User';
                final date = log['removal_date'] ?? '';
                final qty = log['quantity_removed'] ?? 0;
                final intQty =
                    qty is int ? qty : int.tryParse(qty.toString()) ?? 0;

                userDateQty[user] ??= {};
                userDateQty[user]![date] =
                    (userDateQty[user]![date] ?? 0) + intQty;
              }

              int totalRemoved = 0;

              final row = [
                item['item_name'] ?? '',
                item['unit'] ?? '',
                item['origin_quantity'].toString(),
                item['exp_date'] ?? '',
              ];

              for (var user in userList) {
                for (var date in dateList) {
                  final qty = userDateQty[user]?[date] ?? 0;
                  totalRemoved += qty;
                  row.add(qty == 0 ? '' : qty.toString());
                }
              }

              row.add(totalRemoved.toString());

              csvRows.add(row.map((e) => e.toString()).toList());
            }

            return csvRows;
          }()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ CSV saved to Downloads folder.")),
        );

        print("CSV File saved at: $filePath");

        // Open the file
        final result = await OpenFile.open(filePath);
        print("OpenFile result: ${result.message}");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error saving or opening CSV: $e")),
        );
        print("Error saving or opening CSV: $e");
      }
    } else if (status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Storage Permission Required"),
              content: Text(
                "Please allow storage permission in settings to save and open CSV files.",
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Storage permission denied! Please allow it in settings.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isAdmin =
        userProvider.role == 'admin'; // Check if the user is an admin

    return Scaffold(
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
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: filterItems,
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.green.shade900,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
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
                          if (isAdmin || userProvider.role == 'user')
                            IconButton(
                              onPressed: openQRScanner,
                              icon: Icon(
                                Icons.qr_code_scanner,
                                size: 30,
                                color: Colors.green[900],
                              ),
                              tooltip: "Scan QR Code",
                            ),
                          if (isAdmin)
                            IconButton(
                              onPressed: () {
                                downloadExcel(context, filteredItems);
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
                    SizedBox(height: 2),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchItems,
                        child: ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];

                            return Container(
                              padding: EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children:
                                              (item['item_name'] as String)
                                                  .split(' ')
                                                  .map(
                                                    (word) => FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        word,
                                                        style: TextStyle(
                                                          fontSize: 21,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),

                                        SizedBox(height: 5),
                                        Text(
                                          'Brand: ${item['brand']} \n'
                                          'Category: ${item['category']} \n'
                                          'Specification: ${item['specification']} \n'
                                          'Unit: ${item['unit']} \n'
                                          'Cost: ${item['cost']} \n'
                                          'Quantity: ${item['quantity']} \n'
                                          'Exp Date: ${item['exp_date'] ?? 'N/A'}',
                                        ),
                                        SizedBox(height: 8),
                                        _buildStatusChips(item['statuses']),
                                      ],
                                    ),
                                  ),
                                  if (isAdmin ||
                                      userProvider.role ==
                                          'user') // Show Edit button only for admin
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
                                                  qrCodeImage:
                                                      item['qr_code_image'],
                                                  expDate:
                                                      item['exp_date'] ?? '',
                                                  fromQRScanner: false,
                                                ),
                                          ),
                                        ).then((_) {
                                          syncOfflineUpdates();
                                          syncOnlineToOffline();
                                        });
                                      },
                                    ),
                                  if (item['qr_code_image'] != null &&
                                      item['qr_code_image'].startsWith('http'))
                                    Container(
                                      width: 150,
                                      height: 150,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          item['qr_code_image'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.qr_code,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  SizedBox(width: 5),
                                ],
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
