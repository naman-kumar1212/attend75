import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/auth/apple_sign_in_button.dart';
import '../../widgets/primary_button.dart';
import '../../utils/snackbar_helper.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(context, 'Welcome back!');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Check if email confirmation is required
      if (authProvider.emailConfirmationRequired) {
        _showEmailConfirmationDialog(authProvider);
      } else {
        // Show specific error from Supabase if available
        final errorMessage =
            authProvider.errorMessage ?? 'Invalid email or password.';
        SnackbarHelper.showError(context, errorMessage);
        authProvider.clearError();
      }
    }
  }

  /// Show dialog when user tries to sign in but email is not confirmed.
  void _showEmailConfirmationDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(LucideIcons.mail, size: 32),
        title: const Text('Email Not Verified'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please check your email and click the confirmation link before signing in.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Didn't receive the email? You can request a new one.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              authProvider.clearError();
            },
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _resendConfirmationEmail(authProvider);
            },
            icon: const Icon(LucideIcons.send, size: 16),
            label: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  /// Resend confirmation email.
  Future<void> _resendConfirmationEmail(AuthProvider authProvider) async {
    setState(() {
      _isLoading = true;
    });

    final success = await authProvider.resendConfirmationEmail();

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(
        context,
        'Confirmation email sent! Please check your inbox.',
      );
    } else {
      SnackbarHelper.showError(
        context,
        authProvider.errorMessage ?? 'Failed to send confirmation email.',
      );
    }
    authProvider.clearError();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
    });

    if (!success) {
      final errorMessage =
          authProvider.errorMessage ?? 'Google sign in failed.';
      SnackbarHelper.showError(context, errorMessage);
      authProvider.clearError();
    }
    // Note: On success, the OAuth flow will open a browser.
    // Navigation happens automatically when auth state changes.
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithApple();

    if (!mounted) return;

    setState(() {
      _isAppleLoading = false;
    });

    if (!success) {
      final errorMessage = authProvider.errorMessage ?? 'Apple sign in failed.';
      SnackbarHelper.showError(context, errorMessage);
      authProvider.clearError();
    }
    // Note: On success, the OAuth flow will open a browser.
    // Navigation happens automatically when auth state changes.
  }

  @override
  Widget build(BuildContext context) {
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
                      'Sign In',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'To sign in to your account, enter your email and password',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Fields
                  AuthTextField(
                    label: 'Email',
                    prefixIcon: LucideIcons.mail,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Password',
                    prefixIcon: LucideIcons.lock,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action
                  PrimaryButton(
                    text: 'Sign in',
                    icon: LucideIcons.logIn,
                    onPressed: _handleSignIn,
                    isLoading: _isLoading,
                    loadingText: 'Signing in...',
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  const OrDivider(),

                  const SizedBox(height: 20),

                  // Apple Sign-In
                  AppleSignInButton(
                    onPressed: _handleAppleSignIn,
                    isLoading: _isAppleLoading,
                  ),

                  const SizedBox(height: 12),

                  // Google Sign-In
                  GoogleSignInButton(
                    onPressed: _handleGoogleSignIn,
                    isLoading: _isGoogleLoading,
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "New to Attend75? ",
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
                              builder: (context) => const SignUpPage(),
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
                            "Sign up",
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
}
