import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How HostelFix Works",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: const Text(
                "HostelFix is a streamlined platform to handle hostel maintenance. When you report an issue, it is sent to your Warden for review. Once approved, it's assigned to a specialized contractor (plumber, electrician, etc.) who will schedule a visit to fix it. You can track everything in real-time from your 'My Complaints' section.",
                style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Common Doubts (FAQs)",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              "How do I report a new complaint?",
              "Go to your dashboard and click 'Report Issue'. Fill in the details, select the category, set priority, and submit. You'll be notified when there's an update.",
            ),
            _buildFAQItem(
              context,
              "Why is my account still 'Pending'?",
              "Every student profile must be verified by the Hostel Warden to prevent fake reports. Please wait up to 24 hours for approval.",
            ),
            _buildFAQItem(
              context,
              "How long does it take to fix an issue?",
              "Emergency issues are usually prioritized within 24 hours. General maintenance depends on contractor availability, but you will see a 'Scheduled Visit' time once assigned.",
            ),
            _buildFAQItem(
              context,
              "What if my complaint is dismissed?",
              "If a complaint is marked as irrelevant or duplicate, the warden may dismiss it. You'll receive a notification explaining the status.",
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Text("Still need help?", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.email_outlined),
                    label: const Text("Contact Support Team"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                answer,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
