import 'package:flutter/material.dart';
import 'package:qrqragain/main.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Add your onPressed code here!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHome()),
                );
              },
              child: Text('Storage'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              child: Text('Treatment Area'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              child: Text('Generate QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
