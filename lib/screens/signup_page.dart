import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  final String? role;
  const SignupPage({super.key, this.role});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  String name = '';
  String email = '';
  String studentId = '';
  String phone = '';
  String hostel = '';
  String gender = 'Boy';
  String password = '';

  bool loading = false;
  bool showPassword = false;

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
        name: name,
        email: email,
        studentId: selectedRole == 'Student' ? studentId : null,
        hostel: (selectedRole == 'Student' || selectedRole == 'Warden')
            ? hostel
            : null,
        gender: (selectedRole == 'Student' || selectedRole == 'Warden')
            ? gender
            : null,
        phone: selectedRole == 'Contractor' ? phone : null,
        password: password,
        role: selectedRole,
      );

      if (userData != null) {
        Provider.of<UserProvider>(context, listen: false).setUser(userData);

        if (selectedRole == 'Admin') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin-dashboard',
            (r) => false,
          );
        } else if (selectedRole == 'Warden') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/warden-dashboard',
            (r) => false,
          );
        } else if (selectedRole == 'Contractor') {
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
    String selectedRole = widget.role ?? 'Student';

    return Scaffold(
      appBar: AppBar(title: Text('$selectedRole Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                onChanged: (v) => name = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email Address'),
                onChanged: (v) => email = v,
                validator: (v) => v!.contains('@') ? null : 'Enter valid email',
              ),
              if (selectedRole == 'Student')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Student ID'),
                  onChanged: (v) => studentId = v,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              if (selectedRole == 'Student' || selectedRole == 'Warden') ...[
                DropdownButtonFormField(
                  value: gender.isEmpty
                      ? null
                      : (selectedRole == 'Warden'
                            ? (gender == 'Boy' ? 'Male' : 'Female')
                            : gender),
                  items:
                      (selectedRole == 'Warden'
                              ? wardenGenders.keys.toList()
                              : hostelData.keys.toList())
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
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
                  decoration: InputDecoration(
                    labelText: selectedRole == 'Warden' ? 'Gender' : 'Gender',
                    hintText: selectedRole == 'Warden'
                        ? 'Select Male/Female'
                        : 'Select Boy/Girl',
                  ),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                DropdownButtonFormField(
                  value: hostel.isEmpty ? null : hostel,
                  items: hostelData[gender]!
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                  onChanged: (v) => hostel = v!,
                  decoration: const InputDecoration(labelText: 'Hostel'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please select a hostel' : null,
                ),
              ],
              if (selectedRole == 'Contractor')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => phone = v,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
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
                      child: Text('Create $selectedRole Account'),
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
