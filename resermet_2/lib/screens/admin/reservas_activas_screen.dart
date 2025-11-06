import 'dart:async';
import 'package:flutter/material.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isAdmin = false;

  Timer? _tick; // para refrescar el contador en pantalla (sin tocar la BD)
  bool _busyActions = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _loadUserRole();
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

  // carga del rol del usuario para mostrar botón solo a administradores
  Future<void> _loadUserRole() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      // Ajusta el nombre de la tabla/columnas a tu esquema
      final row = await Supabase.instance.client
          .from('usuario')
          .select('rol')
          .eq('id_usuario', uid)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _isAdmin = (row != null && (row['rol'] ?? '') == 'administrador');
      });
    } catch (_) {
      // Si falla, dejamos _isAdmin = false sin romper nada
    }
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

  Future<void> _verIntegrantes(int idReserva) async {
    try {
      // 1) Tomamos titular y acompañantes de la reserva (por id)
      final reserva = await Supabase.instance.client
          .from('reserva') // <-- tu tabla real
          .select('id_usuario, companions_user_ids')
          .eq('id_reserva', idReserva)
          .single();

      final titularId = (reserva['id_usuario'] as String?) ?? '';
      final companions =
          (reserva['companions_user_ids'] as List?)?.cast<String>() ??
          const <String>[];

      final ids = <String>[if (titularId.isNotEmpty) titularId, ...companions];

      if (ids.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta reserva no tiene integrantes')),
        );
        return;
      }

      // 2) Traer perfiles
      final perfiles = await Supabase.instance.client
          .from('usuario') //
          .select('id_usuario, nombre, apellido, correo, rol, foto_url')
          .inFilter('id_usuario', ids);

      if (!mounted) return;

      // 3) Mostrar sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _IntegrantesSheet(
          integrantes: (perfiles as List).cast<Map<String, dynamic>>(),
          titularId: titularId,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando integrantes: $e')));
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
    final idReserva = r['id_reserva'] as int;
    final idArticulo = r['id_articulo'] as int?;
    final estado = (r['estado'] ?? '') as String;

    final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
    final fin = DateTime.tryParse('${r['fin']}')?.toUtc();

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
            // --- Botones de acción ---
            Wrap(
              alignment: WrapAlignment.end, // Equivalente a mainAxisAlignment.end
              spacing: 8.0, // Espacio horizontal (reemplaza tu SizedBox)
              runSpacing: 4.0, // Espacio vertical (si los botones bajan de línea)
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('Ver integrantes'),
                  onPressed: () => _verIntegrantes(idReserva),
                ),

                // El SizedBox(width: 8) ya no es necesario, 'spacing' se encarga.

                if (vencida)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.flag),
                    label: const Text('Finalizar'),
                    onPressed: () => _finalizar(idReserva),
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

  Future<int> _syncVencidas() async {
    final n = await _reservaService.finalizarVencidas();
    if (!mounted) return n;
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se finalizaron $n reservas vencidas.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay reservas vencidas por finalizar.'),
        ),
      );
    }
    return n;
  }

  Future<void> _syncAndRefresh() async {
    if (_busyActions) return;
    setState(() => _busyActions = true);
    try {
      await _syncVencidas(); // finaliza vencidas (si hay) y muestra snackbar
      await _fetch(); // luego recarga la lista
    } finally {
      if (mounted) setState(() => _busyActions = false);
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
            tooltip: 'Sincronizar y recargar',
            onPressed: _busyActions ? null : _syncAndRefresh,
            icon: _busyActions
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
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
    );
  }
}

// Sheet para mostrar integrantes
class _IntegrantesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> integrantes;
  final String titularId;

  const _IntegrantesSheet({required this.integrantes, required this.titularId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Ordena: titular primero, luego acompañantes
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
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Text(
              'Integrantes de la reserva',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ordenados.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
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
                    leading: CircleAvatar(
                      backgroundImage: foto.isNotEmpty
                          ? NetworkImage(foto)
                          : null,
                      child: foto.isEmpty
                          ? Text(
                              (nombreCompleto.isNotEmpty
                                      ? nombreCompleto[0]
                                      : (correo.isNotEmpty ? correo[0] : 'U'))
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      nombreCompleto.isNotEmpty ? nombreCompleto : correo,
                    ),
                    subtitle: Text(
                      '${isTitular ? "Titular" : "Acompañante"} • $rolSistema',
                    ),
                    trailing: isTitular
                        ? Chip(
                            label: const Text('Titular'),
                            backgroundColor: cs.primaryContainer,
                            side: BorderSide(color: cs.primary),
                            labelStyle: TextStyle(color: cs.onPrimaryContainer),
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
