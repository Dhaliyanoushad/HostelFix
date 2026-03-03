import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.build, color: Colors.blue),
            SizedBox(width: 8),
            Text("HostelFix", style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.userData != null) {
                return ElevatedButton(
                  onPressed: () {
                    String role = userProvider.userData!['role'];
                    if (role == 'Admin') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/admin-dashboard',
                      );
                    } else if (role == 'Warden') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/warden-dashboard',
                      );
                    } else if (role == 'Contractor') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/contractor-dashboard',
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  },
                  child: const Text("Go to Dashboard"),
                );
              }
              return Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/select-role');
                    },
                    child: const Text("Login"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/select-signup-role');
                    },
                    child: const Text("Get Started"),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HERO SECTION
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Chip(
                          label: Text("Simplifying Hostel Maintenance"),
                          backgroundColor: Color(0xFFE3F2FD),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Your Hostel Issue,\nSolved Faster",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Report issues instantly, track progress in real-time, "
                          "and enjoy a comfortable hostel life.",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/images/hostel.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// FEATURES
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  featureCard(
                    image: "assets/images/maintenance.jpg",
                    title: "Report Issues Instantly",
                    description:
                        "Submit maintenance complaints in just a few taps.",
                  ),
                  featureCard(
                    image: "assets/images/progress.jpg",
                    title: "Track Work Progress",
                    description: "Get real-time updates as work progresses.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget featureCard({
    required String image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: Image.asset(
                image,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
