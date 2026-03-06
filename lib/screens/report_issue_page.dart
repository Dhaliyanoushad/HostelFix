import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_fix/services/notification_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();

  final roomController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = 'Electrician';
  String priority = 'normal';
  bool isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Image Source", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerOption(Icons.camera_alt_rounded, "Camera", () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _pickerOption(Icons.photo_library_rounded, "Gallery", () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
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
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Report", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Maintenance Request",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                "Please provide accurate details for faster resolution.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 32),
              
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (userData != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Icon(Icons.person_rounded, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userData['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("ID: ${userData['studentId']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ],
                        ),
                      ),

                    _buildField(Icons.meeting_room_rounded, "Room Number", roomController),
                    
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Issue Category",
                        prefixIcon: const Icon(Icons.category_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      ),
                      value: 'Electrician',
                      items: ['Electrician', 'Plumber', 'Carpenter', 'Painter', 'Cleaning', 'Other']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => category = value!,
                    ),
                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                         color: priority == 'high' ? Colors.red.withOpacity(0.05) : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                         borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        title: const Text("Emergency Proceeding", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Mark for immediate high-priority attention"),
                        value: priority == 'high',
                        activeColor: Colors.redAccent,
                        onChanged: (bool value) {
                          setState(() => priority = value ? 'high' : 'normal');
                        },
                        secondary: Icon(
                          priority == 'high' ? Icons.report_problem_rounded : Icons.info_outline_rounded,
                          color: priority == 'high' ? Colors.redAccent : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(Icons.title_rounded, "Short Title", titleController),
                    _buildField(Icons.description_rounded, "Details of Issue", descriptionController, maxLines: 4),

                    const SizedBox(height: 20),
                    const Text("Attach Photo (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showImagePicker(context),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, size: 40, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                                  const SizedBox(height: 8),
                                  Text("Click to upload JPG/JPEG", style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.5), fontSize: 13)),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => submitForm(userData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: priority == 'high' ? Colors.redAccent : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Submit Maintenance Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
      ),
    );
  }

  Future<void> submitForm(Map<String, dynamic>? userData) async {
    if (!_formKey.currentState!.validate()) return;
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User session lost. Please login again.")));
      return;
    }

    setState(() => isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('complaint_images')
            .child('${userData['uid']}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('complaints').add({
        'uid': userData['uid'],
        'name': userData['name'],
        'studentName': userData['name'],
        'studentId': userData['uid'],
        'registerNumber': userData['studentId'],
        'hostel': userData['hostel'],
        'department': userData['department'] ?? 'General',
        'room': roomController.text.trim(),
        'studentPhone': userData['phone'] ?? 'N/A',
        'category': category,
        'priority': priority,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'issueDescription': descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.showNotification(
        title: "New Report: $category",
        body: "A new ${category.toLowerCase()} issue has been reported in ${userData['hostel']}.",
        color: Theme.of(context).primaryColor,
      );

      if (priority == 'high') {
        await NotificationService.showEmergencyNotification(
          title: "EMERGENCY: ${titleController.text.trim()}",
          body: "New high priority complaint from room ${roomController.text.trim()} in ${userData['hostel']}",
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint submitted successfully ✅")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission failed: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
