import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerPage extends StatefulWidget {
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
      Navigator.pop(context, scanData.code);
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                '111,no brand,pampaligaya,paksk,24,48,111,02/2025,02/2026,Vitamins',
              );
            },
            child: Text('Simulate QR Scan'),
          ),
        ],
      ),
    );
  }

  // void onQRViewCreated(QRViewController controller) {
  //   this.controller = controller;
  //   controller.scannedDataStream.listen((scanData) {
  //     controller.pauseCamera();
  //     Navigator.pop(context, scanData.code);
  //   });
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('Scan QR Code')),
  //     body: QRView(key: qrKey, onQRViewCreated: onQRViewCreated),
  //   );
  // }
}
