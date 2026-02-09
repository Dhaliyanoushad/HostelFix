import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  String name = '';
  String email = '';
  String studentId = '';
  String hostel = 'Hostel A';
  String password = '';

  bool loading = false;
  bool showPassword = false;

  final hostels = ['Hostel A', 'Hostel B', 'Hostel C'];

  void signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    String? error = await _auth.signUp(
      name: name,
      email: email,
      studentId: studentId,
      hostel: hostel,
      password: password,
    );

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) => name = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (v) => email = v,
                validator: (v) => v!.contains('@') ? null : 'Enter valid email',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Student ID'),
                onChanged: (v) => studentId = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField(
                value: hostel,
                items: hostels
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => hostel = v!,
                decoration: const InputDecoration(labelText: 'Hostel'),
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
                obscureText: !showPassword,
                onChanged: (v) => password = v,
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 20),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: signup,
                      child: const Text('Create Account'),
                    ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
