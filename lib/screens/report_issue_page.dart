import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_fix/services/notification_service.dart';
import '../widgets/custom_widgets.dart';
import '../theme/app_theme.dart';

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

  String category = 'Electricity';
  String priority = 'normal';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("Report an Issue")),
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: GlassCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.report_gmailerrorred_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "New Support Ticket",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        shadows: [
                          Shadow(
                            color: Colors.redAccent.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (userData != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textFieldBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_pin_rounded,
                              color: AppColors.primaryAccent,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'Student',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Roll No: ${userData['studentId']}",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    CustomTextField(
                      label: "Room Number",
                      controller: roomController,
                      prefixIcon: Icons.door_front_door_rounded,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildDropdown(
                      label: "Issue Category",
                      value: category,
                      items: ['Electricity', 'Water', 'Cleaning', 'Other'],
                      onChanged: (v) => category = v!,
                    ),
                    const SizedBox(height: 16),

                    _buildPrioritySwitch(),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: "Issue Title",
                      controller: titleController,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: "Detailed Description",
                      controller: descriptionController,
                      prefixIcon: Icons.description_rounded,
                    ),
                    const SizedBox(height: 40),

                    NeonButton(
                      label: "SUBMIT TICKET",
                      onPressed: () => submitForm(userData),
                      isLoading: isLoading,
                      height: 60,
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
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.cardBg,
      style: const TextStyle(color: Colors.white),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.textFieldBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryAccent),
        ),
      ),
    );
  }

  Widget _buildPrioritySwitch() {
    bool isHigh = priority == 'high';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.textFieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => priority = 'normal'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isHigh
                      ? AppColors.primaryAccent.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Normal",
                    style: TextStyle(
                      color: !isHigh
                          ? AppColors.primaryAccent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => priority = 'high'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isHigh
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Emergency",
                    style: TextStyle(
                      color: isHigh
                          ? Colors.redAccent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submitForm(Map<String, dynamic>? userData) async {
    if (!_formKey.currentState!.validate()) return;
    if (userData == null) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'uid': userData['uid'],
        'studentName': userData['name'],
        'studentId': userData['uid'],
        'registerNumber': userData['studentId'],
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint submitted successfully ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }
}
