import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/services/usuario_service.dart';

/// Bottom sheet para seleccionar múltiples usuarios (máximo 6).
/// Devuelve `List<UserProfile>` al cerrar con "Agregar".
class UserMultiPickerSheet extends StatefulWidget {
  const UserMultiPickerSheet({
    super.key,
    this.initialSelected,
    this.title = 'Seleccionar estudiantes',
    this.hintText = 'Buscar por nombre, correo...',
    this.maxSelected = 6,
  });

  final List<UserProfile>? initialSelected;
  final String title;
  final String hintText;
  final int maxSelected;

  @override
  State<UserMultiPickerSheet> createState() => _UserMultiPickerSheetState();
}

class _UserMultiPickerSheetState extends State<UserMultiPickerSheet> {
  final _service = UsuarioService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<UserProfile> _results = [];

  /// Key: idUsuario
  final Map<String, UserProfile> _selected = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      for (final u in widget.initialSelected!) {
        _selected[u.idUsuario] = u;
      }
    }
    _loadAll();
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
        _results = data;
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
      await _loadAll();
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
        _results = data;
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

  void _toggleSelection(UserProfile u) {
    final already = _selected.containsKey(u.idUsuario);
    if (already) {
      setState(() => _selected.remove(u.idUsuario));
      return;
    }
    if (_selected.length >= widget.maxSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo ${widget.maxSelected} acompañantes')),
      );
      return;
    }
    setState(() => _selected[u.idUsuario] = u);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final restantes = widget.maxSelected - _selected.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (restantes < widget.maxSelected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Seleccionados: ${_selected.length} / ${widget.maxSelected}',
                      style: TextStyle(color: cs.primary),
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Text(_error!, style: TextStyle(color: cs.error)),
                      )
                    : _results.isEmpty
                    ? const Center(child: Text('Sin resultados'))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final u = _results[i];
                          final key = u.idUsuario;
                          final selected = _selected.containsKey(key);

                          final nombreCompleto = [
                            if ((u.nombre ?? '').isNotEmpty) u.nombre,
                            if ((u.apellido ?? '').isNotEmpty) u.apellido,
                          ].whereType<String>().join(' ').trim();

                          return ListTile(
                            onTap: () => _toggleSelection(u),
                            leading: _avatar(u),
                            title: Text(
                              nombreCompleto.isNotEmpty
                                  ? nombreCompleto
                                  : u.correo,
                            ),
                            subtitle: Text(u.correo),
                            trailing: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected ? cs.primary : cs.outline,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pop<List<UserProfile>>([]),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop<List<UserProfile>>(_selected.values.toList());
                        },
                        icon: const Icon(Icons.check),
                        label: Text('Agregar (${_selected.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(UserProfile u) {
    final base = [
      if ((u.nombre ?? '').isNotEmpty) u.nombre,
      if ((u.apellido ?? '').isNotEmpty) u.apellido,
    ].whereType<String>().join(' ').trim();

    final initialsFrom = base.isNotEmpty ? base : 'U';
    final initials = initialsFrom
        .trim()
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    final cs = Theme.of(context).colorScheme;
    final foto = u.fotoUrl;
    return CircleAvatar(
      backgroundColor: cs.primary.withOpacity(0.1),
      foregroundColor: cs.primary,
      backgroundImage: (foto != null && foto.isNotEmpty)
          ? NetworkImage(foto)
          : null,
      child: (foto == null || foto.isEmpty)
          ? Text(
              initials.isEmpty ? 'U' : initials.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}
