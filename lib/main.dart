import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding_screen.dart';
import 'utils/routes.dart';
import 'screens/root_nav.dart';
import 'utils/db_helper.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'FlexGuard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF2166F3),
            onPrimary: Colors.white,
            secondary: Color(0xFFF2F6FF),
            onSecondary: Color(0xFF0E1B2A),
            error: Color(0xFFDC2626),
            onError: Colors.white,
            background: Colors.white,
            onBackground: Color(0xFF0E1B2A),
            surface: Colors.white,
            onSurface: Color(0xFF0E1B2A),
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F6FF),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Color(0xFF0E1B2A),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.transparent,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF3B82F6),
            onPrimary: Colors.white,
            secondary: Color(0xFF0B1220),
            onSecondary: Colors.white,
            error: Color(0xFFDC2626),
            onError: Colors.white,
            background: Color(0xFF0B1220),
            onBackground: Colors.white,
            surface: Color(0xFF111827),
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF0B1220),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.transparent,
          ),
          useMaterial3: true,
        ),
        onGenerateRoute: (settings) {
          final widget = settings.name == '/' ? const _StartupGate() : null;
          if (widget != null) return fadeSlideRoute(builder: (_) => widget);
          return null;
        },
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;
  bool _onboardingSeen = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Ensure DB is initialized
    await DatabaseHelper.instance.database;
    await context.read<AuthProvider>().bootstrap();
    // If onboarding already seen and no user, go to Auth directly
    final seen = await DatabaseHelper.instance.getPreference('onboarding_seen');
    if (mounted) {
      setState(() {
        _onboardingSeen = (seen == '1');
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final auth = context.watch<AuthProvider>();
    if (auth.currentUser == null) {
      return _onboardingSeen ? const LoginScreen() : const OnboardingScreen();
    }
    return const RootNav();
  }
}
