// main.dart — Entry point, Firebase init, Auth screens, Router

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'forgot_password_screen.dart';
import 'shared.dart';
import 'admin_screens.dart';
import 'agent_screens.dart';

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const RentoraApp());
}

class RentoraApp extends StatelessWidget {
  const RentoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentora',
      debugShowCheckedModeBanner: false,
      theme: RentoraTheme.theme,
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// SPLASH SCREEN — Advanced Animated
// ─────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _bgGradient;
  late Animation<double> _particleOpacity;
  late Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bgGradient = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOut),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _ringScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _particleOpacity = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final permissionsDone = prefs.getBool('permissions_done') ?? false;

    if (!mounted) return;

    if (!onboardingDone) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else if (!permissionsDone) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PermissionScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_bgController, _logoController, _textController, _particleController]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Colors.white, const Color(0xFF0D47A1),
                      _bgGradient.value * 0.12)!,
                  Color.lerp(Colors.white, const Color(0xFF2979FF),
                      _bgGradient.value * 0.08)!,
                  Color.lerp(Colors.white, const Color(0xFF0D47A1),
                      _bgGradient.value * 0.05)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Floating particle circles
                ..._buildParticles(size),

                // Main content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated ring + logo
                      SlideTransition(
                        position: _logoSlide,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer pulsing ring
                                ScaleTransition(
                                  scale: _ringScale,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: RentoraTheme.primary
                                            .withOpacity(0.2 * _particleOpacity.value),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                // Middle ring
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: RentoraTheme.primary.withOpacity(0.08),
                                    border: Border.all(
                                      color: RentoraTheme.primary.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Logo box
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0D47A1),
                                        Color(0xFF2979FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: RentoraTheme.primary.withOpacity(0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App name + tagline
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: Column(
                            children: [
                              const Text(
                                'Rentora',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: RentoraTheme.primary,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FadeTransition(
                                opacity: _taglineOpacity,
                                child: const Text(
                                  'Smart Rentals. Total Control.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom loading indicator
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              RentoraTheme.primary.withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles(Size size) {
    final positions = [
      [0.1, 0.12, 60.0],
      [0.85, 0.08, 40.0],
      [0.05, 0.55, 30.0],
      [0.92, 0.45, 50.0],
      [0.15, 0.85, 45.0],
      [0.78, 0.80, 35.0],
      [0.5, 0.05, 25.0],
    ];
    return positions.map((p) {
      return Positioned(
        left: p[0] * size.width - p[2] / 2,
        top: p[1] * size.height - p[2] / 2,
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (_, __) => Opacity(
            opacity: _particleOpacity.value * _bgGradient.value,
            child: Container(
              width: p[2],
              height: p[2],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    RentoraTheme.primary.withOpacity(0.15),
                    RentoraTheme.accent.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────
// ONBOARDING SCREEN — shown only once
// ─────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      gradient: [Color(0xFF0D47A1), Color(0xFF1565C0)],
      icon: Icons.directions_car_rounded,
      title: 'Manage Your Fleet',
      subtitle:
      'Add, track, and update all your vehicles in one place. Know their status at a glance.',
      illustrationIcon: Icons.garage_rounded,
    ),
    _OnboardingPage(
      gradient: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      icon: Icons.calendar_month_rounded,
      title: 'Smart Bookings',
      subtitle:
      'Create and manage rental bookings effortlessly. Track payments, advances, and due amounts.',
      illustrationIcon: Icons.event_available_rounded,
    ),
    _OnboardingPage(
      gradient: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
      icon: Icons.people_rounded,
      title: 'Team Management',
      subtitle:
      'Add agents to your team. Control their access and monitor their bookings.',
      illustrationIcon: Icons.supervisor_account_rounded,
    ),
    _OnboardingPage(
      gradient: [Color(0xFFBF360C), Color(0xFFE64A19)],
      icon: Icons.insights_rounded,
      title: 'Revenue Insights',
      subtitle:
      'Track daily and total revenue in real-time. Stay on top of your business performance.',
      illustrationIcon: Icons.trending_up_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animController.reset();
    _animController.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    final permissionsDone = prefs.getBool('permissions_done') ?? false;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
        permissionsDone ? const AuthWrapper() : const PermissionScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: page.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final p = _pages[index];
                    return AnimatedBuilder(
                      animation: _animController,
                      builder: (_, __) => FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Illustration
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                      Icon(p.illustrationIcon,
                                          size: 80,
                                          color: Colors.white.withOpacity(0.9)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 48),
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  p.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page dots + button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finish();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: page.gradient[0],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Continue'
                              : "Let's Get Started",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData illustrationIcon;

  const _OnboardingPage({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.illustrationIcon,
  });
}

// ─────────────────────────────────────────────
// PERMISSION SCREEN — shown only once
// ─────────────────────────────────────────────

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _permissions = [
    {
      'icon': Icons.photo_library_outlined,
      'label': 'Gallery Access',
      'desc': 'To select & upload vehicle photos from your gallery',
      'permission': Permission.photos,
      'granted': false,
    },
    {
      'icon': Icons.camera_alt_outlined,
      'label': 'Camera',
      'desc': 'To take photos of vehicles directly in-app',
      'permission': Permission.camera,
      'granted': false,
    },
    {
      'icon': Icons.wifi_outlined,
      'label': 'Internet Access',
      'desc': 'To sync data and upload images to cloud',
      'permission': null,
      'granted': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _requestAll() async {
    setState(() => _loading = true);
    for (final item in _permissions) {
      final perm = item['permission'] as Permission?;
      if (perm == null) continue;
      final status = await perm.request();
      item['granted'] = status.isGranted;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_done', true);
    setState(() => _loading = false);
    if (mounted) _goToAuth();
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_done', true);
    if (mounted) _goToAuth();
  }

  void _goToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [RentoraTheme.primary, RentoraTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'App Permissions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rentora needs a few permissions\nto work at its best',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          ..._permissions.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration:
                              Duration(milliseconds: 400 + i * 150),
                              curve: Curves.easeOut,
                              builder: (_, val, child) => Opacity(
                                opacity: val,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - val)),
                                  child: child,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            RentoraTheme.primary,
                                            RentoraTheme.accent
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['label'] as String,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item['desc'] as String,
                                            style: const TextStyle(
                                                color: Colors.black45,
                                                fontSize: 12,
                                                height: 1.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Required',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 18, color: Colors.blue),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You can change these anytime in your device Settings.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _requestAll,
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                                : const Text(
                              'Allow Permissions',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _loading ? null : _skip,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black45,
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Skip for now',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────
// AUTH WRAPPER — listens to Firebase auth state
// ─────────────────────────────────────────────

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == null) return const LoginScreen();
        return FutureBuilder<AppUser?>(
          future: FirebaseService.getUser(snap.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final user = userSnap.data;
            if (user == null) return const LoginScreen();
            if (user.disabled) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Your account has been disabled.',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: FirebaseService.signOut,
                          child: const Text('Logout')),
                    ],
                  ),
                ),
              );
            }
            if (user.role == 'admin') return AdminDashboard(user: user);
            return AgentDashboard(user: user);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred =
      await FirebaseService.signIn(_email.text.trim(), _password.text);
      final uid = cred.user!.uid;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Signing you in...'),
            ]),
            duration: Duration(seconds: 3),
            backgroundColor: RentoraTheme.primary,
          ),
        );
      }

      final user = await FirebaseService.getUser(uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (user == null) {
        setState(() =>
        _error = 'Account profile not found. Please contact support.');
        return;
      }

      if (user.disabled) {
        setState(
                () => _error = 'Your account has been disabled by the admin.');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text('Welcome back, ${user.name.split(' ').first}! 👋'),
          ]),
          backgroundColor: RentoraTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => user.role == 'admin'
              ? AdminDashboard(user: user)
              : AgentDashboard(user: user),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authError(e.code));
    } catch (e) {
      setState(() => _error = 'An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found with this email or wrong password.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'Your account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Login failed ($code). Check your credentials.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // ── Logo + App name ──
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [RentoraTheme.primary, RentoraTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.directions_car,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rentora',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: RentoraTheme.primary)),
                      Text('Smart Rentals. Total Control.',
                          style:
                          TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 50),

              const Text('Welcome back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              // ── UPDATED: clarify both owners and agents can login ──
              const Text('Owners & agents can sign in here',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),

              // ── Info banner for agents ──
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: RentoraTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: RentoraTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline,
                        size: 16, color: RentoraTheme.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Agents: use the credentials provided by your admin.',
                        style: TextStyle(
                            fontSize: 12,
                            color: RentoraTheme.primary,
                            fontWeight: FontWeight.w500,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Form ──
              Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                      v!.isEmpty ? 'Enter your email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: (v) =>
                      v!.isEmpty ? 'Enter your password' : null,
                    ),
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: RentoraTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RentoraTheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: RentoraTheme.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: RentoraTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: RentoraTheme.error,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading
                            ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Text('Sign In',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),

              // ── UPDATED: bottom section for new business registration ──
              const Text("Don't have a business account yet?",
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text(
                'Register your company to get started as an owner.',
                style: TextStyle(color: Colors.black38, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.business),
                  label: const Text('Register Your Business'),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RentoraTheme.primary,
                    side: const BorderSide(color: RentoraTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REGISTER SCREEN
// ─────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Creating your business account...'),
            ]),
            duration: Duration(seconds: 10),
            backgroundColor: RentoraTheme.primary,
          ),
        );
      }

      final user = await FirebaseService.registerCompany(
        companyName: _company.text.trim(),
        ownerName: _owner.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Account created! Welcome, ${user.name.split(' ').first}! 🎉')),
          ]),
          backgroundColor: RentoraTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' =>
          'This email is already registered. Please login instead.',
          'weak-password' => 'Password too weak. Use at least 6 characters.',
          'invalid-email' => 'Please enter a valid email address.',
          _ => 'Registration failed: ${e.message}',
        };
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() => _error = 'An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Business')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [RentoraTheme.primary, RentoraTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.business, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text('Start Your Business',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Register to manage your rental fleet',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Business Information',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 14),
              _field(_company, 'Company Name', Icons.business_outlined),
              const SizedBox(height: 14),
              _field(_phone, 'Business Phone', Icons.phone_outlined,
                  type: TextInputType.phone),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                    labelText: 'Business Address',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text('Owner & Login Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 14),
              _field(_owner, 'Owner Full Name', Icons.person_outlined),
              const SizedBox(height: 14),
              _field(_email, 'Email Address', Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) =>
                (v?.length ?? 0) < 6 ? 'Minimum 6 characters' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RentoraTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: RentoraTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: RentoraTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: RentoraTheme.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Create Business Account',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      keyboardType: type,
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}