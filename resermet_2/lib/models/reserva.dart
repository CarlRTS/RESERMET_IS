import 'package:resermet_2/models/articulo.dart';

class Reserva {
  final int? idReserva; // Nulo en la creación
  final String userId; // ID del usuario de Supabase
  final Articulo articulo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String proposito;
  final String estado; // 'pendiente', 'activa', 'rechazada', 'completada'

  Reserva({
    this.idReserva,
    required this.userId,
    required this.articulo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.proposito,
    this.estado = 'pendiente', // Valor por defecto
  });

  // Constructor para crear la Reserva a partir de datos de Supabase
  factory Reserva.fromSupabase(Map<String, dynamic> json, Articulo articulo) {
    return Reserva(
      idReserva: json['id_reserva'] as int,
      userId: json['id_usuario'] as String,
      articulo: articulo,

      fechaInicio: DateTime.parse(json['inicio'] as String).toLocal(),
      fechaFin: DateTime.parse(json['fin'] as String).toLocal(),

      proposito: json['compromiso_estudiante'] as String,
      estado: json['estado'] as String,
    );
  }

  // Método para convertir el objeto a un Map para la inserción en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_articulo': articulo.idObjeto,
      'id_usuario': userId,
      'inicio': fechaInicio.toUtc().toIso8601String(),
      'fin': fechaFin.toUtc().toIso8601String(),
      'compromiso_estudiante': proposito,
      'estado': estado,
    };
  }

  String get nombreArticulo => articulo.nombre;
}