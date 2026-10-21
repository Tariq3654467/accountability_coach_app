import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _phone = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _displayName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final result = _isSignUp
        ? await auth.signUp(
            email: _email.text,
            password: _password.text,
            username: _username.text,
            displayName: _displayName.text,
            phone: _phone.text,
          )
        : await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.needsConfirmation) {
      setState(() => _isSignUp = false);
    }
  }

  Future<void> _resetPassword(AuthProvider auth) async {
    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }
    final result = await auth.resetPassword(_email.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A241D4B), blurRadius: 28, offset: Offset(0, 10)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        child: Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(17)),
                          child: const Icon(Icons.track_changes, color: Colors.white, size: 29),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        _isSignUp ? 'Create your account' : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -.5),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        auth.isRemoteAvailable
                            ? 'Sign in to manage your Waypoint profile.'
                            : 'Your goals stay on this device. Sign-in is optional.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                      ),
                      const SizedBox(height: 23),
                      if (auth.isRemoteAvailable) ...[
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _displayName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Display name'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 11),
                          TextFormField(
                            controller: _username,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixText: '@',
                              helperText: '3–24 letters, numbers, or underscores',
                            ),
                            validator: (v) {
                              if (v == null || !RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(v.trim())) {
                                return 'Use 3–24 letters, numbers, or underscores';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 11),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone (optional)', hintText: '+923001234567'),
                            validator: Validators.phoneOptional,
                          ),
                          const SizedBox(height: 11),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 11),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password'),
                          validator: Validators.password,
                        ),
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: auth.isBusy ? null : () => _resetPassword(auth),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: auth.isBusy ? null : () => _submit(auth),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: auth.isBusy
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_isSignUp ? 'Create account' : 'Sign in',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        TextButton(
                          onPressed: auth.isBusy ? null : () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(_isSignUp
                              ? 'Already have an account? Sign in'
                              : 'New to Waypoint? Create an account'),
                        ),
                        const Row(children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: TextStyle(fontSize: 10, color: AppColors.textMute)),
                          ),
                          Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 10),
                      ],
                      OutlinedButton(
                        onPressed: auth.isBusy ? null : auth.continueOffline,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text('Continue without an account',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
