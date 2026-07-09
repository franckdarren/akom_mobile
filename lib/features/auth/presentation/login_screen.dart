import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/akom_button.dart';
import '../../../shared/widgets/akom_logo.dart';
import '../../../shared/widgets/akom_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../data/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // La session Supabase est maintenant active.
      // RouterAuthNotifier notifie GoRouter qui redirige automatiquement.
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkomColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AkomSpacing.lg,
              vertical: AkomSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Logo(),
                    const SizedBox(height: AkomSpacing.xxl),
                    Text(
                      'Connexion',
                      style: AkomTextStyles.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AkomSpacing.sm),
                    Text(
                      'Connectez-vous à votre compte Akôm',
                      style: AkomTextStyles.bodyMedium
                          .copyWith(color: AkomColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AkomSpacing.xl),
                    if (_errorMessage != null) ...[
                      ErrorBanner.error(message: _errorMessage!),
                      const SizedBox(height: AkomSpacing.md),
                    ],
                    AkomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'votre@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      prefixIcon: const Icon(Icons.email_outlined),
                      onSubmitted: (_) => FocusScope.of(context)
                          .requestFocus(_passwordFocusNode),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AkomSpacing.md),
                    AkomTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      label: 'Mot de passe',
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir votre mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Mot de passe trop court';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AkomSpacing.xl),
                    AkomButton(
                      label: 'Se connecter',
                      onPressed: _submit,
                      isLoading: _isLoading,
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
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AkomLogo(fontSize: 36),
        const SizedBox(height: AkomSpacing.xs),
        Text(
          'SCANNER',
          style: AkomTextStyles.labelLarge.copyWith(
            color: AkomColors.onSurfaceVariant,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}
