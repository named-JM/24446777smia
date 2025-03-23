import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';

class RemoveQuantityPage extends StatefulWidget {
  final String qrCodeData;

  RemoveQuantityPage({required this.qrCodeData});

  @override
  _RemoveQuantityPageState createState() => _RemoveQuantityPageState();
}

class _RemoveQuantityPageState extends State<RemoveQuantityPage> {
  final TextEditingController quantityController = TextEditingController();

  Future<void> removeQuantity() async {
    final response = await http.post(
      Uri.parse('$BASE_URL/remove_item.php'),
      body: jsonEncode({
        'qr_code_data': widget.qrCodeData,
        'quantity': int.parse(quantityController.text),
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
      Navigator.pop(context, true); // Return true to refresh inventory
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove quantity')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Remove Quantity')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Quantity to Remove',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: removeQuantity,
              child: Text('Remove Quantity'),
            ),
          ],
        ),
      ),
    );
  }
}
