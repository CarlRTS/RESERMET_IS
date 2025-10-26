import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UsuarioService {
  final _sb = Supabase.instance.client;

  // ===== Helpers seguros de casting =====
  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw StateError('Se esperaba Map, llegó: ${value.runtimeType}');
  }

  List<Map<String, dynamic>> _asListOfMap(dynamic value) {
    if (value is List) {
      return value.map<Map<String, dynamic>>((e) => _asMap(e)).toList();
    }
    throw StateError('Se esperaba List, llegó: ${value.runtimeType}');
  }
  // ======================================

  Future<UserProfile> getCurrentUserProfile() async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa.');
    }

    final uid = user.id;
    final correoAuth = user.email ?? '';

    final rowsDyn = await _sb
        .from('usuario')
        .select()
        .eq('id_usuario', uid)
        .limit(1);

    final rows = _asListOfMap(rowsDyn);
    if (rows.isNotEmpty) {
      final row = Map<String, dynamic>.from(rows.first);
      row['correo'] ??= correoAuth;
      return UserProfile.fromMap(row);
    }

    final insertedDyn = await _sb
        .from('usuario')
        .insert({
          'id_usuario': uid,
          'correo': correoAuth,
          'nombre': null,
          'apellido': null,
          'telefono': null,
          'rol': 'estudiante',
          'foto_url': null,
        })
        .select()
        .single();

    final inserted = _asMap(insertedDyn);
    return UserProfile.fromMap(inserted);
  }

  Future<void> updateCurrentUserProfile(UserProfile data) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No hay sesión activa.');

    final updates = data.toStudentUpdateMap(); // nombre, apellido, telefono, foto_url
    if (updates.isEmpty) return;

    await _sb.from('usuario').update(updates).eq('id_usuario', user.id);
  }

  // ====== ADMIN ======

  Future<UserProfile?> getUserProfileById(String idUsuario) async {
    final rowsDyn = await _sb
        .from('usuario')
        .select()
        .eq('id_usuario', idUsuario)
        .limit(1);

    final rows = _asListOfMap(rowsDyn);
    if (rows.isNotEmpty) {
      return UserProfile.fromMap(rows.first);
    }
    return null;
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final rowsDyn = await _sb
        .from('usuario')
        .select()
        .or('nombre.ilike.%$q%,apellido.ilike.%$q%,correo.ilike.%$q%')
        .limit(50);

    final rows = _asListOfMap(rowsDyn);
    return rows.map((e) => UserProfile.fromMap(e)).toList();
  }

  Future<void> adminUpdateUserProfile(String idUsuario, UserProfile data) async {
    final updates = data.toUpdateMap();
    if (updates.isEmpty) return;

    await _sb.from('usuario').update(updates).eq('id_usuario', idUsuario);
  }

  // ====== AVATAR (bucket AVATARS) ======
  static const String _bucket = 'avatars';

  /// Sube bytes a `<uid>/avatar_<timestamp>.<ext>`, borra la anterior (si hay),
  /// guarda la nueva `foto_url` y devuelve una URL con cache-busting (?v=...).
  Future<String> uploadAvatarBytes({
    required Uint8List bytes,
    required String fileExt,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No hay sesión activa.');
    final uid = user.id;

    // Cargar perfil actual para conocer foto previa
    final current = await getCurrentUserProfile();
    final oldUrl = current.fotoUrl;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = (fileExt.trim().isEmpty ? 'jpg' : fileExt.trim()).toLowerCase();
    final newPath = '$uid/avatar_$ts.$ext';

    // Subir (no usamos upsert a mismo path; creamos archivo nuevo para romper caché)
    await _sb.storage.from(_bucket).uploadBinary(
          newPath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            cacheControl: '0', // no cachear en CDN
            contentType: 'image/$ext',
          ),
        );

    // Borrar anterior si existía
    if (oldUrl != null && oldUrl.isNotEmpty) {
      final prevPath = _extractPathFromPublicUrl(oldUrl);
      if (prevPath != null) {
        try {
          await _sb.storage.from(_bucket).remove([prevPath]);
        } catch (_) {/* ignorar */}
      }
    }

    // Nueva URL pública + query para bust de caché en la app
    final baseUrl = _sb.storage.from(_bucket).getPublicUrl(newPath);
    final publicUrl = '$baseUrl?v=$ts';

    // Guardar en BD
    await _sb
        .from('usuario')
        .update({'foto_url': publicUrl})
        .eq('id_usuario', uid);

    return publicUrl;
  }

  /// Elimina la imagen actual del usuario y pone foto_url = null.
  Future<void> deleteAvatar() async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No hay sesión activa.');
    final uid = user.id;

    final current = await getCurrentUserProfile();
    final url = current.fotoUrl;

    if (url != null && url.isNotEmpty) {
      final path = _extractPathFromPublicUrl(url);
      if (path != null) {
        try {
          await _sb.storage.from(_bucket).remove([path]);
        } catch (_) {/* ignorar */}
      }
    }

    await _sb
        .from('usuario')
        .update({'foto_url': null})
        .eq('id_usuario', uid);
  }

  /// Extrae `<uid>/archivo.ext` desde una public URL de Storage.
  String? _extractPathFromPublicUrl(String url) {
    try {
      final u = Uri.parse(url);
      final seg = u.pathSegments;
      // .../object/public/AVATARS/<AQUI VA EL PATH>
      final idx = seg.indexOf(_bucket);
      if (idx == -1 || idx + 1 >= seg.length) return null;
      final rel = seg.sublist(idx + 1).join('/');
      return rel.isEmpty ? null : rel;
    } catch (_) {
      return null;
    }
  }
}
