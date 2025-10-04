// lib/models/consola.dart
import 'articulo.dart';

class Consola extends Articulo {
  final String modelo;
  final int cantidadTotal;
  final int cantidadDisponible;

  Consola({
    required String idObjeto,
    required String nombre,
    required String estado,
    required String idArea,
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
      idObjeto: json['articulos']['id_objeto'] ?? json['id_articulo'] ?? '',
      nombre: json['articulos']['nombre'] ?? '',
      estado: json['articulos']['estado'] ?? 'disponible',
      idArea: json['articulos']['id_area'] ?? '',
      modelo: json['modelo'] ?? '',
      cantidadTotal: json['cantidad_total'] ?? 0,
      cantidadDisponible: json['cantidad_disponible'] ?? 0,
    );
  }
}