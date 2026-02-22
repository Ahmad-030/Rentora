// main.dart — Entry point, Firebase init, Auth screens, Router

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared.dart';
import 'admin_screens.dart';
import 'agent_screens.dart';

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // Replace with your Firebase config (via google-services.json / GoogleService-Info.plist)
    // Or use DefaultFirebaseOptions from firebase_options.dart if using FlutterFire CLI
  );
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
      home: const AuthWrapper(),
    );
  }
}

// ─────────────────────────────────────────────
// AUTH WRAPPER — listens to Firebase auth state
// ─────────────────────────────────────────────

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  static const _prefKey = 'permissions_requested';

  @override
  void initState() {
    super.initState();
    // Show dialog after first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPermissionDialog());
  }

  Future<void> _maybeShowPermissionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_prefKey) ?? false;
    if (!alreadyRequested && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PermissionDialog(),
      );
      await prefs.setBool(_prefKey, true);
    }
  }

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
// PERMISSION DIALOG — shown once on first launch
// ─────────────────────────────────────────────

class PermissionDialog extends StatefulWidget {
  const PermissionDialog({super.key});

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  bool _loading = false;

  // Each permission item: icon, label, description, status
  final List<Map<String, dynamic>> _permissions = [
    {
      'icon': Icons.photo_library_outlined,
      'label': 'Photo Library',
      'desc': 'To select vehicle images from your gallery',
      'permission': Permission.photos,
      'granted': false,
    },
    {
      'icon': Icons.camera_alt_outlined,
      'label': 'Camera',
      'desc': 'To take photos of vehicles directly',
      'permission': Permission.camera,
      'granted': false,
    },
    {
      'icon': Icons.wifi_outlined,
      'label': 'Internet Access',
      'desc': 'To sync data and upload images to cloud',
      'permission': null, // always granted on Android via manifest
      'granted': true,
    },
  ];

  Future<void> _requestAll() async {
    setState(() => _loading = true);

    for (final item in _permissions) {
      final perm = item['permission'] as Permission?;
      if (perm == null) continue; // internet is auto-granted
      final status = await perm.request();
      item['granted'] = status.isGranted;
    }

    setState(() => _loading = false);

    // Close dialog after requesting
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [RentoraTheme.primary, RentoraTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'App Permissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rentora needs a few permissions\nto work properly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Permission items
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                children: _permissions.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: RentoraTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: RentoraTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc'] as String,
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Required badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                  );
                }).toList(),
              ),
            ),

            // Note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can change these anytime in your device Settings.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _requestAll,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black45,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(fontSize: 13),
                      ),
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
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseService.signIn(_email.text.trim(), _password.text);
      final uid = cred.user!.uid;

      // Show loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Signing you in...'),
            ]),
            duration: Duration(seconds: 3),
            backgroundColor: RentoraTheme.primary,
          ),
        );
      }

      // Fetch user profile directly
      final user = await FirebaseService.getUser(uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (user == null) {
        setState(() => _error = 'Account profile not found. Please contact support.');
        return;
      }

      if (user.disabled) {
        setState(() => _error = 'Your account has been disabled by the admin.');
        return;
      }

      // ✅ Success toast
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

      // Navigate directly — no relying on AuthWrapper stream
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
              // Logo
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: RentoraTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.directions_car, color: Colors.white, size: 30),
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
                          style: TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 50),
              const Text('Welcome back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Sign in to your account',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),
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
                      validator: (v) => v!.isEmpty ? 'Enter your email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: (v) => v!.isEmpty ? 'Enter your password' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RentoraTheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border:
                          Border.all(color: RentoraTheme.error.withOpacity(0.3)),
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),
              const Text("Don't have a business account?",
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 10),
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
    setState(() { _loading = true; _error = null; });
    try {
      // Show progress snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
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

      // ✅ Success toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text('Account created! Welcome, ${user.name.split(' ').first}! 🎉')),
          ]),
          backgroundColor: RentoraTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate directly to Admin Dashboard
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
          'email-already-in-use' => 'This email is already registered. Please login instead.',
          'weak-password'        => 'Password too weak. Use at least 6 characters.',
          'invalid-email'        => 'Please enter a valid email address.',
          _                      => 'Registration failed: ${e.message}',
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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
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
                    border: Border.all(color: RentoraTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: RentoraTheme.error, size: 18),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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