import 'package:flutter/material.dart';
import 'package:qrqragain/login/create/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> loginUser(BuildContext context) async {
    //function here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(decoration: InputDecoration(labelText: 'Email')),
            TextField(
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
