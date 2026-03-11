import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─── Design Tokens ───────────────────────────────────────────────
class _AppColors {
  // Deep navy + electric accent theme
  static const bg = Color(0xFF0A0E1A);
  static const surface = Color(0xFF111827);
  static const surfaceElevated = Color(0xFF1C2537);
  static const border = Color(0xFF263352);
  static const borderFocus = Color(0xFF4F7EFF);

  static const accentBlue = Color(0xFF4F7EFF);
  static const accentCyan = Color(0xFF00D4FF);
  static const accentPurple = Color(0xFF8B5CF6);

  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8A9BBE);
  static const textMuted = Color(0xFF4A5878);

  static const error = Color(0xFFFF6B6B);
  static const errorBg = Color(0xFF1A0F0F);
  static const success = Color(0xFF10D9A0);
}

// ─── Animated Gradient Orb ────────────────────────────────────────
class _AnimatedOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Offset offset;

  const _AnimatedOrb({
    required this.size,
    required this.color,
    required this.duration,
    required this.offset,
  });

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(
            widget.offset.dx * _anim.value,
            widget.offset.dy * math.sin(_anim.value * math.pi),
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(0.35),
                  widget.color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Rotating Ring Logo ───────────────────────────────────────────
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer spinning ring
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.rotate(
              angle: _ctrl.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(88, 88),
                painter: _RingPainter(),
              ),
            ),
          ),
          // Inner glow container
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_AppColors.accentBlue, _AppColors.accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _AppColors.accentBlue.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const SweepGradient(
        colors: [
          _AppColors.accentBlue,
          _AppColors.accentCyan,
          Colors.transparent,
        ],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Animated Field Wrapper ───────────────────────────────────────
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, required this.delay});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Main Login Page ──────────────────────────────────────────────
// ─── Custom Google "G" Logo ───────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // 4-colour segments of the Google "G"
    // Blue: top-right arc
    paint.color = const Color(0xFF4285F4);
    _arc(canvas, cx, cy, r, -math.pi / 12, math.pi * 7 / 12, paint);

    // Red: left arc
    paint.color = const Color(0xFFEA4335);
    _arc(canvas, cx, cy, r, math.pi * 7 / 12, math.pi * 13 / 12, paint);

    // Yellow: bottom-left arc
    paint.color = const Color(0xFFFBBC05);
    _arc(canvas, cx, cy, r, math.pi * 13 / 12, math.pi * 17 / 12, paint);

    // Green: bottom-right arc
    paint.color = const Color(0xFF34A853);
    _arc(canvas, cx, cy, r, math.pi * 17 / 12, math.pi * 23 / 12, paint);

    // Inner white/bg circle — creates the "C" ring shape
    paint.color = const Color(0xFF1C2537);
    canvas.drawCircle(Offset(cx, cy), r * 0.60, paint);

    // Blue horizontal crossbar of the G (right half)
    paint.color = const Color(0xFF4285F4);
    final barH = r * 0.30;
    canvas.drawRect(
      Rect.fromLTWH(cx - r * 0.02, cy - barH / 2, r * 1.02, barH),
      paint,
    );

    // Re-punch inner circle so bar only shows in the ring area
    paint.color = const Color(0xFF1C2537);
    canvas.drawCircle(Offset(cx, cy), r * 0.60, paint);

    // Restore the visible part of the bar (between inner and outer radius)
    paint.color = const Color(0xFF4285F4);
    final path = Path();
    path.addRect(Rect.fromLTWH(cx, cy - barH / 2, r * 0.40, barH));
    canvas.drawPath(path, paint);
  }

  void _arc(Canvas canvas, double cx, double cy, double r,
      double start, double end, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        end - start,
        false,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Main Login Page ──────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Mode switch animation
  late final AnimationController _modeCtrl;
  late final Animation<double> _modeAnim;

  @override
  void initState() {
    super.initState();
    _modeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _modeAnim = CurvedAnimation(parent: _modeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _modeCtrl.dispose();
    super.dispose();
  }

  // ─── Auth Logic ───────────────────────────────────────────────

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
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
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
          msg = 'Password should be at least 10 characters';
          break;
        case 'email-already-in-use':
          msg = 'This email is already registered';
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
          msg = 'Too many attempts — please try later';
          break;
      }
      setState(() => _errorMessage = msg);
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (_) {
      setState(() => _errorMessage = 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email address first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack('Reset link sent — check your inbox', success: true);
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13.5),
        ),
        backgroundColor:
            success ? _AppColors.success.withOpacity(0.9) : _AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _confirmPasswordController.clear();
      _formKey.currentState?.reset();
    });
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isTablet = screenW > 600;

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: Stack(
        children: [
          // Background ambient orbs
          Positioned(
            top: -80,
            left: -80,
            child: _AnimatedOrb(
              size: 320,
              color: _AppColors.accentBlue,
              duration: const Duration(seconds: 7),
              offset: const Offset(20, 0),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _AnimatedOrb(
              size: 280,
              color: _AppColors.accentPurple,
              duration: const Duration(seconds: 9),
              offset: const Offset(-15, 0),
            ),
          ),
          Positioned(
            top: 200,
            right: -40,
            child: _AnimatedOrb(
              size: 180,
              color: _AppColors.accentCyan,
              duration: const Duration(seconds: 11),
              offset: const Offset(-10, 0),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isTablet ? 480 : double.infinity),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40 : 24,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo
                        _FadeSlideIn(
                          delay: Duration.zero,
                          child: const _AnimatedLogo(),
                        ),

                        const SizedBox(height: 28),

                        // ── Brand badge
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: _AppColors.accentBlue.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(20),
                              color: _AppColors.accentBlue.withOpacity(0.08),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _AppColors.accentCyan,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Analytics Platform',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 11,
                                    color: _AppColors.accentCyan,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Heading
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isLoginMode ? 'Welcome Back' : 'Create Account',
                              key: ValueKey(_isLoginMode),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: _AppColors.textPrimary,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Subtitle
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isLoginMode
                                  ? 'Sign in to access your dashboard'
                                  : 'Start analyzing your customers today',
                              key: ValueKey('sub_$_isLoginMode'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 14.5,
                                color: _AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Google Button
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 250),
                          child: _buildGoogleButton(),
                        ),

                        const SizedBox(height: 24),

                        // ── Divider
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Colors.transparent,
                                      _AppColors.border,
                                    ]),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.dmMono(
                                    color: _AppColors.textMuted,
                                    fontSize: 11,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      _AppColors.border,
                                      Colors.transparent,
                                    ]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Email Field
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 350),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Email Address'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.dmSans(
                                    color: _AppColors.textPrimary,
                                    fontSize: 14.5),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(v.trim())) {
                                    return 'Invalid email address';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(
                                  hint: 'you@company.com',
                                  prefixIcon: const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 18,
                                    color: _AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Password Field
                        _FadeSlideIn(
                          delay: const Duration(milliseconds: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: _isLoginMode
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                style: GoogleFonts.dmSans(
                                    color: _AppColors.textPrimary,
                                    fontSize: 14.5),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (!_isLoginMode && v.length < 10) {
                                    return 'Must be at least 10 characters';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(
                                  hint: '••••••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: _AppColors.textMuted,
                                  ),
                                  suffixIcon: _visibilityToggle(
                                    obscure: _obscurePassword,
                                    onTap: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Confirm Password (sign up only)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          child: _isLoginMode
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 18),
                                    _fieldLabel('Confirm Password'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      textInputAction: TextInputAction.done,
                                      style: GoogleFonts.dmSans(
                                          color: _AppColors.textPrimary,
                                          fontSize: 14.5),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (v != _passwordController.text) {
                                          return "Passwords don't match";
                                        }
                                        return null;
                                      },
                                      decoration: _inputDecoration(
                                        hint: '••••••••••••',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 18,
                                          color: _AppColors.textMuted,
                                        ),
                                        suffixIcon: _visibilityToggle(
                                          obscure: _obscureConfirmPassword,
                                          onTap: () => setState(() =>
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        // ── Forgot password
                        if (_isLoginMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 12),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.dmSans(
                                  color: _AppColors.accentBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 20),

                        // ── Error Banner
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _errorMessage == null
                              ? const SizedBox.shrink()
                              : Container(
                                  width: double.infinity,
                                  margin:
                                      const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: _AppColors.errorBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _AppColors.error
                                            .withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: _AppColors.error,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.dmSans(
                                            color: _AppColors.error,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),

                        // ── Primary CTA Button
                        _buildPrimaryButton(),

                        const SizedBox(height: 28),

                        // ── Mode Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLoginMode
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: GoogleFonts.dmSans(
                                color: _AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : _switchMode,
                              child: Text(
                                _isLoginMode ? 'Sign Up' : 'Sign In',
                                style: GoogleFonts.dmSans(
                                  color: _AppColors.accentBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _AppColors.accentBlue
                                      .withOpacity(0.4),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Footer
                        Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: _AppColors.textMuted,
                            fontSize: 11.5,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widget Builders ──────────────────────────────────────────

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isLoading ? null : _signInWithGoogle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleLogo(size: 22),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _isLoading
            ? LinearGradient(
                colors: [
                  _AppColors.accentBlue.withOpacity(0.5),
                  _AppColors.accentPurple.withOpacity(0.5)
                ],
              )
            : const LinearGradient(
                colors: [_AppColors.accentBlue, _AppColors.accentPurple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: _AppColors.accentBlue.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isLoading ? null : _handleSubmit,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLoginMode ? 'Sign In' : 'Create Account',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _visibilityToggle(
      {required bool obscure, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey(obscure),
            color: _AppColors.textMuted,
            size: 18,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        color: _AppColors.textMuted,
        fontSize: 14,
      ),
      filled: true,
      fillColor: _AppColors.surface,
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: prefixIcon,
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: _AppColors.borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: _AppColors.error.withOpacity(0.7), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.error, width: 1.5),
      ),
      errorStyle: GoogleFonts.dmSans(
        color: _AppColors.error,
        fontSize: 12,
      ),
    );
  }
}