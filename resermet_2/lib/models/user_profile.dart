class UserProfile {
  final String idUsuario;
  final String? nombre;
  final String? apellido;
  final String correo;
  final String? telefono;
  final String rol; // 'estudiante' | 'administrador'
  final String? fotoUrl;

  UserProfile({
    required this.idUsuario,
    required this.correo,
    required this.rol,
    this.nombre,
    this.apellido,
    this.telefono,
    this.fotoUrl,
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
    };
  }

  /// Para updates del estudiante (no toca correo/rol)
  Map<String, dynamic> toStudentUpdateMap() {
    final m = <String, dynamic>{};
    if (nombre != null) m['nombre'] = nombre;
    if (apellido != null) m['apellido'] = apellido;
    if (telefono != null) m['telefono'] = telefono;
    if (fotoUrl != null) m['foto_url'] = fotoUrl;
    return m;
  }

  /// Para updates genéricos (admin) – usa este si necesitas desde admin.
  Map<String, dynamic> toUpdateMap() {
    final m = <String, dynamic>{};
    m['nombre'] = nombre;
    m['apellido'] = apellido;
    m['telefono'] = telefono;
    m['correo'] = correo;
    m['rol'] = rol;
    m['foto_url'] = fotoUrl;
    return m;
  }

  UserProfile copyWith({
    String? nombre,
    String? apellido,
    String? telefono,
    String? fotoUrl,
  }) {
    return UserProfile(
      idUsuario: idUsuario,
      correo: correo,
      rol: rol,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}
