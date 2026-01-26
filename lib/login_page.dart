import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  // Simple breakpoint helpers
  bool get _isVerySmall => MediaQuery.of(context).size.width < 360;
  bool get _isSmall => MediaQuery.of(context).size.width < 420;
  bool get _isTabletLike => MediaQuery.of(context).size.width > 600;

  double get horizontalPadding => _isVerySmall ? 16.0 : _isSmall ? 20.0 : 28.0;
  double get verticalSpacingSmall => _isVerySmall ? 12.0 : _isSmall ? 16.0 : 20.0;
  double get verticalSpacingMedium => _isVerySmall ? 20.0 : _isSmall ? 24.0 : 32.0;
  double get logoSize => _isVerySmall ? 64.0 : _isSmall ? 72.0 : 88.0;
  double get headingSize => _isVerySmall ? 24.0 : _isSmall ? 28.0 : 32.0;
  double get subtitleSize => _isVerySmall ? 13.0 : _isSmall ? 14.0 : 15.0;
  double get buttonHeight => _isVerySmall ? 48.0 : _isSmall ? 52.0 : 56.0;
  double get googleIconSize => _isVerySmall ? 20.0 : 24.0;

  // ────────────────────────────────────────────────────────────────
  // Your auth logic (unchanged — paste your working versions here)
  // ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final confirm = _confirmPasswordController.text.trim();
        if (password != confirm) {
          setState(() => _errorMessage = "Passwords do not match");
          return;
        }

        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'displayName': user.displayName ?? email.split('@')[0],
          });
        }
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Authentication failed';
      switch (e.code) {
        case 'weak-password':
          msg = 'Password should be stronger (min 10–12 chars)';
          break;
        case 'email-already-in-use':
          msg = 'Email already registered';
          break;
        case 'invalid-email':
          msg = 'Invalid email format';
          break;
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          msg = 'Invalid email or password';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts — try later';
          break;
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset link sent — check inbox'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isTabletLike ? 480 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalSpacingSmall,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.indigo.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: logoSize * 0.55,
                      ),
                    ),

                    SizedBox(height: verticalSpacingMedium),

                    Text(
                      _isLoginMode ? "Welcome Back" : "Create Account",
                      style: GoogleFonts.poppins(
                        fontSize: headingSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.3,
                      ),
                    ),

                    SizedBox(height: verticalSpacingSmall),

                    Text(
                      _isLoginMode
                          ? "Sign in to your dashboard"
                          : "Start analyzing your customers",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: subtitleSize,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: verticalSpacingMedium),

                    // Google Button
                    _buildGoogleButton(),

                    SizedBox(height: verticalSpacingMedium),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: _isVerySmall ? 12 : 16),
                          child: Text(
                            "OR",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    SizedBox(height: verticalSpacingMedium),

                    // Form Fields
                    _buildFieldLabel("Email Address"),
                    SizedBox(height: verticalSpacingSmall / 2),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(hint: "you@example.com"),
                    ),

                    SizedBox(height: verticalSpacingSmall),

                    _buildFieldLabel("Password"),
                    SizedBox(height: verticalSpacingSmall / 2),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: _isLoginMode ? TextInputAction.done : TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!_isLoginMode && v.length < 10) return 'Min 10 characters';
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: "•••••••••••",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    if (!_isLoginMode) ...[
                      SizedBox(height: verticalSpacingSmall),
                      _buildFieldLabel("Confirm Password"),
                      SizedBox(height: verticalSpacingSmall / 2),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _passwordController.text) return "Doesn't match";
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: "•••••••••••",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                      ),
                    ],

                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: Text(
                            "Forgot password?",
                            style: GoogleFonts.poppins(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    if (_errorMessage != null) ...[
                      SizedBox(height: verticalSpacingSmall),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(color: Colors.red.shade800, fontSize: 13.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    SizedBox(height: verticalSpacingMedium),

                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                _isLoginMode ? "Sign In" : "Create Account",
                                style: GoogleFonts.poppins(
                                  fontSize: _isVerySmall ? 14.5 : 15.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: verticalSpacingMedium),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoginMode ? "Don't have an account? " : "Already have an account? ",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: _isVerySmall ? 13.5 : 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isLoginMode = !_isLoginMode;
                                    _errorMessage = null;
                                    _confirmPasswordController.clear();
                                    _formKey.currentState?.reset();
                                  });
                                },
                          child: Text(
                            _isLoginMode ? "Sign Up" : "Sign In",
                            style: GoogleFonts.poppins(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: _isVerySmall ? 13.5 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: verticalSpacingSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: buttonHeight - 4, // slightly smaller than main button
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _signInWithGoogle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                width: googleIconSize,
                height: googleIconSize,
                errorBuilder: (_, __, ___) => Icon(Icons.g_translate, size: googleIconSize),
              ),
              SizedBox(width: _isVerySmall ? 10 : 14),
              Text(
                "Continue with Google",
                style: GoogleFonts.poppins(
                  fontSize: _isVerySmall ? 13.5 : 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: _isVerySmall ? 14 : 16,
        vertical: _isVerySmall ? 14 : 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}