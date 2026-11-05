import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/services/app_repository.dart';
import '../core/theme/app_theme.dart';
import 'common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCEEFF), Color(0xFFF6FBFF), Color(0xFFE8F4FF)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(42),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.blue.withValues(alpha: .11),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.how_to_vote_rounded,
                      size: 102,
                      color: AppTheme.blue,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'School Online Voting',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your voice. Your choice. Your campus.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 38),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.blue,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DemoBanner(
                    label: 'Demo mode uses temporary sample data only.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String _selectedRole = 'student';
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppRepository>().signIn(
        identifier: _identifier.text,
        password: _password.text,
        selectedRole: _selectedRole,
      );
      if (mounted) {
        context.go(context.read<AppRepository>().dashboardLocation);
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString();
    if (message.contains('wrong-password') ||
        message.contains('user-not-found') ||
        message.contains('invalid-credential')) {
      return 'Email or username, or password, is incorrect.';
    }
    if (message.contains('network-request-failed')) {
      return 'Network unavailable. Check your connection and try again.';
    }
    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '')
        .replaceFirst('Bad state: ', '');
  }

  Future<void> _resetPassword() async {
    try {
      await context.read<AppRepository>().sendPasswordReset(_identifier.text);
      if (mounted) {
        setState(() => _error = 'Password reset instructions have been sent.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppRepository>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('LOG IN'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: AppTheme.paleBlue,
                    child: Icon(
                      Icons.how_to_vote_rounded,
                      color: AppTheme.blue,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to School Online Voting and Survey System',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select Your Role:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RoleOption(
                        label: 'Admin',
                        icon: Icons.admin_panel_settings_outlined,
                        selected: _selectedRole == 'admin',
                        onTap: () => setState(() {
                          _selectedRole = 'admin';
                          _error = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _RoleOption(
                        label: 'Student',
                        icon: Icons.school_outlined,
                        selected: _selectedRole == 'student',
                        onTap: () => setState(() {
                          _selectedRole = 'student';
                          _error = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _RoleOption(
                        label: 'Teacher',
                        icon: Icons.cast_for_education_outlined,
                        selected: _selectedRole == 'teacher',
                        onTap: () => setState(() {
                          _selectedRole = 'teacher';
                          _error = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (!app.firebaseConfigured)
                    const DemoBanner(
                      label: 'Demo credentials: 2024-1887 / demo1234',
                    )
                  else
                    const DemoBanner(
                      label:
                          'Sign in with an account provisioned by your school.',
                    ),
                  if (app.authError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      app.authError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _identifier,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email or Username',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your email or username.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryAction(
                    label: 'LOG IN',
                    loading: _loading,
                    onPressed: _login,
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

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppTheme.blue : theme.colorScheme.outline;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label role',
        child: Card(
          margin: EdgeInsets.zero,
          color: selected ? AppTheme.paleBlue : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color, width: selected ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppTheme.navy : null,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
