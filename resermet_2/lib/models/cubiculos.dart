// lib/models/cubiculo.dart
import 'articulo.dart';

class Cubiculo extends Articulo {
  final String ubicacion;
  final int capacidad;

  Cubiculo({
    required String idObjeto,
    required String nombre,
    required String estado,
    required String idArea,
    required this.ubicacion,
    required this.capacidad,
  }) : super(
          idObjeto: idObjeto,
          nombre: nombre,
          estado: estado,
          idArea: idArea,
        );

  @override
  String get tipo => 'cubiculo';

  @override
  Map<String, dynamic> toEspecificoJson() {
    return {
      'id_articulo': idObjeto,
      'ubicacion': ubicacion,
      'capacidad': capacidad,
    };
  }

  // Factory para crear desde JOIN de Supabase
  factory Cubiculo.fromSupabase(Map<String, dynamic> json) {
    return Cubiculo(
      idObjeto: json['articulos']['id_objeto'] ?? json['id_articulo'] ?? '',
      nombre: json['articulos']['nombre'] ?? '',
      estado: json['articulos']['estado'] ?? 'disponible',
      idArea: json['articulos']['id_area'] ?? '',
      ubicacion: json['ubicacion'] ?? '',
      capacidad: json['capacidad'] ?? 1,
    );
  }
}