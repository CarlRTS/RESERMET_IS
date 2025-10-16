import 'base_service.dart'; // Clase base con Supabase inicializado
import '../models/equipo_deportivo.dart'; // Modelo de datos

class EquipoDeportivoService with BaseService {
  // Obtener todos los equipos deportivos
  Future<List<EquipoDeportivo>> getEquiposDeportivos() async {
    try {
      final response = await supabase
          .from('equipo_deportivo')
          .select('*, articulo(*)');

      return [for (final item in response) EquipoDeportivo.fromSupabase(item)];
    } catch (e) {
      print('Error obteniendo equipos deportivos: $e');
      return [];
    }
  }

  // Crear nuevo equipo deportivo
  Future<EquipoDeportivo> createEquipoDeportivo(EquipoDeportivo equipo) async {
    try {
      final nextId = await getNextId();

      await createArticulo(equipo.toArticuloJson(), nextId);
      await createEspecifico(
        'equipo_deportivo',
        equipo.toEspecificoJson(),
        nextId,
      );

      return EquipoDeportivo(
        idObjeto: nextId,
        nombre: equipo.nombre,
        estado: equipo.estado,
        idArea: equipo.idArea,
        tipoEquipo: equipo.tipoEquipo,
        cantidadTotal: equipo.cantidadTotal,
        cantidadDisponible: equipo.cantidadDisponible,
      );
    } catch (e) {
      await _rollbackCreacion(equipo.idObjeto);
      throw Exception('Error creando equipo deportivo: $e');
    }
  }

  // Actualizar equipo deportivo existente
  Future<EquipoDeportivo> updateEquipoDeportivo(EquipoDeportivo equipo) async {
    try {
      await updateArticulo(equipo.toArticuloJson(), equipo.idObjeto);
      await updateEspecifico(
        'equipo_deportivo',
        equipo.toEspecificoJson(),
        equipo.idObjeto,
      );
      return equipo;
    } catch (e) {
      throw Exception('Error actualizando equipo deportivo: $e');
    }
  }

  // Eliminar equipo deportivo
  Future<void> deleteEquipoDeportivo(int idObjeto) async {
    try {
      await deleteEntidad('equipo_deportivo', idObjeto);
    } catch (e) {
      throw Exception('Error eliminando equipo deportivo: $e');
    }
  }

  // Rollback en caso de error
  Future<void> _rollbackCreacion(int idObjeto) async {
    try {
      await supabase.from('articulo').delete().eq('id_articulo', idObjeto);
    } catch (e) {
      print('Error en rollback: $e');
    }
  }
}
