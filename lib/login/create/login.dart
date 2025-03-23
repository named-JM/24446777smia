import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Treatment_Page_Offline/treatment_page_offline.dart';
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/home.dart';
import 'package:qrqragain/login/create/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    syncInventory(); // Sync data on app start
    checkInternetAndSync();
  }

  Future<void> checkInternetAndSync() async {
    try {
      final response = await http.get(
        Uri.parse("$BASE_URL/check_connection.php"),
      );
      if (response.statusCode == 200) {
        syncOfflineUpdates(); // Sync if online
      }
    } catch (e) {
      print("No internet connection");
    }
  }

  Future<void> syncInventory() async {
    final box = await Hive.openBox('inventory');
    print("Stored Items: ${box.toMap()}");

    if (box.isNotEmpty) {
      print("Offline inventory already exists.");
      return;
    }

    final response = await http.get(Uri.parse("$BASE_URL/get_items.php"));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse.containsKey('items')) {
        // Ensure "items" exists
        List<dynamic> inventoryList = jsonResponse['items'];

        for (var item in inventoryList) {
          box.put(item['qr_code_data'], {
            'serial_no': item['serial_no'],
            'brand': item['brand'],
            'item_name': item['item_name'],
            'specification': item['specification'],
            'unit': item['unit'],
            'cost': item['cost'],
            'quantity': int.parse(item['quantity']), // Ensure it's an integer
            'mfg_date': item['mfg_date'],
            'exp_date': item['exp_date'],
            'category': item['category'],
            'qr_code_image': item['qr_code_image'],
          });
        }

        print("Inventory synced successfully!");
      } else {
        print("Error: 'items' key not found in API response.");
      }
    } else {
      print("Failed to fetch inventory from server.");
    }
  }

  Future<void> syncOfflineUpdates() async {
    final pendingUpdatesBox = await Hive.openBox('pending_updates');

    if (pendingUpdatesBox.isNotEmpty) {
      List<Map<String, dynamic>> updates = [];

      for (var item in pendingUpdatesBox.values) {
        updates.add({
          'qr_code_data': item['qr_code_data'],
          'quantity_removed': item['quantity_removed'],
        });
      }

      final response = await http.post(
        Uri.parse('$BASE_URL/sync_updates.php'),
        body: jsonEncode({'updates': updates}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          // Clear synced updates
          await pendingUpdatesBox.clear();
          print("Offline updates synced successfully!");
        } else {
          print("Sync failed: ${result['message']}");
        }
      } else {
        print("Failed to sync offline updates.");
      }
    }
  }

  Future<void> loginUser(BuildContext context) async {
    final String email = emailController.text;
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      }
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await offlineLogin(email, password);
      return;
    }

    try {
      final String apiUrl = "$BASE_URL/login.php";
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"email_address": email, "password": password},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('password', password);

          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Login successful!")));
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          showErrorMessage(data["message"] ?? "Login failed. Try again.");
        }
      } else {
        showErrorMessage("Server error. Please try again later.");
      }
    } catch (e) {
      showErrorMessage("An error occurred. Please try again.");
    }
  }

  Future<void> offlineLogin(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedEmail = prefs.getString('email');
    String? storedPassword = prefs.getString('password');

    if (storedEmail == email && storedPassword == password) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Offline login successful!")));
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TreatmentPageOffline()),
      );
    } else {
      showErrorMessage("Invalid credentials for offline login.");
    }
  }

  void showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Login'),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightGreen),
                  borderRadius: BorderRadius.circular(18),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightGreen),
                  borderRadius: BorderRadius.circular(18),
                ),
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightGreen),
                  borderRadius: BorderRadius.circular(18),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightGreen),
                  borderRadius: BorderRadius.circular(18),
                ),
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Set margin on both sides
              child: ElevatedButton(
                onPressed: () => loginUser(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.lightGreen, // Text color
                  padding: EdgeInsets.symmetric(vertical: 16.0), // Padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18), // Rounded corners
                  ),
                  textStyle: TextStyle(
                    fontSize: 18, // Font size
                    fontWeight: FontWeight.bold, // Font weight
                  ),
                ),
                child: const Text('Login'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Registration()),
                );
              },
              child: const Text('No Account? Register Here'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreatmentPageOffline(),
                  ),
                );
              },
              child: const Text('Offline Mode '),
            ),
          ],
        ),
      ),
    );
  }
}
