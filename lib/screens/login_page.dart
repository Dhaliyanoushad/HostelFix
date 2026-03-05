import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  final String? role;
  const LoginPage({super.key, this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool loading = false;

  void login() async {
    String identity = _idController.text.trim();
    String password = _passwordController.text.trim();

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

      if (identity.contains('@')) {
        userData = await _auth.loginWithEmail(
          email: identity,
          password: password,
        );
      } else if (selectedRole == 'Student') {
        userData = await _auth.loginWithStudentId(
          studentId: identity,
          password: password,
        );
      } else if (selectedRole == 'Contractor') {
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
        if (widget.role != null && userData['role'] != widget.role) {
          await _auth.logout();
          throw 'Unauthorized: You are not a ${widget.role}';
        }

        if (userData['role'] == 'Contractor') {
          if (userData['status'] == 'pending') {
            await _auth.logout();
            throw 'Your account is waiting for admin approval.';
          } else if (userData['status'] != 'approved') {
            await _auth.logout();
            throw 'Account not found.';
          }
        }

        if (userData['role'] == 'Student') {
          if (userData['status'] == 'pending') {
            await _auth.logout();
            throw 'Your account is waiting for warden approval.';
          }
        }

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
      } else {
        throw 'Account not found.';
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
      idLabel = "Email";
      idIcon = Icons.email;
    } else if (widget.role == "Contractor") {
      idLabel = "Email or Phone";
      idIcon = Icons.contact_mail;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('$roleTitle Login')),
      body: FuturisticBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_person_rounded,
                      size: 64,
                      color: AppColors.primaryAccent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "$roleTitle Login",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        shadows: [
                          Shadow(
                            color: AppColors.primaryAccent.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: idLabel,
                      controller: _idController,
                      prefixIcon: idIcon,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: "Password",
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: Icons.vpn_key_rounded,
                    ),
                    const SizedBox(height: 40),
                    NeonButton(
                      label: "LOGIN",
                      onPressed: login,
                      isLoading: loading,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/select-signup-role'),
                      child: const Text(
                        "Need an account? Sign Up",
                        style: TextStyle(color: AppColors.secondaryAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
