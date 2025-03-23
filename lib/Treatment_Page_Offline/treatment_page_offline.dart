import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:qrqragain/Treatment_Area/qr.dart';
import 'package:qrqragain/Treatment_Page_Offline/remove_item_offline.dart';
import 'package:qrqragain/login/create/login.dart';

class TreatmentPageOffline extends StatefulWidget {
  @override
  _TreatmentPageOfflineState createState() => _TreatmentPageOfflineState();
}

class _TreatmentPageOfflineState extends State<TreatmentPageOffline> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  Future<void> fetchMedicines() async {
    final box = await Hive.openBox('inventory');
    setState(() {
      items = box.values.map((e) => Map<String, dynamic>.from(e)).toList();
    });
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
          builder:
              (context) => RemoveQuantityPageOffline(qrCodeData: scannedQR),
        ),
      );

      if (updated == true) {
        fetchMedicines(); // Refresh inventory if an item was updated
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment Area (Offline)'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
      ),
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
