import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'customer_segmentation_page.dart';
import 'history_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Slide-from-top animation
  Route _slideFromTop(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0, -0.25);
        const end = Offset.zero;

        final slide = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        final fade = Tween<double>(begin: 0, end: 1);

        return SlideTransition(
          position: animation.drive(slide),
          child: FadeTransition(
            opacity: animation.drive(fade),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // SCREEN SIZE
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // RESPONSIVE MULTIPLIERS
    double textScale = (width / 390).clamp(0.8, 1.0);   // iPhone 12 size reference
    double paddingScale = (width / 390).clamp(0.85, 1.0);
    double iconScale = (width / 390).clamp(0.8, 1.0);

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Dashboard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 23 * textScale,
            color: Colors.indigo.shade800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.red.shade600,
              size: 25 * iconScale,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: EdgeInsets.all(22 * paddingScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // GREETING
            Text(
              "Hello, $userName 👋",
              style: GoogleFonts.poppins(
                fontSize: 28 * textScale,
                fontWeight: FontWeight.w800,
                color: Colors.indigo.shade900,
              ),
            ),

            SizedBox(height: 6 * paddingScale),

            Text(
              "Welcome back! Explore your analytics and insights.",
              style: GoogleFonts.poppins(
                fontSize: 15 * textScale,
                color: Colors.grey.shade700,
              ),
            ),

            SizedBox(height: 28 * paddingScale),

            // OVERVIEW CARD
            _overviewCard(textScale, paddingScale, iconScale),

            SizedBox(height: 32 * paddingScale),

            Text(
              "Features",
              style: GoogleFonts.poppins(
                fontSize: 21 * textScale,
                fontWeight: FontWeight.w700,
                color: Colors.indigo.shade900,
              ),
            ),

            SizedBox(height: 16 * paddingScale),

            // FEATURE CARDS
            _featureCard(
              icon: Icons.people_alt_rounded,
              title: "Customer Segmentation",
              description: "Cluster customers using ML for insights.",
              color: Colors.blue,
              textScale: textScale,
              paddingScale: paddingScale,
              iconScale: iconScale,
              onTap: () {
                Navigator.push(
                  context,
                  _slideFromTop(const CustomerSegmentationPage()),
                );
              },
            ),

            _featureCard(
              icon: Icons.sentiment_satisfied_alt_rounded,
              title: "Sentiment Analysis",
              description: "Analyze customer reviews using NLP.",
              color: Colors.teal,
              textScale: textScale,
              paddingScale: paddingScale,
              iconScale: iconScale,
            ),

            _featureCard(
              icon: Icons.history_rounded,
              title: "Upload History",
              description: "View your recent CSV uploads.",
              color: Colors.deepPurple,
              textScale: textScale,
              paddingScale: paddingScale,
              iconScale: iconScale,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),

            SizedBox(height: 40 * paddingScale),

            Center(
              child: Text(
                "© 2026 Customer Intelligence Platform",
                style: GoogleFonts.poppins(
                  fontSize: 13 * textScale,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- CARDS ----------------

  Widget _overviewCard(double textScale, double paddingScale, double iconScale) {
    return Container(
      padding: EdgeInsets.all(22 * paddingScale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.indigo.shade500, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 25,
            offset: const Offset(0, 10),
            color: Colors.indigo.shade200.withOpacity(0.5),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded,
              size: 42 * iconScale, color: Colors.white),
          SizedBox(width: 18 * paddingScale),
          Expanded(
            child: Text(
              "AI-powered Customer Intelligence Platform",
              style: GoogleFonts.poppins(
                fontSize: 18 * textScale,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required double textScale,
    required double paddingScale,
    required double iconScale,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 20 * paddingScale),
        padding: EdgeInsets.all(20 * paddingScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              color: color.withOpacity(0.15),
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(18 * paddingScale),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 32 * iconScale, color: color),
            ),

            SizedBox(width: 18 * paddingScale),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18 * textScale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1D),
                    ),
                  ),
                  SizedBox(height: 5 * paddingScale),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5 * textScale,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios_rounded,
                size: 18 * iconScale, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
