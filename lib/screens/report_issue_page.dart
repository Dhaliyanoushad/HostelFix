import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_fix/services/notification_service.dart';

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
  String? imageUrl;

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

                    _buildField(icon: Icons.meeting_room_rounded, label: "Room Number", controller: roomController),
                    
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

                    _buildField(icon: Icons.title_rounded, label: "Short Title", controller: titleController),
                    _buildField(icon: Icons.description_rounded, label: "Details of Issue", controller: descriptionController, maxLines: 4),
                    _buildField(icon: Icons.link_rounded, label: "Image URL (Optional)", controller: TextEditingController(text: imageUrl), onChangedCallback: (v) => imageUrl = v, validator: (v) => null),


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

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    Function(String)? onChangedCallback,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChangedCallback,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
        validator: validator ?? (value) => value == null || value.isEmpty ? 'Required field' : null,
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
        'imageUrl': imageUrl?.trim(),
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
