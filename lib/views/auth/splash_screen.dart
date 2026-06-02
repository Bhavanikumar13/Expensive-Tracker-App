import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/app_state.dart';
import 'package:expense_tracker/views/main_shell.dart';
import 'package:expense_tracker/views/auth/login_screen.dart';
import 'package:expense_tracker/views/widgets/animated_background.dart';
import 'package:expense_tracker/views/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Animates the path drawing of the logo (0.0 to 0.7 of the total time)
    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.70, curve: Curves.easeInOutCubic),
    );

    // Animates the fade-in of the app name and slogan (0.60 to 0.85 of the total time)
    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.85, curve: Curves.easeIn),
    );

    // Animates the slide up of the text
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.90, curve: Curves.easeOutBack),
      ),
    );

    // Animates the progress/shimmer bar (0.70 to 1.0 of the total time)
    _shimmerAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward();

    // Use a robust real-time delay to ensure the splash screen remains visible
    // for at least 3.2 seconds on slow emulators, or when system animation scales are set to 0.
    Future.delayed(const Duration(milliseconds: 3200), () {
      _navigateToNext();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            appState.isAuthenticated ? const MainShell() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Provider.of<AppState>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      body: AnimatedMeshBackground(
        child: Stack(
          children: [
            // Central content column
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Animated Logo
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    final scale = 0.85 + (0.15 * _logoAnimation.value);
                    return Transform.scale(
                      scale: scale,
                      child: ExpenseTrackerLogo(
                        size: 140,
                        progress: _logoAnimation.value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Animated App Name and Subtitle
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accentIncome],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'EXPENSE TRACKER',
                                style: GoogleFonts.outfit(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'INTELLIGENT PERSONAL FINANCE',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.2,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom loading slider
          Positioned(
            bottom: size.height * 0.12,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'INITIATING SAFE OFF-LINE SANDBOX...',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 180,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.borderDark.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 180 * _shimmerAnimation.value,
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.accentIncome],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
     ),
    );
  }
}
