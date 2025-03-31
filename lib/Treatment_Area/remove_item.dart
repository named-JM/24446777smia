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
  List<Map<String, dynamic>> batches = [];
  String? selectedExpDate;

  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  // Fetch all batches with the same qr_code_data
  Future<void> fetchBatches() async {
    final response = await http.post(
      Uri.parse('$BASE_URL/get_batches.php'), // Create this PHP script
      body: jsonEncode({'qr_code_data': widget.qrCodeData}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        batches = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        if (batches.isNotEmpty) {
          selectedExpDate = batches[0]['exp_date']; // Default to first batch
        }
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch batches')));
    }
  }

  // Remove quantity from the selected batch
  Future<void> removeQuantity() async {
    if (selectedExpDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a batch')));
      return;
    }

    final response = await http.post(
      Uri.parse('$BASE_URL/remove_item.php'),
      body: jsonEncode({
        'qr_code_data': widget.qrCodeData,
        'exp_date': selectedExpDate, // Send the selected expiry date
        'quantity': int.parse(quantityController.text),
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
      Navigator.pop(context, true); // Refresh inventory
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
            if (batches.isNotEmpty)
              DropdownButton<String>(
                value: selectedExpDate,
                items:
                    batches.map((batch) {
                      return DropdownMenuItem<String>(
                        value: batch['exp_date'],
                        child: Text(
                          'Expiry: ${batch['exp_date']} | Qty: ${batch['quantity']}',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedExpDate = value;
                  });
                },
              )
            else
              Text('Loading batches...'),

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
