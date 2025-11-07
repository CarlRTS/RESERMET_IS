// lib/screens/admin/users_list_screen.dart
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

  /// Lista mostrada actualmente
  List<UserProfile> _users = [];

  /// Caché completa para filtrar en memoria (sin tocar el servicio)
  List<UserProfile> _allUsers = [];

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
        _allUsers = data;
        _users = data; // vista inicial = todos
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

  /// Normaliza texto: minúsculas + sin acentos/ñ para comparar de forma robusta
  String _norm(String? s) {
    if (s == null) return '';
    final lower = s.toLowerCase();

    // Reemplazos comunes sin depender de paquetes externos
    return lower
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ') // colapsa espacios múltiples
        .trim();
  }

  /// Filtra en memoria con múltiples tokens (nombre, apellido, correo)
  List<UserProfile> _filterLocal(String rawQuery) {
    final query = _norm(rawQuery);
    if (query.isEmpty) return List<UserProfile>.from(_allUsers);

    // Separamos por espacios; cada token debe aparecer en el texto combinado
    final tokens = query.split(' ').where((t) => t.isNotEmpty).toList();

    return _allUsers.where((u) {
      final combined = _norm('${u.nombre ?? ""} ${u.apellido ?? ""} ${u.correo}');
      // Cada token debe estar en el string combinado (orden libre)
      for (final t in tokens) {
        if (!combined.contains(t)) return false;
      }
      return true;
    }).toList();
  }

  /// Búsqueda principal: usa filtro local para soportar "nombre apellido" flexible
  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      // sin texto => mostrar todos (desde caché)
      setState(() => _users = List<UserProfile>.from(_allUsers));
      return;
    }

    // Para mantener UI consistente mostramos loading breve (opcional)
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Filtrado local robusto
      final filtered = _filterLocal(query);

      if (!mounted) return;
      setState(() {
        _users = filtered;
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
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
    final initials =
        '${(u.nombre ?? '').isNotEmpty ? u.nombre![0] : ''}${(u.apellido ?? '').isNotEmpty ? u.apellido![0] : ''}';
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
                            onRefresh: () async {
                              // Recarga lista completa y vuelve a aplicar el filtro actual
                              await _loadAll();
                              if (mounted) {
                                setState(() {
                                  _users = _filterLocal(_searchCtrl.text);
                                });
                              }
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _users.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final u = _users[index];

                                // Nombre completo (puede venir vacío si el usuario no lo completó)
                                final fullName =
                                    '${u.nombre ?? ''} ${u.apellido ?? ''}'.trim();

                                // Si no hay nombre, usamos el correo (no-nullable en tu modelo)
                                final title = fullName.isEmpty ? u.correo : fullName;

                                // Subtítulo: siempre el correo
                                final subtitle = u.correo;

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
                                    // Al volver, refrescamos (respetando el query actual)
                                    if (!mounted) return;
                                    setState(() {
                                      _users = _filterLocal(_searchCtrl.text);
                                    });
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
