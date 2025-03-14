import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';
import 'package:qrqragain/login/create/login.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  Future<void> registerUser(BuildContext context) async {
    final String apiUrl =
        "$BASE_URL/register.php"; // Change this to your actual PHP URL
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        "email_address": emailController.text,
        "password": passwordController.text,
        "first_name": fnameController.text,
        "last_name": lnameController.text,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration successful!")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed. Try again.")),
      );
    }
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
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: fnameController,
              decoration: InputDecoration(labelText: 'Firstname'),
            ),
            TextField(
              controller: lnameController,
              decoration: InputDecoration(labelText: 'Lastname'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Create your Password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmPassController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),

            ElevatedButton(
              onPressed: () => registerUser(context),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
