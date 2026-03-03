import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

import 'screens/landing_page.dart';
import 'screens/select_role_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/report_issue_page.dart';
import 'screens/my_complaints_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/matron_dashboard.dart';
import 'screens/contractor_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const HostelFixApp(),
    ),
  );
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
      builder: (context, child) {
        return _AuthWrapper(child: child!);
      },
      routes: {
        '/': (context) => const LandingPage(),
        '/select-role': (context) => const SelectRoleScreen(),
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

class _AuthWrapper extends StatefulWidget {
  final Widget child;
  const _AuthWrapper({required this.child});

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await AuthService().fetchUserData(user.uid);
      if (userData != null && mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(userData);
      }
    }
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
