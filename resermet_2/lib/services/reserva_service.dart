import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import '../models/reserva.dart';
import '../models/articulo.dart';
import 'cubiculo_service.dart';
import 'consola_service.dart';
import 'equipo_deportivo_service.dart';

/// Servicio de reservas:
/// - NO modifica `articulo.estado` (el stock/estado se controla en tus pantallas).
/// - Lee reservas para usuario/admin.
/// - Crea reserva (si deseas centralizar el insert aquí).
/// - Finaliza reservas manualmente o masivamente (vencidas).
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

  /// Devuelve las reservas de todo el sistema.
  /// ⚠️ ADVERTENCIA: Devuelve TODAS las reservas (sin filtro de usuario).
  Future<List<Reserva>> getMyReservations() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('reserva')
          .select('*')
      // Filtro removido para la planificación global
          .order('inicio', ascending: false);

      final List<Reserva> reservas = [];
      for (final item in (response as List)) {
        final int idArticulo = item['id_articulo'] as int;
        try {
          final Articulo articulo = await _getArticuloById(idArticulo);
          reservas.add(Reserva.fromSupabase(item, articulo));
        } catch (_) {
          // Ignorar errores de carga de artículo para no romper UX
        }
      }
      return reservas;
    } on PostgrestException catch (e) {
      throw Exception('Error de BD al cargar reservas: ${e.message}');
    } catch (e) {
      throw Exception('Error al cargar sus reservas');
    }
  }

  /// Crea una nueva reserva a partir de tu modelo Reserva.
  /// IMPORTANTE: no cambia `articulo.estado`.
  Future<Reserva> createReserva(Reserva reserva) async {
    try {
      final inserted = await supabase
          .from('reserva')
          .insert(reserva.toJson()) // tu modelo incluye: id_articulo, id_usuario, inicio, fin, estado, etc.
          .select()
          .single();

      return Reserva.fromSupabase(inserted, reserva.articulo);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear la reserva: ${e.message}');
    } catch (e) {
      throw Exception('Error desconocido al crear la reserva: $e');
    }
  }

  //  NUEVA FUNCIÓN PARA OBTENER EL CONTEO DE RESERVAS ACTIVAS EN UN RANGO
  // Devuelve el número de reservas activas para un artículo que se solapan
  // con el rango de tiempo (inicio/fin) proporcionado.
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

  // -------------------------------------------------
  // API de administración
  // -------------------------------------------------

  /// Devuelve las reservas en estado 'activa' (ordenadas por fin asc).
  /// La vista admin calcula el contador y decide cuándo finalizar.
  Future<List<Map<String, dynamic>>> getReservasActivasRaw() async {
    final data = await supabase
        .from('reserva')
        .select(
      // incluye nombre del artículo por relación supabase
      'id_reserva, id_articulo, id_usuario, inicio, fin, estado, articulo(nombre)',
    )
        .eq('estado', 'activa')
        .order('fin', ascending: true);

    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Finaliza una reserva manualmente (desde botón).
  /// No toca `articulo.estado`.
  Future<void> finalizarReserva({
    required int idReserva,
  }) async {
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
        .select('id_reserva'); // para contar cuántas filas se actualizaron

    final updated = (response as List?)?.length ?? 0;
    return updated;
  }
}
