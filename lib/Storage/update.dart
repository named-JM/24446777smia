import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';

class UpdateItemPage extends StatefulWidget {
  final String serialNo; // Add Serial Number
  final String qrCodeData;
  final String itemName;
  final String specification;
  final String unit;
  final String cost;
  final String expDate;
  // final String mfgDate;
  final String qrCodeImage;
  final bool fromQRScanner;

  UpdateItemPage({
    required this.serialNo, // Add Serial Number
    required this.qrCodeData,
    required this.itemName,
    required this.specification,
    required this.unit,
    required this.cost,
    required this.expDate,
    // required this.mfgDate,
    required this.qrCodeImage,
    required this.fromQRScanner,
  });

  @override
  _UpdateItemPageState createState() => _UpdateItemPageState();
}

class _UpdateItemPageState extends State<UpdateItemPage> {
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController expirationDateController =
      TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController specificationController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController manufacturingDateController =
      TextEditingController();
  String qrCodeImageValue = '';
  List<String> categories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchItemDetails();
    itemNameController.text = widget.itemName;
    specificationController.text = widget.specification;
    unitController.text = widget.unit;
    costController.text = widget.cost;
    // manufacturingDateController.text = widget.mfgDate;
    qrCodeImageValue = widget.qrCodeImage;
  }

  ///The server will create a new entry if the expiration date is new.
  ///The server will update the quantity if the expiration date already exists.
  ///The Flutter app will handle both scenarios seamlessly.
  Future<void> updateItem(int batchCount) async {
    if (quantityController.text.isEmpty ||
        expirationDateController.text.isEmpty ||
        brandController.text.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    if (int.tryParse(quantityController.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid quantity.')));
      return;
    }

    try {
      for (int i = 0; i < batchCount; i++) {
        final response = await http.post(
          Uri.parse('$BASE_URL/update_item.php'),
          body: jsonEncode({
            'serial_no': widget.serialNo,
            'qr_code_data': widget.qrCodeData,
            'quantity': int.parse(quantityController.text),
            'exp_date': expirationDateController.text,
            'brand': brandController.text,
            'category': selectedCategory,
            'item_name': itemNameController.text,
            'specification': specificationController.text,
            'unit': unitController.text,
            'cost': double.tryParse(costController.text) ?? 0.0,
            // 'mfg_date': manufacturingDateController.text,
            'qr_code_image': qrCodeImageValue,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          print(
            jsonEncode({
              'qr_code_data': widget.qrCodeData,
              'quantity': quantityController.text,
              'exp_date': expirationDateController.text,
              'brand': brandController.text,
              'category': selectedCategory,
              'item_name': itemNameController.text,
              'specification': specificationController.text,
              'unit': unitController.text,
              'cost': double.tryParse(costController.text) ?? 0.0,
              //  'mfg_date': manufacturingDateController.text,
              'qr_code_image': qrCodeImageValue,
            }),
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create or update entry')),
          );
          break;
        }
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  // Fetch categories from database
  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('$BASE_URL/get_categories.php'));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        categories =
            (result['categories'] as List)
                .map<String>((cat) => cat['name'].toString())
                .toSet() // Removes duplicates
                .toList();

        // Ensure the selectedCategory is valid
        if (selectedCategory == null ||
            !categories.contains(selectedCategory)) {
          selectedCategory = categories.isNotEmpty ? categories[0] : null;
        }
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch categories')));
    }
  }

  // Fetch item details
  Future<void> fetchItemDetails() async {
    final response = await http.post(
      Uri.parse('$BASE_URL/update_get_item.php'),
      body: jsonEncode({'qr_code_data': widget.qrCodeData}),
      headers: {'Content-Type': 'application/json'},
    );
    print("Fetching item details..."); // Debugging
    print("From QR Scanner: ${widget.fromQRScanner}"); // Debugging

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success']) {
        setState(() {
          if (!widget.fromQRScanner) {
            print("Exp Date Fetched: ${widget.expDate}"); // Debugging

            expirationDateController.text = widget.expDate;
          }
          brandController.text = result['brand'] ?? '';

          // Ensure category exists before assigning
          String fetchedCategory = result['category'] ?? '';
          if (categories.contains(fetchedCategory)) {
            selectedCategory = fetchedCategory;
          } else {
            selectedCategory = null; // Prevents assertion error
          }
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
  // Future<void> fetchItemDetails() async {
  //   final response = await http.post(
  //     Uri.parse('$BASE_URL/update_get_item.php'),
  //     body: jsonEncode({'qr_code_data': widget.qrCodeData}),
  //     headers: {'Content-Type': 'application/json'},
  //   );
  //   if (response.statusCode == 200) {
  //     final result = jsonDecode(response.body);
  //     if (result['success']) {
  //       setState(() {
  //         brandController.text = result['brand'] ?? '';
  //         categoryController.text = result['category'] ?? '';
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(result['message'] ?? 'Failed to fetch item details'),
  //         ),
  //       );
  //     }
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to connect to the server')),
  //     );
  //   }
  // }

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
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value:
                    categories.contains(selectedCategory)
                        ? selectedCategory
                        : null, // Prevents invalid value
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                items:
                    categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
              ),

              // New field for category
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  updateItem(1); // Pass a default value for batch count
                },
                child: Text('Update Item'),
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
      child: SizedBox(
        width: double.infinity, // Ensure full width
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
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
