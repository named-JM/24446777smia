import 'package:flutter/material.dart';
import 'package:qrqragain/Generate_QR_Code/create_category.dart';
import 'package:qrqragain/Generate_QR_Code/create_qr.dart';

class QrHome extends StatefulWidget {
  const QrHome({super.key});

  @override
  State<QrHome> createState() => _QrHomeState();
}

class _QrHomeState extends State<QrHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QRGeneratorPage()),
                  );
                },
                child: Text('Generate QR Code'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateCategory()),
                  );
                },
                child: Text("Create Category"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
