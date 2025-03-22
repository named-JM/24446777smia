import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class QRGeneratorPage extends StatefulWidget {
  @override
  _QRGeneratorPageState createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController serialController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController specController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(); // New Quantity Field
  final TextEditingController mfgDateController =
      TextEditingController(); // New Mfg Date Field
  final TextEditingController expDateController =
      TextEditingController(); // New Exp Date Field
  String selectedCategory = 'Antibiotics';
  String qrData = '';
  ScreenshotController screenshotController = ScreenshotController();

  void generateQR() {
    setState(() {
      qrData =
          '${serialController.text},${brandController.text},${itemNameController.text},'
          '${specController.text},${unitController.text},${costController.text},'
          '${quantityController.text},${mfgDateController.text},${expDateController.text},$selectedCategory';
    });
    print("Generated QR Data: $qrData"); // Debugging
  }

  Future<void> saveQR() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/qr_code.png';
    screenshotController
        .captureAndSave(directory.path, fileName: 'qr_code.png')
        .then((value) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('QR Code saved at $filePath')));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate QR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEW ITEM',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category:'),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
                    },
                    items:
                        ['Antibiotics', 'Painkillers', 'Vitamins']
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              _buildTextField('Serial No.', serialController),
              _buildTextField('Brand Name', brandController),
              _buildTextField('Item Name', itemNameController),
              _buildTextField('Specification', specController),
              _buildTextField(
                'Quantity',
                quantityController,
              ), // Added Quantity Field
              Row(
                children: [
                  Expanded(child: _buildTextField('Unit', unitController)),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      'Mfg Date (MM/YYYY)',
                      mfgDateController,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField('Cost', costController)),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      'Exp Date (MM/YYYY)',
                      expDateController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: generateQR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'CREATE ITEM',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (qrData.trim().isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Screenshot(
                        controller: screenshotController,
                        child: QrImageView(data: qrData, size: 200),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: saveQR,
                        child: Text('Download QR'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
