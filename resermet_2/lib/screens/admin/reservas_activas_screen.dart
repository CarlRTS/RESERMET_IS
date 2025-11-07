// lib/screens/admin/reservas_activas_screen.dart
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

  Timer? _tick; // refresco de UI para contador
  bool _busyActions = false;

  // Realtime
  RealtimeChannel? _reservaChannel;

  @override
  void initState() {
    super.initState();
    _fetch();
    _loadUserRole();
    _subscribeRealtime();

    // Refrescar la UI cada segundo para el contador
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    // Cerrar canal realtime de forma segura
    try {
      _reservaChannel?.unsubscribe();
      Supabase.instance.client.removeChannel(_reservaChannel!);
    } catch (_) {}
    super.dispose();
  }

  // ====== Realtime (API correcta) ======
  void _subscribeRealtime() {
    final client = Supabase.instance.client;

    _reservaChannel = client.channel('public:reserva-activas-admin');

    _reservaChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reserva',
          callback: (payload) async {
            if (!mounted) return;
            // Cualquier cambio en "reserva" vuelve a cargar
            await _fetch();
          },
        )
        .subscribe();
  }

  // carga del rol del usuario para mostrar botón solo a administradores
  Future<void> _loadUserRole() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
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

      // 👇 Juntamos ids de usuarios titulares para traer sus nombres de una sola vez
      final ids = <String>{};
      for (final r in data) {
        final uid = (r['id_usuario'] ?? '').toString();
        if (uid.isNotEmpty) ids.add(uid);
      }

      Map<String, Map<String, dynamic>> perfilesMap = {};
      if (ids.isNotEmpty) {
        final perfiles = await Supabase.instance.client
            .from('usuario')
            .select('id_usuario, nombre, apellido, correo')
            .inFilter('id_usuario', ids.toList());

        for (final raw in (perfiles as List)) {
          final u = Map<String, dynamic>.from(raw as Map);
          final key = (u['id_usuario'] ?? '').toString();
          if (key.isNotEmpty) {
            perfilesMap[key] = u;
          }
        }
      }

      // Enriquecer cada reserva con el nombre de usuario
      final enriched = data.map<Map<String, dynamic>>((raw) {
        final r = Map<String, dynamic>.from(raw);
        final uid = (r['id_usuario'] ?? '').toString();
        String displayName = 'Usuario';
        final u = perfilesMap[uid];
        if (u != null) {
          final nombre = (u['nombre'] ?? '').toString().trim();
          final apellido = (u['apellido'] ?? '').toString().trim();
          if (nombre.isNotEmpty || apellido.isNotEmpty) {
            displayName = ('$nombre $apellido').trim();
          } else {
            final correo = (u['correo'] ?? '').toString();
            if (correo.isNotEmpty) displayName = correo;
          }
        }
        r['_user_name'] = displayName;
        return r;
      }).toList();

      if (!mounted) return;
      setState(() {
        _reservas = enriched;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _verIntegrantes(int idReserva) async {
    try {
      final reserva = await Supabase.instance.client
          .from('reserva')
          .select('id_usuario, companions_user_ids')
          .eq('id_reserva', idReserva)
          .single();

      final titularId = (reserva['id_usuario'] as String?) ?? '';
      final companions =
          (reserva['companions_user_ids'] as List?)?.cast<String>() ??
              const <String>[];

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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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

  // ====== Helpers visuales y de tiempo ======
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

  double _progressBetween(DateTime inicioUtc, DateTime finUtc) {
    final now = DateTime.now().toUtc();
    final total = finUtc.difference(inicioUtc).inSeconds;
    if (total <= 0) return 1;
    final transcurrido = now.difference(inicioUtc).inSeconds;
    final p = transcurrido / total;
    return p.clamp(0.0, 1.0);
  }

  Widget _estadoChip(DateTime finUtc) {
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
          fontWeight: FontWeight.w700,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  (IconData, Color) _iconoPorArticulo(Map<String, dynamic>? articulo) {
    final nombre = (articulo?['nombre'] ?? '').toString().toLowerCase();
    final tipo = (articulo?['tipo'] ??
            articulo?['categoria'] ??
            articulo?['tipo_articulo'] ??
            '')
        .toString()
        .toLowerCase();
    if (nombre.contains('ps') ||
        nombre.contains('xbox') ||
        nombre.contains('nintendo') ||
        nombre.contains('switch') ||
        nombre.contains('consola') ||
        tipo.contains('consola')) {
      return (Icons.sports_esports_rounded, Colors.orange);
    }
    if (nombre.contains('cubículo') ||
        nombre.contains('cubiculo') ||
        nombre.contains('sala') ||
        nombre.contains('estudio') ||
        tipo.contains('cubículo') ||
        tipo.contains('sala')) {
      return (Icons.meeting_room_rounded, UnimetPalette.primary);
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

  String _fmtHoraCorta(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ====== Card estética ======
  Widget _buildReservaCard(Map<String, dynamic> r) {
    // id_reserva puede venir como int o num
    final idReserva = (r['id_reserva'] as num).toInt();

    final articuloObj = (r['articulo'] is Map)
        ? Map<String, dynamic>.from(r['articulo'])
        : null;
    final nombreArticulo = (articuloObj?['nombre'] ?? 'Artículo').toString();

    final inicioUtc = DateTime.tryParse('${r['inicio']}')?.toUtc();
    final finUtc = DateTime.tryParse('${r['fin']}')?.toUtc();

    final userName = (r['_user_name'] ?? 'Usuario').toString();

    final (icono, colorIcono) = _iconoPorArticulo(articuloObj);

    final vencida =
        finUtc != null ? DateTime.now().toUtc().isAfter(finUtc) : false;
    final restante = finUtc != null ? _formatRemaining(finUtc) : '--:--:--';
    final progress = (inicioUtc != null && finUtc != null)
        ? _progressBetween(inicioUtc, finUtc)
        : 0.0;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: icono + título + chip estado
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorIcono.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: colorIcono, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombreArticulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: UnimetPalette.primary,
                      height: 1.2,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                if (finUtc != null) _estadoChip(finUtc),
              ],
            ),
            const SizedBox(height: 8),

            // Titular
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Titular: $userName',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tiempos
            if (inicioUtc != null && finUtc != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_fmtHoraCorta(inicioUtc.toLocal())} - ${_fmtHoraCorta(finUtc.toLocal())}  •  Restante: $restante',
                      style: TextStyle(
                        color: vencida
                            ? Colors.red.shade700
                            : Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Barra de progreso de la reserva
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: vencida ? 1 : progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: vencida ? Colors.red : UnimetPalette.primary,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.group_outlined),
                    label: const Text('Ver integrantes'),
                    onPressed: () => _verIntegrantes(idReserva),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                        vencida ? Icons.flag : Icons.check_circle_outline),
                    label: Text(vencida ? 'Finalizar' : 'Finalizar ahora'),
                    onPressed: () => _finalizar(idReserva),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          vencida ? Colors.red : UnimetPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      await _syncVencidas();
      await _fetch();
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
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 40),
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
                            Icon(Icons.inbox_outlined,
                                size: 56, color: theme.disabledColor),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'No hay reservas activas',
                                style:
                                    TextStyle(color: theme.disabledColor),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          itemCount: _reservas.length,
                          itemBuilder: (_, i) =>
                              _buildReservaCard(_reservas[i]),
                        ),
                ),
    );
  }
}

// ====== Sheet integrantes ======
class _IntegrantesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> integrantes;
  final String titularId;

  const _IntegrantesSheet(
      {required this.integrantes, required this.titularId});

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
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (_, i) {
                  final u = ordenados[i];
                  final isTitular = u['id_usuario'] == titularId;
                  final nombre =
                      (u['nombre'] ?? '').toString().trim();
                  final apellido =
                      (u['apellido'] ?? '').toString().trim();
                  final nombreCompleto =
                      ('$nombre $apellido').trim();
                  final correo = (u['correo'] ?? '').toString();
                  final rolSistema = (u['rol'] ?? '').toString();
                  final foto = (u['foto_url'] ?? '').toString();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          foto.isNotEmpty ? NetworkImage(foto) : null,
                      child: foto.isEmpty
                          ? Text(
                              (nombreCompleto.isNotEmpty
                                      ? nombreCompleto[0]
                                      : (correo.isNotEmpty
                                          ? correo[0]
                                          : 'U'))
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(nombreCompleto.isNotEmpty
                        ? nombreCompleto
                        : correo),
                    subtitle: Text(
                        '${isTitular ? "Titular" : "Acompañante"} • $rolSistema'),
                    trailing: isTitular
                        ? Chip(
                            label: const Text('Titular'),
                            backgroundColor: cs.primaryContainer,
                            side: BorderSide(color: cs.primary),
                            labelStyle: TextStyle(
                                color: cs.onPrimaryContainer),
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
