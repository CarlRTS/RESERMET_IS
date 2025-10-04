// lib/models/cubiculo.dart
import 'articulo.dart';

class Cubiculo extends Articulo {
  final String ubicacion;
  final int capacidad;

  Cubiculo({
    required int idObjeto,
    required String nombre,
    required String estado,
    required int idArea,
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

  factory Cubiculo.fromSupabase(Map<String, dynamic> json) {
    return Cubiculo(
      idObjeto: json['articulo']['id_articulo'] ?? json['id_articulo'] ?? 0, // ← CAMBIADO
      nombre: json['articulo']['nombre'] ?? '',
      estado: json['articulo']['estado'] ?? 'disponible',
      idArea: json['articulo']['id_area'] ?? 0,
      ubicacion: json['ubicacion'] ?? '',
      capacidad: json['capacidad'] ?? 1,
    );
  }
}