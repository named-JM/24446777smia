import 'package:flutter/material.dart';

class CreateCategory extends StatefulWidget {
  const CreateCategory({super.key});

  @override
  State<CreateCategory> createState() => _CreateCategoryState();
}

class _CreateCategoryState extends State<CreateCategory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Name', style: TextStyle(fontSize: 16)),
            TextField(
              decoration: InputDecoration(hintText: 'Enter Category Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Save Category
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
