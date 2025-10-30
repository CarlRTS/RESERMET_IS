// lib/services/reserva_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import '../models/reserva.dart';
import '../models/articulo.dart';
import 'cubiculo_service.dart';
import 'consola_service.dart';
import 'equipo_deportivo_service.dart';

/// Servicio de reservas:
/// - NO modifica `articulo.estado` (el stock/estado lo controlan las pantallas).
/// - API para usuario y administración.
/// - Crea/lee reservas y permite finalizar/cancelar.
class ReservaService with BaseService {
  final _cubiculoService = CubiculoService();
  final _consolaService = ConsolaService();
  final _equipoService = EquipoDeportivoService();

  // -------------------------------------------------
  // Helpers privados
  // -------------------------------------------------

  /// Carga el Articulo concreto (Cubículo / Consola / Equipo) por su ID.
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

  // -------------------------------------------------
  // API de usuario
  // -------------------------------------------------

  /// Devuelve las reservas del usuario autenticado con el Articulo cargado.
  Future<List<Reserva>> getMyReservations() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('reserva')
          .select('*')
          .eq('id_usuario', userId) // <-- Mantener filtro por usuario
          .order('inicio', ascending: false);

      final List<Reserva> reservas = [];
      for (final item in (response as List)) {
        final int idArticulo = item['id_articulo'] as int;
        try {
          final Articulo articulo = await _getArticuloById(idArticulo);
          reservas.add(Reserva.fromSupabase(item, articulo));
        } catch (_) {
          // Ignorar fallos de carga de artículo para no romper la UX
        }
      }
      return reservas;
    } on PostgrestException catch (e) {
      throw Exception('Error de BD al cargar reservas: ${e.message}');
    } catch (e) {
      throw Exception('Error al cargar sus reservas');
    }
  }

  /// Devuelve MIS reservas en formato crudo (con nombre de artículo).
  Future<List<Map<String, dynamic>>> getMisReservasRaw() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await supabase
        .from('reserva')
        .select(
      'id_reserva, id_articulo, inicio, fin, estado, articulo(nombre)',
    )
        .eq('id_usuario', userId)
        .order('inicio', ascending: true);

    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Cancela una reserva (uso estudiante, para reservas FUTURAS).
  Future<void> cancelarReserva({required int idReserva}) async {
    await supabase
        .from('reserva')
        .update({'estado': 'cancelada'})
        .eq('id_reserva', idReserva);
  }

  /// Finaliza una reserva (uso estudiante, para reservas ACTIVAS).
  Future<void> finalizarReservaUsuario({required int idReserva}) async {
    await supabase
        .from('reserva')
        .update({'estado': 'finalizada'})
        .eq('id_reserva', idReserva);
  }

  /// Crea una nueva reserva a partir de tu modelo Reserva.
  /// IMPORTANTE: no cambia `articulo.estado`.
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

  // --- Utilidad: conteo de solapes activos para un artículo ---
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
      // solape: inicio < finSolicitado AND fin > inicioSolicitado
          .lt('inicio', finIso)
          .gt('fin', inicioIso);

      return (response as List).length;
    } on PostgrestException catch (e) {
      // log y rethrow para depurar sin romper UX arriba
      // ignore: avoid_print
      print('Error de BD al calcular las reservas activas: ${e.message}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('Error al calcular las reservas activas: $e');
      rethrow;
    }
  }

  // -------------------------------------------------
  // API de administración
  // -------------------------------------------------

  /// Devuelve las reservas en estado 'activa' (ordenadas por fin asc).
  /// La vista admin calcula el contador y decide cuándo finalizar.
  Future<List<Map<String, dynamic>>> getReservasActivasRaw() async {
    final data = await supabase
        .from('reserva')
        .select(
      // incluye nombre del artículo por relación Supabase
      'id_reserva, id_articulo, id_usuario, inicio, fin, estado, articulo(nombre)',
    )
        .eq('estado', 'activa')
        .order('fin', ascending: true);

    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Finaliza una reserva manualmente (desde botón en admin).
  Future<void> finalizarReserva({required int idReserva}) async {
    await supabase
        .from('reserva')
        .update({'estado': 'finalizada'})
        .eq('id_reserva', idReserva);
  }

  /// Finaliza todas las reservas vencidas (fin < ahora UTC) que siguen 'activa'.
  /// Usado por el botón "Sincronizar vencidas" en la vista admin.
  /// Devuelve cuántas reservas fueron actualizadas.
  Future<int> finalizarVencidas() async {
    final nowUtcIso = DateTime.now().toUtc().toIso8601String();

    final response = await supabase
        .from('reserva')
        .update({'estado': 'finalizada'})
        .lt('fin', nowUtcIso)
        .eq('estado', 'activa')
        .select('id_reserva'); // contar filas actualizadas

    final updated = (response as List?)?.length ?? 0;
    return updated;
  }

  /// Obtiene las estadísticas de reservas para un rango de fechas usando RPC.
  Future<ReporteStats> getEstadisticasReservas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      // Formatear las fechas como 'YYYY-MM-DD'
      final inicioStr = fechaInicio.toIso8601String().split('T').first;
      final finStr = fechaFin.toIso8601String().split('T').first;

      final response = await supabase.rpc(
        'get_reporte_reservas',
        params: {
          'fecha_inicio': inicioStr,
          'fecha_fin': finStr,
        },
      );

      // El response es el JSONB que devolvimos
      return ReporteStats.fromJson(response as Map<String, dynamic>);

    } on PostgrestException catch (e) {
      throw Exception('Error de BD al generar reporte: ${e.message}');
    } catch (e) {
      throw Exception('Error al generar reporte: $e');
    }
  }
}

// =================================================
// == CLASE PARA REPORTES (EXISTENTE) ==
// =================================================

/// Modelo para la respuesta de la función de reporte
class ReporteStats {
  final int totalReservas;
  final int finalizadas;
  final int canceladas;
  final int cubiculos;
  final int consolas;
  final int equipos;

  ReporteStats.fromJson(Map<String, dynamic> json)
      : totalReservas = json['total_reservas'] ?? 0,
        finalizadas = json['finalizadas'] ?? 0,
        canceladas = json['canceladas'] ?? 0,
        cubiculos = json['desglose']?['cubiculos'] ?? 0,
        consolas = json['desglose']?['consolas'] ?? 0,
        equipos = json['desglose']?['equipos'] ?? 0;

  // Un reporte vacío por defecto
  ReporteStats.empty()
      : totalReservas = 0,
        finalizadas = 0,
        canceladas = 0,
        cubiculos = 0,
        consolas = 0,
        equipos = 0;
}