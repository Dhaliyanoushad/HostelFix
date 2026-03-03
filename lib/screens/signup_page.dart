import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
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
  String role = 'Student';
  String password = '';

  bool loading = false;
  bool showPassword = false;

  final hostels = ['Hostel A', 'Hostel B', 'Hostel C'];
  final roles = ['Student', 'Admin', 'Matron', 'Contractor'];

  void signup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      Map<String, dynamic>? userData = await _auth.signUp(
        name: name,
        email: email,
        studentId: studentId,
        hostel: hostel,
        password: password,
        role: role,
      );

      if (userData != null) {
        Provider.of<UserProvider>(context, listen: false).setUser(userData);

        if (role == 'Admin') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin-dashboard',
            (r) => false,
          );
        } else if (role == 'Matron') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/matron-dashboard',
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
                initialValue: hostel,
                items: hostels
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => hostel = v!,
                decoration: const InputDecoration(labelText: 'Hostel'),
              ),
              DropdownButtonFormField(
                initialValue: role,
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => role = v!,
                decoration: const InputDecoration(labelText: 'User Role'),
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
