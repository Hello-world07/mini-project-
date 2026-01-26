import 'package:flutter/material.dart';

class ProjectIntroPage extends StatefulWidget {
  const ProjectIntroPage({super.key});

  @override
  State<ProjectIntroPage> createState() => _ProjectIntroPageState();
}

class _ProjectIntroPageState extends State<ProjectIntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔹 App Logo
                Image.asset(
                  "assets/images/logo.png",
                  height: 130,
                ),

                const SizedBox(height: 25),

                // 🔹 Main Title
                Text(
                  "Mini Project",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),

                const SizedBox(height: 15),

                // 🔹 Project Title
                const Text(
                  "Customer Segmentation &\nSentiment Analysis of Customer Reviews",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 Description
                const Text(
                  "This project analyzes customer behavior and reviews using:\n\n"
                  "• K-Means Clustering\n"
                  "• Sentiment Analysis (ML)\n"
                  "• CSV File Upload\n"
                  "• Professional Charts & Dashboard\n",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),

                const SizedBox(height: 40),

                // 🔹 Continue Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 45,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
