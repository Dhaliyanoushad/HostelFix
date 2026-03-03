import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  void setUser(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void clearUser() {
    _userData = null;
    notifyListeners();
  }

  bool get isLoggedIn => _userData != null;
  String? get role => _userData?['role'];
  String? get uid => _userData?['uid'];
  String? get studentId => _userData?['studentId'];
  String? get name => _userData?['name'];
  String? get hostel => _userData?['hostel'];
}
