// lib/services/reserva_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import '../models/reserva.dart';
import '../models/articulo.dart';
import 'cubiculo_service.dart';
import 'consola_service.dart';
import 'equipo_deportivo_service.dart';

class ReservaService with BaseService {
  final _cubiculoService = CubiculoService();
  final _consolaService = ConsolaService();
  final _equipoService = EquipoDeportivoService();

  Future<Articulo> _getArticuloById(int idArticulo) async {
    final cubiculos = await _cubiculoService.getCubiculos();
    try {
      return cubiculos.firstWhere((e) => e.idObjeto == idArticulo);
    } catch (_) {}
    final consolas = await _consolaService.getConsolas();
    try {
      return consolas.firstWhere((e) => e.idObjeto == idArticulo);
    } catch (_) {}
    final equipos = await _equipoService.getEquiposDeportivos();
    try {
      return equipos.firstWhere((e) => e.idObjeto == idArticulo);
    } catch (_) {}
    throw Exception('Tipo de artículo no reconocido para ID: $idArticulo');
  }

  /// Devuelve las reservas del usuario actual como modelos `Reserva`.
  /// Ahora incluye:
  /// - Reservas donde es titular (id_usuario == userId)
  /// - Reservas donde es acompañante (companions_user_ids contiene userId)
  Future<List<Reserva>> getMyReservations() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Traer reservas donde el usuario es TITULAR
      final titularResponse = await supabase
          .from('reserva')
          .select('*')
          .eq('id_usuario', userId);

      // Traer reservas donde el usuario es ACOMPAÑANTE
      final acompananteResponse = await supabase
          .from('reserva')
          .select('*')
          .contains('companions_user_ids', [userId]);

      final List<Map<String, dynamic>> titularList =
          (titularResponse as List).cast<Map<String, dynamic>>();
      final List<Map<String, dynamic>> acompananteList =
          (acompananteResponse as List).cast<Map<String, dynamic>>();

      // Unir y evitar duplicados por id_reserva
      final Map<int, Map<String, dynamic>> merged = {};
      for (final item in titularList) {
        final id = item['id_reserva'] as int;
        merged[id] = item;
      }
      for (final item in acompananteList) {
        final id = item['id_reserva'] as int;
        if (!merged.containsKey(id)) {
          merged[id] = item;
        }
      }

      // Ordenar por inicio DESC (como antes: ascending: false)
      final List<Map<String, dynamic>> ordenadas = merged.values.toList()
        ..sort((a, b) {
          final aInicio = DateTime.parse(a['inicio'] as String);
          final bInicio = DateTime.parse(b['inicio'] as String);
          return bInicio.compareTo(aInicio);
        });

      // Mapear a modelos Reserva
      final List<Reserva> reservas = [];
      for (final item in ordenadas) {
        final int idArticulo = item['id_articulo'] as int;
        try {
          final Articulo articulo = await _getArticuloById(idArticulo);
          reservas.add(Reserva.fromSupabase(item, articulo));
        } catch (_) {
          // Si falla obtener el artículo, ignoramos esa reserva puntual
        }
      }

      return reservas;
    } on PostgrestException catch (e) {
      throw Exception('Error de BD al cargar reservas: ${e.message}');
    } catch (e) {
      throw Exception('Error al cargar sus reservas');
    }
  }

  /// Devuelve las reservas del usuario actual como Map<String, dynamic>,
  /// pensado para HomeScreen y Mis Reservas.
  ///
  /// Incluye reservas donde:
  /// - es titular (id_usuario == userId)
  /// - es acompañante (companions_user_ids contiene userId)
  ///
  /// Además, agrega un campo calculado:
  /// - es_invitado: true si el usuario NO es el titular de la reserva.
  Future<List<Map<String, dynamic>>> getMisReservasRaw() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      const selectColumns =
          'id_reserva, id_articulo, id_usuario, inicio, fin, estado, companions_user_ids, articulo(nombre)';

      // Reservas donde el usuario es TITULAR
      final titularData = await supabase
          .from('reserva')
          .select(selectColumns)
          .eq('id_usuario', userId);

      // Reservas donde el usuario es ACOMPAÑANTE
      final acompananteData = await supabase
          .from('reserva')
          .select(selectColumns)
          .contains('companions_user_ids', [userId]);

      final List<Map<String, dynamic>> titularList =
          (titularData as List).cast<Map<String, dynamic>>();
      final List<Map<String, dynamic>> acompananteList =
          (acompananteData as List).cast<Map<String, dynamic>>();

      // Unir las dos listas evitando duplicados por id_reserva
      final Map<int, Map<String, dynamic>> merged = {};
      for (final item in titularList) {
        final id = item['id_reserva'] as int;
        merged[id] = Map<String, dynamic>.from(item);
      }
      for (final item in acompananteList) {
        final id = item['id_reserva'] as int;
        if (!merged.containsKey(id)) {
          merged[id] = Map<String, dynamic>.from(item);
        }
      }

      // Convertir a lista y ordenar por inicio ASC (como antes)
      final List<Map<String, dynamic>> result = merged.values.toList()
        ..sort((a, b) {
          final aInicio = DateTime.parse(a['inicio'] as String);
          final bInicio = DateTime.parse(b['inicio'] as String);
          return aInicio.compareTo(bInicio);
        });

      // Enriquecer con campo 'es_invitado'
      for (final reserva in result) {
        final String creadorId = reserva['id_usuario'] as String;
        reserva['es_invitado'] = creadorId != userId;
      }

      return result;
    } on PostgrestException catch (e) {
      throw Exception('Error de BD al cargar reservas: ${e.message}');
    } catch (e) {
      throw Exception('Error al cargar sus reservas');
    }
  }

  Future<void> cancelarReserva({required int idReserva}) async {
    await supabase
        .from('reserva')
        .update({'estado': 'cancelada'}).eq('id_reserva', idReserva);
  }

  Future<void> finalizarReservaUsuario({required int idReserva}) async {
    await supabase
        .from('reserva')
        .update({'estado': 'finalizada'}).eq('id_reserva', idReserva);
  }

  Future<Reserva> createReserva(Reserva reserva) async {
    try {
      final inserted = await supabase
          .from('reserva')
          .insert(reserva.toJson())
          .select()
          .single();
      return Reserva.fromSupabase(inserted, reserva.articulo);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear la reserva: ${e.message}');
    } catch (e) {
      throw Exception('Error desconocido al crear la reserva: $e');
    }
  }

  Future<int> getActiveReservationsCount({
    required int idArticulo,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    try {
      final inicioIso = inicio.toUtc().toIso8601String();
      final finIso = fin.toUtc().toIso8601String();
      final response = await supabase
          .from('reserva')
          .select('id_reserva')
          .eq('id_articulo', idArticulo)
          .eq('estado', 'activa')
          .lt('inicio', finIso)
          .gt('fin', inicioIso);
      return (response as List).length;
    } on PostgrestException catch (e) {
      print('Error de BD al calcular las reservas activas: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error al calcular las reservas activas: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReservasActivasRaw() async {
    final data = await supabase
        .from('reserva')
        .select(
            'id_reserva, id_articulo, id_usuario, inicio, fin, estado, articulo(nombre)')
        .eq('estado', 'activa')
        .order('fin', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> finalizarReserva({required int idReserva}) async {
    await supabase
        .from('reserva')
        .update({'estado': 'finalizada'}).eq('id_reserva', idReserva);
  }

  Future<int> finalizarVencidas() async {
    final nowUtcIso = DateTime.now().toUtc().toIso8601String();
    final response = await supabase
        .from('reserva')
        .update({'estado': 'finalizada'})
        .lt('fin', nowUtcIso)
        .eq('estado', 'activa')
        .select('id_reserva');
    final updated = (response as List?)?.length ?? 0;
    return updated;
  }

  // --- FUNCIÓN DE TU COMPAÑERO (SE QUEDA) ---
  Future<void> crearReservaCubiculo({
    required String cubiculoId,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? companionsUserIds,
  }) async {
    final sb = Supabase.instance.client;
    final payload = {
      'cubiculo_id': cubiculoId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      if (companionsUserIds != null && companionsUserIds.isNotEmpty)
        'companions_user_ids': companionsUserIds,
    };
    await sb.from('reservations').insert(payload);
  }

  // --- ¡FUNCIÓN DE REPORTES ACTUALIZADA! ---
  Future<ReporteStats> getEstadisticasReservas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int filtroArea = 0, // <-- Acepta el filtro
  }) async {
    try {
      final inicioStr = fechaInicio.toIso8601String().split('T').first;
      final finStr = fechaFin.toIso8601String().split('T').first;

      final response = await supabase.rpc(
        'get_reporte_reservas',
        params: {
          'fecha_inicio': inicioStr,
          'fecha_fin': finStr,
          'filtro_area': filtroArea, // <-- Lo pasa al SQL
        },
      );

      return ReporteStats.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error de BD al generar reporte: ${e.message}');
    } catch (e) {
      throw Exception('Error al generar reporte: $e');
    }
  }
}

// =================================================
// == NUEVAS CLASES PARA REPORTES (Compatibles) ==
// =================================================

class GraficoTipo {
  final int cubiculos;
  final int consolas;
  final int equipos;

  GraficoTipo.fromJson(Map<String, dynamic> json)
      : cubiculos = json['cubiculos'] ?? 0,
        consolas = json['consolas'] ?? 0,
        equipos = json['equipos'] ?? 0;

  GraficoTipo.empty()
      : cubiculos = 0,
        consolas = 0,
        equipos = 0;
}

class GraficoHora {
  final int hora;
  final int total;

  GraficoHora.fromJson(Map<String, dynamic> json)
      : hora = json['hora'] ?? 0,
        total = json['total'] ?? 0;
}

class ReporteStats {
  final int totalReservas;
  final int finalizadas;
  final int canceladas;
  final double totalHoras; // <-- El nuevo KPI
  final GraficoTipo graficoTipo;
  final List<GraficoHora> graficoHora;

  ReporteStats.fromJson(Map<String, dynamic> json)
      : totalReservas = json['kpi_total_reservas'] ?? 0,
        finalizadas = json['kpi_finalizadas'] ?? 0,
        canceladas = json['kpi_canceladas'] ?? 0,
        totalHoras = (json['kpi_total_horas'] as num?)?.toDouble() ?? 0.0,
        graficoTipo = GraficoTipo.fromJson(json['grafico_tipo'] ?? {}),
        graficoHora = (json['grafico_hora'] as List?)
                ?.map((item) => GraficoHora.fromJson(item))
                .toList() ??
            [];

  ReporteStats.empty()
      : totalReservas = 0,
        finalizadas = 0,
        canceladas = 0,
        totalHoras = 0.0,
        graficoTipo = GraficoTipo.empty(),
        graficoHora = [];
}
