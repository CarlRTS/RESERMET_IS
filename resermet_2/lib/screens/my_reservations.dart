// lib/screens/my_reservations.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _service = ReservaService();

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
    setState(() => _error = null);
    try {
      final data = await _service.getMisReservasRaw();
      setState(() => _reservas = data);
    } catch (e) {
      setState(() => _error = 'Error al cargar tus reservas: $e');
    }
  }

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

  Future<void> _cancelar(int idReserva) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar reserva', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('¿Deseas cancelar esta reserva? Esto liberará el recurso para otros estudiantes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalizar ahora', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('¿Deseas finalizar la reserva antes de su hora de fin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.unimetBlue, foregroundColor: Colors.white),
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

  Future<void> _verIntegrantes(int idReserva) async {
    try {
      final reserva = await Supabase.instance.client
          .from('reserva')
          .select('id_usuario, companions_user_ids')
          .eq('id_reserva', idReserva)
          .single();

      final titularId = (reserva['id_usuario'] as String?) ?? '';
      final companions =
          (reserva['companions_user_ids'] as List?)?.cast<String>() ?? const <String>[];

      final ids = <String>[
        if (titularId.isNotEmpty) titularId,
        ...companions,
      ];

      if (ids.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta reserva no tiene integrantes')),
        );
        return;
      }

      final perfiles = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario, nombre, apellido, correo, rol, foto_url')
          .inFilter('id_usuario', ids);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _IntegrantesSheet(
          integrantes: (perfiles as List).cast<Map<String, dynamic>>(),
          titularId: titularId,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando integrantes: $e')),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final activas = _filtrarActivas();
    final futuras = _filtrarFuturas();
    final historial = _filtrarHistorial();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // ===== HEADER =====
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.unimetBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mis Reservas',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28, // ← más grande
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_reservas.length} reservas en total',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15, // ← más grande
                          ),
                        ),
                      ],
                    ),
                  ),
                  _headerCounter('Activas', activas.length, Colors.greenAccent.shade400),
                  const SizedBox(width: 14),
                  _headerCounter('Futuras', futuras.length, Colors.orangeAccent.shade200),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: _fetch,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== ERROR =====
          if (_error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ===== TABS + CONTENIDO =====
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.unimetBlue,
                      unselectedLabelColor: Colors.grey.shade500,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), // ← más grande
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.unimetBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.unimetBlue.withOpacity(0.2)),
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

  Widget _headerCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 22, // ← más grande
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLista(List<Map<String, dynamic>> data, {required _TipoLista tipo}) {
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.unimetBlue,
      child: data.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Icon(_getEmptyIcon(tipo), size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 14),
                      Text(
                        _getEmptyMessage(tipo),
                        style: TextStyle(
                          fontSize: 16, // ← más grande
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
                final bool esInvitado = (r['es_invitado'] == true);
                final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
                final fin = DateTime.tryParse('${r['fin']}')?.toUtc();
                final (icono, colorIcono) = _obtenerIconoYColor(r);
                final estadoColor = _getEstadoColor(tipo, estado);
                final estadoText = _getEstadoText(tipo, estado);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorIcono.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icono, color: colorIcono, size: 24),
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
                                      fontSize: 16, // ← más grande
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getTipoArticulo(r),
                                    style: TextStyle(
                                      fontSize: 13, // ← más grande
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: estadoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: estadoColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                estadoText,
                                style: TextStyle(
                                  color: estadoColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12, // ← más grande
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (esInvitado) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'INVITADO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],

                        Divider(color: Colors.grey.shade100, height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: _timeChip(
                                Icons.play_arrow_rounded,
                                'Inicio',
                                inicio != null ? _formatDateTimeShort(inicio.toLocal()) : '-',
                                Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _timeChip(
                                Icons.stop_rounded,
                                'Fin',
                                fin != null ? _formatDateTimeShort(fin.toLocal()) : '-',
                                Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        if (tipo == _TipoLista.activas && fin != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timer_rounded, size: 16, color: Colors.green.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Tiempo restante: ${_formatRemaining(fin)}',
                                  style: TextStyle(
                                    fontSize: 14, // ← más grande
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _actionBtn(
                              icon: Icons.group_outlined,
                              label: 'Integrantes',
                              color: AppColors.unimetBlue,
                              onTap: () => _verIntegrantes(idReserva),
                            ),
                            if (tipo != _TipoLista.historial && !esInvitado) ...[
                              const SizedBox(width: 8),
                              if (tipo == _TipoLista.futuras)
                                _actionBtn(
                                  icon: Icons.cancel_outlined,
                                  label: 'Cancelar',
                                  color: Colors.red,
                                  onTap: () => _cancelar(idReserva),
                                ),
                              if (tipo == _TipoLista.activas)
                                _actionBtn(
                                  icon: Icons.flag_rounded,
                                  label: 'Finalizar',
                                  color: AppColors.unimetBlue,
                                  onTap: () => _finalizarAhora(idReserva),
                                ),
                            ],
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

  Widget _timeChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13, // ← más grande
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13, // ← más grande
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _obtenerIconoYColor(Map<String, dynamic> reserva) {
    final articulo = reserva['articulo'] is Map
        ? Map<String, dynamic>.from(reserva['articulo'] as Map)
        : <String, dynamic>{};
    final nombre = (articulo['nombre'] ?? '').toString().toLowerCase();
    final tipo = (articulo['tipo'] ?? articulo['categoria'] ?? articulo['tipo_articulo'] ?? '')
        .toString().toLowerCase();

    if (nombre.contains('ps') || nombre.contains('xbox') ||
        nombre.contains('nintendo') || nombre.contains('switch') ||
        nombre.contains('consola') || tipo.contains('consola')) {
      return (Icons.sports_esports_rounded, AppColors.unimetOrange);
    }
    if (nombre.contains('cubículo') || nombre.contains('cubiculo') ||
        nombre.contains('sala') || nombre.contains('estudio') ||
        tipo.contains('cubículo') || tipo.contains('sala')) {
      return (Icons.meeting_room_rounded, AppColors.unimetBlue);
    }
    if (nombre.contains('balón') || nombre.contains('balon') ||
        nombre.contains('pelota') || nombre.contains('raqueta') ||
        nombre.contains('equipo') || tipo.contains('deportivo') ||
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
    final tipo = (articulo['tipo'] ?? articulo['categoria'] ?? articulo['tipo_articulo'] ?? '')
        .toString().toLowerCase();

    if (nombre.contains('ps') || nombre.contains('xbox') ||
        nombre.contains('nintendo') || nombre.contains('switch') ||
        nombre.contains('consola') || tipo.contains('consola')) return 'Consola';
    if (nombre.contains('cubículo') || nombre.contains('cubiculo') ||
        nombre.contains('sala') || nombre.contains('estudio') ||
        tipo.contains('cubículo') || tipo.contains('sala')) return 'Cubículo';
    if (nombre.contains('balón') || nombre.contains('balon') ||
        nombre.contains('pelota') || nombre.contains('raqueta') ||
        nombre.contains('equipo') || tipo.contains('deportivo') ||
        tipo.contains('equipo')) return 'Deportivo';
    return 'Artículo';
  }

  Color _getEstadoColor(_TipoLista tipo, String estado) {
    switch (tipo) {
      case _TipoLista.activas: return Colors.green;
      case _TipoLista.futuras: return Colors.orange;
      case _TipoLista.historial: return estado == 'finalizada' ? Colors.green : Colors.red;
    }
  }

  String _getEstadoText(_TipoLista tipo, String estado) {
    switch (tipo) {
      case _TipoLista.activas: return 'ACTIVA';
      case _TipoLista.futuras: return 'FUTURA';
      case _TipoLista.historial: return estado.toUpperCase();
    }
  }

  IconData _getEmptyIcon(_TipoLista tipo) {
    switch (tipo) {
      case _TipoLista.activas: return Icons.play_circle_outline_rounded;
      case _TipoLista.futuras: return Icons.schedule_outlined;
      case _TipoLista.historial: return Icons.history_toggle_off_rounded;
    }
  }

  String _getEmptyMessage(_TipoLista tipo) {
    switch (tipo) {
      case _TipoLista.activas: return 'No tienes reservas activas';
      case _TipoLista.futuras: return 'No tienes reservas futuras';
      case _TipoLista.historial: return 'No hay historial de reservas';
    }
  }

  String _formatDateTimeShort(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

enum _TipoLista { activas, futuras, historial }

class _IntegrantesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> integrantes;
  final String titularId;

  const _IntegrantesSheet({required this.integrantes, required this.titularId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final ordenados = [...integrantes]
      ..sort((a, b) {
        final aTit = a['id_usuario'] == titularId ? 0 : 1;
        final bTit = b['id_usuario'] == titularId ? 0 : 1;
        return aTit.compareTo(bTit);
      });

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Text(
              'Integrantes de la reserva',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ordenados.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
                itemBuilder: (_, i) {
                  final u = ordenados[i];
                  final isTitular = u['id_usuario'] == titularId;
                  final nombre = (u['nombre'] ?? '').toString().trim();
                  final apellido = (u['apellido'] ?? '').toString().trim();
                  final nombreCompleto = ('$nombre $apellido').trim();
                  final correo = (u['correo'] ?? '').toString();
                  final rolSistema = (u['rol'] ?? '').toString();
                  final foto = (u['foto_url'] ?? '').toString();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                      backgroundColor: AppColors.unimetBlue.withOpacity(0.1),
                      child: foto.isEmpty
                          ? Text(
                              (nombreCompleto.isNotEmpty
                                      ? nombreCompleto[0]
                                      : (correo.isNotEmpty ? correo[0] : 'U'))
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.unimetBlue,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      nombreCompleto.isNotEmpty ? nombreCompleto : correo,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      '${isTitular ? "Titular" : "Acompañante"} · $rolSistema',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    trailing: isTitular
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Titular',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cerrar'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}