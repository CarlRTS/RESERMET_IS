// 📍 REEMPLAZAR ARCHIVO: lib/models/consola.dart
import 'articulo.dart';

class Consola extends Articulo {
  final String modelo;
  final int cantidadTotal;
  final int cantidadDisponible;
  // 1. CAMPO NUEVO (leído desde la BD)
  final List<String> juegosCompatibles;

  Consola({
    required int idObjeto,
    required String nombre,
    required String estado,
    required int idArea,
    required this.modelo,
    required this.cantidadTotal,
    required this.cantidadDisponible,
    this.juegosCompatibles = const [], // 2. VALOR POR DEFECTO
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
    // 3. ENVIAR LOS JUEGOS A SUPABASE AL GUARDAR
    return {
      'id_articulo': idObjeto,
      'modelo': modelo,
      'cantidad_total': cantidadTotal,
      'cantidad_disponible': cantidadDisponible,
      'juegos_compatibles': juegosCompatibles, // <-- AÑADIDO
    };
  }

  factory Consola.fromSupabase(Map<String, dynamic> json) {
    // 4. LEER LA LISTA DE JUEGOS DESDE SUPABASE
    // (Maneja si es nulo o si viene en un formato diferente)
    final List<dynamic> juegosDynamic = json['juegos_compatibles'] ?? [];
    final List<String> juegos = juegosDynamic.map((s) => s.toString()).toList();

    return Consola(
      idObjeto: json['articulo']['id_articulo'] ?? json['id_articulo'] ?? 0,
      nombre: json['articulo']['nombre'] ?? '',
      estado: json['articulo']['estado'] ?? 'disponible',
      idArea: json['articulo']['id_area'] ?? 0,
      modelo: json['modelo'] ?? '',
      cantidadTotal: json['cantidad_total'] ?? 0,
      cantidadDisponible: json['cantidad_disponible'] ?? 0,
      juegosCompatibles: juegos, // <-- AÑADIDO
    );
  }
}