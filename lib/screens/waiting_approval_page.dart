import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/glass_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class WaitingApprovalPage extends StatefulWidget {
  const WaitingApprovalPage({super.key});

  @override
  State<WaitingApprovalPage> createState() => _WaitingApprovalPageState();
}

class _WaitingApprovalPageState extends State<WaitingApprovalPage> {
  bool refreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.timer_rounded, size: 80, color: Colors.orange),
                    const SizedBox(height: 24),
                    const Text(
                      "Approval Pending",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your account is currently under review. Please wait for an administrator or warden to verify your profile.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: refreshing ? null : () async {
                          setState(() => refreshing = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final userData = await AuthService().fetchUserData(user.uid);
                              if (userData != null && context.mounted) {
                                Provider.of<UserProvider>(context, listen: false).setUser(userData);
                                if (userData['approved'] == true) {
                                  Navigator.pushReplacementNamed(context, '/');
                                  return;
                                }
                              }
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Still pending... Please wait.")));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          } finally {
                            if (mounted) setState(() => refreshing = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: refreshing 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Check Status / Go Home"),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Provider.of<UserProvider>(context, listen: false).clearUser();
                          Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                        }
                      },
                      child: const Text("Logout"),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
