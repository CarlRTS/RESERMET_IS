// lib/services/equipo_deportivo_service.dart
import '../models/equipo_deportivo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EquipoDeportivoService {
  final supabase = Supabase.instance.client;

  // GET: Obtener todos los equipos deportivos
  Future<List<EquipoDeportivo>> getEquiposDeportivos() async {
    try {
      final response = await supabase
          .from('equipo_deportivo')
          .select('*, articulo(*)');
      
      final List<EquipoDeportivo> equipos = [];
      for (final item in response) {
        equipos.add(EquipoDeportivo.fromSupabase(item));
      }
      
      return equipos;
    } catch (e) {
      print('❌ Error en getEquiposDeportivos: $e');
      return [];
    }
  }

  // POST: Crear un nuevo equipo deportivo
  Future<EquipoDeportivo> createEquipoDeportivo(EquipoDeportivo equipo) async {
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
        ...equipo.toArticuloJson(),
        'id_articulo': nextId,
      };
      
      await supabase
          .from('articulo')
          .insert(articuloData);

      // 3. Crear el equipo deportivo
      final equipoData = {
        ...equipo.toEspecificoJson(),
        'id_articulo': nextId,
      };
      
      await supabase
          .from('equipo_deportivo')
          .insert(equipoData);

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
      print('❌ Error al crear equipo deportivo: $e');
      throw Exception('Error al crear equipo deportivo: $e');
    }
  }

  // PUT: Actualizar un equipo deportivo
  Future<EquipoDeportivo> updateEquipoDeportivo(EquipoDeportivo equipo) async {
    try {
      // 1. Actualizar el artículo
      await supabase
          .from('articulo')
          .update(equipo.toArticuloJson())
          .eq('id_articulo', equipo.idObjeto);

      // 2. Actualizar el equipo deportivo
      await supabase
          .from('equipo_deportivo')
          .update(equipo.toEspecificoJson())
          .eq('id_articulo', equipo.idObjeto);

      return equipo;
    } catch (e) {
      throw Exception('Error al actualizar equipo deportivo: $e');
    }
  }

  // DELETE: Eliminar un equipo deportivo
  Future<void> deleteEquipoDeportivo(int idObjeto) async {
    try {
      // 1. Primero eliminar el equipo deportivo
      await supabase
          .from('equipo_deportivo')
          .delete()
          .eq('id_articulo', idObjeto);

      // 2. Luego eliminar el artículo
      await supabase
          .from('articulo')
          .delete()
          .eq('id_articulo', idObjeto);
    } catch (e) {
      throw Exception('Error al eliminar equipo deportivo: $e');
    }
  }
}