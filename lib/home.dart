import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Generate_QR_Code/qr_home.dart';
import 'package:qrqragain/Storage/inventory.dart';
import 'package:qrqragain/Treatment_Area/treatment_page.dart';
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/login/create/login.dart';
import 'package:qrqragain/offline_db.dart';

class SyncService {
  static Future<void> syncPendingUpdates() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none)
      return; // Skip if offline

    List<Map<String, dynamic>> updates =
        await LocalDatabase.getPendingUpdates();
    for (int i = 0; i < updates.length; i++) {
      var update = updates[i];
      var response = await http.post(
        Uri.parse('$BASE_URL/sync.php'),
        body: jsonEncode(update),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        LocalDatabase.deletePendingUpdate(i); // Remove after successful sync
      }
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hasLowStock = false;
  List<dynamic> lowStockItems = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Ensure first API call after UI build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLowStock();
    });

    _startAutoCheck(); // Start auto-refresh
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop timer when the widget is disposed
    super.dispose();
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      checkLowStock();
    });
  }

  Future<void> checkLowStock() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Show a message if offline
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No internet connection.')));
      return;
    }

    try {
      final response = await http.get(Uri.parse("$BASE_URL/notif.php"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: ${response.body}");

        bool newHasLowStock = data['low_stock'] ?? false;
        List<dynamic> newLowStockItems = List.from(
          data['low_stock_items'] ?? [],
        );

        // Only update state if there are changes to avoid unnecessary rebuilds
        if (mounted &&
            (newHasLowStock != hasLowStock ||
                newLowStockItems.length != lowStockItems.length)) {
          setState(() {
            hasLowStock = newHasLowStock;
            lowStockItems = newLowStockItems;
          });
        }
      } else {
        print("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching low stock data: $e");
    }
  }

  void showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.3, // 30% of screen height
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                hasLowStock ? "Low Stock Alert!" : "No Low Stock Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (hasLowStock)
                Expanded(
                  child: ListView.builder(
                    itemCount: lowStockItems.length,
                    itemBuilder: (context, index) {
                      final item = lowStockItems[index];
                      return ListTile(
                        leading: Icon(Icons.warning, color: Colors.red),
                        title: Text(item['item_name']),
                        subtitle: Text("Remaining: ${item['quantity']}"),
                      );
                    },
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Stack(
          children: [
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications, size: 30),
                  if (hasLowStock)
                    Positioned(
                      right: 3,
                      top: 3,
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
              onPressed: () async {
                showNotificationSheet();
              },
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Set margin on both sides
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InventoryPage()),
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
                    MaterialPageRoute(builder: (context) => TreatmentPage()),
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
