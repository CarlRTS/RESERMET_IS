import 'base_service.dart';
import '../models/consola.dart';

class ConsolaService with BaseService {

  // Obtener todas las consolas
  Future<List<Consola>> getConsolas() async {
    try {
      final response = await supabase
          .from('consola')
          .select('*, articulo(*)');
      
      return [for (final item in response) Consola.fromSupabase(item)];
    } catch (e) {
      print('Error obteniendo consolas: $e');
      return [];
    }
  }

  // Crear nueva consola
  Future<Consola> createConsola(Consola consola) async {
    try {
      final nextId = await getNextId();
      
      await createArticulo(consola.toArticuloJson(), nextId);
      await createEspecifico('consola', consola.toEspecificoJson(), nextId);

      return Consola(
        idObjeto: nextId,
        nombre: consola.nombre,
        estado: consola.estado,
        idArea: consola.idArea,
        modelo: consola.modelo,
        cantidadTotal: consola.cantidadTotal,
        cantidadDisponible: consola.cantidadDisponible,
      );
    } catch (e) {
      await _rollbackCreacion(consola.idObjeto);
      throw Exception('Error creando consola: $e');
    }
  }

  // Actualizar consola existente
  Future<Consola> updateConsola(Consola consola) async {
    try {
      await updateArticulo(consola.toArticuloJson(), consola.idObjeto);
      await updateEspecifico('consola', consola.toEspecificoJson(), consola.idObjeto);
      return consola;
    } catch (e) {
      throw Exception('Error actualizando consola: $e');
    }
  }

  // Eliminar consola
  Future<void> deleteConsola(int idObjeto) async {
    try {
      await deleteEntidad('consola', idObjeto);
    } catch (e) {
      throw Exception('Error eliminando consola: $e');
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