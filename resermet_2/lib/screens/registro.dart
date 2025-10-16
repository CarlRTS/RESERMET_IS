import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';

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

  final List<String> _carreras = [
    'Ingeniería',
    'Administración',
    'Economía',
    'Contaduría',
    'Psicología',
    'Educación',
    'Derecho',
    'Comunicación Social',
    'Arquitectura',
    'Medicina',
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
    if (!_formKey.currentState!.validate()) return;

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

      // Mensaje de verificación de correo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            ' Registro exitoso! Verifica tu correo para activar la cuenta.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Esperar un poco antes de regresar al login
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }

    } on AuthException catch (_) {
      // Mostrar el mismo mensaje aunque haya excepción de correo no confirmado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Registro exitoso! Verifica tu correo para activar la cuenta.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 90,
                      color: AppColors.unimetOrange,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Crea tu Cuenta Resermet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.unimetBlue,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Correo
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo UNIMET',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Ingrese su correo UNIMET';
                        final correo = value.toLowerCase();
                        if (!correo.endsWith('@correo.unimet.edu.ve') &&
                            !correo.endsWith('@unimet.edu.ve'))
                          return 'Use su correo institucional';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
                          return 'Solo se permiten letras';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Apellido
                    TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El apellido es obligatorio';
                        }
                        if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
                          return 'Solo se permiten letras';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Teléfono
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
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
                    const SizedBox(height: 20),

                    // Rol
                    DropdownButtonFormField<String>(
                      value: _selectedRol,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Usuario',
                        prefixIcon: Icon(Icons.people),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
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
                    const SizedBox(height: 20),

                    // Carrera (solo estudiantes)
                    if (_selectedRol == 'estudiante') ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCarrera,
                        decoration: const InputDecoration(
                          labelText: 'Carrera',
                          prefixIcon: Icon(Icons.school),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        items: _carreras.map((carrera) {
                          return DropdownMenuItem(
                            value: carrera,
                            child: Text(carrera),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCarrera = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedRol == 'estudiante' &&
                              (value == null || value.isEmpty)) {
                            return 'Seleccione una carrera';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Contraseña
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña (mín. 6 chars)',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.unimetOrange,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Debe tener al menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirmar Contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        prefixIcon: const Icon(Icons.lock_reset),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.unimetOrange,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme su contraseña.';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Botón Registrar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registrarUsuarioCompleto,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.unimetBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'CREAR CUENTA',
                        style: TextStyle(fontSize: 18),
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
}

