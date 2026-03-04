import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_fix/services/notification_service.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final studentIdController = TextEditingController();
  final roomController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String? hostelBlock;
  String category = 'Electricity';
  String priority = 'normal';

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text("Report an Issue")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Report a New Issue",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Show some info that it's being auto-filled
                  if (userData != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Text(
                            "Reporting as: ${userData['name']}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "Student ID: ${userData['studentId']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  buildTextField("Room Number", roomController),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Issue Category",
                    ),
                    initialValue: category,
                    items: ['Electricity', 'Water', 'Cleaning', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => category = value!,
                  ),

                  SwitchListTile(
                    title: const Text("Immediate (Emergency)"),
                    subtitle: const Text(
                      "Mark this as a high priority emergency",
                    ),
                    value: priority == 'high',
                    activeColor: Colors.redAccent,
                    onChanged: (bool value) {
                      setState(() {
                        priority = value ? 'high' : 'normal';
                      });
                    },
                    secondary: Icon(
                      priority == 'high'
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: priority == 'high' ? Colors.redAccent : null,
                    ),
                  ),

                  buildTextField("Issue Title", titleController),
                  buildTextField(
                    "Detailed Description",
                    descriptionController,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : () => submitForm(userData),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Issue"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required field' : null,
      ),
    );
  }

  Future<void> submitForm(Map<String, dynamic>? userData) async {
    if (!_formKey.currentState!.validate()) return;
    if (userData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User data not found")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'uid': userData['uid'], // For backward compatibility
        'studentName': userData['name'],
        'studentId': userData['uid'], // Firebase UID (Requirement)
        'registerNumber': userData['studentId'], // Roll Number
        'hostel': userData['hostel'],
        'department': userData['department'] ?? 'General',
        'room': roomController.text.trim(),
        'category': category,
        'priority': priority,
        'title': titleController.text.trim(),
        'issueDescription': descriptionController.text.trim(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (priority == 'high') {
        await NotificationService.showEmergencyNotification(
          title: "EMERGENCY: ${titleController.text.trim()}",
          body:
              "New high priority complaint from room ${roomController.text.trim()}",
        );
      } else {
        await NotificationService.showNotification(
          title: "New Complaint: ${titleController.text.trim()}",
          body:
              "A new complaint has been submitted from room ${roomController.text.trim()}",
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint submitted successfully ✅")),
      );

      Navigator.pop(context); // go back to dashboard or complaints page
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }
}
