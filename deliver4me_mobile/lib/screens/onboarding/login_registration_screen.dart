import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/services/auth_service.dart';
import 'package:deliver4me_mobile/models/user_model.dart';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:local_auth/error_codes.dart' as auth_error; // Unused
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginRegistrationScreen extends ConsumerStatefulWidget {
  const LoginRegistrationScreen({super.key});

  @override
  ConsumerState<LoginRegistrationScreen> createState() =>
      _LoginRegistrationScreenState();
}

class _LoginRegistrationScreenState
    extends ConsumerState<LoginRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedRole = 'sender';
  bool isLoading = false;

  // Password Visibility
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureSignupConfirmPassword = true;

  // Biometrics
  final LocalAuthentication auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  bool _canCheckBiometrics = false;

  // Form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  // Form keys
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (mounted) {
        setState(() => _canCheckBiometrics = canCheck);
      }
    } on PlatformException catch (_) {
      // Handle error gracefully
    }
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        setState(() => isLoading = true);
        try {
          final email = await _storage.read(key: 'email');
          final password = await _storage.read(key: 'password');

          if (email != null && password != null) {
            await authService.signInWithEmail(
              email: email,
              password: password,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Welcome back!'),
                    backgroundColor: Colors.green),
              );
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Please log in manually once to enable biometrics.'),
                    backgroundColor: Colors.orange),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Biometric login failed: $e'),
                  backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication Error: ${e.message}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await authService.signInWithEmail(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );

      // Save credentials for biometrics
      await _storage.write(
          key: 'email', value: _loginEmailController.text.trim());
      await _storage.write(
          key: 'password', value: _loginPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    if (_signupPasswordController.text !=
        _signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.signUpWithEmail(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
        name: _signupNameController.text.trim(),
        role: selectedRole == 'sender' ? UserRole.sender : UserRole.rider,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to profile setup
        Navigator.pushReplacementNamed(context, '/profile-setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);

    try {
      final result = await authService.signInWithGoogle(
        selectedRole:
            selectedRole == 'rider' ? UserRole.rider : UserRole.sender,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get role from arguments if available
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      selectedRole = args;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Welcome Back'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Tab switcher
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF135BEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Role selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I am a',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleOption(
                                'sender', 'Sender', Icons.send),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleOption(
                                'rider', 'Rider', Icons.motorcycle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tab content
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildSignupForm(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Social login
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String value, String label, IconData icon) {
    final isSelected = selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135BEC) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF135BEC) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureLoginPassword,
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              child: const Text('Login'),
            ),
          ),
          if (_canCheckBiometrics) ...[
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.fingerprint,
                  size: 40, color: Color(0xFF135BEC)),
              onPressed: _authenticate,
              tooltip: 'Login with Biometrics',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _signupNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupPasswordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignupPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureSignupPassword = !_obscureSignupPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureSignupPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              // Strong password check: Letter + Number
              if (!value.contains(RegExp(r'[A-Za-z]')) ||
                  !value.contains(RegExp(r'[0-9]'))) {
                return 'Password must contain letters and numbers';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupConfirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignupConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureSignupConfirmPassword =
                        !_obscureSignupConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureSignupConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSignup,
              child: const Text('Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}
