import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "title": "Your Hostel Issue,\nSolved Faster",
      "subtitle": "Report issues instantly, track progress in real-time, and enjoy a comfortable hostel life.",
      "icon": Icons.bolt_rounded,
      "color": Color(0xFF2563EB),
      "chip": "PRO MAINTENANCE",
    },
    {
      "title": "Verified Staff &\nQuick Response",
      "subtitle": "Professional contractors assigned by wardens to ensure high-quality fixes within 24 hours.",
      "icon": Icons.verified_user_rounded,
      "color": Color(0xFF10B981),
      "chip": "TRUSTED SERVICE",
    },
    {
      "title": "Real-time Tracking\n& Transparency",
      "subtitle": "Stay updated with live status changes and direct communication with maintenance teams.",
      "icon": Icons.track_changes_rounded,
      "color": Color(0xFF8B5CF6),
      "chip": "LIVE UPDATES",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.build_circle_rounded, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Text(
              "HostelFix",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          const SizedBox(width: 8),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.userData != null) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: () => _navigateToDashboard(context, userProvider.userData!),
                    child: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated Background Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _slides[_currentPage]['color'].withOpacity(0.08),
                  Theme.of(context).scaffoldBackgroundColor,
                  _slides[_currentPage]['color'].withOpacity(0.05),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) => setState(() => _currentPage = page),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: slide['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(slide['icon'], size: 100, color: slide['color']),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Chip(
                              label: Text(slide['chip'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              backgroundColor: slide['color'].withOpacity(0.1),
                              labelStyle: TextStyle(color: slide['color']),
                              side: BorderSide.none,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              slide['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide['subtitle'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Indicators and Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? slideActiveColor : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/select-signup-role'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: slideActiveColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: slideActiveColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (_currentPage < _slides.length - 1) {
                                  _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                                } else {
                                  _pageController.animateToPage(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
                                }
                              },
                              icon: const Icon(Icons.arrow_forward_rounded),
                              color: slideActiveColor,
                              padding: const EdgeInsets.all(18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get slideActiveColor => _slides[_currentPage]['color'];

  void _navigateToDashboard(BuildContext context, Map<String, dynamic> userData) {
    if (userData['approved'] == false) {
      Navigator.pushReplacementNamed(context, '/waiting-approval');
      return;
    }

    String role = userData['role'];
    if (role == 'Admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (role == 'Warden') {
      Navigator.pushReplacementNamed(context, '/warden-dashboard');
    } else if (role == 'Contractor') {
      Navigator.pushReplacementNamed(context, '/contractor-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}
