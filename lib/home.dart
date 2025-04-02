import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Generate_QR_Code/qr_home.dart';
import 'package:qrqragain/Storage/inventory.dart';
import 'package:qrqragain/Treatment_Area/treatment_page.dart';
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/login/create/login.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hasLowStock = false;
  List<dynamic> lowStockItems = [];
  Timer? _timer;
  List<String> categories = [];
  String? selectedCategory;
  bool hasNewNotif = false;
  List<dynamic> previousLowStockItems = [];
  void _startAutoCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      print("Auto-checking for low stock...");
      checkLowStock();
    });
  }

  @override
  void initState() {
    super.initState();
    _startAutoCheck(); // Start auto-refresh

    checkLowStock(); // Initial check for low stock
    print("New Notif Status: $hasNewNotif");
    // Ensure first API call after UI build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLowStock();
    });

    syncOfflineUpdates();
    syncOfflineRemovals(); // Sync offline removals
    fetchCategories(); // Fetch categories from the server
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger low stock check when navigating back to this page
    checkLowStock();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop timer when the widget is disposed
    super.dispose();
  }

  bool _hasNewNotifications(
    List<dynamic> currentItems,
    List<dynamic> previousItems,
  ) {
    // Convert both lists to sets of unique batch identifiers
    final currentSet =
        currentItems.map((item) {
          return "${item['item_name']}_${item['exp_date']}_${item['statuses']}";
        }).toSet();

    final previousSet =
        previousItems.map((item) {
          return "${item['item_name']}_${item['exp_date']}_${item['statuses']}";
        }).toSet();

    // Check if there are any new batches in the current set that are not in the previous set
    return !currentSet.difference(previousSet).isEmpty;
  }

  Future<void> fetchCategories() async {
    final categoryBox = await Hive.openBox('categories');

    final response = await http.get(Uri.parse('$BASE_URL/get_categories.php'));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      List<String> fetchedCategories =
          (result['categories'] as List)
              .map<String>((cat) => cat['name'].toString())
              .toSet()
              .toList();

      setState(() {
        categories = fetchedCategories;

        if (selectedCategory == null ||
            !categories.contains(selectedCategory)) {
          selectedCategory = categories.isNotEmpty ? categories[0] : null;
        }
      });
      print(fetchedCategories);
      // Save categories offline
      await categoryBox.put('categories', fetchedCategories);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch categories')));
    }
  }

  //pUNTAGNGINANGBBUAHYTOAYOKONAHASDAOYOKOAAYOKONA
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
      //print("Final updates being sent: ${jsonEncode({'updates': updates})}");

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

  Future<void> checkLowStock() async {
    print("Checking for low stock notifications...");
    try {
      final response = await http.get(Uri.parse("$BASE_URL/notif.php"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the API response for debugging
        print("API Response: $data");

        // Filter out items where status is "normal"
        List<dynamic> newItems =
            (data['items'] ?? [])
                .where(
                  (item) =>
                      item['statuses'] != null && item['statuses'].isNotEmpty,
                )
                .toList();

        print("Filtered Low Stock Items: $newItems");

        if (mounted) {
          setState(() {
            lowStockItems = newItems;
            hasLowStock = newItems.isNotEmpty;

            // Compare the new list with the previous list to detect changes
            bool hasNewItems = _hasNewNotifications(
              newItems,
              previousLowStockItems,
            );

            if (hasNewItems) {
              print("New notifications detected!");
              hasNewNotif = true; // Set the red dot flag
            } else {
              print("No new notifications.");
            }

            // Update the previous list for the next comparison
            previousLowStockItems = List.from(newItems);
          });
        }
        print("Low Stock Items: $lowStockItems");
        print("Has New Notifications: $hasNewNotif");
      } else {
        print("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching low stock data: $e");
    }
  }

  void showNotificationSheet() {
    setState(() {
      hasNewNotif = false; // Clear the red dot when user views notifications
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                hasLowStock ? "Low Stock / Expiry Alert!" : "All items are OK",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 25),
              if (hasLowStock)
                Expanded(
                  child: ListView(
                    children:
                        lowStockItems.expand((item) {
                          List<Widget> notifications = [];

                          for (var status in item['statuses']) {
                            notifications.add(
                              _buildNotificationTile(
                                itemName: item['item_name'],
                                quantity: item['quantity'],
                                expiry: item['exp_date'],
                                status: status,
                              ),
                            );
                          }

                          return notifications;
                        }).toList(),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("All items are sufficiently stocked."),
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Dismiss"),
                        ),
                      ],
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hasNewNotif = false; // Clear the red dot
                    previousLowStockItems = List.from(
                      lowStockItems,
                    ); // Update previous list
                  });
                  Navigator.pop(context); // Close the notification sheet
                },
                child: Text("Mark as Read"),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Updated Helper Function for Multiple Statuses
  Widget _buildNotificationTile({
    required String itemName,
    required int quantity,
    required String? expiry,
    required String status,
  }) {
    IconData icon;
    Color iconColor;
    Color textColor;
    String statusText;

    switch (status) {
      case "low_stock":
        icon = Icons.warning;
        iconColor = Colors.red[800]!;
        textColor = Colors.red[900]!;
        statusText = "Low Stock (Critical)";
        break;
      case "warning":
        icon = Icons.event;
        iconColor = Colors.yellow[800]!;
        textColor = Colors.yellow[900]!;
        statusText = "3 months before expired";
        break;
      case "near_expiry":
        icon = Icons.event_available;
        iconColor = Colors.orange[800]!;
        textColor = Colors.orange[900]!;
        statusText = "Nearly Expired";
        break;
      case "expired":
        icon = Icons.event_busy;
        iconColor = Colors.red[800]!;
        textColor = Colors.red[900]!;
        statusText = "Expired";
        break;
      default:
        return SizedBox(); // Ignore "normal" status
    }

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(
          itemName,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Remaining: $quantity | Expiry: ${expiry ?? 'N/A'}',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AIMS",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Stack(
          children: [
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications, size: 30), // Notification Icon
                  if (hasNewNotif) // Show red dot only when there's a new notification
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: showNotificationSheet,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 30),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 60),
                Image.asset('assets/bulacan_logo.png', width: 250, height: 250),
                SizedBox(height: 50),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ), // Set margin on both sides

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InventoryPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.lightGreen,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Storage'),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ), // Set margin on both sides
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TreatmentPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.lightGreen,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Treatment Page'),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ), // Set margin on both sides
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QrHome()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.lightGreen,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Generate QR Code'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
