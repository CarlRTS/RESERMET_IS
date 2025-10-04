// lib/services/cubiculo_service.dart
import '../models/cubiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CubiculoService {
  final supabase = Supabase.instance.client;

  // GET: Obtener todos los cubículos
  Future<List<Cubiculo>> getCubiculos() async {
    try {
      final response = await supabase
          .from('cubiculos')
          .select('*, articulos(*)');
      
      final List<Cubiculo> cubiculos = [];
      for (final item in response) {
        cubiculos.add(Cubiculo.fromSupabase(item));
      }
      
      return cubiculos;
    } catch (e) {
      throw Exception('Error al obtener cubículos: $e');
    }
  }

  // POST: Crear un nuevo cubículo
  Future<Cubiculo> createCubiculo(Cubiculo cubiculo) async {
    try {
      // 1. Primero crear el artículo en la tabla articulos
      await supabase
          .from('articulos')
          .insert(cubiculo.toArticuloJson());

      // 2. Luego crear el cubículo en la tabla cubiculos
      await supabase
          .from('cubiculos')
          .insert(cubiculo.toEspecificoJson());

      return cubiculo;
    } catch (e) {
      // Si falla, eliminar el artículo creado (rollback)
      await supabase
          .from('articulos')
          .delete()
          .eq('id_objeto', cubiculo.idObjeto);
      throw Exception('Error al crear cubículo: $e');
    }
  }

  // PUT: Actualizar un cubículo
  Future<Cubiculo> updateCubiculo(Cubiculo cubiculo) async {
    try {
      // 1. Actualizar el artículo
      await supabase
          .from('articulos')
          .update(cubiculo.toArticuloJson())
          .eq('id_objeto', cubiculo.idObjeto);

      // 2. Actualizar el cubículo
      await supabase
          .from('cubiculos')
          .update(cubiculo.toEspecificoJson())
          .eq('id_articulo', cubiculo.idObjeto);

      return cubiculo;
    } catch (e) {
      throw Exception('Error al actualizar cubículo: $e');
    }
  }

  // DELETE: Eliminar un cubículo
  Future<void> deleteCubiculo(String idObjeto) async {
    try {
      // 1. Primero eliminar el cubículo
      await supabase
          .from('cubiculos')
          .delete()
          .eq('id_articulo', idObjeto);

      // 2. Luego eliminar el artículo
      await supabase
          .from('articulos')
          .delete()
          .eq('id_objeto', idObjeto);
    } catch (e) {
      throw Exception('Error al eliminar cubículo: $e');
    }
  }
}