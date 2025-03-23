import 'dart:convert';

// void main() => runApp(MaterialApp(home: LoginScreen()));
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/offline_db.dart';
import 'package:qrqragain/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('inventory'); // Open the local database

  // runApp(MaterialApp(home: LoginScreen()));
  runApp(MaterialApp(home: SplashScreen()));
}

Future<void> syncPendingUpdates() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) return;

  List<Map<String, dynamic>> pendingUpdates =
      await LocalDatabase.getPendingUpdates();

  for (var i = 0; i < pendingUpdates.length; i++) {
    var update = pendingUpdates[i];

    final response = await http.post(
      Uri.parse(
        update['action'] == 'remove'
            ? '$BASE_URL/remove_item.php'
            : '$BASE_URL/update_item.php',
      ),
      body: jsonEncode({
        'qr_code_data': update['qr_code_data'],
        'quantity': update['quantity'],
      }),
      headers: {'Content-Type': 'application/json'},
    );

    print("Syncing: ${update['qr_code_data']} - ${update['quantity']}");

    if (response.statusCode == 200) {
      await LocalDatabase.deletePendingUpdate(i);
    }
  }
}

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => QRScannerScreen()));
          },
          child: const Text('qrView'),
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String scannedData = 'Scan a QR code';

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code Scanner')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
          ),
          Expanded(flex: 1, child: Center(child: Text(scannedData))),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scannedData = scanData.code ?? 'No data';
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
