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
      userId: json['user_id'] as String,
      articulo: articulo,
      // Convertir a DateTime y asegurar que está en zona horaria local
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String).toLocal(),
      fechaFin: DateTime.parse(json['fecha_fin'] as String).toLocal(),
      proposito: json['proposito'] as String,
      estado: json['estado'] as String,
    );
  }

  // Método para convertir el objeto a un Map para la inserción en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_articulo': articulo.idObjeto,
      'user_id': userId,
      // Usar toUtc() para asegurar que la fecha se guarda correctamente en la base de datos (PostgreSQL/Supabase)
      'fecha_inicio': fechaInicio.toUtc().toIso8601String(),
      'fecha_fin': fechaFin.toUtc().toIso8601String(),
      'proposito': proposito,
      'estado': estado,
    };
  }

  String get nombreArticulo => articulo.nombre;
}