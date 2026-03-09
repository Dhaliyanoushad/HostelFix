import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';

class LoginPage extends StatefulWidget {
  final String? role;
  const LoginPage({super.key, this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();

  String identity = ''; 
  String password = '';
  bool loading = false;
  bool _obscureText = true;

  void login() async {
    if (identity.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Credentials"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => loading = true);

    try {
      String selectedRole = widget.role ?? 'Student';
      Map<String, dynamic>? userData;
      final cleanIdentity = identity.trim();
      final cleanPassword = password; // Passwords usually shouldn't be trimmed

      if (cleanIdentity.contains('@')) {
        userData = await _auth.loginWithEmail(email: cleanIdentity, password: cleanPassword);
      } else if (selectedRole == 'Student') {
        userData = await _auth.loginWithStudentId(studentId: cleanIdentity, password: cleanPassword);
      } else if (selectedRole == 'Contractor') {
        userData = await _auth.loginWithPhone(phone: cleanIdentity, password: cleanPassword);
      } else {
        userData = await _auth.loginWithEmail(email: cleanIdentity, password: cleanPassword);
      }

      if (userData != null) {
        if (widget.role != null && userData['role'] != widget.role) {
          await _auth.logout();
          throw 'Unauthorized: You are not a ${widget.role}';
        }

        Provider.of<UserProvider>(context, listen: false).setUser(userData);

        String role = userData['role'];
        if (role == 'Admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (r) => false);
        } else if (role == 'Warden') {
          Navigator.pushNamedAndRemoveUntil(context, '/warden-dashboard', (r) => false);
        } else if (role == 'Contractor') {
          Navigator.pushNamedAndRemoveUntil(context, '/contractor-dashboard', (r) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleTitle = widget.role ?? "User";
    String idLabel = widget.role == "Contractor" ? "Email or Phone" : "Email";
    IconData idIcon = widget.role == "Contractor" ? Icons.contact_mail_rounded : Icons.email_rounded;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('$roleTitle Login'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(radius: 100, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: CircleAvatar(radius: 150, backgroundColor: Colors.blueAccent.withOpacity(0.05)),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(idIcon, size: 64, color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Login to manage your hostel fixed",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 40),
                  GlassContainer(
                    child: Column(
                      children: [
                        _buildTextField(
                          label: idLabel,
                          icon: idIcon,
                          onChanged: (v) => identity = v,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Password",
                          icon: Icons.lock_rounded,
                          obscure: _obscureText,
                          onChanged: (v) => password = v,
                          suffix: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: login,
                                  child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/select-signup-role'),
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      onChanged: onChanged,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
