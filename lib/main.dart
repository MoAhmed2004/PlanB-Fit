import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/plan_b_provider.dart';
import 'providers/gym_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — gym phones are vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar chrome: transparent, light icons (white on dark)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialise SharedPreferences before anything else — all providers
  // depend on StorageService.instance being ready.
  await StorageService.instance.init();

  runApp(const PlanbFitApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────
class PlanbFitApp extends StatelessWidget {
  const PlanbFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // UserProvider — profile + gamification
        ChangeNotifierProvider(
          create: (_) => UserProvider()..loadProfile(),
        ),
        // RoutineProvider — workout days + exercises
        ChangeNotifierProvider(
          create: (_) => RoutineProvider()..loadRoutine(),
        ),
        // PlanBProvider — stateless between creates; reset on each Plan B tap
        ChangeNotifierProvider(
          create: (_) => PlanBProvider(),
        ),
        // GymProvider — real-time gym occupancy & equipment status
        ChangeNotifierProvider(
          create: (_) => GymProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'PlanB Fit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _StartupRouter(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Startup router
// ─────────────────────────────────────────────────────────────────────────────
class _StartupRouter extends StatelessWidget {
  const _StartupRouter();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // While loading from disk, show the splash
    if (!userProvider.isLoaded) {
      return const _SplashScreen();
    }

    // Onboarding is flagged done AND a profile name exists → home
    final onboardingDone =
        StorageService.instance.getBool(StorageKeys.onboardingDone);

    if (onboardingDone && userProvider.hasProfile) {
      return const HomeScreen();
    }

    return const OnboardingScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Splash screen
// ─────────────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              AppTheme.accentGreen.withOpacity(0.03),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.planBGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: AppTheme.accentPurple.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'B',
                    style: GoogleFonts.orbitron(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App name
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.planBGradient.createShader(bounds),
                child: Text(
                  'PLANB FIT',
                  style: GoogleFonts.orbitron(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 5,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Never miss a rep.',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppTheme.accentGreen,
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
