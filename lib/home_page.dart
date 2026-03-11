import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'customer_segmentation_page.dart';
import 'sentiment_analysis.dart';
import 'history_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// THEME  ·  Design tokens for light & dark
// ═══════════════════════════════════════════════════════════════════════════════

abstract final class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _brand      = Color(0xFF4F6AF0);
  static const Color _brandDeep  = Color(0xFF3451D1);
  static const Color _brandGlow  = Color(0xFF7B93F7);

  static const Color _teal   = Color(0xFF0EA5B0);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _amber  = Color(0xFFF59E0B);

  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light {
    const background = Color(0xFFF0F2FA);
    const surface    = Colors.white;
    const onSurface  = Color(0xFF111827);

    return ThemeData(
      useMaterial3:            true,
      brightness:              Brightness.light,
      colorSchemeSeed:         _brand,
      scaffoldBackgroundColor: background,
      cardColor:               surface,
      textTheme:               _textTheme(onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor:        surface,
        surfaceTintColor:       Colors.transparent,
        scrolledUnderElevation: 0.5,
        elevation:              0,
        systemOverlayStyle:     SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w800, color: onSurface,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
    );
  }

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const background = Color(0xFF0D0F18);
    const surface    = Color(0xFF161927);
    const onSurface  = Color(0xFFE8EAFF);

    return ThemeData(
      useMaterial3:            true,
      brightness:              Brightness.dark,
      colorSchemeSeed:         _brandGlow,
      scaffoldBackgroundColor: background,
      cardColor:               surface,
      textTheme:               _textTheme(onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor:        surface,
        surfaceTintColor:       Colors.transparent,
        scrolledUnderElevation: 0.5,
        elevation:              0,
        systemOverlayStyle:     SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w800, color: onSurface,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
    );
  }

  static TextTheme _textTheme(Color base) =>
      GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: base),
          bodyLarge:    TextStyle(color: base),
          bodyMedium:   TextStyle(color: base.withValues(alpha: 0.75)),
        ),
      );

  // ── Exposed accent tokens ─────────────────────────────────────────────────
  static Color brand(bool dark)     => dark ? _brandGlow : _brandDeep;

  static const List<_FeatureStyle> featureStyles = [
    _FeatureStyle(
      accent:    _brand,
      darkAccent: _brandGlow,
      fillLight:  Color(0xFFEBEEFF),
      fillDark:   Color(0xFF1A2040),
    ),
    _FeatureStyle(
      accent:    _teal,
      darkAccent: Color(0xFF2DD4DC),
      fillLight:  Color(0xFFE6F9FA),
      fillDark:   Color(0xFF0D2729),
    ),
    _FeatureStyle(
      accent:    _violet,
      darkAccent: Color(0xFFA78BFA),
      fillLight:  Color(0xFFF3EEFF),
      fillDark:   Color(0xFF1E1340),
    ),
  ];

  static const Color statBlue  = Color(0xFF3B82F6);
  static const Color statGreen = Color(0xFF10B981);
  static const Color statAmber = _amber;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

final class _FeatureStyle {
  const _FeatureStyle({
    required this.accent,
    required this.darkAccent,
    required this.fillLight,
    required this.fillDark,
  });
  final Color accent, darkAccent, fillLight, fillDark;

  Color resolveAccent(bool isDark) => isDark ? darkAccent : accent;
  Color resolveFill(bool isDark)   => isDark ? fillDark   : fillLight;
}

final class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.destination,
  });
  final IconData icon;
  final String   title, description, badge;
  final Widget   destination;
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  bool get isDark => value == ThemeMode.dark;

  void toggle() {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
    HapticFeedback.lightImpact();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP ROOT  ·  Wrap your MaterialApp with this
// ═══════════════════════════════════════════════════════════════════════════════

class CustomerIntelligenceApp extends StatelessWidget {
  CustomerIntelligenceApp({super.key});

  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title:     'Customer Intelligence',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme:     AppTheme.light,
        darkTheme: AppTheme.dark,
        home:      HomePage(themeNotifier: _themeNotifier),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOME PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.themeNotifier});

  final ThemeNotifier themeNotifier;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  static const List<_FeatureItem> _features = [
    _FeatureItem(
      icon:        Icons.people_alt_rounded,
      title:       'Customer Segmentation',
      description: 'Cluster customers with ML for actionable insights.',
      badge:       'ML',
      destination: CustomerSegmentationPage(),
    ),
    _FeatureItem(
      icon:        Icons.sentiment_satisfied_alt_rounded,
      title:       'Sentiment Analysis',
      description: 'Analyze customer reviews using advanced NLP.',
      badge:       'NLP',
      destination: CustomerAnalysisPage(),
    ),
    _FeatureItem(
      icon:        Icons.history_rounded,
      title:       'Upload History',
      description: 'Browse and manage all your CSV upload sessions.',
      badge:       'NEW',
      destination: HistoryPage(),
    ),
  ];

  late final AnimationController        _masterCtrl;
  late final List<Animation<double>>    _anims;

  // slots: 0=greeting, 1=banner, 2=stats, 3-5=feature cards
  static const int _slots = 6;

  @override
  void initState() {
    super.initState();
    _masterCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1500),
    );

    _anims = List.generate(_slots, (i) {
      final start = (i * 0.11).clamp(0.0, 0.68);
      final end   = (start + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _masterCtrl,
        curve:  Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final user     = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@').first ?? 'User';
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
        children: [

          _FadeSlide(animation: _anims[0],
            child: _GreetingSection(userName: userName, isDark: isDark)),

          const SizedBox(height: 28),

          _FadeSlide(animation: _anims[1],
            child: _BannerCard(isDark: isDark)),

          const SizedBox(height: 28),

          _FadeSlide(animation: _anims[2],
            child: _StatsRow(isDark: isDark)),

          const SizedBox(height: 32),

          _FadeSlide(animation: _anims[2],
            child: _SectionHeader(label: 'Features', isDark: isDark)),

          const SizedBox(height: 16),

          ..._features.asMap().entries.map((e) {
            final style = AppTheme.featureStyles[e.key];
            return _FadeSlide(
              animation: _anims[3 + e.key],
              child: _FeatureCard(
                item:   e.value,
                style:  style,
                isDark: isDark,
                onTap: () => Navigator.push(context, _slideFromTop(e.value.destination)),
              ),
            );
          }),

          const SizedBox(height: 8),
          _FadeSlide(animation: _anims[5], child: _Footer(isDark: isDark)),
        ],
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final titleColor = isDark ? const Color(0xFFE8EAFF) : const Color(0xFF111827);
    return AppBar(
      title: Text(
        'Dashboard',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w800, color: titleColor,
        ),
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: widget.themeNotifier,
          builder: (_, mode, __) => _AnimatedThemeToggle(
            isDark:   mode == ThemeMode.dark,
            onToggle: widget.themeNotifier.toggle,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip:   'Sign out',
          icon:      Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 22),
          onPressed: _signOut,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Page transition ───────────────────────────────────────────────────────
  static Route<void> _slideFromTop(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween(
          begin: const Offset(0.0, -0.18),
          end:   Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
          child:   SlideTransition(position: animation.drive(offset), child: child),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED THEME TOGGLE  ·  Morphing sun / moon button
// ═══════════════════════════════════════════════════════════════════════════════

class _AnimatedThemeToggle extends StatefulWidget {
  const _AnimatedThemeToggle({required this.isDark, required this.onToggle});
  final bool         isDark;
  final VoidCallback onToggle;

  @override
  State<_AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<_AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double>   _rotate;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
      value: widget.isDark ? 1.0 : 0.0,
    );
    _rotate = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutBack),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.55), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_AnimatedThemeToggle old) {
    super.didUpdateWidget(old);
    if (old.isDark != widget.isDark) {
      widget.isDark ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isDark
                ? const Color(0xFF1E2547)
                : const Color(0xFFFFF3CD),
          ),
          child: Transform.scale(
            scale: _scale.value,
            child: Transform.rotate(
              angle: _rotate.value * math.pi,
              child: Icon(
                widget.isDark
                    ? Icons.nights_stay_rounded
                    : Icons.wb_sunny_rounded,
                size:  22,
                color: widget.isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GREETING SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.userName, required this.isDark});
  final String userName;
  final bool   isDark;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? const Color(0xFFE8EAFF) : const Color(0xFF0F172A);
    final subColor   = isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $userName 👋',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: titleColor, height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Here's what's happening with your data today.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: subColor, height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BANNER CARD  ·  Looping shimmer sweep
// ═══════════════════════════════════════════════════════════════════════════════

class _BannerCard extends StatefulWidget {
  const _BannerCard({required this.isDark});
  final bool isDark;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard>
    with SingleTickerProviderStateMixin {

  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => Container(
        height:     148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: widget.isDark
                ? [const Color(0xFF2A3580), const Color(0xFF1A2060), const Color(0xFF0D1340)]
                : [const Color(0xFF4F6AF0), const Color(0xFF3451D1), const Color(0xFF2741C0)],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius:   32, spreadRadius: -4,
              offset:       const Offset(0, 14),
              color: const Color(0xFF4F6AF0).withValues(alpha: widget.isDark ? 0.38 : 0.3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Shimmer sweep ───────────────────────────────────────────
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(_shimmerAnim.value - 1, 0),
                    end:   Alignment(_shimmerAnim.value,     0),
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ).createShader(bounds),
                  child: Container(color: Colors.white),
                ),
              ),
            ),

            // ── Decorative orbs ─────────────────────────────────────────
            Positioned(right: -20, top: -20,
              child: _Orb(size: 130, alpha: 0.05)),
            Positioned(right: 55, bottom: -32,
              child: _Orb(size: 80, alpha: 0.04)),

            // ── Content ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    padding:    const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:        Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.insights_rounded, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.center,
                      children: [
                        Text(
                          'AI-Powered Platform',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Customer Intelligence  ·  ML  ·  NLP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color:    Colors.white.withValues(alpha: 0.72),
                            height:   1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Decorative orb ──────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.alpha});
  final double size, alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATS ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF161927) : Colors.white;
    return Row(
      children: [
        _StatChip(label: 'Customers', value: '0',
            icon: Icons.people_alt_rounded,  accentColor: AppTheme.statBlue,  cardColor: cardColor, isDark: isDark),
        const SizedBox(width: 12),
        _StatChip(label: 'Accuracy',  value: '60 - 70%',
            icon: Icons.verified_rounded,    accentColor: AppTheme.statGreen, cardColor: cardColor, isDark: isDark),
        const SizedBox(width: 12),
        _StatChip(label: 'Uploads',   value: '0',
            icon: Icons.upload_file_rounded, accentColor: AppTheme.statAmber, cardColor: cardColor, isDark: isDark),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.cardColor,
    required this.isDark,
  });
  final String label, value;
  final IconData icon;
  final Color    accentColor, cardColor;
  final bool     isDark;

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B);
    final valColor = isDark ? const Color(0xFFE8EAFF) : const Color(0xFF0F172A);

    return Expanded(
      child: Container(
        padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color:        cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: valColor,
            )),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: subColor,
            )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER  ·  Accent-bar label
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});
  final String label;
  final bool   isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            color:        AppTheme.brand(isDark),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFFE8EAFF) : const Color(0xFF0F172A),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEATURE CARD  ·  Press-scale + haptic
// ═══════════════════════════════════════════════════════════════════════════════

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.item,
    required this.style,
    required this.isDark,
    required this.onTap,
  });
  final _FeatureItem  item;
  final _FeatureStyle style;
  final bool          isDark;
  final VoidCallback  onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pressCtrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync:          this,
      duration:       const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
      lowerBound: 0.96,
      upperBound: 1.00,
      value: 1.00,
    );
    _scale = CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent    = widget.style.resolveAccent(widget.isDark);
    final fill      = widget.style.resolveFill(widget.isDark);
    final cardColor = widget.isDark ? const Color(0xFF161927) : Colors.white;
    final titleColor= widget.isDark ? const Color(0xFFE8EAFF) : const Color(0xFF0F172A);
    final subColor  = widget.isDark ? const Color(0xFF8892B0) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown:   (_) { _pressCtrl.reverse(); HapticFeedback.selectionClick(); },
          onTapUp:     (_) { _pressCtrl.forward(); widget.onTap(); },
          onTapCancel: ()  =>  _pressCtrl.forward(),
          child: Container(
            decoration: BoxDecoration(
              color:        cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius:   20, spreadRadius: -2,
                  offset:       const Offset(0, 8),
                  color: accent.withValues(alpha: widget.isDark ? 0.18 : 0.12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color:        fill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.item.icon, size: 28, color: accent),
                  ),
                  const SizedBox(width: 16),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(widget.item.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.5, fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Badge(label: widget.item.badge, accent: accent, isDark: widget.isDark),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(widget.item.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: subColor, height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Arrow chip
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color:        fill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_forward_rounded, size: 17, color: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Badge pill ───────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accent, required this.isDark});
  final String label;
  final Color  accent;
  final bool   isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        accent.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: accent, letterSpacing: 0.5,
      )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '© 2026 Customer Intelligence Platform',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: isDark ? const Color(0xFF4A5280) : const Color(0xFFADB5BD),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FADE + SLIDE  ·  Reusable staggered entry wrapper
// ═══════════════════════════════════════════════════════════════════════════════

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget            child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child:     child,
      builder: (_, c) => FadeTransition(
        opacity: animation,
        child:   Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child:  c,
        ),
      ),
    );
  }
}