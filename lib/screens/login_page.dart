import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();

  String studentId = '';
  String password = '';
  bool loading = false;

  void login() async {
    setState(() => loading = true);

    String? error = await _auth.loginWithStudentId(
      studentId: studentId,
      password: password,
    );

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      String? role = await _auth.getRole(studentId);
      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (role == 'Matron') {
        Navigator.pushReplacementNamed(context, '/matron-dashboard');
      } else if (role == 'Contractor') {
        Navigator.pushReplacementNamed(context, '/contractor-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Student ID'),
              onChanged: (v) => studentId = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (v) => password = v,
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: const Text('Login')),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text("Create new account"),
            ),
          ],
        ),
      ),
    );
  }
}
