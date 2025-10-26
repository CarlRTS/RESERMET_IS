import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/services/usuario_service.dart';
import 'user_detail_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _service = UsuarioService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<UserProfile> _users = [];

  @override
  void initState() {
    super.initState();
    _loadAll(); // carga inicial: todos, ordenados
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.listAllUsersOrdered();
      if (!mounted) return;
      setState(() {
        _users = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error cargando usuarios: $e';
        _loading = false;
      });
    }
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      await _loadAll(); // sin texto => mostrar todos
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _users = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error buscando usuarios: $e';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value);
    });
  }

  Future<void> _call(String? phone) async {
    final tel = phone?.trim();
    if (tel == null || tel.isEmpty) return;
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _email(String? email) async {
    final mail = email?.trim();
    if (mail == null || mail.isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: mail,
      query: Uri.encodeFull('subject=Contacto UNIMET&body=Hola,'),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _avatar(UserProfile u) {
    final foto = u.fotoUrl;
    final initials = '${(u.nombre ?? '').isNotEmpty ? u.nombre![0] : ''}${(u.apellido ?? '').isNotEmpty ? u.apellido![0] : ''}';
    return CircleAvatar(
      radius: 20,
      backgroundImage: (foto != null && foto.isNotEmpty) ? NetworkImage(foto) : null,
      child: (foto == null || foto.isEmpty)
          ? Text(
              initials.isEmpty ? 'U' : initials.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, apellido o correo…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
                    : _users.isEmpty
                        ? const Center(child: Text('No hay usuarios para mostrar'))
                        : RefreshIndicator(
                            onRefresh: () => _search(_searchCtrl.text),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _users.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final u = _users[index];
                                final title = '${u.nombre ?? ''} ${u.apellido ?? ''}'.trim().isEmpty
                                    ? (u.correo ?? 'Usuario')
                                    : '${u.nombre ?? ''} ${u.apellido ?? ''}'.trim();
                                final subtitle = u.correo ?? '-';

                                return ListTile(
                                  leading: _avatar(u),
                                  title: Text(title),
                                  subtitle: Text(subtitle, overflow: TextOverflow.ellipsis),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: 'Enviar correo',
                                        icon: const Icon(Icons.email_outlined),
                                        onPressed: () => _email(u.correo),
                                      ),
                                      IconButton(
                                        tooltip: 'Llamar',
                                        icon: const Icon(Icons.phone_outlined),
                                        onPressed: () => _call(u.telefono),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => UserDetailScreen(userId: u.idUsuario),
                                      ),
                                    );
                                    // Al volver, refrescamos la lista (respetando búsqueda)
                                    if (!mounted) return;
                                    await _search(_searchCtrl.text);
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
