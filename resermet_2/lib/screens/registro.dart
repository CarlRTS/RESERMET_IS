import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import '../widgets/toastification_log.dart'; // Importación agregada

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedRol = 'estudiante';
  String? _selectedCarrera;

  final List<String> _carreras = const [
    'Ingeniería',
    'Administración',
    'Economía',
    'Contaduría',
    'Psicología',
    'Educación',
    'Derecho',
    'Comunicación Social',
    'Arquitectura',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCarrera = _carreras.first;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuarioCompleto() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      // Si la validación falla (campos vacíos o inválidos)
      LoginToastService.showRegistrationError(context);
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final telefono = _telefonoController.text.trim();
    final rol = _selectedRol!;
    final carrera = _selectedCarrera!;

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user != null) {
        await Supabase.instance.client.from('usuario').insert({
          'id_usuario': user.id,
          'correo': user.email,
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono,
          'rol': rol,
        });

        // tabla especifica por rol
        if (rol == 'estudiante') {
          await Supabase.instance.client.from('estudiante').insert({
            'id_usuario': user.id,
            'carrera': carrera,
          });
        } else if (rol == 'administrador') {
          await Supabase.instance.client.from('administrador').insert({
            'id_usuario': user.id,
          });
        }
      }

      // Toast de registro exitoso
      LoginToastService.showRegistrationSuccess(context);

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      // Manejo específico de errores de autenticación
      if (e.message.contains('User already registered')) {
        LoginToastService.showRegistrationError(
          context,
          message: 'Este correo ya está registrado',
        );
      } else {
        // Si es otro error de Auth, mostramos registro exitoso (por el flujo de verificación)
        LoginToastService.showRegistrationSuccess(context);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      // Error inesperado
      LoginToastService.showRegistrationError(
        context,
        message: 'Error inesperado: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens =
        Theme.of(context).extension<AppTokens>() ??
        const AppTokens(
          radiusXL: 24,
          radiusMD: 14,
          paddingMD: EdgeInsets.all(12),
        );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: UnimetPalette.base),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                          // Header
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(.10),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.primary.withOpacity(.25),
                              ),
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 36,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Crea tu cuenta Resermet',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usa tu correo institucional UNIMET',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: cs.onSurface.withOpacity(.75),
                                ),
                          ),
                          const SizedBox(height: 22),
                          //  Correo
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Correo Institucional',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese su correo institucional';
                              }
                              final correo = value.toLowerCase();
                              if (!correo.endsWith('@correo.unimet.edu.ve') &&
                                  !correo.endsWith('@unimet.edu.ve')) {
                                return 'Use su correo institucional';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          //  Nombre
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              if (!RegExp(
                                r"^[a-zA-ZÀ-ÿ\u00f1\u00d1\s]+$",
                              ).hasMatch(value)) {
                                return 'Solo se permiten letras (incluye acentos y ñ)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          //  Apellido
                          TextFormField(
                            controller: _apellidoController,
                            decoration: const InputDecoration(
                              labelText: 'Apellido',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El apellido es obligatorio';
                              }
                              if (!RegExp(
                                r"^[a-zA-ZÀ-ÿ\u00f1\u00d1\s]+$",
                              ).hasMatch(value)) {
                                return 'Solo se permiten letras (incluye acentos y ñ)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          //  Teléfono
                          TextFormField(
                            controller: _telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El teléfono es obligatorio';
                              }
                              if (!RegExp(r"^\d{10,}$").hasMatch(value)) {
                                return 'El teléfono debe tener al menos 10 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          //  Tipo de Usuario
                          DropdownButtonFormField<String>(
                            value: _selectedRol,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Usuario',
                              prefixIcon: Icon(Icons.people),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'estudiante',
                                child: Text('Estudiante'),
                              ),
                              DropdownMenuItem(
                                value: 'administrador',
                                child: Text('Administrador'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRol = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Seleccione un tipo de usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          if (_selectedRol == 'estudiante') ...[
                            DropdownButtonFormField<String>(
                              value: _selectedCarrera,
                              decoration: const InputDecoration(
                                labelText: 'Carrera',
                                prefixIcon: Icon(Icons.school),
                              ),
                              items: _carreras
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCarrera = v),
                            ),
                            const SizedBox(height: 14),
                          ],

                          //  Contraseña
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña (min. 6 caracteres)',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor: UnimetPalette.primary,
                                  overlayColor: Colors.transparent,
                                  splashFactory: NoSplash.splashFactory,
                                ),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Debe tener al menos 6 caracteres.'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Confirmar contraseña
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: const Icon(Icons.lock_reset),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor: UnimetPalette.primary,
                                  overlayColor: Colors.transparent,
                                  splashFactory: NoSplash.splashFactory,
                                ),
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirme su contraseña.';
                              }
                              if (v != _passwordController.text) {
                                return 'Las contraseñas no coinciden.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // CTA
                          FilledButton(
                            onPressed: _isLoading
                                ? null
                                : _registrarUsuarioCompleto,
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
                                : const Text('CREAR CUENTA'),
                          ),

                          const SizedBox(height: 12),

                          // Link: ¿Ya tienes cuenta? Inicia sesión
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                                children: const [
                                  TextSpan(
                                    text: '¿Ya tienes cuenta?',
                                    style: TextStyle(
                                      color: UnimetPalette.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' Inicia sesión',
                                    style: TextStyle(
                                      color: UnimetPalette.accent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }
}
