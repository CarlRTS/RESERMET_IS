import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import '../widgets/toastification_log.dart';
import 'password_recovery.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      LoginToastService.showLoginError(context);
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        LoginToastService.showInvalidCredentials(context);
      } else if (user.emailConfirmedAt == null) {
        LoginToastService.showEmailNotVerified(context);
      } else {
        LoginToastService.showLoginSuccess(context);
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        LoginToastService.showInvalidCredentials(context);
      } else if (e.message.contains('Email not confirmed')) {
        LoginToastService.showEmailNotVerified(context);
      } else {
        LoginToastService.showLoginError(
          context,
          message: 'Error: ${e.message}',
        );
      }
    } catch (e) {
      LoginToastService.showLoginError(
        context,
        message: 'Error inesperado: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(decoration: BoxDecoration(color: UnimetPalette.base)),
          // Imagen superior
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/universidad_metropolitana.png',
                width: 250,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.only(
              top: 160,
            ), // Espacio para la imagen fija
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 320,
                                height: 260,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.asset(
                                    'assets/images/logo_resermet_titulo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              //  Correo
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Correo Institucional',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Ingrese su correo institucional';
                                  final correo = value.toLowerCase();
                                  if (!correo.endsWith(
                                        '@correo.unimet.edu.ve',
                                      ) &&
                                      !correo.endsWith('@unimet.edu.ve')) {
                                    return 'Use su correo institucional';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              //  Contraseña
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(
                                      () => _obscureText = !_obscureText,
                                    ),
                                    child: Icon(
                                      _obscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                                obscureText: _obscureText,
                                autofillHints: const [AutofillHints.password],
                                validator: (value) {
                                  if (value == null || value.length < 6)
                                    return 'Ingrese una contraseña válida';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // CTA
                              FilledButton(
                                onPressed: _isLoading ? null : _loginUser,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: const StadiumBorder(),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('INICIAR SESIÓN'),
                              ),
                              const SizedBox(height: 12),

                              // Enlace a registro
                              TextButton(
                                onPressed: _goToRegister,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 15),
                                    children: const [
                                      TextSpan(
                                        text: '¿No tienes cuenta?',
                                        style: TextStyle(
                                          color: UnimetPalette.primary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' Regístrate aquí',
                                        style: TextStyle(
                                          color: UnimetPalette.accent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Enlace a recuperación de contraseña
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PasswordRecoveryScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: UnimetPalette.accent,
                                        fontSize: 14,
                                      ),
                                ),
                              ),

                              SizedBox(height: tokens.paddingMD.bottom),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
