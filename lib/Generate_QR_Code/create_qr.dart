// ignore_for_file: unused_element, unused_local_variable

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController mfgDateController = TextEditingController();
  final TextEditingController expDateController = TextEditingController();
  String selectedCategory = 'Antibiotics';
  String qrData = '';
  ScreenshotController screenshotController = ScreenshotController();

  List<dynamic> categories = [];

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('$BASE_URL/get_categories.php'));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          categories = jsonDecode(response.body)["categories"];
          if (categories.isNotEmpty) {
            selectedCategory = categories[0]["name"]; // Set default category
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  bool validateFields() {
    if (serialController.text.isEmpty ||
        brandController.text.isEmpty ||
        itemNameController.text.isEmpty ||
        specController.text.isEmpty ||
        unitController.text.isEmpty ||
        costController.text.isEmpty ||
        quantityController.text.isEmpty ||
        mfgDateController.text.isEmpty ||
        expDateController.text.isEmpty ||
        selectedCategory.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));
      return false;
    }
    return true;
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
    clearFormFields();
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

  void clearFormFields() {
    serialController.clear();
    brandController.clear();
    itemNameController.clear();
    specController.clear();
    unitController.clear();
    costController.clear();
    quantityController.clear();
    mfgDateController.clear();
    expDateController.clear();
    setState(() {
      selectedCategory =
          categories.isNotEmpty ? categories[0]["name"] : 'Antibiotics';
      // qrData = '';
    });
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
      // clearFormFields();
    } catch (e) {
      print('Error saving QR: $e');
    }
  }

  Future<void> saveQR() async {
    try {
      // Request storage permission (needed for Android 10 and below)
      Future<void> requestPermissions() async {
        if (Platform.isAndroid) {
          final status = await Permission.storage.request();
          if (status.isDenied || status.isPermanentlyDenied) {
            openAppSettings();
            return;
          }
        }
      }

      // Get the downloads directory
      Directory? downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory = await getExternalStorageDirectory();
      }
      if (downloadsDirectory == null)
        throw Exception("Could not find download directory");

      // Define file path with item name
      final fileName = '${itemNameController.text}_qr_code.png';
      final filePath = '${downloadsDirectory.path}/$fileName';

      // Capture screenshot and save
      final imagePath = await screenshotController.captureAndSave(
        downloadsDirectory.path,
        fileName: fileName,
      );

      if (imagePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved as $fileName in Downloads')),
        );
      } else {
        throw Exception("Failed to save QR code");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving QR code: $e')));
    }
  }

  Future<void> _showMonthYearPicker(
    BuildContext context,
    TextEditingController controller,
  ) async {
    // Default to current month/year
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    // Check if text field already has a valid date
    if (controller.text.isNotEmpty) {
      List<String> parts = controller.text.split('/');
      if (parts.length == 2) {
        int? parsedMonth = int.tryParse(parts[0]);
        int? parsedYear = int.tryParse(parts[1]);
        if (parsedMonth != null && parsedYear != null) {
          selectedMonth = parsedMonth;
          selectedYear = parsedYear;
        }
      }
    }

    FixedExtentScrollController monthController = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );
    FixedExtentScrollController yearController = FixedExtentScrollController(
      initialItem: selectedYear - 2000,
    );

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 300,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Select Month & Year",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Month Selector
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ListWheelScrollView.useDelegate(
                                controller: monthController,
                                itemExtent: 50,
                                diameterRatio: 2,
                                physics: FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedMonth = index + 1;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (context, index) {
                                    bool isSelected =
                                        selectedMonth == index + 1;
                                    return Center(
                                      child: Text(
                                        "${index + 1}",
                                        style: TextStyle(
                                          fontSize: isSelected ? 24 : 18,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              isSelected
                                                  ? Colors.blue
                                                  : Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: 12, // Months 1-12
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      height: 50,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        // Year Selector
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ListWheelScrollView.useDelegate(
                                controller: yearController,
                                itemExtent: 50,
                                diameterRatio: 2,
                                physics: FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedYear = 2000 + index;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (context, index) {
                                    bool isSelected =
                                        selectedYear == 2000 + index;
                                    return Center(
                                      child: Text(
                                        "${2000 + index}",
                                        style: TextStyle(
                                          fontSize: isSelected ? 24 : 18,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              isSelected
                                                  ? Colors.blue
                                                  : Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: 102, // Years from 2000 to 2101
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      height: 50,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.text =
                          "${selectedMonth.toString().padLeft(2, '0')}/$selectedYear";
                      Navigator.pop(context);
                    },
                    child: Text("Confirm"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              _buildNumberField(
                'Quantity',
                quantityController,
              ), // Updated Quantity Field
              Row(
                children: [
                  Expanded(child: _buildTextField('Unit', unitController)),
                  SizedBox(width: 10),
                  Expanded(child: _buildTextField('Cost', costController)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () =>
                              _showMonthYearPicker(context, mfgDateController),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          'Mfg Date (MM/YYYY)',
                          mfgDateController,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () =>
                              _showMonthYearPicker(context, expDateController),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          'Exp Date (MM/YYYY)',
                          expDateController,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (validateFields()) {
                      generateQR(); // Generate QR code data
                      saveQR(); // Save the QR Code to Downloads
                      await saveQRAndSendToServer(); // Capture and send QR code image
                    }
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
                        onPressed: () async {
                          await saveQR(); // Save the QR Code to Downloads
                        },
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

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: SizedBox(
            height: 30, // Reduce height
            width: 30, // Adjust width as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 14, // Reduce button height
                  child: IconButton(
                    icon: Icon(Icons.arrow_drop_up, size: 16), // Smaller icon
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                      int currentValue = int.tryParse(controller.text) ?? 0;
                      setState(() {
                        controller.text = (currentValue + 1).toString();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 14, // Reduce button height
                  child: IconButton(
                    icon: Icon(Icons.arrow_drop_down, size: 16), // Smaller icon
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                      int currentValue = int.tryParse(controller.text) ?? 0;
                      if (currentValue > 0) {
                        setState(() {
                          controller.text = (currentValue - 1).toString();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
