import 'package:flutter/material.dart';
import 'package:qrqragain/Treatment_Page_Offline/offline_inventory_scanning.dart';

class OfflineHomePage extends StatefulWidget {
  const OfflineHomePage({super.key});

  @override
  State<OfflineHomePage> createState() => _OfflineHomePageState();
}

class _OfflineHomePageState extends State<OfflineHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('You are on Offline Mode'),
        backgroundColor: Colors.lightGreen, // Green app bar color
        centerTitle: true,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Center the content vertically
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Code Scanner Button
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
                        builder: (context) => OfflineScanningPage(),
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
                  child: const Text('Scan QR Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
