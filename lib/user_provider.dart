import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userID;
  String? _role;
  Map<String, String> _userMap = {};

  //getter
  String? get userID => _userID;
  String? get role => _role;
  Map<String, String> get userMap => _userMap;
  void setUserID(String userID) {
    _userID = userID;
    notifyListeners();
  }

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void setUserMap(Map<String, String> map) {
    _userMap = map;
    notifyListeners();
  }
}
