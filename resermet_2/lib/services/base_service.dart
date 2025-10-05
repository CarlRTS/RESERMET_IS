// Servicio base con lógica común para todos los servicios
import 'package:supabase_flutter/supabase_flutter.dart';

mixin BaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Obtener el próximo ID disponible
  Future<int> getNextId() async {
    final response = await supabase
        .from('articulo')
        .select('id_articulo')
        .order('id_articulo', ascending: false)
        .limit(1);
    
    return response.isNotEmpty && response[0]['id_articulo'] != null
        ? (response[0]['id_articulo'] as int) + 1
        : 1;
  }

  // Crear artículo base
  Future<void> createArticulo(Map<String, dynamic> articuloData, int nextId) async {
    final articuloDataWithId = {...articuloData, 'id_articulo': nextId};
    await supabase.from('articulo').insert(articuloDataWithId);
  }

  // Crear entidad específica
  Future<void> createEspecifico(String tableName, Map<String, dynamic> especificoData, int nextId) async {
    final especificoDataWithId = {...especificoData, 'id_articulo': nextId};
    await supabase.from(tableName).insert(especificoDataWithId);
  }

  // Actualizar artículo base
  Future<void> updateArticulo(Map<String, dynamic> articuloData, int id) async {
    await supabase
        .from('articulo')
        .update(articuloData)
        .eq('id_articulo', id);
  }

  // Actualizar entidad específica
  Future<void> updateEspecifico(String tableName, Map<String, dynamic> especificoData, int id) async {
    await supabase
        .from(tableName)
        .update(especificoData)
        .eq('id_articulo', id);
  }

  // Eliminar entidad (artículo + específico)
  Future<void> deleteEntidad(String tableName, int id) async {
    await supabase.from(tableName).delete().eq('id_articulo', id);
    await supabase.from('articulo').delete().eq('id_articulo', id);
  }
}