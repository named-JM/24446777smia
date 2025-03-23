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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Item')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter Quantity'),
            ),
            TextField(
              controller: expirationDateController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Enter Expiration Date (YYYY-MM-DD)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: updateItem, child: Text('Update Item')),
          ],
        ),
      ),
    );
  }
}
