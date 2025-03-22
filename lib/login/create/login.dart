import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/home.dart';
import 'package:qrqragain/login/create/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginUser(BuildContext context) async {
    final String email = emailController.text;
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    final String apiUrl = "$BASE_URL/login.php";
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {"email_address": email, "password": password},
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body); // Decode JSON response

        if (data["status"] == "success") {
          // Make sure login is successful
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Login successful!")));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "Login failed. Try again."),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Empty response from server. Please try again later.",
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error. Please try again later.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),

            //register nav text and button
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Registration()),
                );
              },
              child: const Text('Register'),
            ),
            ElevatedButton(
              onPressed: () => loginUser(context),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
