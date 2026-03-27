import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

class SignupPage extends StatefulWidget {
  final String? role;
  const SignupPage({super.key, this.role});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String hostel = '';
  String gender = 'Boy';
  String specialization = 'Electricity';
  bool showPassword = false;
  bool loading = false;

  final List<String> specializations = [
    'Electricity',
    'Water',
    'Cleaning',
    'Other',
  ];

  final Map<String, List<String>> hostelData = {
    'Boy': ['Sahara', 'Siberia', 'Swaraj', 'Sagar', 'Sarovar'],
    'Girl': ['Alakananda', 'Aiswarya', 'Anagha', 'Ananya', 'Anaswara'],
  };
  final Map<String, String> wardenGenders = {'Male': 'Boy', 'Female': 'Girl'};

  void signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      String selectedRole = widget.role ?? 'Student';
      Map<String, dynamic>? userData = await _auth.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        studentId: selectedRole == 'Student'
            ? _studentIdController.text.trim()
            : null,
        hostel: (selectedRole == 'Student' || selectedRole == 'Warden')
            ? hostel
            : null,
        gender: (selectedRole == 'Student' || selectedRole == 'Warden')
            ? gender
            : null,
        phone: selectedRole == 'Contractor'
            ? _phoneController.text.trim()
            : null,
        specialization: selectedRole == 'Contractor' ? specialization : null,
        password: _passwordController.text,
        role: selectedRole,
      );

      if (userData != null) {
        if (!mounted) return;

        // For Students and Contractors, show approval message and redirect to Login
        if (selectedRole == 'Student' || selectedRole == 'Contractor') {
          _showApprovalDialog(selectedRole);
        } else {
          // For Admin/Warden (if approved immediately), go to their dashboard
          Provider.of<UserProvider>(context, listen: false).setUser(userData);
          if (selectedRole == 'Admin') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/admin-dashboard',
              (r) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/warden-dashboard',
              (r) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg = "Signup failed. Please try again.";
        if (e.code == 'email-already-in-use') {
          errorMsg = "This email is already registered. Please login instead.";
        } else if (e.code == 'invalid-email') {
          errorMsg = "The email address is not valid.";
        } else if (e.code == 'weak-password') {
          errorMsg = "The password is too weak.";
        } else if (e.message != null) {
          errorMsg = e.message!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showApprovalDialog(String role) {
    String approver = role == 'Student' ? 'Warden' : 'Admin';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.timer_rounded, color: AppColors.primaryAccent),
            SizedBox(width: 10),
            Text("Registration Success", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "Your $role account has been created successfully!\n\nPlease wait for the $approver to approve your request before you can login.",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              "OK",
              style: TextStyle(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String selectedRole = widget.role ?? 'Student';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('$selectedRole Signup')),
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add_rounded,
                      size: 64,
                      color: AppColors.primaryAccent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "$selectedRole Signup",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        shadows: [
                          Shadow(
                            color: AppColors.primaryAccent.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: "Full Name",
                      controller: _nameController,
                      prefixIcon: Icons.badge_rounded,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: "Email Address",
                      controller: _emailController,
                      prefixIcon: Icons.email_rounded,
                      validator: (v) =>
                          v!.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 16),
                    if (selectedRole == 'Student') ...[
                      CustomTextField(
                        label: "Student ID / Roll No",
                        controller: _studentIdController,
                        prefixIcon: Icons.numbers_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedRole == 'Student' ||
                        selectedRole == 'Warden') ...[
                      _buildDropdown(
                        label: "Gender",
                        value: gender.isEmpty
                            ? null
                            : (selectedRole == 'Warden'
                                  ? (gender == 'Boy' ? 'Male' : 'Female')
                                  : gender),
                        items: (selectedRole == 'Warden'
                            ? wardenGenders.keys.toList()
                            : hostelData.keys.toList()),
                        onChanged: (v) {
                          setState(() {
                            if (selectedRole == 'Warden') {
                              gender = wardenGenders[v]!;
                            } else {
                              gender = v!;
                            }
                            hostel = '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: "Hostel Name",
                        value: hostel.isEmpty ? null : hostel,
                        items: hostelData[gender]!,
                        onChanged: (v) => setState(() => hostel = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedRole == 'Contractor') ...[
                      CustomTextField(
                        label: "Phone Number",
                        controller: _phoneController,
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: "Specialization",
                        value: specialization,
                        items: specializations,
                        onChanged: (v) => setState(() => specialization = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CustomTextField(
                      label: "Password",
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_rounded,
                      validator: (v) =>
                          v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 40),
                    NeonButton(
                      label: "REGISTER",
                      onPressed: signup,
                      isLoading: loading,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        "Already have an account? Login",
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.cardBg,
      style: const TextStyle(color: Colors.white),
      items: items
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.textFieldBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryAccent),
        ),
      ),
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}
