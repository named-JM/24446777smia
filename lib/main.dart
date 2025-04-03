import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qrqragain/offline_page.dart';
import 'package:qrqragain/splash_page.dart';

import 'user_provider.dart'; // Import your UserProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await Hive.openBox('inventory'); // Open the local database
  } catch (e, stacktrace) {
    print("Hive Initialization Error: $e");
    print(stacktrace);
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MyApp(),
    ),
    // DevicePreview(
    //   enabled: false, // Enable device preview
    //   builder: (context) => MyApp(),
    // ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Connectivity _connectivity = Connectivity();
  bool isOnline = true; // Default assumption: online

  @override
  void initState() {
    super.initState();
    checkConnectivity();

    try {
      _connectivity.onConnectivityChanged.listen((results) {
        bool currentlyOnline =
            results.isNotEmpty && results.first != ConnectivityResult.none;

        if (isOnline != currentlyOnline) {
          setState(() {
            isOnline = currentlyOnline;
          });
        }
      });
    } catch (e, stacktrace) {
      print("Connectivity Listener Error: $e");
      print(stacktrace);
    }
  }

  Future<void> checkConnectivity() async {
    try {
      var results = await _connectivity.checkConnectivity();
      setState(() {
        isOnline =
            results.isNotEmpty && results.first != ConnectivityResult.none;
      });
    } catch (e, stacktrace) {
      print("Check Connectivity Error: $e");
      print(stacktrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true, // Required for DevicePreview
      debugShowCheckedModeBanner: true,
      locale: DevicePreview.locale(context), // Use DevicePreview's locale
      builder: DevicePreview.appBuilder, // Wrap app with DevicePreview
      home: Builder(
        builder: (context) {
          return isOnline ? SplashScreen() : OfflineHomePage();
        },
      ),
    );
  }
}

// import 'dart:convert';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:qrqragain/constants.dart';
// import 'package:qrqragain/offline_db.dart';
// import 'package:qrqragain/splash_page.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Hive.initFlutter();
//   await Hive.openBox('inventory'); // Open the local database

//   runApp(MaterialApp(home: SplashScreen()));
//   // runApp(

  //   DevicePreview(
  //     enabled: true, // Enable device preview
  //     builder:
  //         (context) => MaterialApp(
  //           useInheritedMediaQuery: true,
  //           debugShowCheckedModeBanner: false,
  //           locale: DevicePreview.locale(context),
  //           builder: DevicePreview.appBuilder,
  //           home: SplashScreen(),
  //         ),
  //   ),
//   // );
// }

// Future<void> syncPendingUpdates() async {
//   var connectivityResult = await Connectivity().checkConnectivity();
//   if (connectivityResult == ConnectivityResult.none) return;

//   List<Map<String, dynamic>> pendingUpdates =
//       await LocalDatabase.getPendingUpdates();

//   for (var i = 0; i < pendingUpdates.length; i++) {
//     var update = pendingUpdates[i];

//     final response = await http.post(
//       Uri.parse(
//         update['action'] == 'remove'
//             ? '$BASE_URL/remove_item.php'
//             : '$BASE_URL/update_item.php',
//       ),
//       body: jsonEncode({
//         'qr_code_data': update['qr_code_data'],
//         'quantity': update['quantity'],
//       }),
//       headers: {'Content-Type': 'application/json'},
//     );

//     print("Syncing: ${update['qr_code_data']} - ${update['quantity']}");

//     if (response.statusCode == 200) {
//       await LocalDatabase.deletePendingUpdate(i);
//     }
//   }
// }
