import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/Treatment_Area/qr.dart';
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/remove_item.dart';

class TreatmentPage extends StatefulWidget {
  @override
  _TreatmentPageState createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  Future<void> fetchMedicines() async {
    final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));
    if (response.statusCode == 200) {
      setState(() {
        items = jsonDecode(response.body)['items'];
      });
    }
  }

  void openQRScanner() async {
    String? scannedQR = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );

    if (scannedQR != null) {
      bool? updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RemoveQuantityPage(qrCodeData: scannedQR),
        ),
      );

      // if (updated == true) {
      //   fetchItems(); // Refresh inventory if an item was updated
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treatment Area')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: openQRScanner,
            child: const Text('Scan QR'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMedicines,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final medicine = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(medicine['item_name']),
                      subtitle: Text('Quantity: ${medicine['quantity']}'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class QRScannerScreen extends StatefulWidget {
//   @override
//   _QRScannerScreenState createState() => _QRScannerScreenState();
// }

// class _QRScannerScreenState extends State<QRScannerScreen> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   String scannedData = 'Scan a QR code';

//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null) {
//       controller!.pauseCamera();
//       controller!.resumeCamera();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('QR Code Scanner')),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 5,
//             child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
//           ),
//           Expanded(flex: 1, child: Center(child: Text(scannedData))),
//         ],
//       ),
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//     controller.scannedDataStream.listen((scanData) {
//       setState(() {
//         scannedData = scanData.code ?? 'No data';
//       });
//     });
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
// }
