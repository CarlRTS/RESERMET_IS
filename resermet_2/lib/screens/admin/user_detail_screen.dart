// lib/screens/admin/user_detail_screen.dart
import 'package:flutter/material.dart';
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

  // 🔹 Gestión de rol
  String _selectedRole = 'estudiante';
  bool _savingRole = false;

  @override
  void initState() {
    super.initState();
    _fetch();
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
        _selectedRole = data.rol; // rol no-nullable en tu modelo
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

  // 🔹 Actualizar rol en Supabase (tabla usuario) y refrescar
  Future<void> _updateUserRole(String newRole) async {
    final user = _user;
    if (user == null) return;

    setState(() {
      _savingRole = true;
    });

    try {
      await Supabase.instance.client
          .from('usuario')
          .update({'rol': newRole}).eq('id_usuario', user.idUsuario);

      await _fetch();

      if (!mounted) return;
      setState(() {
        _savingRole = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rol actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingRole = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar rol: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        final telefono = user.telefono; // puede ser null

        body = Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header con avatar
              CircleAvatar(
                radius: 42,
                backgroundImage: (user.fotoUrl != null &&
                        user.fotoUrl!.isNotEmpty)
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
                label: Text(
                  user.rol.toUpperCase(),
                ),
                backgroundColor: cs.primaryContainer,
                labelStyle: TextStyle(color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 16),

              // Info de contacto
              _infoTile(
                icon: Icons.alternate_email,
                label: 'Correo',
                value: user.correo, // correo es no-nullable
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

              // 🔹 Gestión de rol (Estudiante / Administrador)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gestión de rol',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingRole || _selectedRole == user.rol
                      ? null
                      : () => _updateUserRole(_selectedRole),
                  icon: _savingRole
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Guardar cambios de rol'),
                ),
              ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
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
