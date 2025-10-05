// lib/screens/catalog_equipo_deportivo_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/equipo_deportivo.dart';
import '../utils/app_colors.dart';

class CatalogEquipoDeportivoScreen extends StatefulWidget {
  const CatalogEquipoDeportivoScreen({super.key});

  @override
  State<CatalogEquipoDeportivoScreen> createState() =>
      _CatalogEquipoDeportivoScreenState();
}

class _CatalogEquipoDeportivoScreenState
    extends State<CatalogEquipoDeportivoScreen> {
  final _client = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<EquipoDeportivo> _all = [];
  List<EquipoDeportivo> _filtered = [];
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadOnce();
    // Realtime en la tabla equipo_deportivo (join con articulo)
    _sub = _client
        .from('equipo_deportivo')
        .stream(
          primaryKey: ['id_articulo'],
        )
        .listen((_) => _loadOnce()); // refetch simple y robusto
  }

  Future<void> _loadOnce() async {
    final rows = await _client
        .from('equipo_deportivo')
        .select('*, articulo(*)');

    final equipos = rows.map((m) => EquipoDeportivo.fromSupabase(m)).toList()
      ..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

    setState(() {
      _all = equipos;
      _applyFilter();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _query = value;
        _applyFilter();
      });
    });
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    _filtered = _all
        .where((e) => q.isEmpty || e.nombre.toLowerCase().contains(q))
        .toList();
  }

  // Estado efectivo:
  // - Si cantidad_disponible > 0 y articulo.estado == 'disponible' => Disponible
  // - Si cantidad_disponible == 0 => Reservado / No disponible para otros
  // - Si articulo.estado == 'no disponible' => No disponible
  (Color, String) _stateChip(EquipoDeportivo e) {
    final base = e.estado.toLowerCase().trim();
    if (base == 'no disponible') {
      return (Colors.red, 'No disponible');
    }
    if (e.cantidadDisponible <= 0) {
      return (Colors.amber, 'Reservado');
    }
    return (Colors.green, 'Disponible');
  }

  IconData _iconForTipoEquipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'raqueta':
        return Icons.sports_tennis;
      case 'balon':
      case 'balón':
        return Icons.sports_soccer;
      case 'pesas':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridCount = (MediaQuery.of(context).size.width / 220).floor().clamp(
      2,
      4,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo • Equipo Deportivo'),
        backgroundColor: AppColors.unimetBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildGrid(gridCount)),
        ],
      ),
    );
  }

  Widget _buildGrid(int crossAxisCount) {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty
              ? 'No hay artículos.'
              : 'No hay resultados para “$_query”.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final e = _filtered[i];
        final (color, label) = _stateChip(e);
        final disabled = label != 'Disponible';

        final card = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled
                ? null
                : () {
                    /* detalle opcional */
                  },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Icon(
                          _iconForTipoEquipo(e.tipoEquipo),
                          size: 48,
                          color: AppColors.unimetBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.unimetBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _AvailabilityBadge(color: color, label: label),
                      const Spacer(),
                      Text(
                        e.tipoEquipo.isEmpty ? 'Equipo' : e.tipoEquipo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Disp: ${e.cantidadDisponible}/${e.cantidadTotal}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        return Opacity(
          opacity: disabled ? 0.6 : 1.0,
          child: IgnorePointer(ignoring: disabled, child: card),
        );
      },
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _AvailabilityBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
