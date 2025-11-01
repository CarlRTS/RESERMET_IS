import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import '../widgets/toastification_log.dart';

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
    'Ingeniería de Sistemas',
    'Ingeniería Mecánica',
    'Ingeniería Química',
    'Ingeniería de Producción',
    'Ingeniería Civil',
    'Ingeniería Eléctrica',
    'Administración',
    'Economía',
    'Contaduría',
    'Psicología',
    'Educación',
    'Derecho',
    'Comunicación Social',
    'Estudios Liberales',
    'Estudios Internacionales',
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

      LoginToastService.showRegistrationSuccess(context);

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (e.message.contains('User already registered')) {
        LoginToastService.showRegistrationError(
          context,
          message: 'Este correo ya está registrado',
        );
      } else {
        LoginToastService.showRegistrationSuccess(context);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusXL),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo en lugar del icono circular
                          SizedBox(
                            width: 200, // Ajusta el ancho según necesites
                            height: 80, // Ajusta la altura según necesites
                            child: Image.asset(
                              'assets/images/logo_resermet_naranja.png', // Cambia por la ruta de tu logo
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 4), // Espacio ajustado
                          Text(
                            'Crea tu cuenta Resermet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usa tu correo institucional UNIMET',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: cs.onSurface.withOpacity(.75),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),

                          // Campos de formulario
                          _buildTextFormField(
                            controller: _emailController,
                            label: 'Correo Institucional',
                            icon: Icons.email,
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

                          _buildTextFormField(
                            controller: _nombreController,
                            label: 'Nombre',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              if (!RegExp(
                                r"^[a-zA-ZÀ-ÿ\u00f1\u00d1\s]+$",
                              ).hasMatch(value)) {
                                return 'Solo se permiten letras';
                              }
                              return null;
                            },
                          ),

                          _buildTextFormField(
                            controller: _apellidoController,
                            label: 'Apellido',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El apellido es obligatorio';
                              }
                              if (!RegExp(
                                r"^[a-zA-ZÀ-ÿ\u00f1\u00d1\s]+$",
                              ).hasMatch(value)) {
                                return 'Solo se permiten letras';
                              }
                              return null;
                            },
                          ),

                          _buildTextFormField(
                            controller: _telefonoController,
                            label: 'Teléfono',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El teléfono es obligatorio';
                              }
                              if (!RegExp(r"^\d{10,}$").hasMatch(value)) {
                                return 'Mínimo 10 dígitos';
                              }
                              return null;
                            },
                          ),

                          // Tipo de Usuario
                          DropdownButtonFormField<String>(
                            value: _selectedRol,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Usuario',
                              prefixIcon: Icon(Icons.people),
                              isDense: true,
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
                          const SizedBox(height: 12),

                          if (_selectedRol == 'estudiante') ...[
                            DropdownButtonFormField<String>(
                              value: _selectedCarrera,
                              decoration: const InputDecoration(
                                labelText: 'Carrera',
                                prefixIcon: Icon(Icons.school),
                                isDense: true,
                              ),
                              dropdownColor: Colors.white,
                              menuMaxHeight: 300,
                              itemHeight: 50,
                              isExpanded: true,
                              items: _carreras
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCarrera = v),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Contraseña
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Contraseña (min. 6 caracteres)',
                            obscureText: _obscurePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),

                          // Confirmar contraseña
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirmar contraseña',
                            obscureText: _obscureConfirmPassword,
                            onToggle: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirme su contraseña';
                              }
                              if (v != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // CTA
                          FilledButton(
                            onPressed: _isLoading
                                ? null
                                : _registrarUsuarioCompleto,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const StadiumBorder(),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('CREAR CUENTA'),
                          ),

                          const SizedBox(height: 10),

                          // Link: ¿Ya tienes cuenta? Inicia sesión
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(fontSize: 14),
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

  // Widget helper para campos de texto
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<String>? autofillHints,
    required String? Function(String?)? validator,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            isDense: true,
          ),
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          validator: validator,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Widget helper para campos de contraseña
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: onToggle,
              style: IconButton.styleFrom(
                foregroundColor: UnimetPalette.primary,
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                padding: const EdgeInsets.all(4),
              ),
            ),
            isDense: true,
          ),
          obscureText: obscureText,
          autofillHints: const [AutofillHints.newPassword],
          validator: validator,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
