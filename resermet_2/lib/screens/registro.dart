import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _selectedCarrera;
  String _selectedOperadora = '0412';

  final List<String> _operadoras = [
    '0412', // Digitel
    '0422', // Digitel
    '0416', // Movilnet
    '0426', // Movilnet
    '0424', // Movistar
    '0414', // Movistar
  ];

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
    final telefono = '$_selectedOperadora${_telefonoController.text.trim()}';
    const rol = 'estudiante'; // 🔹 Siempre estudiante
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

        // 🔹 Siempre insertamos en estudiante (ya no se crean admins aquí)
        await Supabase.instance.client.from('estudiante').insert({
          'id_usuario': user.id,
          'carrera': carrera,
        });
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
        // 🔹 Mantenemos tu comportamiento actual
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
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 80,
                            child: Image.asset(
                              'assets/images/logo_resermet_naranja.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crea tu cuenta Resermet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usa tu correo institucional UNIMET',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurface.withOpacity(.75),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),

                          _buildTextFormField(
                            controller: _emailController,
                            label: 'Correo Institucional',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
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

                          // Teléfono con dropdown
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: cs.outlineVariant,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedOperadora,
                                    items: _operadoras
                                        .map(
                                          (op) => DropdownMenuItem(
                                            value: op,
                                            child: Text(op),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() => _selectedOperadora = v!);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _telefonoController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                    hintText: '7 dígitos',
                                    prefixIcon: Icon(Icons.phone),
                                    isDense: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(7),
                                  ],
                                  validator: (value) {
                                    final v = (value ?? '').trim();
                                    if (v.isEmpty) {
                                      return 'Ingrese los 7 dígitos';
                                    }
                                    if (!RegExp(r'^\d{7}$').hasMatch(v)) {
                                      return 'Deben ser exactamente 7 dígitos';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Carrera siempre visible (todos son estudiantes)
                          DropdownButtonFormField<String>(
                            value: _selectedCarrera,
                            decoration: const InputDecoration(
                              labelText: 'Carrera',
                              prefixIcon: Icon(Icons.school),
                              isDense: true,
                            ),
                            dropdownColor: Colors.white,
                            isExpanded: true,
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
                          const SizedBox(height: 12),

                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Contraseña (min. 6 caracteres)',
                            obscureText: _obscurePassword,
                            onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),

                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirmar contraseña',
                            obscureText: _obscureConfirmPassword,
                            onToggle: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
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

                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              '¿Ya tienes cuenta? Inicia sesión',
                              style: TextStyle(
                                color: UnimetPalette.accent,
                                fontWeight: FontWeight.w600,
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
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
          validator: validator,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

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
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            isDense: true,
          ),
          validator: validator,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
