import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  String room = '';
  String gender = 'Boy';
  String specialization = 'Electrician';
  String experience = '';
  String profilePhoto = '';
  String hostelCode = '';
  String password = '';
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 40);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Profile Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerOption(Icons.camera_alt_rounded, "Camera", () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                }),
                _pickerOption(Icons.photo_library_rounded, "Gallery", () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  final List<String> specializations = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Cleaning',
    'Other',
  ];

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
      String? photoUrl;

      if (_profileImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${DateTime.now().millisecondsSinceEpoch}_$email.jpg');
        await ref.putFile(_profileImage!);
        photoUrl = await ref.getDownloadURL();
      }

      Map<String, dynamic>? userData = await _auth.signUp(
        name: name,
        email: email,
        studentId: selectedRole == 'Student' ? studentId : null,
        hostel: (selectedRole == 'Student' || selectedRole == 'Warden') ? hostel : null,
        room: selectedRole == 'Student' ? room : null,
        hostelCode: selectedRole == 'Warden' ? hostelCode : null,
        gender: (selectedRole == 'Student' || selectedRole == 'Warden') ? gender : null,
        phone: (selectedRole == 'Contractor' || selectedRole == 'Warden' || selectedRole == 'Student') ? phone : null,
        specialization: selectedRole == 'Contractor' ? specialization : null,
        experience: selectedRole == 'Contractor' ? experience : null,
        profilePhoto: photoUrl,
        password: password,
        role: selectedRole,
      );

      if (userData != null && context.mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(userData);
        if (selectedRole == 'Admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (r) => false);
        } else if (selectedRole == 'Warden') {
          Navigator.pushNamedAndRemoveUntil(context, '/warden-dashboard', (r) => false);
        } else if (selectedRole == 'Contractor') {
          Navigator.pushNamedAndRemoveUntil(context, '/contractor-dashboard', (r) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedRole = widget.role ?? 'Student';
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Join as $selectedRole', style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildField(Icons.person_rounded, 'Full Name', (v) => name = v),
                          _buildField(Icons.email_rounded, 'Email Address', (v) => email = v, keyboardType: TextInputType.emailAddress),
                          
                          if (selectedRole == 'Student') ...[
                            _buildField(Icons.badge_rounded, 'Student ID', (v) => studentId = v),
                            _buildField(Icons.meeting_room_rounded, 'Room Number', (v) => room = v),
                            _buildField(Icons.phone_rounded, 'Phone Number', (v) => phone = v, keyboardType: TextInputType.phone),
                          ],
                          
                          const SizedBox(height: 10),
                          const Text("Profile Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _showImagePicker,
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                                image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null,
                              ),
                              child: _profileImage == null ? Icon(Icons.add_a_photo_rounded, color: Theme.of(context).primaryColor, size: 30) : null,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (selectedRole == 'Warden') ...[
                            _buildField(Icons.phone_rounded, 'Phone Number', (v) => phone = v, keyboardType: TextInputType.phone),
                            _buildField(Icons.qr_code_rounded, 'Hostel Code', (v) => hostelCode = v),
                          ],

                          if (selectedRole == 'Contractor') ...[
                            _buildField(Icons.phone_rounded, 'Phone Number', (v) => phone = v, keyboardType: TextInputType.phone),
                            _buildDropdownField(
                              Icons.engineering_rounded, 
                              'Specialization', 
                              specialization,
                              specializations,
                              (v) => setState(() => specialization = v!)
                            ),
                            _buildField(Icons.history_rounded, 'Experience (Years)', (v) => experience = v, keyboardType: TextInputType.number),
                          ],

                          if (selectedRole == 'Student' || selectedRole == 'Warden') ...[
                            _buildDropdownField(
                              selectedRole == 'Student' ? Icons.wc_rounded : Icons.person_search_rounded,
                              'Gender',
                              gender.isEmpty ? null : (selectedRole == 'Warden' ? (gender == 'Boy' ? 'Male' : 'Female') : gender),
                              (selectedRole == 'Warden' ? wardenGenders.keys.toList() : hostelData.keys.toList()),
                              (v) {
                                setState(() {
                                  if (selectedRole == 'Warden') {
                                    gender = wardenGenders[v]!;
                                  } else {
                                    gender = v!;
                                  }
                                  hostel = '';
                                });
                              }
                            ),
                            _buildDropdownField(
                              Icons.apartment_rounded,
                              'Hostel',
                              hostel.isEmpty ? null : hostel,
                              hostelData[gender]!,
                              (v) => setState(() => hostel = v!)
                            ),
                          ],

                          _buildPasswordField(),
                         
                          const SizedBox(height: 32),
                          loading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                children: [
                                  const TextSpan(text: "Already have an account? "),
                                  TextSpan(
                                    text: "Login",
                                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(IconData icon, String label, Function(String) onChanged, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdownField(IconData icon, String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: onChanged,
        style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: !showPassword,
      onChanged: (v) => password = v,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      ),
      validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }
}
