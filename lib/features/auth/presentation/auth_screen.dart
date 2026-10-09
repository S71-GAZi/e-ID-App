import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';
import '../../../app/l10n/app_strings.dart';
import '../../auth/data/supabase_providers.dart';
import '../data/card_repository.dart';

/// Email/password sign-in + sign-up + password reset, Google & Apple OAuth.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      if (mounted && !_isSignUp) _showError(AppStrings.of(context).genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(authRepositoryProvider);
    if (!repo.isConfigured) {
      _showError('Supabase not configured. Pass --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY.');
      return;
    }
    await _run(() => _isSignUp
        ? repo.signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim())
        : repo.signIn(email: _emailCtrl.text.trim(), password: _passwordCtrl.text));

    if (_isSignUp && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).resetLinkSent)),
      );
      setState(() => _isSignUp = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showError(AppStrings.of(context).validationRequired);
      return;
    }
    await _run(() => ref.read(authRepositoryProvider).sendPasswordReset(_emailCtrl.text.trim()));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.of(context).resetLinkSent)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(Icons.credit_card_rounded,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(strings.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(strings.tagline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(labelText: strings.fullName),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? strings.validationRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: strings.email),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? strings.validationRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: strings.password),
                      validator: (v) => (_isSignUp && (v == null || v.length < 8))
                          ? '${strings.validationRequired} (8+)'
                          : (v == null || v.isEmpty ? strings.validationRequired : null),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: Text(strings.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isSignUp ? strings.signUp : strings.signIn),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(strings.orContinueWith,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(ref.read(authRepositoryProvider).signInWithGoogle),
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: Text(strings.continueWithGoogle),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(ref.read(authRepositoryProvider).signInWithApple),
                      icon: const Icon(Icons.apple_rounded),
                      label: Text(strings.continueWithApple),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? strings.signIn : strings.signUp,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(_isSignUp ? strings.signUp : strings.signIn),
                        ),
                      ],
                    ),
                    if (!AppConfig.hasSupabase)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          '⚠ Supabase keys missing — configure with --dart-define',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error, fontSize: 12),
                        ),
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }
}
