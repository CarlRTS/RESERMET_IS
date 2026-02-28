class UserProfile {
  final String idUsuario;
  final String? nombre;
  final String? apellido;
  final String correo;
  final String? telefono;
  final String rol; // 'estudiante' | 'administrador'
  final String? fotoUrl;
  final int cedula;
  final int carnet;

  UserProfile({
    required this.idUsuario,
    required this.correo,
    required this.rol,
    this.nombre,
    this.apellido,
    this.telefono,
    this.fotoUrl,
    required this.cedula,
    required this.carnet,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      idUsuario: (map['id_usuario'] ?? map['id'] ?? '').toString(),
      correo: (map['correo'] ?? '').toString(),
      rol: (map['rol'] ?? 'estudiante').toString(),
      nombre: map['nombre']?.toString(),
      apellido: map['apellido']?.toString(),
      telefono: map['telefono']?.toString(),
      fotoUrl: map['foto_url']?.toString(),
      cedula: int.tryParse(map['cedula']?.toString() ?? '0') ?? 0,
      carnet: int.tryParse(map['carnet']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'correo': correo,
      'rol': rol,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'foto_url': fotoUrl,
      'cedula': cedula,
      'carnet': carnet,
    };
  }

  /// Para updates del estudiante (no modifica correo/rol/cedula/carnet)
  Map<String, dynamic> toStudentUpdateMap() {
    final m = <String, dynamic>{};
    if (nombre != null) m['nombre'] = nombre;
    if (apellido != null) m['apellido'] = apellido;
    if (telefono != null) m['telefono'] = telefono;
    if (fotoUrl != null) m['foto_url'] = fotoUrl;
    return m;
  }

  /// Para updates genéricos (admin)
  Map<String, dynamic> toUpdateMap() {
    final m = <String, dynamic>{};
    m['nombre'] = nombre;
    m['apellido'] = apellido;
    m['telefono'] = telefono;
    m['correo'] = correo;
    m['rol'] = rol;
    m['foto_url'] = fotoUrl;
    //El administrador sí debe poder corregir una cédula o carnet mal ingresado.
    m['cedula'] = cedula;
    m['carnet'] = carnet;
    return m;
  }

  UserProfile copyWith({
    String? nombre,
    String? apellido,
    String? telefono,
    String? fotoUrl,
    int? cedula,
    int? carnet,
    String? rol,
  }) {
    return UserProfile(
      idUsuario: idUsuario,
      correo: correo,
      rol: rol ?? this.rol,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      cedula: cedula ?? this.cedula,
      carnet: carnet ?? this.carnet,
    );
  }
}
