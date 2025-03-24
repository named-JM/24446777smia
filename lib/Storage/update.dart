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

  Future<void> updateItem() async {
    final response = await http.post(
      Uri.parse('$BASE_URL/update_item.php'),
      body: jsonEncode({
        'qr_code_data': widget.qrCodeData,
        'quantity': int.parse(quantityController.text),
        'exp_date': expirationDateController.text,
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

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Item')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildNumberField('Enter Quantity', quantityController),
            GestureDetector(
              onTap: () => _selectDate(context, expirationDateController),
              child: AbsorbPointer(
                child: _buildTextField(
                  'Enter Expiration Date (MM/YYYY)',
                  expirationDateController,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: updateItem, child: Text('Update Item')),
          ],
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
