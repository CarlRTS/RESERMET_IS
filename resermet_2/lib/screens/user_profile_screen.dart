// lib/screens/user_profile_screen.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/services/usuario_service.dart';
import 'package:resermet_2/utils/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UsuarioService _service = UsuarioService();
  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.red : Colors.green, // éxito: verde
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _service.getCurrentUserProfile();
      setState(() {
        _profile = p;
        _nombreCtrl.text = p.nombre ?? '';
        _apellidoCtrl.text = p.apellido ?? '';
        _telefonoCtrl.text = p.telefono ?? '';
      });
    } catch (e) {
      if (mounted) _showSnack('Error cargando perfil: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _profile == null) return;
    setState(() => _saving = true);
    try {
      final updated = _profile!.copyWith(
        nombre: _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim().isEmpty ? null : _apellidoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      );
      await _service.updateCurrentUserProfile(updated);
      _showSnack('Perfil actualizado');
      await _load();
    } catch (e) {
      _showSnack('Error al guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final Uint8List? bytes = file.bytes;
      final String ext = (file.extension ?? 'jpg').toLowerCase();

      if (bytes == null) {
        _showSnack('No se pudo leer el archivo seleccionado', error: true);
        return;
      }

      final String url = await _service.uploadAvatarBytes(bytes: bytes, fileExt: ext);
      setState(() => _profile = _profile?.copyWith(fotoUrl: url));
      _showSnack('Foto actualizada');
    } catch (e) {
      _showSnack('Error subiendo foto: $e', error: true);
    }
  }

  Future<void> _removeAvatar() async {
    final foto = _profile?.fotoUrl ?? '';
    if (foto.isEmpty) return;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Deseas eliminar tu foto de perfil?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteAvatar();
      setState(() => _profile = _profile?.copyWith(fotoUrl: null));
      _showSnack('Foto eliminada');
    } catch (e) {
      _showSnack('Error eliminando foto: $e', error: true);
    }
  }

  String _initials(String? n, String? a) {
    final String i1 = (n != null && n.trim().isNotEmpty) ? n.trim()[0] : '';
    final String i2 = (a != null && a.trim().isNotEmpty) ? a.trim()[0] : '';
    return (i1 + i2).isEmpty ? 'U' : (i1 + i2).toUpperCase();
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.unimetBlue),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.unimetBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }

  Widget _buildHeader() {
    final String foto = _profile?.fotoUrl ?? '';
    final String initials = _initials(_profile?.nombre, _profile?.apellido);
    final String role = (_profile?.rol ?? 'estudiante').toUpperCase();
    final String name =
        ((_profile?.nombre ?? '').isEmpty && (_profile?.apellido ?? '').isEmpty)
            ? 'Estudiante'
            : '${_profile?.nombre ?? ''} ${_profile?.apellido ?? ''}';
    final String correo = _profile?.correo ?? ''; // <- evita el bang operator

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.unimetBlue.withOpacity(.08),
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                child: foto.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.unimetBlue,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: -6,
              right: -6,
              child: Row(
                children: [
                  _avatarAction(
                    icon: Icons.camera_alt,
                    tooltip: 'Cambiar foto',
                    onTap: _pickAndUploadAvatar,
                    bg: AppColors.unimetBlue,
                  ),
                  const SizedBox(width: 8),
                  if (foto.isNotEmpty)
                    _avatarAction(
                      icon: Icons.delete_outline,
                      tooltip: 'Eliminar foto',
                      onTap: _removeAvatar,
                      bg: Colors.red,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.unimetBlue,
          ),
        ),
        const SizedBox(height: 6),
        Chip(
          label: Text(role),
          backgroundColor: Colors.grey.shade100,
          labelStyle: const TextStyle(
            color: AppColors.unimetBlue,
            fontWeight: FontWeight.w600,
          ),
          shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        ),
        const SizedBox(height: 6),
        if (correo.isNotEmpty)
          SelectableText(
            correo,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(.7)),
          ),
      ],
    );
  }

  Widget _avatarAction({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color bg = AppColors.unimetBlue,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.unimetBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(controller: _nombreCtrl, decoration: _input('Nombre', Icons.person_outline)),
                      const SizedBox(height: 12),
                      TextFormField(controller: _apellidoCtrl, decoration: _input('Apellido', Icons.person)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _input('Teléfono', Icons.phone_iphone),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: _ReadOnlyRow(
                  icon: Icons.badge_outlined,
                  label: 'Rol',
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final profile = context.findAncestorStateOfType<_UserProfileScreenState>()?._profile;
    final value = (profile?.rol ?? 'estudiante').toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.unimetBlue),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.black.withOpacity(.7))),
        ],
      ),
    );
  }
}
