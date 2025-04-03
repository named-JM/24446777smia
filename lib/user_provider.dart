import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userID;

  String? get userID => _userID;

  void setUserID(String userID) {
    _userID = userID;
    print("User ID set to: $_userID"); // Debugging
    notifyListeners();
  }

  void clearUserID() {
    _userID = null;
    notifyListeners();
  }
}
