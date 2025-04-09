import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Help"), backgroundColor: Colors.lightGreen),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "User Manual",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "1. Storage Area:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "- Navigate to the Storage Area page to manage your inventory.\n"
              "- Use the Search Bar to find specific items by name or category.\n"
              "- Use the Category Dropdown to filter items by category.\n"
              "- Admins can Download CSV files of the inventory.\n"
              "- Both Admins and Users can Edit Items or Scan QR Codes to add or remove items.\n",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              "2. Treatment Page:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "- Navigate to the Treatment page to manage treatments.\n"
              "- View and manage medicines used in treatments.\n"
              "- Check the bar chart for a visual representation of limited stock items.\n",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              "3. Generate QR Code:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "- Use this feature to generate QR codes for items in your inventory.\n"
              "- QR codes can be scanned to quickly add or remove items.\n",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              "4. Notifications:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "- Check notifications for low stock or expiry alerts.\n"
              "- New notifications are highlighted in yellow.\n"
              "- Mark notifications as read to clear the alert.\n",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              "5. Logout:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "- Use the logout button to securely log out of the application.\n",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
              ),
              child: Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
