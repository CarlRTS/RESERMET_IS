import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';

class ReservasActivasScreen extends StatefulWidget {
  const ReservasActivasScreen({super.key});

  @override
  State<ReservasActivasScreen> createState() => _ReservasActivasScreenState();
}

class _ReservasActivasScreenState extends State<ReservasActivasScreen> {
  final _reservaService = ReservaService();

  bool _loading = true;
  bool _error = false;
  String? _errorMsg;

  List<Map<String, dynamic>> _reservas = [];

  Timer? _tick; // para refrescar el contador en pantalla (sin tocar la BD)

  @override
  void initState() {
    super.initState();
    _fetch();
    // Refrescar la UI cada segundo para el contador
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMsg = null;
    });
    try {
      final data = await _reservaService.getReservasActivasRaw();
      setState(() {
        _reservas = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMsg = 'Error al cargar reservas: $e';
      });
    }
  }

  Future<void> _finalizar(int idReserva) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar reserva'),
        content: const Text(
          '¿Confirmas finalizar esta reserva? Esta acción marcará la reserva como "finalizada".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _reservaService.finalizarReserva(idReserva: idReserva);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva finalizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Formatea el tiempo restante hacia hh:mm:ss (o “Vencida”)
  String _formatRemaining(DateTime finUtc) {
    final nowUtc = DateTime.now().toUtc();
    final diff = finUtc.difference(nowUtc);
    if (diff.isNegative) return '00:00:00';
    final totalSeconds = diff.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Badge para estado visual
  Widget _buildEstadoChip(DateTime finUtc) {
    final nowUtc = DateTime.now().toUtc();
    final vencida = nowUtc.isAfter(finUtc);
    return Chip(
      backgroundColor: vencida ? Colors.red.shade50 : Colors.green.shade50,
      avatar: Icon(
        vencida ? Icons.warning_amber_rounded : Icons.timer_outlined,
        color: vencida ? Colors.red : Colors.green,
        size: 18,
      ),
      label: Text(
        vencida ? 'VENCIDA' : 'ACTIVA',
        style: TextStyle(
          color: vencida ? Colors.red : Colors.green.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Tarjeta de una reserva
  Widget _buildReservaCard(Map<String, dynamic> r) {
    // Campos esperados: id_reserva, id_articulo, id_usuario, inicio, fin, estado, articulo(nombre)
    final idReserva = r['id_reserva'] as int;
    final idArticulo = r['id_articulo'] as int?;
    final estado = (r['estado'] ?? '') as String;

    // inicio/fin vienen como timestamptz -> ISO. Parsearlos a UTC.
    final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
    final fin = DateTime.tryParse('${r['fin']}')?.toUtc();

    // articulo puede venir como mapa anidado: {"nombre": "..."}
    String nombreArticulo = 'Artículo #${idArticulo ?? '-'}';
    final articuloObj = r['articulo'];
    if (articuloObj is Map && articuloObj['nombre'] != null) {
      nombreArticulo = articuloObj['nombre'].toString();
    }

    final vencida = fin != null ? DateTime.now().toUtc().isAfter(fin) : false;
    final restante = fin != null ? _formatRemaining(fin) : '--:--:--';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    nombreArticulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: UnimetPalette.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (fin != null) _buildEstadoChip(fin),
              ],
            ),
            const SizedBox(height: 8),
            // Detalles
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _kv('Estado', estado),
                _kv('Inicio (UTC)', inicio?.toIso8601String() ?? '-'),
                _kv('Fin (UTC)', fin?.toIso8601String() ?? '-'),
                _kv('Tiempo restante', restante),
              ],
            ),
            const SizedBox(height: 12),
            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (vencida)
                  Tooltip(
                    message: 'La reserva ya venció. Puedes finalizarla.',
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.flag),
                      label: const Text('Finalizar'),
                      onPressed: () => _finalizar(idReserva),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Finalizar ahora'),
                    onPressed: () => _finalizar(idReserva),
                  ),
              ],
            ),
          ],
        ),
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

  Future<void> _syncVencidas() async {
    // Este botón es opcional. Llama a la RPC/Update que marca como finalizadas las vencidas.
    try {
      final n = await _reservaService.finalizarVencidas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n > 0
                ? 'Se finalizaron $n reservas vencidas.'
                : 'No hay reservas vencidas por finalizar.',
          ),
        ),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sincronizando vencidas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas activas'),
        backgroundColor: UnimetPalette.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sincronizar vencidas',
            onPressed: _syncVencidas,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: _fetch,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMsg ?? 'Error'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _fetch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _reservas.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'No hay reservas activas',
                            style: TextStyle(color: theme.disabledColor),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _reservas.length,
                      itemBuilder: (_, i) => _buildReservaCard(_reservas[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetch,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualizar'),
      ),
    );
  }
}
