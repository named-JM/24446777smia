import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UpdateItemOffline extends StatefulWidget {
  final String itemName;
  final String qrCodeData;
  final String serialNo;
  final String expDate;
  final bool fromQRScanner; // New flag to indicate source

  UpdateItemOffline({
    required this.itemName,
    required this.qrCodeData,
    required this.serialNo,
    required this.expDate,
    required this.fromQRScanner, // Initialize the flag
  });

  @override
  State<UpdateItemOffline> createState() => _UpdateItemOfflineState();
}

class _UpdateItemOfflineState extends State<UpdateItemOffline> {
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController expirationDateController =
      TextEditingController();
  final TextEditingController brandController = TextEditingController();
  List<String> categories = [];
  String? selectedCategory;
  @override
  void initState() {
    super.initState();

    fetchItemDetailsOffline();
    fetchCategoriesOffline(); // Load categories from Hive when the screen opens
    //clearPendingUpdates(); // Clear pending updates when the screen opens
  }

  Future<void> clearPendingUpdates() async {
    try {
      final inventoryBox = await Hive.openBox('inventory');
      final pendingUpdatesBox = await Hive.openBox('pending_updates');
      await pendingUpdatesBox.clear(); // Clear all pending updates
      await inventoryBox.clear(); // Clear all inventory items
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pending updates cleared successfully.')),
      );
      print("Pending updates cleared successfully.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear pending updates: $e')),
      );
      print("Failed to clear pending updates: $e");
    }
  }

  Future<void> fetchItemDetailsOffline() async {
    final inventoryBox = await Hive.openBox('inventory');

    // Find the item in the Hive inventory using qr_code_data
    final item = inventoryBox.values.firstWhere(
      (item) => item['qr_code_data'] == widget.qrCodeData,
      orElse: () => null, // Return null if not found
    );

    if (item != null) {
      setState(() {
        if (!widget.fromQRScanner) {
          // Fetch expiration date only if not from QR Scanner
          expirationDateController.text = widget.expDate;
        }
        brandController.text = item['brand'] ?? '';
        selectedCategory = item['category'] ?? '';

        // Additional fields
        String specification = item['specification'] ?? 'N/A';
        String unit = item['unit'] ?? 'N/A';
        String cost = item['cost'] ?? 'N/A';
        String qrCodeImage = item['qr_code_image'] ?? '';

        print("Specification: $specification");
        print("Unit: $unit");
        print("Cost: $cost");
        print("QR Code Image: $qrCodeImage");
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item not found in offline inventory')),
      );
      Navigator.pop(context); // Close the page if the item is not found
    }
  }

  Future<void> fetchCategoriesOffline() async {
    final categoryBox = await Hive.openBox('categories');

    setState(() {
      categories = List<String>.from(
        categoryBox.get('categories', defaultValue: []),
      );
      print("Offline categories loaded: $categories"); // Debugging
      if (selectedCategory == null || !categories.contains(selectedCategory)) {
        selectedCategory = categories.isNotEmpty ? categories[0] : null;
      }
    });
  }

  Future<void> addQuantity() async {
    final inventoryBox = await Hive.openBox('inventory');
    final pendingUpdatesBox = await Hive.openBox('pending_updates');

    // Validate fields
    if (quantityController.text.isEmpty ||
        expirationDateController.text.isEmpty ||
        brandController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    // Ensure quantity is a valid number
    int? addQuantity = int.tryParse(quantityController.text);
    if (addQuantity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid quantity.')));
      return;
    }

    // Retrieve item details based on qr_code_data
    final item = inventoryBox.values.firstWhere(
      (item) => item['qr_code_data'] == widget.qrCodeData,
      orElse: () => null,
    );

    String itemName = item?['item_name'] ?? widget.itemName;
    String serialNo = item?['serial_no'] ?? widget.serialNo;
    String specification = item?['specification'] ?? 'N/A';
    String unit = item?['unit'] ?? 'N/A';
    String cost = item?['cost'] ?? 'N/A';
    String qrCodeImage = item?['qr_code_image'] ?? '';

    // Find if the batch already exists
    final batchKey = inventoryBox.keys.firstWhere((key) {
      var item = inventoryBox.get(key);
      return item['qr_code_data'] == widget.qrCodeData &&
          item['exp_date'] == expirationDateController.text;
    }, orElse: () => null);

    if (batchKey != null) {
      var existingItem = inventoryBox.get(batchKey);
      int currentQuantity =
          int.tryParse(existingItem['quantity'].toString()) ?? 0;

      existingItem['item_name'] = itemName;
      existingItem['serial_no'] = serialNo;
      existingItem['quantity'] = currentQuantity + addQuantity;
      existingItem['exp_date'] = expirationDateController.text;
      existingItem['brand'] = brandController.text;
      existingItem['category'] = selectedCategory ?? "Uncategorized";
      existingItem['specification'] = specification;
      existingItem['unit'] = unit;
      existingItem['cost'] = cost;
      existingItem['qr_code_image'] = qrCodeImage;

      await inventoryBox.put(batchKey, existingItem);
    } else {
      // Create a new batch entry with additional fields
      await inventoryBox.add({
        'qr_code_data': widget.qrCodeData,
        'item_name': itemName,
        'serial_no': serialNo,
        'quantity': addQuantity,
        'exp_date': expirationDateController.text,
        'brand': brandController.text,
        'category': selectedCategory ?? "Uncategorized",
        'specification': specification,
        'unit': unit,
        'cost': cost,
        'qr_code_image': qrCodeImage,
      });
    }

    // Save update to pending_updates with additional fields
    pendingUpdatesBox.add({
      'qr_code_data': widget.qrCodeData,
      'item_name': itemName,
      'serial_no': serialNo,
      'quantity_added': addQuantity,
      'exp_date': expirationDateController.text,
      'brand': brandController.text,
      'category': selectedCategory ?? "Uncategorized",
      'specification': specification,
      'unit': unit,
      'cost': cost,
      'qr_code_image': qrCodeImage,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quantity added successfully (Offline).')),
    );
    Navigator.pop(context, true);
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
      appBar: AppBar(title: Text('Update Item (Offline)')),
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
              _buildTextField('Enter Brand', brandController),
              SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedCategory,
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

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addQuantity,
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
