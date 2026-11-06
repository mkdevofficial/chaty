import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/localization/app_localizations.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const String appPackageName = 'com.example.chaty';
  static const String appSha1 =
      '95:A2:35:6D:06:BB:51:6E:81:D7:59:C4:63:88:C6:F8:30:D0:E6:1F';

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authProvider.notifier).register(
          phone: phone,
          username: username,
          displayName: displayName,
          password: password,
        );

    if (success && mounted) {
      context.go('/');
    } else if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final success = await ref.read(authProvider.notifier).loginWithGoogle(
            idToken: auth.idToken,
            accessToken: auth.accessToken,
            email: account.email,
            displayName: account.displayName,
            photoUrl: account.photoUrl,
            googleId: account.id,
          );

      if (success && mounted) {
        context.go('/');
      } else if (!success && mounted) {
        final error = ref.read(authProvider).errorMessage;
        final strings = AppLocalizations.of(context).strings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? strings.googleSignInFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('10') || errStr.toLowerCase().contains('developer_error')) {
        _showGoogleConfigErrorDialog();
      } else {
        final strings = AppLocalizations.of(context).strings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.googleSignInFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGoogleConfigErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Google Sign-In (Code 10)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'حدث خطأ مطور (Developer Error: 10) لأن بصمة SHA-1 غير مضافة في Google Cloud Console لمشروعك.\n\n'
                  'لحل المشكلة، افتح Google Cloud Console وأضف بيانات التطبيق التالية:',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Package Name:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: SelectableText(
                              appPackageName,
                              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: appPackageName));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Package Name copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      const Text(
                        'SHA-1 Fingerprint:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: SelectableText(
                              appSha1,
                              style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: appSha1));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('SHA-1 copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'أو يمكنك تسجيل الدخول المباشر بحساب Google تجريبي للاختبار الفوري:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق / Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.flash_on, size: 18),
              label: const Text('دخول تجريبي بـ Google'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final testId = DateTime.now().millisecondsSinceEpoch.toString();
                final success = await ref.read(authProvider.notifier).loginWithGoogle(
                      email: 'google_user_$testId@gmail.com',
                      displayName: 'Google Tester',
                      googleId: 'google_$testId',
                    );
                if (success && mounted) {
                  context.go('/');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.register),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.createAccount,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.registerSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Display Name Input
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: strings.displayName,
                    hintText: 'John Doe',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return strings.invalidDisplayName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username Input
                TextFormField(
                  controller: _usernameController,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: strings.username,
                    hintText: 'johndoe',
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 3) {
                      return strings.invalidUsername;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: strings.phone,
                    hintText: '+1234567890',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return strings.invalidPhone;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: strings.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return strings.invalidPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(strings.createAccount),
                ),
                const SizedBox(height: 20),

                // Divider OR
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        strings.or,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign In Button
                OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 28,
                    color: Color(0xFF4285F4),
                  ),
                  label: Text(
                    strings.continueWithGoogle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Already have account Link
                TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  child: Text(strings.haveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
