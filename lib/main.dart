import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'providers/attendance_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/app_scaffold.dart';
import 'pages/home_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/manage_subjects_page.dart';
import 'pages/duty_leave_page.dart';
import 'pages/settings_page.dart';
import 'services/permissions_service.dart';
import 'services/notification_service.dart';
import 'pages/auth/sign_in_page.dart';
import 'pages/auth/sign_up_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/profile_page.dart';
import 'providers/auth_provider.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize notification service
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize deep link handling for OAuth callbacks
    _initDeepLinks();

    // Global Supabase auth state listener
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        // User signed in (either via login or email verification)
        debugPrint('Auth state: signedIn');

        // SECURITY: Check if we're in password recovery mode
        // If so, skip normal sign-in flow - user must complete password reset first
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          if (authProvider.isInRecoveryMode) {
            debugPrint('Auth: In recovery mode, skipping normal sign-in flow');
            return;
          }

          // Normal sign-in: Trigger data sync
          context.read<AttendanceProvider>().onUserLogin();
          context.read<SettingsProvider>().onUserLogin();
          authProvider.refreshUserData();
        }

        // Navigate to dashboard after OAuth returns from browser
        // Use a small delay to ensure the app is fully resumed
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return; // Guard against unmounted state

          // Double-check recovery mode after delay
          final authProvider = context.read<AuthProvider>();
          if (authProvider.isInRecoveryMode) {
            debugPrint(
              'Auth: Still in recovery mode, not navigating to dashboard',
            );
            return;
          }

          final navContext = navigatorKey.currentContext;
          if (navContext != null) {
            debugPrint('Auth: Navigating to dashboard after sign-in');
            // ignore: use_build_context_synchronously
            Navigator.of(navContext).pushNamedAndRemoveUntil(
              '/dashboard',
              (route) => false, // Clear entire navigation stack
            );
          }
        });
      } else if (event == AuthChangeEvent.passwordRecovery) {
        // User clicked password recovery link from email
        debugPrint('Auth state: passwordRecovery');

        // SECURITY: Set recovery mode flag to prevent treating this as a real login
        if (mounted) {
          await context.read<AuthProvider>().setRecoveryMode(true);
        }

        // Navigate to reset password screen
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          final navContext = navigatorKey.currentContext;
          if (navContext != null) {
            debugPrint('Auth: Navigating to reset password screen');
            // ignore: use_build_context_synchronously
            Navigator.of(
              navContext,
            ).pushNamedAndRemoveUntil('/reset-password', (route) => false);
          }
        });
      } else if (event == AuthChangeEvent.signedOut) {
        // User signed out
        debugPrint('Auth state: signedOut');

        // Clear local data
        if (mounted) {
          // Use the context from the state
          context.read<AttendanceProvider>().clearLocalData();
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Initialize deep link handling for OAuth callbacks
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle deep link if app was started from a link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('App started with deep link: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }

    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('Received deep link: $uri');
        _handleDeepLink(uri);
      },
      onError: (e) {
        debugPrint('Deep link stream error: $e');
      },
    );
  }

  /// Handle incoming deep links (OAuth callbacks)
  Future<void> _handleDeepLink(Uri uri) async {
    if (!uri.toString().startsWith('com.namankumar.attend75://')) return;

    // Extract session from OAuth callback URL
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {
      // Session extraction failed - auth state listener will not fire
    }
  }

  /// Global navigator key for auth state navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Attend 75',
          theme: themeProvider.getLightTheme(),
          darkTheme: themeProvider.getDarkTheme(),
          themeMode: themeProvider.themeMode,
          // Localization for DD/MM/YYYY date format
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'GB'), // British English (DD/MM/YYYY)
            Locale('en', 'US'), // US English
          ],
          home: MainNavigator(key: MainNavigator.navigatorKey),
          routes: {
            '/dashboard': (context) => const MainNavigator(),
            '/login': (context) => const SignInPage(),
            '/signup': (context) => const SignUpPage(),
            '/profile': (context) => const ProfilePage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  /// Global key for programmatic tab switching from anywhere in the app
  static final GlobalKey<MainNavigatorState> navigatorKey =
      GlobalKey<MainNavigatorState>();

  /// Switch to a specific tab index programmatically
  static void switchToTab(int index) {
    navigatorKey.currentState?.switchToTab(index);
  }

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DashboardPage(),
    const ManageSubjectsPage(),
    const DutyLeavePage(),
    const SettingsPage(),
  ];

  /// Called programmatically to switch tabs
  void switchToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    // Request notification permission on first app launch (system dialog only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionsService().requestNotificationPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250), // Optimized duration
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic, // Symmetrical exit
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          // Consistent with FadeSlidePageTransitionsBuilder:
          // Fade + Slide (0.02) + Scale (0.98)

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
    );
  }
}
