// lib/models/articulo.dart
abstract class Articulo {
  final int idObjeto; // ← CAMBIADO: String → int
  final String nombre;
  final String estado;
  final int idArea; // ← CAMBIADO: String → int
  
  const Articulo({
    required this.idObjeto,
    required this.nombre,
    required this.estado,
    required this.idArea,
  });

  String get tipo;

  Map<String, dynamic> toArticuloJson() {
    return {
      'id_articulo': idObjeto, // ← CAMBIADO: 'id_objeto' → 'id_artim'
      'nombre': nombre,
      'estado': estado,
      'id_area': idArea,
    };
  }

  Map<String, dynamic> toEspecificoJson();
}