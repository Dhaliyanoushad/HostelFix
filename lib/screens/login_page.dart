import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String? role;
  const LoginPage({super.key, this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();

  String identity = ''; // Can be email, studentId, or phone
  String password = '';
  bool loading = false;

  void login() async {
    if (identity.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter Credentials")));
      return;
    }

    setState(() => loading = true);

    try {
      String selectedRole = widget.role ?? 'Student';
      Map<String, dynamic>? userData;

      if (selectedRole == 'Student') {
        userData = await _auth.loginWithStudentId(
          studentId: identity,
          password: password,
        );
      } else if (selectedRole == 'Contractor' && !identity.contains('@')) {
        userData = await _auth.loginWithPhone(
          phone: identity,
          password: password,
        );
      } else {
        userData = await _auth.loginWithEmail(
          email: identity,
          password: password,
        );
      }

      if (userData != null) {
        // Check if role matches if provided
        if (widget.role != null && userData['role'] != widget.role) {
          await _auth.logout();
          throw 'Unauthorized: You are not a ${widget.role}';
        }

        // Store in Provider
        Provider.of<UserProvider>(context, listen: false).setUser(userData);

        String role = userData['role'];
        if (role == 'Admin') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin-dashboard',
            (r) => false,
          );
        } else if (role == 'Warden') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/warden-dashboard',
            (r) => false,
          );
        } else if (role == 'Contractor') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/contractor-dashboard',
            (r) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (r) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleTitle = widget.role ?? "User";
    String idLabel = "Email";
    IconData idIcon = Icons.email;

    if (widget.role == "Student") {
      idLabel = "Student ID";
      idIcon = Icons.person;
    } else if (widget.role == "Contractor") {
      idLabel = "Email or Phone";
      idIcon = Icons.contact_mail;
    }

    String passLabel = widget.role == "Student"
        ? "Student Passcode"
        : "Password";

    return Scaffold(
      appBar: AppBar(title: Text('$roleTitle Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (widget.role == "Warden")
              const Text(
                "Warden Login – Hostel Management",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                labelText: idLabel,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(idIcon),
              ),
              onChanged: (v) => identity = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: passLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
              onChanged: (v) => password = v,
            ),
            const SizedBox(height: 30),
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: login,
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/select-signup-role');
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
