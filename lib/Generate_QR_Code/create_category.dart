import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController categoryController = TextEditingController();
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final url = '$BASE_URL/Category/all';
      print("🔍 FETCH: $url");

      final response = await http.get(Uri.parse(url));
      print("🔍 CODE: ${response.statusCode}");
      print("🔍 BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body)["categories"];
        });
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching: $e");
    }
  }

  Future<void> addCategory() async {
    if (categoryController.text.isEmpty) return;

    final response = await http.post(
      Uri.parse('$BASE_URL/Category/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": categoryController.text}),
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");
    print("🔍 CODE: ${response.statusCode}");
    print("🔍 BODY: ${response.body}");

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: ${response.statusCode}")),
      );
      return;
    }

    try {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"])));

      if (result["success"]) {
        categoryController.clear();
        fetchCategories();
      }
    } catch (e) {
      print("Error decoding JSON: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid response format")));
    }
  }

  Future<void> deleteCategory(dynamic id) async {
    final response = await http.delete(
      Uri.parse('$BASE_URL/Category/delete/$id'),
    );

    print("Delete Response Code: ${response.statusCode}");
    print("Delete Response Body: ${response.body}");

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: ${response.statusCode}")),
      );
      return;
    }

    try {
      final result = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"])));

      if (result["success"]) {
        fetchCategories();
      }
    } catch (e) {
      print("Error decoding JSON: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addCategory,
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(categories[index]["name"]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteCategory(categories[index]["id"]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
