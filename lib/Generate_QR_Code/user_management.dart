import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';

class User {
  final String uId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  User({
    required this.uId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uId: json['u_id'].toString(),
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email_address'],
      role: json['role'],
    );
  }
}

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  List<User> users = [];
  bool isLoading = false;

  final baseUrl = "$BASE_URL"; // <- replace with your backend URL

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _role = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('$BASE_URL/um_get_users.php'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      users = data.map((json) => User.fromJson(json)).toList();
    }
    setState(() => isLoading = false);
  }

  Future<void> addUser() async {
    final response = await http.post(
      Uri.parse('$baseUrl/um_add_users.php'),
      body: {
        "first_name": _firstName.text,
        "last_name": _lastName.text,
        "email_address": _email.text,
        "password": _password.text,
        "role": _role.text,
      },
    );
    if (jsonDecode(response.body)['status'] == 'success') {
      fetchUsers();
    }
  }

  Future<void> updateUserRole(String uId, String newRole) async {
    final response = await http.post(
      Uri.parse('$baseUrl/um_update_users.php'),
      body: {"u_id": uId, "role": newRole},
    );
    if (jsonDecode(response.body)['status'] == 'success') {
      fetchUsers();
    }
  }

  Future<void> deleteUser(String uId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/um_delete_users.php'),
      body: {"u_id": uId},
    );
    if (jsonDecode(response.body)['status'] == 'success') {
      fetchUsers();
    }
  }

  void clearTextField() {
    _firstName.clear();
    _lastName.clear();
    _email.clear();
    _password.clear();
    _role.clear();
  }

  void _showAddUserDialog() {
    String selectedRole = 'user'; // default

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add User"),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(
                        labelText: "First Name",
                      ),
                    ),
                    TextFormField(
                      controller: _lastName,
                      decoration: const InputDecoration(labelText: "Last Name"),
                    ),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password"),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items:
                          ['admin', 'user']
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        selectedRole = value!;
                      },
                      decoration: const InputDecoration(labelText: "Role"),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  _role.text = selectedRole; // assign selected role
                  addUser();
                  clearTextField();
                  // Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  void _showEditRoleDialog(User user) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit Role for ${user.firstName}"),
            content: DropdownButtonFormField<String>(
              value: selectedRole,
              items:
                  ['admin', 'user']
                      .map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      )
                      .toList(),
              onChanged: (value) {
                selectedRole = value!;
              },
              decoration: const InputDecoration(labelText: "Role"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  updateUserRole(user.uId, selectedRole);
                  Navigator.pop(context);
                },
                child: const Text("Update"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Management")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    child: ListTile(
                      title: Text("${user.firstName} ${user.lastName}"),
                      subtitle: Text(
                        "${user.email}\nRole: ${user.role}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditRoleDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text("Confirm Deletion"),
                                      content: Text(
                                        "Are you sure you want to delete ${user.firstName} ${user.lastName}?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(
                                                context,
                                              ), // Cancel
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (user.role == 'admin') {
                                              final adminCount =
                                                  users
                                                      .where(
                                                        (u) =>
                                                            u.role == 'admin',
                                                      )
                                                      .length;
                                              if (adminCount <= 1) {
                                                Navigator.pop(
                                                  context,
                                                ); // Close the confirm dialog first
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                        title: const Text(
                                                          "Action Blocked",
                                                        ),
                                                        content: const Text(
                                                          "You cannot delete the last admin. Please assign another admin before deleting this one.",
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                            child: const Text(
                                                              "OK",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                return;
                                              }
                                            }

                                            deleteUser(user.uId);
                                            Navigator.pop(
                                              context,
                                            ); // Close the confirm dialog
                                          },

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
