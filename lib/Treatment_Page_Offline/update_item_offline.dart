import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UpdateItemOffline extends StatefulWidget {
  final String qrCodeData;

  UpdateItemOffline({required this.qrCodeData});

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
    fetchCategoriesOffline(); // Load categories from Hive when the screen opens
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

    Map<dynamic, dynamic> inventoryMap = inventoryBox.toMap();
    var itemKey;
    var item;
    print("Scanned QR Code Data: ${widget.qrCodeData}");

    // Search for the correct item by matching qr_code_data
    for (var key in inventoryMap.keys) {
      var currentItem = inventoryMap[key];
      if (currentItem['qr_code_data'] == widget.qrCodeData) {
        item = currentItem;
        itemKey = key;
        break;
      }
    }
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
    if (int.tryParse(quantityController.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid quantity.')));
      return;
    }

    if (item != null) {
      int currentQuantity = int.tryParse(item['quantity'].toString()) ?? 0;
      int addQuantity = int.tryParse(quantityController.text) ?? 0;
      item['exp_date'] = expirationDateController.text;
      item['brand'] = brandController.text;
      item['category'] =
          selectedCategory ?? "Uncategorized"; // Ensure category is updated

      if (addQuantity > 0) {
        item['quantity'] = currentQuantity + addQuantity;

        await inventoryBox.put(itemKey, item);

        // Save the addition to pending updates for later sync
        pendingUpdatesBox.add({
          'qr_code_data': widget.qrCodeData,
          'quantity_added': addQuantity,
          'exp_date': expirationDateController.text,
          'brand': brandController.text,
          'category':
              selectedCategory ??
              item['category'] ??
              "Uncategorized", // Ensure category is stored
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity added successfully (Offline).')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid quantity entered.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item not found in offline storage.')),
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
