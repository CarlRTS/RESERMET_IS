// lib/models/consola.dart
import 'articulo.dart';

class Consola extends Articulo {
  final String modelo;
  final int cantidadTotal;
  final int cantidadDisponible;

  Consola({
    required int idObjeto,
    required String nombre,
    required String estado,
    required int idArea,
    required this.modelo,
    required this.cantidadTotal,
    required this.cantidadDisponible,
  }) : super(
          idObjeto: idObjeto,
          nombre: nombre,
          estado: estado,
          idArea: idArea,
        );

  @override
  String get tipo => 'consola';

  @override
  Map<String, dynamic> toEspecificoJson() {
    return {
      'id_articulo': idObjeto,
      'modelo': modelo,
      'cantidad_total': cantidadTotal,
      'cantidad_disponible': cantidadDisponible,
    };
  }

  factory Consola.fromSupabase(Map<String, dynamic> json) {
    return Consola(
      idObjeto: json['articulo']['id_articulo'] ?? json['id_articulo'] ?? 0, // ← CAMBIADO
      nombre: json['articulo']['nombre'] ?? '',
      estado: json['articulo']['estado'] ?? 'disponible',
      idArea: json['articulo']['id_area'] ?? 0,
      modelo: json['modelo'] ?? '',
      cantidadTotal: json['cantidad_total'] ?? 0,
      cantidadDisponible: json['cantidad_disponible'] ?? 0,
    );
  }
}