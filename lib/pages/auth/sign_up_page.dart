import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/auth/apple_sign_in_button.dart';
import '../../widgets/primary_button.dart';
import '../../utils/snackbar_helper.dart';
import 'sign_in_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      SnackbarHelper.showError(
        context,
        'You must agree to the terms and conditions',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get providers BEFORE any async calls to avoid context issues
    final attendanceProvider = context.read<AttendanceProvider>();
    final authProvider = context.read<AuthProvider>();

    // Clear any cached data from previous user BEFORE signing up
    await attendanceProvider.clearLocalData();

    final success = await authProvider.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      if (!mounted) return;

      if (authProvider.isSignedIn) {
        // Email confirmation disabled - user is fully signed in
        // Sync with Supabase to get the new user's actual subjects
        await attendanceProvider.syncWithSupabase();

        if (!mounted) return;

        SnackbarHelper.showSuccess(
          context,
          'Account created successfully! Welcome to Attend75!',
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Email confirmation enabled - user needs to verify email
        SnackbarHelper.showSuccess(
          context,
          'Account created! Please check your email to verify your account.',
        );
        // Navigate to sign in page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      }
    } else {
      // Show specific error from Supabase if available - auto dismiss in 4 sec
      final errorMessage =
          authProvider.errorMessage ??
          'Failed to create account. Please try again.';
      SnackbarHelper.showError(
        context,
        errorMessage,
        duration: const Duration(seconds: 4),
      );
      authProvider.clearError();
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isGoogleLoading = true;
    });

    // Get providers BEFORE any async calls to avoid context issues
    final attendanceProvider = context.read<AttendanceProvider>();
    final authProvider = context.read<AuthProvider>();

    // Clear any cached data from previous user BEFORE signing up
    await attendanceProvider.clearLocalData();

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
    });

    if (!success) {
      final errorMessage =
          authProvider.errorMessage ?? 'Google sign up failed.';
      SnackbarHelper.showError(context, errorMessage);
      authProvider.clearError();
    }
    // Note: On success, the OAuth flow will open a browser.
    // Navigation happens automatically when auth state changes.
  }

  Future<void> _handleAppleSignUp() async {
    setState(() {
      _isAppleLoading = true;
    });

    // Get providers BEFORE any async calls to avoid context issues
    final attendanceProvider = context.read<AttendanceProvider>();
    final authProvider = context.read<AuthProvider>();

    // Clear any cached data from previous user BEFORE signing up
    await attendanceProvider.clearLocalData();

    final success = await authProvider.signInWithApple();

    if (!mounted) return;

    setState(() {
      _isAppleLoading = false;
    });

    if (!success) {
      final errorMessage = authProvider.errorMessage ?? 'Apple sign up failed.';
      SnackbarHelper.showError(context, errorMessage);
      authProvider.clearError();
    }
    // Note: On success, the OAuth flow will open a browser.
    // Navigation happens automatically when auth state changes.
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width >= 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AuthCard(
            maxWidth: 480, // Slightly wider for ease of twin inputs
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'lib/assets/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Header
                  Center(
                    child: Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Join Attend75 to start tracking your attendance and achieve your academic goals.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Fields
                  layoutGrid(
                    isWide: isWide,
                    children: [
                      AuthTextField(
                        label: 'First Name',
                        prefixIcon: LucideIcons.user,
                        controller: _firstNameController,
                        validator: (value) =>
                            (value == null || value.length < 2)
                            ? 'Min 2 chars'
                            : null,
                      ),
                      AuthTextField(
                        label: 'Last Name',
                        prefixIcon: LucideIcons.user,
                        controller: _lastNameController,
                        validator: (value) =>
                            (value == null || value.length < 2)
                            ? 'Min 2 chars'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Email
                  AuthTextField(
                    label: 'Email',
                    prefixIcon: LucideIcons.mail,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  AuthTextField(
                    label: 'Password',
                    prefixIcon: LucideIcons.lock,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.length < 8) return 'Min 8 chars';
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Need uppercase';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Need lowercase';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Need number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  AuthTextField(
                    label: 'Confirm Password',
                    prefixIcon: LucideIcons.lock,
                    isPassword: true,
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Terms Checkbox
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (val) {
                            setState(() {
                              _agreedToTerms = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text('I agree to the '),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Terms',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(' and '),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action
                  PrimaryButton(
                    text: 'Create account',
                    icon: LucideIcons.userPlus,
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                    loadingText: 'Creating account...',
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  const OrDivider(),

                  const SizedBox(height: 20),

                  // Apple Sign-Up
                  AppleSignInButton(
                    onPressed: _handleAppleSignUp,
                    isLoading: _isAppleLoading,
                    text: 'Sign up with Apple',
                  ),

                  const SizedBox(height: 12),

                  // Google Sign-Up
                  GoogleSignInButton(
                    onPressed: _handleGoogleSignUp,
                    isLoading: _isGoogleLoading,
                    text: 'Sign up with Google',
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            "Sign in",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget layoutGrid({required bool isWide, required List<Widget> children}) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 16),
          Expanded(child: children[1]),
        ],
      );
    } else {
      return Column(
        children: [children[0], const SizedBox(height: 16), children[1]],
      );
    }
  }
}
