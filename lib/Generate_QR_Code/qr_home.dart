import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrqragain/Generate_QR_Code/create_category.dart';
import 'package:qrqragain/Generate_QR_Code/create_qr.dart';
import 'package:qrqragain/Generate_QR_Code/user_management.dart';
import 'package:qrqragain/user_provider.dart';

class QrHome extends StatefulWidget {
  const QrHome({super.key});

  @override
  State<QrHome> createState() => _QrHomeState();
}

class _QrHomeState extends State<QrHome> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isAdmin =
        userProvider.role == 'admin'; // Check if the user is an admin

    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Center the content vertically
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAdmin)
                // Generate QR Code Button
                Container(
                  width: double.infinity, // Full width
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ), // Add margin
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRGeneratorPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.lightGreen, // Green button color
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Generate QR Code'),
                  ),
                ),
              const SizedBox(height: 20), // Add spacing between buttons
              // Create Category Button
              Container(
                width: double.infinity, // Full width
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ), // Add margin
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CategoryPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightGreen, // Green button color
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Create Category'),
                ),
              ),
              const SizedBox(height: 20), // Add spacing between buttons
              if (isAdmin)
                // Generate QR Code Button
                Container(
                  width: double.infinity, // Full width
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ), // Add margin
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserManagement(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.lightGreen, // Green button color
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('User Management'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
