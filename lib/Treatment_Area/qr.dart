import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

//heres the remove
class QRScannerPage extends StatefulWidget {
  final String action; // 'scan'

  QRScannerPage({required this.action});

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      controller.pauseCamera();
      Navigator.pop(context, scanData.code); // Return scanned QR data
    });
  }

  // Add a button for manual testing
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(child: QRView(key: qrKey, onQRViewCreated: onQRViewCreated)),
          // ElevatedButton(
          //   onPressed: () {
          //     Navigator.pop(
          //       context,
          //       'ND2828282,no brnd,Paracentamol,gampt aa sakit,500mg,10,250,03/2025,09/2025,Antibiotic',
          //     );
          //   },
          //   child: Text('Simulate QR Scan'),
          // ),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('Scan QR Code')),
  //     body: QRView(key: qrKey, onQRViewCreated: onQRViewCreated),
  //   );
  // }
}
