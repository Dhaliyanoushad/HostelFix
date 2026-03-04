import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: "Welcome to\nHostelFix",
      description:
          "Step into the future of hostel living. Reliable maintenance and seamless care, all in one place.",
      image: "assets/images/onboarding_welcome.png",
      icon: Icons.auto_awesome_rounded,
    ),
    OnboardingData(
      title: "Utilities Handled\nLife Continues",
      description:
          "Manage your property account, track consumption, spending and elevate your lifestyle.",
      image: "assets/images/onboarding_report.png",
      icon: Icons.plumbing_rounded,
    ),
    OnboardingData(
      title: "Real-time Insight\nTrack Everything",
      description:
          "Monitor the pulse of your maintenance requests with precision and transparency.",
      image: "assets/images/onboarding_track.png",
      icon: Icons.insights_rounded,
    ),
    OnboardingData(
      title: "Seamless Network\nCampus Care",
      description:
          "Fast communication bridges the gap between students, wardens and repair teams.",
      image: "assets/images/onboarding_connect.png",
      icon: Icons.hub_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B3E), Color(0xFF000000)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_slides[index]);
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Text(
            "HostelFix",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            data.title,
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            data.description,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Center(
            child: Image.asset(
              data.image,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Return an iconic representation if asset fails to load
                return Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 50,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, size: 100, color: Colors.blue),
                );
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 50),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 4,
                width: _currentPage == index ? 15 : 4,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.blueAccent
                      : Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/select-signup-role'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Get Started",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Login",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}
