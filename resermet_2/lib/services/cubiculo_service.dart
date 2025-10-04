// lib/services/cubiculo_service.dart - CON IDs SECUENCIALES
import '../models/cubiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CubiculoService {
  final supabase = Supabase.instance.client;

  // GET: Obtener todos los cubículos
  Future<List<Cubiculo>> getCubiculos() async {
    try {
      final response = await supabase
          .from('cubiculo')
          .select('*, articulo(*)');
      
      final List<Cubiculo> cubiculos = [];
      for (final item in response) {
        cubiculos.add(Cubiculo.fromSupabase(item));
      }
      
      return cubiculos;
    } catch (e) {
      print('❌ Error en getCubiculos: $e');
      return [];
    }
  }

  // POST: Crear un nuevo cubículo CON ID SECUENCIAL
  Future<Cubiculo> createCubiculo(Cubiculo cubiculo) async {
    try {
      // 1. Obtener el máximo ID actual para generar el siguiente
      final maxIdResponse = await supabase
          .from('articulo')
          .select('id_articulo')
          .order('id_articulo', ascending: false)
          .limit(1);
      
      int nextId = 1;
      if (maxIdResponse.isNotEmpty && maxIdResponse[0]['id_articulo'] != null) {
        nextId = (maxIdResponse[0]['id_articulo'] as int) + 1;
      }

      print('🆕 Generando nuevo ID: $nextId');

      // 2. Crear el artículo con el nuevo ID
      final articuloData = {
        ...cubiculo.toArticuloJson(),
        'id_articulo': nextId, // ← USAMOS EL NUEVO ID SECUENCIAL
      };
      
      await supabase
          .from('articulo')
          .insert(articuloData);

      // 3. Crear el cubículo con el mismo ID
      final cubiculoData = {
        ...cubiculo.toEspecificoJson(),
        'id_articulo': nextId, // ← MISMO ID
      };
      
      await supabase
          .from('cubiculo')
          .insert(cubiculoData);

      print('✅ Cubículo creado con ID: $nextId');

      // Devolver el cubículo con el ID correcto
      return Cubiculo(
        idObjeto: nextId,
        nombre: cubiculo.nombre,
        estado: cubiculo.estado,
        idArea: cubiculo.idArea,
        ubicacion: cubiculo.ubicacion,
        capacidad: cubiculo.capacidad,
      );
    } catch (e) {
      print('❌ Error al crear cubículo: $e');
      throw Exception('Error al crear cubículo: $e');
    }
  }

  // PUT: Actualizar un cubículo
  Future<Cubiculo> updateCubiculo(Cubiculo cubiculo) async {
    try {
      // 1. Actualizar el artículo
      await supabase
          .from('articulo')
          .update(cubiculo.toArticuloJson())
          .eq('id_articulo', cubiculo.idObjeto);

      // 2. Actualizar el cubículo
      await supabase
          .from('cubiculo')
          .update(cubiculo.toEspecificoJson())
          .eq('id_articulo', cubiculo.idObjeto);

      return cubiculo;
    } catch (e) {
      throw Exception('Error al actualizar cubículo: $e');
    }
  }

  // DELETE: Eliminar un cubículo
  Future<void> deleteCubiculo(int idObjeto) async {
    try {
      // 1. Primero eliminar el cubículo
      await supabase
          .from('cubiculo')
          .delete()
          .eq('id_articulo', idObjeto);

      // 2. Luego eliminar el artículo
      await supabase
          .from('articulo')
          .delete()
          .eq('id_articulo', idObjeto);
    } catch (e) {
      throw Exception('Error al eliminar cubículo: $e');
    }
  }
}