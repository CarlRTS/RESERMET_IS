import 'base_service.dart';
import '../models/cubiculo.dart';

class CubiculoService with BaseService {

  // Obtener todos los cubículos
  Future<List<Cubiculo>> getCubiculos() async {
    try {
      final response = await supabase
          .from('cubiculo')
          .select('*, articulo(*)');
      
      return [for (final item in response) Cubiculo.fromSupabase(item)];
    } catch (e) {
      print('Error obteniendo cubículos: $e');
      return [];
    }
  }

  // Crear nuevo cubículo
  Future<Cubiculo> createCubiculo(Cubiculo cubiculo) async {
    try {
      final nextId = await getNextId();
      
      await createArticulo(cubiculo.toArticuloJson(), nextId);
      await createEspecifico('cubiculo', cubiculo.toEspecificoJson(), nextId);

      // En lugar de copyWith, crear nueva instancia
      return Cubiculo(
        idObjeto: nextId,
        nombre: cubiculo.nombre,
        estado: cubiculo.estado,
        idArea: cubiculo.idArea,
        ubicacion: cubiculo.ubicacion,
        capacidad: cubiculo.capacidad,
      );
    } catch (e) {
      await _rollbackCreacion(cubiculo.idObjeto);
      throw Exception('Error creando cubículo: $e');
    }
  }

  // Actualizar cubículo existente
  Future<Cubiculo> updateCubiculo(Cubiculo cubiculo) async {
    try {
      await updateArticulo(cubiculo.toArticuloJson(), cubiculo.idObjeto);
      await updateEspecifico('cubiculo', cubiculo.toEspecificoJson(), cubiculo.idObjeto);
      return cubiculo;
    } catch (e) {
      throw Exception('Error actualizando cubículo: $e');
    }
  }

  // Eliminar cubículo
  Future<void> deleteCubiculo(int idObjeto) async {
    try {
      await deleteEntidad('cubiculo', idObjeto);
    } catch (e) {
      throw Exception('Error eliminando cubículo: $e');
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