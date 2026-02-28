// lib/screens/admin/user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/services/usuario_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UsuarioService _service = UsuarioService();

  bool _loading = true;
  String? _error;
  UserProfile? _user;

  // 🔹 Gestión de rol y datos de admin
  String _selectedRole = 'estudiante';
  bool _savingChanges = false;

  // 🔹 Controladores para edición de administrador
  final _cedulaCtrl = TextEditingController();
  final _carnetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _carnetCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getUserProfileById(widget.userId);

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _error = 'Usuario no encontrado';
          _loading = false;
        });
        return;
      }

      setState(() {
        _user = data;
        _selectedRole = data.rol;
        // 🔹 Inicializamos los controladores con los datos actuales
        _cedulaCtrl.text = data.cedula.toString();
        _carnetCtrl.text = data.carnet.toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error cargando usuario: $e';
        _loading = false;
      });
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // 🔹 Actualizar todos los datos sensibles (Rol, Cédula, Carnet)
  Future<void> _updateAdminData() async {
    final user = _user;
    if (user == null) return;

    // Validaciones básicas antes de enviar
    final int? nuevaCedula = int.tryParse(_cedulaCtrl.text.trim());
    final int? nuevoCarnet = int.tryParse(_carnetCtrl.text.trim());

    if (nuevaCedula == null || nuevaCedula <= 0) {
      _showError('Cédula inválida');
      return;
    }
    if (nuevoCarnet == null || _carnetCtrl.text.trim().length != 11) {
      _showError('El carnet debe tener exactamente 11 dígitos');
      return;
    }

    setState(() {
      _savingChanges = true;
    });

    try {
      // Usamos el toUpdateMap que configuramos para que incluya cedula y carnet
      final updatedUser = user.copyWith(
        rol: _selectedRole,
        cedula: nuevaCedula,
        carnet: nuevoCarnet,
      );

      final updateData = updatedUser.toUpdateMap();

      await Supabase.instance.client
          .from('usuario')
          .update(updateData)
          .eq('id_usuario', user.idUsuario);

      await _fetch();

      if (!mounted) return;
      setState(() {
        _savingChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos del usuario actualizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingChanges = false;
      });
      _showError('Error al actualizar datos: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else {
      final user = _user;
      if (user == null) {
        body = const Center(child: Text('Usuario no encontrado'));
      } else {
        final telefono = user.telefono;

        // 🔹 Verificamos si hubo algún cambio en los datos para habilitar el botón
        final bool roleChanged = _selectedRole != user.rol;
        final bool cedulaChanged =
            _cedulaCtrl.text.trim() != user.cedula.toString();
        final bool carnetChanged =
            _carnetCtrl.text.trim() != user.carnet.toString();
        final bool hasChanges = roleChanged || cedulaChanged || carnetChanged;

        body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header con avatar
              CircleAvatar(
                radius: 42,
                backgroundImage:
                    (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                    ? NetworkImage(user.fotoUrl!)
                    : null,
                child: (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                    ? Text(
                        _initials(user),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                _displayName(user),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Chip(
                label: Text(user.rol.toUpperCase()),
                backgroundColor: cs.primaryContainer,
                labelStyle: TextStyle(color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 16),

              // Info de contacto (Solo lectura)
              _infoTile(
                icon: Icons.alternate_email,
                label: 'Correo',
                value: user.correo,
                action: user.correo.isNotEmpty
                    ? () => _launchEmail(user.correo)
                    : null,
                actionIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 8),
              _infoTile(
                icon: Icons.phone_iphone,
                label: 'Teléfono',
                value: telefono ?? '—',
                action: (telefono != null && telefono.isNotEmpty)
                    ? () => _launchPhone(telefono)
                    : null,
                actionIcon: Icons.phone_outlined,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Datos Administrativos (Modificables)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Edición de Cédula
              TextField(
                controller: _cedulaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) =>
                    setState(() {}), // Para actualizar el estado del botón
                decoration: InputDecoration(
                  labelText: 'Cédula de Identidad',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 Edición de Carnet
              TextField(
                controller: _carnetCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (_) =>
                    setState(() {}), // Para actualizar el estado del botón
                decoration: InputDecoration(
                  labelText: 'Carnet Estudiantil (11 dígitos)',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Gestión de rol
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nivel de Acceso',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Estudiante'),
                      selected: _selectedRole == 'estudiante',
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _selectedRole = 'estudiante');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Administrador'),
                      selected: _selectedRole == 'administrador',
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _selectedRole = 'administrador');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🔹 Botón Unificado de Guardado
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingChanges || !hasChanges
                      ? null
                      : _updateAdminData,
                  icon: _savingChanges
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Guardar cambios'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Usuario')),
      body: body,
    );
  }

  String _initials(UserProfile u) {
    final n = (u.nombre ?? '').trim();
    final a = (u.apellido ?? '').trim();
    final ni = n.isNotEmpty ? n.characters.first : '';
    final ai = a.isNotEmpty ? a.characters.first : '';
    final both = (ni + ai).toUpperCase();
    return both.isEmpty ? 'U' : both;
  }

  String _displayName(UserProfile u) {
    final name = '${u.nombre ?? ''} ${u.apellido ?? ''}'.trim();
    return name.isEmpty ? 'Estudiante' : name;
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? action,
    IconData? actionIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null && actionIcon != null)
            IconButton(
              icon: Icon(actionIcon, color: cs.primary),
              onPressed: action,
              tooltip: label,
            ),
        ],
      ),
    );
  }
}
