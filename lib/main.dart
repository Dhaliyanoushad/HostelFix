import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

import 'screens/landing_page.dart';
import 'screens/select_role_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/select_signup_role_screen.dart';
import 'screens/dashboard_page.dart';
import 'screens/report_issue_page.dart';
import 'screens/my_complaints_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/warden_dashboard.dart';
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryAccent,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          centerTitle: true,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
            .copyWith(
              bodyLarge: const TextStyle(color: AppColors.textPrimary),
              bodyMedium: const TextStyle(color: AppColors.textSecondary),
            ),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppColors.primaryAccent,
          secondary: AppColors.secondaryAccent,
          surface: AppColors.cardBg,
          background: AppColors.background,
        ),
      ),
      initialRoute: '/',
      builder: (context, child) {
        return _AuthWrapper(child: child!);
      },
      routes: {
        '/': (context) => const LandingPage(),
        '/select-role': (context) => const SelectRoleScreen(),
        '/select-signup-role': (context) => const SelectSignupRoleScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/warden-dashboard': (context) => const WardenDashboard(),
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
      final userData = await AuthService()
          .fetchUserData(user.uid)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
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
