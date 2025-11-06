import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/toastification_log.dart';
import 'login.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureTextConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final currentContext = context;
    final supabase = Supabase.instance.client;

    try {
      final currentUser = supabase.auth.currentUser;

      if (currentUser != null) {
        print('🔄 Usuario temporalmente autenticado: ${currentUser.email}');

        // Actualizamos el usuario con la nueva contraseña
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim()),
        );

        print('✅ Contraseña actualizada exitosamente');

        if (mounted) {
          LoginToastService.showLoginSuccess(currentContext);
        }
      } else {
        print('❌ Error: No hay sesión de recuperación activa.');
        throw AuthException(
          'Enlace inválido o expirado. Solicita un nuevo enlace de recuperación.',
        );
      }
    } on AuthException catch (e) {
      print('❌ Error de Auth: ${e.message}');
      if (mounted) {
        LoginToastService.showLoginError(
          currentContext,
          message: _getErrorMessage(e),
        );
      }
    } catch (e) {
      print('❌ Error general: $e');
      if (mounted) {
        LoginToastService.showLoginError(
          currentContext,
          message: 'Error inesperado: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(AuthException e) {
    if (e.message.contains('JWT expired')) {
      return 'El enlace ha expirado. Solicita uno nuevo.';
    } else if (e.message.contains('Invalid JWT')) {
      return 'Enlace inválido. Solicita uno nuevo.';
    } else if (e.message.contains('Password should be at least 6 characters')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    } else if (e.message.contains('not authenticated')) {
      return 'El enlace no es válido o ya fue usado. Solicita uno nuevo.';
    } else {
      return 'Error al actualizar contraseña: ${e.message}';
    }
  }

  // Botón para "cancelar" y volver al login
  void _goBackToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _goBackToLogin,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Crear nueva contraseña',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tu nueva contraseña para continuar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Campo de Nueva Contraseña
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  obscureText: _obscureText,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureTextConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _obscureTextConfirm = !_obscureTextConfirm,
                      ),
                    ),
                  ),
                  obscureText: _obscureTextConfirm,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón de Actualizar
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ACTUALIZAR CONTRASEÑA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
