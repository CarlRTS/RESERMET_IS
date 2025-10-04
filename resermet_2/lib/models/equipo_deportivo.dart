// lib/models/equipo_deportivo.dart
import 'articulo.dart';

class EquipoDeportivo extends Articulo {
  final String tipoEquipo;
  final int cantidadTotal;
  final int cantidadDisponible;

  EquipoDeportivo({
    required String idObjeto,
    required String nombre,
    required String estado,
    required String idArea,
    required this.tipoEquipo,
    required this.cantidadTotal,
    required this.cantidadDisponible,
  }) : super(
          idObjeto: idObjeto,
          nombre: nombre,
          estado: estado,
          idArea: idArea,
        );

  @override
  String get tipo => 'equipo_deportivo';

  @override
  Map<String, dynamic> toEspecificoJson() {
    return {
      'id_articulo': idObjeto,
      'tipo': tipoEquipo,
      'cantidad_total': cantidadTotal,
      'cantidad_disponible': cantidadDisponible,
    };
  }

  factory EquipoDeportivo.fromSupabase(Map<String, dynamic> json) {
    return EquipoDeportivo(
      idObjeto: json['articulos']['id_objeto'] ?? json['id_articulo'] ?? '',
      nombre: json['articulos']['nombre'] ?? '',
      estado: json['articulos']['estado'] ?? 'disponible',
      idArea: json['articulos']['id_area'] ?? '',
      tipoEquipo: json['tipo'] ?? '',
      cantidadTotal: json['cantidad_total'] ?? 0,
      cantidadDisponible: json['cantidad_disponible'] ?? 0,
    );
  }
}