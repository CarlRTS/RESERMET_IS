// lib/services/consola_service.dart
import '../models/consola.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsolaService {
  final supabase = Supabase.instance.client;

  // GET: Obtener todas las consolas
  Future<List<Consola>> getConsolas() async {
    try {
      final response = await supabase
          .from('consola')
          .select('*, articulo(*)');
      
      final List<Consola> consolas = [];
      for (final item in response) {
        consolas.add(Consola.fromSupabase(item));
      }
      
      return consolas;
    } catch (e) {
      print('❌ Error en getConsolas: $e');
      return [];
    }
  }

  // POST: Crear una nueva consola
  Future<Consola> createConsola(Consola consola) async {
    try {
      // 1. Obtener el máximo ID actual
      final maxIdResponse = await supabase
          .from('articulo')
          .select('id_articulo')
          .order('id_articulo', ascending: false)
          .limit(1);
      
      int nextId = 1;
      if (maxIdResponse.isNotEmpty && maxIdResponse[0]['id_articulo'] != null) {
        nextId = (maxIdResponse[0]['id_articulo'] as int) + 1;
      }

      // 2. Crear el artículo
      final articuloData = {
        ...consola.toArticuloJson(),
        'id_articulo': nextId,
      };
      
      await supabase
          .from('articulo')
          .insert(articuloData);

      // 3. Crear la consola
      final consolaData = {
        ...consola.toEspecificoJson(),
        'id_articulo': nextId,
      };
      
      await supabase
          .from('consola')
          .insert(consolaData);

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
      print('❌ Error al crear consola: $e');
      throw Exception('Error al crear consola: $e');
    }
  }

  // PUT: Actualizar una consola
  Future<Consola> updateConsola(Consola consola) async {
    try {
      // 1. Actualizar el artículo
      await supabase
          .from('articulo')
          .update(consola.toArticuloJson())
          .eq('id_articulo', consola.idObjeto);

      // 2. Actualizar la consola
      await supabase
          .from('consola')
          .update(consola.toEspecificoJson())
          .eq('id_articulo', consola.idObjeto);

      return consola;
    } catch (e) {
      throw Exception('Error al actualizar consola: $e');
    }
  }

  // DELETE: Eliminar una consola
  Future<void> deleteConsola(int idObjeto) async {
    try {
      // 1. Primero eliminar la consola
      await supabase
          .from('consola')
          .delete()
          .eq('id_articulo', idObjeto);

      // 2. Luego eliminar el artículo
      await supabase
          .from('articulo')
          .delete()
          .eq('id_articulo', idObjeto);
    } catch (e) {
      throw Exception('Error al eliminar consola: $e');
    }
  }
}