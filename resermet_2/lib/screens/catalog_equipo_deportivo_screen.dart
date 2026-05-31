// lib/screens/catalog_equipo_deportivo_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/equipo_deportivo.dart';
import '../services/reserva_service.dart';
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
  final _reservaService = ReservaService();

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<EquipoDeportivo> _all = [];
  List<EquipoDeportivo> _filtered = [];
  final Map<int, DateTime?> _horasDisponibilidad = {};

  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadOnce();
    _sub = _client
        .from('equipo_deportivo')
        .stream(primaryKey: ['id_articulo'])
        .listen((_) => _loadOnce());
  }

  Future<void> _loadOnce() async {
    await _reservaService.finalizarVencidas(); // ← NUEVO
    final rows = await _client
        .from('equipo_deportivo')
        .select('*, articulo(*)');

    final equipos = rows.map((m) => EquipoDeportivo.fromSupabase(m)).toList()
      ..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

    final Map<int, DateTime?> horas = {};
    for (final e in equipos) {
      if (e.cantidadDisponible <= 0) {
        horas[e.idObjeto] =
            await _reservaService.getHoraDisponibilidad(e.idObjeto);
      } else {
        horas[e.idObjeto] = null;
      }
    }

    setState(() {
      _all = equipos;
      _horasDisponibilidad.addAll(horas);
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

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
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
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty
              ? 'No hay artículos.'
              : 'No hay resultados para "$_query".',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = _filtered[i];
        final (color, label) = _stateChip(e);
        final horaDisp = _horasDisponibilidad[e.idObjeto];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.unimetBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForTipoEquipo(e.tipoEquipo),
                  color: AppColors.unimetBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.tipoEquipo.isEmpty ? 'Equipo' : e.tipoEquipo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(color: color, label: label),
                        const SizedBox(width: 8),
                        Text(
                          'Disp: ${e.cantidadDisponible}/${e.cantidadTotal}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (horaDisp != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 13, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Disponible a las ${_hhmm(horaDisp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}