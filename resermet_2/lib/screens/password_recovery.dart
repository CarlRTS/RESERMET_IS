import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import '../widgets/toastification_log.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
            'resermet://reset-password', // Cambia esto por tu URL de deep linking
      );

      setState(() => _emailSent = true);
      LoginToastService.showLoginSuccess(context);
    } on AuthException catch (e) {
      LoginToastService.showLoginError(context, message: 'Error: ${e.message}');
    } catch (e) {
      LoginToastService.showLoginError(
        context,
        message: 'Error inesperado: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goBackToLogin() {
    Navigator.pop(context);
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

          // Botón de regreso
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: cs.onSurface),
              onPressed: _goBackToLogin,
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.only(top: 160),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
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
                            // Icono de recuperación
                            Icon(Icons.lock_reset, size: 80, color: cs.primary),
                            const SizedBox(height: 16),

                            // Título
                            Text(
                              'Recuperar Contraseña',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 8),

                            // Descripción
                            Text(
                              _emailSent
                                  ? 'Revisa tu correo electrónico para restablecer tu contraseña'
                                  : 'Ingresa tu correo institucional y te enviaremos un enlace para restablecer tu contraseña',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),

                            if (!_emailSent) ...[
                              // Campo de correo
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Correo Institucional',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
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
                              const SizedBox(height: 24),

                              // Botón de enviar
                              FilledButton(
                                onPressed: _isLoading
                                    ? null
                                    : _sendRecoveryEmail,
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
                                    : const Text(
                                        'ENVIAR ENLACE DE RECUPERACIÓN',
                                      ),
                              ),
                            ],

                            if (_emailSent) ...[
                              // Botón de regresar al login después de enviar
                              FilledButton(
                                onPressed: _goBackToLogin,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('VOLVER AL INICIO DE SESIÓN'),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Enlace para volver al login
                            TextButton(
                              onPressed: _goBackToLogin,
                              child: const Text('Volver al inicio de sesión'),
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
        ],
      ),
    );
  }
}
