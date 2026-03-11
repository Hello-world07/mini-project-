import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens ────────────────────────────────────────────────
class _T {
  // Backgrounds
  static const bg = Color(0xFF060912);
  static const surface = Color(0xFF0F1524);
  static const card = Color(0xFF141D2E);
  static const cardHover = Color(0xFF1A2438);
  static const border = Color(0xFF1E2D47);
  static const borderAccent = Color(0xFF2A4070);

  // Accents
  static const blue = Color(0xFF4F7EFF);
  static const blueDark = Color(0xFF3A65E0);
  static const cyan = Color(0xFF00D4FF);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF10D9A0);
  static const amber = Color(0xFFFFB800);

  // Text
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8A9BBE);
  static const textMuted = Color(0xFF3D4F6B);

  // Gradients
  static const gradientMain = LinearGradient(
    colors: [blue, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// ─── Responsive helpers ───────────────────────────────────────────
class _Screen {
  static bool isSmall(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < 380;
  static bool isMedium(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < 480;
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600;

  static double hPad(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < 360) return 16;
    if (w < 420) return 20;
    if (w < 600) return 24;
    return 40;
  }

  static double headingSize(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < 360) return 22;
    if (w < 420) return 26;
    if (w < 600) return 30;
    return 34;
  }

  static double subSize(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < 360) return 12;
    if (w < 420) return 13.5;
    return 15;
  }

  static double logoSize(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < 360) return 72;
    if (w < 420) return 84;
    if (w < 600) return 96;
    return 110;
  }

  static double ringSize(BuildContext ctx) => logoSize(ctx) * 1.55;
}

// ─── Ambient Orb ─────────────────────────────────────────────────
class _Orb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Offset drift;

  const _Orb({
    required this.size,
    required this.color,
    required this.duration,
    required this.drift,
  });

  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.translate(
        offset: Offset(
          widget.drift.dx * _c.value,
          widget.drift.dy * math.sin(_c.value * math.pi),
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              widget.color.withOpacity(0.28),
              widget.color.withOpacity(0.0),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Dashed Spinning Ring ─────────────────────────────────────────
class _SpinRing extends StatefulWidget {
  final double radius;
  final Color color;
  final int dashes;
  final bool reverse;
  final Duration duration;

  const _SpinRing({
    required this.radius,
    required this.color,
    this.dashes = 28,
    this.reverse = false,
    this.duration = const Duration(seconds: 12),
  });

  @override
  State<_SpinRing> createState() => _SpinRingState();
}

class _SpinRingState extends State<_SpinRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.rotate(
        angle: (widget.reverse ? -1 : 1) * _c.value * 2 * math.pi,
        child: CustomPaint(
          size: Size(widget.radius * 2, widget.radius * 2),
          painter: _DashPainter(color: widget.color, dashes: widget.dashes),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  final int dashes;
  const _DashPainter({required this.color, required this.dashes});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1.5;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final step = (2 * math.pi) / dashes;
    for (int i = 0; i < dashes; i++) {
      final s = i * step;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        s, step * 0.45, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Reveal animation ─────────────────────────────────────────────
class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const _Reveal({
    required this.child,
    required this.delay,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
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

// ─── Feature Row Card ─────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final Duration delay;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.delay,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final small = _Screen.isSmall(context);

    return _Reveal(
      delay: widget.delay,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 16,
            vertical: small ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color.withOpacity(0.07)
                : _T.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? widget.color.withOpacity(0.45)
                  : _T.border,
              width: 1.2,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: small ? 36 : 42,
                height: small ? 36 : 42,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: widget.color.withOpacity(0.25)),
                ),
                child: Icon(widget.icon,
                    color: widget.color, size: small ? 18 : 21),
              ),
              SizedBox(width: small ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.dmSans(
                        color: _T.textPrimary,
                        fontSize: small ? 13 : 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.desc,
                      style: GoogleFonts.dmSans(
                        color: _T.textSecondary,
                        fontSize: small ? 11.5 : 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: widget.color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Pill ────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final small = _Screen.isSmall(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: small ? 10 : 13,
          horizontal: small ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                color: color,
                fontSize: small ? 15 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: _T.textSecondary,
                fontSize: small ? 9.5 : 10.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Page ────────────────────────────────────────────────────
class ProjectIntroPage extends StatefulWidget {
  const ProjectIntroPage({super.key});

  @override
  State<ProjectIntroPage> createState() => _ProjectIntroPageState();
}

class _ProjectIntroPageState extends State<ProjectIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = _Screen.hPad(context);
    final isTablet = _Screen.isTablet(context);
    final logoSz = _Screen.logoSize(context);
    final ringSz = _Screen.ringSize(context);

    return Scaffold(
      backgroundColor: _T.bg,
      body: Stack(
        children: [
          // ── Ambient orbs (scaled to screen)
          Positioned(top: -size.height * 0.12, left: -size.width * 0.2,
            child: _Orb(size: size.width * 0.85, color: _T.blue,
                duration: const Duration(seconds: 8),
                drift: const Offset(18, 0))),
          Positioned(bottom: -size.height * 0.10, right: -size.width * 0.18,
            child: _Orb(size: size.width * 0.75, color: _T.purple,
                duration: const Duration(seconds: 10),
                drift: const Offset(-14, 0))),
          Positioned(top: size.height * 0.35, right: -size.width * 0.08,
            child: _Orb(size: size.width * 0.50, color: _T.cyan,
                duration: const Duration(seconds: 7),
                drift: const Offset(-10, 0))),

          // ── Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isTablet ? 520 : double.infinity),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          hPad, 16, hPad, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── Top Bar: badge + version
                          _Reveal(
                            delay: Duration.zero,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _LiveBadge(pulse: _pulse),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _T.card,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _T.border),
                                  ),
                                  child: Text(
                                    'v1.0.0',
                                    style: GoogleFonts.dmMono(
                                      color: _T.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.03),

                          // ── Hero section: Logo + rings + title
                          _Reveal(
                            delay: const Duration(milliseconds: 100),
                            child: _HeroSection(
                              pulse: _pulse,
                              logoSize: logoSz,
                              ringSize: ringSz,
                            ),
                          ),

                          SizedBox(height: size.height * 0.025),

                          // ── Gradient headline
                          _Reveal(
                            delay: const Duration(milliseconds: 180),
                            child: ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [_T.cyan, _T.blue, _T.purple],
                                stops: [0.0, 0.45, 1.0],
                              ).createShader(b),
                              child: Text(
                                'Customer\nIntelligence',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: _Screen.headingSize(context),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Subtitle
                          _Reveal(
                            delay: const Duration(milliseconds: 230),
                            child: Text(
                              'Segmentation & Sentiment Analysis\nof Customer Reviews',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: _Screen.subSize(context),
                                color: _T.textSecondary,
                                height: 1.55,
                              ),
                            ),
                          ),

                          SizedBox(height: size.height * 0.025),

                          // ── Stats row
                          _Reveal(
                            delay: const Duration(milliseconds: 300),
                            child: Row(
                              children: [
                                _StatPill(value: 'K-Means', label: 'Clustering\nAlgorithm', color: _T.blue),
                                const SizedBox(width: 8),
                                _StatPill(value: 'ML', label: 'Sentiment\nAnalysis', color: _T.purple),
                                const SizedBox(width: 8),
                                _StatPill(value: 'Live', label: 'Real-time\nDashboard', color: _T.green),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.03),

                          // ── Section label
                          _Reveal(
                            delay: const Duration(milliseconds: 360),
                            child: Row(
                              children: [
                                Container(
                                    width: 3, height: 14,
                                    decoration: BoxDecoration(
                                      color: _T.blue,
                                      borderRadius: BorderRadius.circular(2),
                                    )),
                                const SizedBox(width: 10),
                                Text(
                                  'CORE CAPABILITIES',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 11,
                                    color: _T.textMuted,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Feature cards
                          _FeatureCard(
                            icon: Icons.hub_outlined,
                            color: _T.blue,
                            title: 'K-Means Clustering',
                            desc: 'Segment customers by behavioral patterns',
                            delay: const Duration(milliseconds: 420),
                          ),
                          _FeatureCard(
                            icon: Icons.psychology_alt_outlined,
                            color: _T.purple,
                            title: 'Sentiment Analysis (ML)',
                            desc: 'ML-powered review emotion classification',
                            delay: const Duration(milliseconds: 480),
                          ),
                          _FeatureCard(
                            icon: Icons.upload_file_outlined,
                            color: _T.cyan,
                            title: 'CSV File Upload',
                            desc: 'Import & process datasets instantly',
                            delay: const Duration(milliseconds: 540),
                          ),
                          _FeatureCard(
                            icon: Icons.bar_chart_rounded,
                            color: _T.green,
                            title: 'Professional Charts',
                            desc: 'Interactive dashboard & visualizations',
                            delay: const Duration(milliseconds: 600),
                          ),

                          SizedBox(height: size.height * 0.03),

                          // ── CTA Button
                          _Reveal(
                            delay: const Duration(milliseconds: 660),
                            child: _CTAButton(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Footer
                          _Reveal(
                            delay: const Duration(milliseconds: 720),
                            child: Center(
                              child: Text(
                                'Flutter · Firebase · Machine Learning',
                                style: GoogleFonts.dmMono(
                                  color: _T.textMuted,
                                  fontSize: 10.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  final Animation<double> pulse;
  const _LiveBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _T.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _T.cyan.withOpacity(0.5 + 0.5 * pulse.value),
                boxShadow: [
                  BoxShadow(
                    color: _T.cyan.withOpacity(0.5 * pulse.value),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'MINI PROJECT  ·  2026',
            style: GoogleFonts.dmMono(
              fontSize: 10.5,
              color: _T.cyan,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Section (Logo + rings) ──────────────────────────────────
class _HeroSection extends StatelessWidget {
  final Animation<double> pulse;
  final double logoSize;
  final double ringSize;

  const _HeroSection({
    required this.pulse,
    required this.logoSize,
    required this.ringSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ringSize,
        height: ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer dashed ring
            _SpinRing(
              radius: ringSize / 2,
              color: _T.blue.withOpacity(0.3),
              dashes: 32,
              duration: const Duration(seconds: 12),
            ),
            // Inner reverse ring
            _SpinRing(
              radius: ringSize * 0.38,
              color: _T.purple.withOpacity(0.28),
              dashes: 18,
              reverse: true,
              duration: const Duration(seconds: 16),
            ),
            // Logo circle with glow
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _T.surface,
                  border: Border.all(color: _T.borderAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _T.blue
                          .withOpacity(0.3 + 0.15 * pulse.value),
                      blurRadius: 24 + 10 * pulse.value,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _T.purple.withOpacity(0.15 * pulse.value),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                // ── App logo from assets
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_T.blue, _T.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CTA Button ───────────────────────────────────────────────────
class _CTAButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CTAButton({required this.onTap});

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (_, child) => Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: _pressed
                    ? [
                        _T.blue.withOpacity(0.6),
                        _T.purple.withOpacity(0.6)
                      ]
                    : [_T.blue, _T.purple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: _T.blue.withOpacity(0.40),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer overlay
              AnimatedBuilder(
                animation: _shimmer,
                builder: (_, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Align(
                      alignment: Alignment(
                          -1.5 + 3.0 * _shimmer.value, 0),
                      child: Container(
                        width: 60,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}