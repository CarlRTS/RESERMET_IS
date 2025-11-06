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

  // ELIMINADA: bool _loading = true; // No se usa
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
      // ELIMINADA: _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getMisReservasRaw();
      setState(() {
        _reservas = data;
        // ELIMINADA: _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar tus reservas: $e';
        // ELIMINADA: _loading = false;
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
      (now.isAfter(inicio) || now.isAtSameMomentAs(inicio)) &&
      now.isBefore(fin);

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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.cancelarReserva(idReserva: idReserva);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finalizarAhora(int idReserva) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar ahora'),
        content: const Text(
          '¿Deseas finalizar la reserva antes de su hora de fin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, finalizar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.finalizarReservaUsuario(idReserva: idReserva);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva finalizada'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar: $e'),
          backgroundColor: Colors.red,
        ),
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
    }).toList()..sort((a, b) => '${a['fin']}'.compareTo('${b['fin']}'));
  }

  List<Map<String, dynamic>> _filtrarFuturas() {
    final now = DateTime.now().toUtc();
    return _reservas.where((r) {
      final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
      if (inicio == null) return false;
      return _esFutura(now, inicio) && (r['estado'] != 'cancelada');
    }).toList()..sort((a, b) => '${a['inicio']}'.compareTo('${b['inicio']}'));
  }

  List<Map<String, dynamic>> _filtrarHistorial() {
    return _reservas.where((r) {
      final estado = (r['estado'] ?? '').toString();
      return estado == 'finalizada' || estado == 'cancelada';
    }).toList()..sort((a, b) => '${b['inicio']}'.compareTo('${a['inicio']}'));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final activas = _filtrarActivas();
    final futuras = _filtrarFuturas();
    final historial = _filtrarHistorial();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            'Mis Reservas',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.unimetBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded, size: 35.0),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🟥 Bloque de error (solo si ocurre)
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Contadores de reservas
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCounter('Activas', activas.length, Colors.green),
                _buildCounter('Futuras', futuras.length, Colors.orange),
                _buildCounter('Historial', historial.length, Colors.grey),
              ],
            ),
          ),

          // Tabs con nuevo diseño
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(
                      4,
                    ), // Espacio interno adicional
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.unimetBlue,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      tabs: [
                        Tab(text: 'Activas (${activas.length})'),
                        Tab(text: 'Futuras (${futuras.length})'),
                        Tab(text: 'Historial (${historial.length})'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

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
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String title, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildLista(
    List<Map<String, dynamic>> data, {
    required _TipoLista tipo,
  }) {
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.unimetBlue,
      child: data.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Column(
                  children: [
                    Icon(
                      _getEmptyIcon(tipo),
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getEmptyMessage(tipo),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
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
                  detalleTiempo =
                      'Empieza: ${_formatDateTimeShort(inicio.toLocal())}';
                }

                // Determinar icono y color según el tipo de artículo
                final (icono, colorIcono) = _obtenerIconoYColor(r);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con icono y estado - COMPLETAMENTE RESPONSIVE
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorIcono.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icono, color: colorIcono, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombreArticulo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getTipoArticulo(r),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 60,
                                  maxWidth: 80,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(
                                    tipo,
                                    estado,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getEstadoColor(
                                      tipo,
                                      estado,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _getEstadoText(tipo, estado),
                                  style: TextStyle(
                                    color: _getEstadoColor(tipo, estado),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Información de tiempo - DISEÑO VERTICAL PARA TODOS (EVITA OVERFLOW)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTimeInfoCompact(
                                'Inicio',
                                inicio?.toLocal(),
                              ),
                              const SizedBox(height: 6),
                              _buildTimeInfoCompact('Fin', fin?.toLocal()),
                              if (tipo == _TipoLista.activas) ...[
                                const SizedBox(height: 6),
                                _buildTimeInfoCompact(
                                  'Tiempo Restante',
                                  null,
                                  customValue: detalleTiempo,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Acciones
                          if (tipo != _TipoLista.historial)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  if (tipo == _TipoLista.futuras)
                                    _buildActionButtonCompact(
                                      icon: Icons.cancel_rounded,
                                      label: 'Cancelar',
                                      color: Colors.red,
                                      onPressed: () => _cancelar(idReserva),
                                    ),
                                  if (tipo == _TipoLista.activas)
                                    _buildActionButtonCompact(
                                      icon: Icons.flag_rounded,
                                      label: 'Finalizar',
                                      color: AppColors.unimetBlue,
                                      onPressed: () =>
                                          _finalizarAhora(idReserva),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTimeInfoCompact(
    String label,
    DateTime? date, {
    String? customValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            customValue ?? (date != null ? _formatDateTimeShort(date) : '-'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonCompact({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para obtener icono y color según el artículo
  (IconData, Color) _obtenerIconoYColor(Map<String, dynamic> reserva) {
    final articulo = reserva['articulo'] is Map
        ? Map<String, dynamic>.from(reserva['articulo'] as Map)
        : <String, dynamic>{};

    final nombre = (articulo['nombre'] ?? '').toString().toLowerCase();
    final tipo =
        (articulo['tipo'] ??
                articulo['categoria'] ??
                articulo['tipo_articulo'] ??
                '')
            .toString()
            .toLowerCase();

    if (nombre.contains('ps') ||
        nombre.contains('xbox') ||
        nombre.contains('nintendo') ||
        nombre.contains('switch') ||
        nombre.contains('consola') ||
        tipo.contains('consola')) {
      return (Icons.sports_esports_rounded, AppColors.unimetOrange);
    }

    if (nombre.contains('cubículo') ||
        nombre.contains('cubiculo') ||
        nombre.contains('sala') ||
        nombre.contains('estudio') ||
        tipo.contains('cubículo') ||
        tipo.contains('sala')) {
      return (Icons.meeting_room_rounded, AppColors.unimetBlue);
    }

    if (nombre.contains('balón') ||
        nombre.contains('balon') ||
        nombre.contains('pelota') ||
        nombre.contains('raqueta') ||
        nombre.contains('equipo') ||
        tipo.contains('deportivo') ||
        tipo.contains('equipo')) {
      return (Icons.sports_soccer_rounded, Colors.green);
    }

    return (Icons.event_available_rounded, Colors.teal);
  }

  String _getTipoArticulo(Map<String, dynamic> reserva) {
    final articulo = reserva['articulo'] is Map
        ? Map<String, dynamic>.from(reserva['articulo'] as Map)
        : <String, dynamic>{};

    final nombre = (articulo['nombre'] ?? '').toString().toLowerCase();
    final tipo =
        (articulo['tipo'] ??
                articulo['categoria'] ??
                articulo['tipo_articulo'] ??
                '')
            .toString()
            .toLowerCase();

    if (nombre.contains('ps') ||
        nombre.contains('xbox') ||
        nombre.contains('nintendo') ||
        nombre.contains('switch') ||
        nombre.contains('consola') ||
        tipo.contains('consola')) {
      return 'Consola';
    }

    if (nombre.contains('cubículo') ||
        nombre.contains('cubiculo') ||
        nombre.contains('sala') ||
        nombre.contains('estudio') ||
        tipo.contains('cubículo') ||
        tipo.contains('sala')) {
      return 'Cubículo';
    }

    if (nombre.contains('balón') ||
        nombre.contains('balon') ||
        nombre.contains('pelota') ||
        nombre.contains('raqueta') ||
        nombre.contains('equipo') ||
        tipo.contains('deportivo') ||
        tipo.contains('equipo')) {
      return 'Deportivo';
    }

    return 'Artículo';
  }

  Color _getEstadoColor(_TipoLista tipo, String estado) {
    switch (tipo) {
      case _TipoLista.activas:
        return Colors.green;
      case _TipoLista.futuras:
        return Colors.orange;
      case _TipoLista.historial:
        return estado == 'finalizada' ? Colors.green : Colors.red;
    }
  }

  String _getEstadoText(_TipoLista tipo, String estado) {
    switch (tipo) {
      case _TipoLista.activas:
        return 'ACTIVA';
      case _TipoLista.futuras:
        return 'FUTURA';
      case _TipoLista.historial:
        return estado.toUpperCase();
    }
  }

  IconData _getEmptyIcon(_TipoLista tipo) {
    switch (tipo) {
      case _TipoLista.activas:
        return Icons.play_circle_outline_rounded;
      case _TipoLista.futuras:
        return Icons.schedule_outlined;
      case _TipoLista.historial:
        return Icons.history_toggle_off_rounded;
    }
  }

  String _getEmptyMessage(_TipoLista tipo) {
    switch (tipo) {
      case _TipoLista.activas:
        return 'No tienes reservas activas';
      case _TipoLista.futuras:
        return 'No tienes reservas futuras';
      case _TipoLista.historial:
        return 'No hay historial de reservas';
    }
  }

  String _formatDateTimeShort(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

enum _TipoLista { activas, futuras, historial }
