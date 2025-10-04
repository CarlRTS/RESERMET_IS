// lib/models/articulo.dart
abstract class Articulo {
  final String idObjeto;
  final String nombre;
  final String estado; // 'disponible', 'prestado', 'en mantenimiento'
  final String idArea;
  
  const Articulo({
    required this.idObjeto,
    required this.nombre,
    required this.estado,
    required this.idArea,
  });

  // Método para identificar el tipo
  String get tipo;

  // Convertir a Map para INSERT/UPDATE en Supabase
  Map<String, dynamic> toArticuloJson() {
    return {
      'id_objeto': idObjeto,
      'nombre': nombre,
      'estado': estado,
      'id_area': idArea,
    };
  }

  // Método abstracto para datos específicos de cada hijo
  Map<String, dynamic> toEspecificoJson();
}