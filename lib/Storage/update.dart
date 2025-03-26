import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';

class UpdateItemPage extends StatefulWidget {
  final String qrCodeData;

  UpdateItemPage({required this.qrCodeData});

  @override
  _UpdateItemPageState createState() => _UpdateItemPageState();
}

class _UpdateItemPageState extends State<UpdateItemPage> {
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController expirationDateController =
      TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItemDetails(); // Fetch existing item details
  }

  Future<void> updateItem() async {
    final response = await http.post(
      Uri.parse('$BASE_URL/update_item1sample.php'),
      body: jsonEncode({
        'qr_code_data': widget.qrCodeData,
        'quantity': int.parse(quantityController.text),
        'exp_date': expirationDateController.text,
        'brand': brandController.text, // Include brand
        'category': categoryController.text, // Include category
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update item')));
    }
  }

  Future<void> fetchItemDetails() async {
    final response = await http.post(
      Uri.parse('$BASE_URL/update_get_item.php'),
      body: jsonEncode({'qr_code_data': widget.qrCodeData}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success']) {
        setState(() {
          brandController.text = result['brand'] ?? '';
          categoryController.text = result['category'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to fetch item details'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to the server')),
      );
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
      appBar: AppBar(title: Text('Update Item')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNumberField('Enter Quantity', quantityController),
              GestureDetector(
                onTap:
                    () =>
                        _showMonthYearPicker(context, expirationDateController),
                child: AbsorbPointer(
                  child: _buildTextField(
                    'Enter Expiration Date (MM/YYYY)',
                    expirationDateController,
                  ),
                ),
              ),
              _buildTextField(
                'Enter Brand',
                brandController,
              ), // New field for brand
              _buildTextField(
                'Enter Category',
                categoryController,
              ), // New field for category
              SizedBox(height: 20),
              ElevatedButton(onPressed: updateItem, child: Text('Update Item')),
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
        ),
      ),
    );
  }
}
