import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/landing_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/report_issue_page.dart';
import 'screens/my_complaints_page.dart';

import 'services/notification_service.dart';

import 'screens/admin_dashboard.dart';
import 'screens/matron_dashboard.dart';
import 'screens/contractor_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const HostelFixApp());
}

class HostelFixApp extends StatelessWidget {
  const HostelFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HostelFix',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/matron-dashboard': (context) => const MatronDashboard(),
        '/contractor-dashboard': (context) => const ContractorDashboard(),
        '/report-issue': (context) => const ReportIssuePage(),
        '/my-complaints': (context) => const MyComplaintsPage(),
      },
    );
  }
}
