// lib/models/juego.dart

class Juego {
  final int idJuego;
  final String nombre;

  Juego({
    required this.idJuego,
    required this.nombre,
  });

  factory Juego.fromMap(Map<String, dynamic> map) {
    return Juego(
      idJuego: (map['id_juego'] as num?)?.toInt() ?? 0,
      nombre: (map['nombre'] as String?) ?? 'Juego Desconocido',
    );
  }
}