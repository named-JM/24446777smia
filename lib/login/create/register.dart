import 'package:flutter/material.dart';
import 'package:qrqragain/login/create/login.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  Future<void> registerUser(BuildContext context) async {
    //function for registering user, fetching api of php
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registration"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            //add logo png here or any image
            Text("Create Account"),
            TextField(decoration: InputDecoration(labelText: 'Email')),
            TextField(decoration: InputDecoration(labelText: 'Firstname')),
            TextField(decoration: InputDecoration(labelText: 'Lastname')),
            TextField(
              decoration: InputDecoration(labelText: 'Create your Password'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),

            ElevatedButton(
              onPressed: () => registerUser(context),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
