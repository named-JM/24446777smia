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
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => LoginScreen()),
        //     ); // Go back to the previous page
        //   },
        // ),
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
              // Text(
              //   'This is the Page. You can add or remove inventory by scanning QR codes while offline. However, syncing your changes to the online database requires an internet connection. Likewise, updating the offline database with the latest data from the online database also requires Wi-Fi.\n Loging in offline might not work as expected. probably i can use a local database to store the user data and sync it when the user is online but it would take longer to implement. \n\n Possible the offline page limitation can only be used to scan qr codes and add or removes items inventory.',
              //   // 'This is the Offline Page. You can add or remove inventory by scanning QR codes while offline. However, syncing your changes to the online database requires an internet connection. Likewise, updating the offline database (Hive) with the latest data from the online database also requires Wi-Fi.\n \nTo test the offline functionality, you can scan a QR code to remove an item from the inventory. This will update the offline database (Hive) and refresh the UI with the updated data.',
              // ),
            ],

            // children: [
            //   // Generate QR Code Button
            //   Container(
            //     width: double.infinity, // Full width
            //     margin: const EdgeInsets.symmetric(
            //       horizontal: 16.0,
            //     ), // Add margin
            //     child: ElevatedButton(
            //       onPressed: () {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => OfflineHomePage(),
            //           ),
            //         );
            //       },
            //       style: ElevatedButton.styleFrom(
            //         foregroundColor: Colors.white,
            //         backgroundColor: Colors.lightGreen, // Green button color
            //         padding: const EdgeInsets.symmetric(vertical: 16.0),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(18.0),
            //         ),
            //         textStyle: const TextStyle(
            //           fontSize: 18,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       child: const Text('Offline Page'),
            //     ),
            //   ),
            //   const SizedBox(height: 20), // Add spacing between buttons
            //   // Create Category Button
            //   Container(
            //     width: double.infinity, // Full width
            //     margin: const EdgeInsets.symmetric(
            //       horizontal: 16.0,
            //     ), // Add margin
            //     child: ElevatedButton(
            //       onPressed: () {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => OfflineHomePage(),
            //           ),
            //         );
            //       },
            //       style: ElevatedButton.styleFrom(
            //         foregroundColor: Colors.white,
            //         backgroundColor: Colors.lightGreen, // Green button color
            //         padding: const EdgeInsets.symmetric(vertical: 16.0),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(18.0),
            //         ),
            //         textStyle: const TextStyle(
            //           fontSize: 18,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       child: const Text('Offline Page'),
            //     ),
            //   ),
            // ],
          ),
        ),
      ),
    );
  }
}
