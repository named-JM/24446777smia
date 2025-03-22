import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrqragain/constants.dart';
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

  List<dynamic> categories = [];

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('$BASE_URL/get_categories.php'));
    if (response.statusCode == 200) {
      setState(() {
        categories = jsonDecode(response.body)["categories"];
        if (categories.isNotEmpty) {
          selectedCategory = categories[0]["name"]; // Set default category
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> sendDataToServer(String base64QR) async {
    final url = '$BASE_URL/add_item.php'; // Change to your server URL
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json; charset=UTF-8"},
      body: jsonEncode({
        "serial_no": serialController.text,
        "brand": brandController.text,
        "item_name": itemNameController.text,
        "specification": specController.text,
        "unit": unitController.text,
        "cost":
            costController.text.isEmpty
                ? 0.0
                : double.parse(costController.text),
        "quantity":
            quantityController.text.isEmpty
                ? 0
                : int.parse(quantityController.text),
        "mfg_date": mfgDateController.text,
        "exp_date": expDateController.text,
        "category": selectedCategory,
        "qr_code_data": qrData, // Send QR data (text)
        "qr_code_image": base64QR, // Send QR code image (base64)
      }),
    );
    print("Server Response: ${response.body}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to connect to server: ${response.body}"),
        ),
      );
    }
  }

  void generateQR() {
    setState(() {
      qrData =
          serialController.text.isNotEmpty
              ? '${serialController.text},${brandController.text},${itemNameController.text},'
                  '${specController.text},${unitController.text},${costController.text},'
                  '${quantityController.text},${mfgDateController.text},${expDateController.text},$selectedCategory'
              : 'N/A'; // Ensure it's never empty
    });
    print("Generated QR Data: $qrData"); // Debugging
  }

  Future<void> saveQRAndSendToServer() async {
    try {
      final imageBytes = await screenshotController.capture();
      if (imageBytes == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture QR code')));
        return;
      }

      // Convert image bytes to Base64 string
      String base64Image = base64Encode(imageBytes);

      await sendDataToServer(base64Image);
    } catch (e) {
      print('Error saving QR: $e');
    }
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
                        categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category["name"] as String,
                                child: Text(category["name"] as String),
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
                  onPressed: () async {
                    generateQR(); // Generate QR code data
                    await saveQRAndSendToServer(); // Capture and send QR code image
                  },
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
                        onPressed: saveQRAndSendToServer,
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
