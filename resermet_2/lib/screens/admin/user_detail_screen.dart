// lib/screens/admin/user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/services/usuario_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _service = UsuarioService();

  bool _loading = true;
  String? _error;
  UserProfile? _user;

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
      if (data == null) {
        setState(() {
          _error = 'Usuario no encontrado';
          _loading = false;
        });
        return;
      }
      setState(() {
        _user = data;
        _loading = false;
      });
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Usuario')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header con avatar
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: (_user!.fotoUrl != null && _user!.fotoUrl!.isNotEmpty)
                            ? NetworkImage(_user!.fotoUrl!)
                            : null,
                        child: (_user!.fotoUrl == null || _user!.fotoUrl!.isEmpty)
                            ? Text(
                                _initials(_user!),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _displayName(_user!),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text((_user!.rol ?? 'estudiante').toUpperCase()),
                        backgroundColor: cs.primaryContainer,
                        labelStyle: TextStyle(color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(height: 16),

                      // Info de contacto
                      _infoTile(
                        icon: Icons.alternate_email,
                        label: 'Correo',
                        value: _user!.correo ?? '—',
                        action: (_user!.correo != null && _user!.correo!.isNotEmpty)
                            ? () => _launchEmail(_user!.correo!)
                            : null,
                        actionIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 8),
                      _infoTile(
                        icon: Icons.phone_iphone,
                        label: 'Teléfono',
                        value: _user!.telefono ?? '—',
                        action: (_user!.telefono != null && _user!.telefono!.isNotEmpty)
                            ? () => _launchPhone(_user!.telefono!)
                            : null,
                        actionIcon: Icons.phone_outlined,
                      ),
                    ],
                  ),
                ),
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
                Text(label,
                    style: TextStyle(color: cs.onSurface.withOpacity(.7), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
