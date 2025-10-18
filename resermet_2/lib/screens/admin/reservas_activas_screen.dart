import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/reserva_service.dart';

class ReservasActivasScreen extends StatefulWidget {
  const ReservasActivasScreen({super.key});
  @override
  State<ReservasActivasScreen> createState() => _ReservasActivasScreenState();
}

class _ReservasActivasScreenState extends State<ReservasActivasScreen> {
  final _svc = ReservaService();
  late Future<List<Map<String, dynamic>>> _future;

  // Para no llamar finalizar 1000 veces cuando cruza a negativo
  final Set<int> _cerrando = {};

  @override
  void initState() {
    super.initState();
    _future = _getActivas(); // cargamos activas; no autolimpiamos
  }

  // Carga todas las 'activa' y ordena por 'fin'
  Future<List<Map<String, dynamic>>> _getActivas() async {
    final raw = await _svc.getReservasActivasRaw();
    raw.sort((a, b) {
      final faStr = a['fin'] as String?;
      final fbStr = b['fin'] as String?;
      if (faStr == null && fbStr == null) return 0;
      if (faStr == null) return 1;
      if (fbStr == null) return -1;
      DateTime fa, fb;
      try {
        fa = DateTime.parse(faStr).toUtc();
      } catch (_) {
        fa = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
      try {
        fb = DateTime.parse(fbStr).toUtc();
      } catch (_) {
        fb = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
      return fa.compareTo(fb);
    });
    return raw;
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Future<void> _finalizarSiExpirada(Map<String, dynamic> r, DateTime now) async {
    final idReserva = r['id_reserva'] as int;
    if (_cerrando.contains(idReserva)) return;

    DateTime fin;
    try {
      fin = DateTime.parse(r['fin'] as String).toUtc();
    } catch (_) {
      return;
    }

    if (fin.isAfter(now)) return; // aún no expira

    // ya expiró → finalizamos UNA VEZ
    _cerrando.add(idReserva);
    try {
      await _svc.finalizarReserva(
        idReserva: idReserva,
        idArticulo: r['id_articulo'] as int,
      );
      if (!mounted) return;
      setState(() {
        _future = _getActivas(); // recargar lista sin esta reserva
      });
    } catch (_) {
      // opcional: mostrar toast/snackbar
    } finally {
      _cerrando.remove(idReserva);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas activas')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay reservas activas'));
          }

          // Redibuja cada segundo y revisa si alguna cruzó a vencida
          return StreamBuilder<int>(
            stream: Stream.periodic(const Duration(seconds: 1), (x) => x),
            builder: (_, __) {
              final now = DateTime.now().toUtc();
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = items[i];

                  final articuloMap =
                      r['articulo'] is Map ? (r['articulo'] as Map) : null;
                  final nombreArticulo =
                      (articuloMap?['nombre'] as String?) ??
                          'Recurso #${r['id_articulo']}';

                  // Parseo seguro de fin
                  DateTime fin;
                  try {
                    fin = DateTime.parse(r['fin'] as String).toUtc();
                  } catch (_) {
                    fin = now;
                  }

                  final remain = fin.difference(now);
                  final expired = remain.isNegative;

                  // Si ya expiró, la cerramos en background (una vez) y la lista se recarga
                  if (expired) {
                    _finalizarSiExpirada(r, now);
                  }

                  return ListTile(
                    title: Text(nombreArticulo),
                    subtitle: Text(
                      expired
                          ? 'Expiró, cerrando...'
                          : 'Tiempo restante: ${_fmt(remain)}',
                    ),
                    trailing: FilledButton(
                      onPressed: () async {
                        try {
                          await _svc.finalizarReserva(
                            idReserva: r['id_reserva'] as int,
                            idArticulo: r['id_articulo'] as int,
                          );
                          if (!mounted) return;
                          setState(() {
                            _future = _getActivas();
                          });
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al finalizar: $e')),
                          );
                        }
                      },
                      child: const Text('Finalizar'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!mounted) return;
          setState(() {
            _future = _getActivas(); // solo recarga, sin cerrar nada
          });
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Refrescar'),
      ),
    );
  }
}
