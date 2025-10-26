// lib/screens/my_reservations.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resermet_2/services/reserva_service.dart';
import '../utils/app_colors.dart';

/// Pantalla: Mis Reservas (estudiante)
/// - Activas (countdown + finalizar ahora)
/// - Futuras (cancelar)
/// - Historial (finalizadas/canceladas, solo lectura)
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _service = ReservaService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reservas = [];

  Timer? _ticker;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetch();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getMisReservasRaw();
      setState(() {
        _reservas = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar tus reservas: $e';
        _loading = false;
      });
    }
  }

  // ---------- Helpers ----------
  String _formatRemaining(DateTime finUtc) {
    final now = DateTime.now().toUtc();
    final diff = finUtc.difference(now);
    if (diff.isNegative) return '00:00:00';
    final s = diff.inSeconds;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  bool _esFutura(DateTime now, DateTime inicio) => now.isBefore(inicio);
  bool _esActiva(DateTime now, DateTime inicio, DateTime fin) =>
      (now.isAfter(inicio) || now.isAtSameMomentAs(inicio)) && now.isBefore(fin);

  // ---------- Acciones ----------
  Future<void> _cancelar(int idReserva) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text(
          '¿Deseas cancelar esta reserva? Esto liberará el recurso para otros estudiantes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.cancelarReserva(idReserva: idReserva);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada'), backgroundColor: Colors.green),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _finalizarAhora(int idReserva) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar ahora'),
        content: const Text('¿Deseas finalizar la reserva antes de su hora de fin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, finalizar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.finalizarReservaUsuario(idReserva: idReserva);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva finalizada'), backgroundColor: Colors.green),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al finalizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------- Filtros ----------
  List<Map<String, dynamic>> _filtrarActivas() {
    final now = DateTime.now().toUtc();
    return _reservas.where((r) {
      final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
      final fin = DateTime.tryParse('${r['fin']}')?.toUtc();
      if (inicio == null || fin == null) return false;
      return _esActiva(now, inicio, fin) && (r['estado'] == 'activa');
    }).toList()
      ..sort((a, b) => '${a['fin']}'.compareTo('${b['fin']}'));
  }

  List<Map<String, dynamic>> _filtrarFuturas() {
    final now = DateTime.now().toUtc();
    return _reservas.where((r) {
      final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
      if (inicio == null) return false;
      return _esFutura(now, inicio) && (r['estado'] != 'cancelada');
    }).toList()
      ..sort((a, b) => '${a['inicio']}'.compareTo('${b['inicio']}'));
  }

  List<Map<String, dynamic>> _filtrarHistorial() {
    return _reservas.where((r) {
      final estado = (r['estado'] ?? '').toString();
      return estado == 'finalizada' || estado == 'cancelada';
    }).toList()
      ..sort((a, b) => '${b['inicio']}'.compareTo('${a['inicio']}'));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final activas = _filtrarActivas();
    final futuras = _filtrarFuturas();
    final historial = _filtrarHistorial();

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Encabezado + refresh
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mis Reservas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.unimetBlue,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: _fetch,
                        icon: const Icon(Icons.refresh, color: AppColors.unimetBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 🟥 Bloque de error (solo si ocurre)
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],

                  const Text(
                    'Consulta, cancela o finaliza tus reservas.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.unimetBlue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.unimetBlue,
                    tabs: [
                      Tab(text: 'Activas (${activas.length})', icon: const Icon(Icons.play_circle_outline)),
                      Tab(text: 'Futuras (${futuras.length})', icon: const Icon(Icons.schedule)),
                      Tab(text: 'Historial (${historial.length})', icon: const Icon(Icons.history)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLista(activas, tipo: _TipoLista.activas),
                        _buildLista(futuras, tipo: _TipoLista.futuras),
                        _buildLista(historial, tipo: _TipoLista.historial),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLista(List<Map<String, dynamic>> data, {required _TipoLista tipo}) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: data.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No hay reservas en esta sección')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final r = data[index];
                final idReserva = r['id_reserva'] as int;
                final nombreArticulo =
                    (r['articulo'] is Map && r['articulo']['nombre'] != null)
                        ? r['articulo']['nombre'].toString()
                        : 'Artículo';
                final estado = (r['estado'] ?? '').toString();

                final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
                final fin = DateTime.tryParse('${r['fin']}')?.toUtc();

                String detalleTiempo = '-';
                if (tipo == _TipoLista.activas && fin != null) {
                  detalleTiempo = _formatRemaining(fin);
                } else if (tipo == _TipoLista.futuras && inicio != null) {
                  detalleTiempo = 'Empieza: ${inicio.toIso8601String()}';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                nombreArticulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.unimetBlue,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Chip(
                              backgroundColor: tipo == _TipoLista.activas
                                  ? Colors.green.shade50
                                  : (tipo == _TipoLista.futuras
                                      ? Colors.blue.shade50
                                      : Colors.grey.shade200),
                              label: Text(
                                tipo == _TipoLista.activas
                                    ? 'ACTIVA'
                                    : (tipo == _TipoLista.futuras ? 'FUTURA' : estado.toUpperCase()),
                                style: TextStyle(
                                  color: tipo == _TipoLista.activas
                                      ? Colors.green.shade700
                                      : (tipo == _TipoLista.futuras
                                          ? Colors.blue.shade700
                                          : Colors.black54),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            _kv('Inicio (UTC)', inicio?.toIso8601String() ?? '-'),
                            _kv('Fin (UTC)', fin?.toIso8601String() ?? '-'),
                            _kv(tipo == _TipoLista.activas ? 'Tiempo restante' : 'Detalle', detalleTiempo),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (tipo == _TipoLista.futuras)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar'),
                                onPressed: () => _cancelar(idReserva),
                              ),
                            if (tipo == _TipoLista.activas)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.flag),
                                label: const Text('Finalizar ahora'),
                                onPressed: () => _finalizarAhora(idReserva),
                              ),
                            if (tipo == _TipoLista.historial)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.info_outline),
                                label: const Text('Sin acciones'),
                                onPressed: null,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Flexible(child: Text(v)),
      ],
    );
  }
}

enum _TipoLista { activas, futuras, historial }

