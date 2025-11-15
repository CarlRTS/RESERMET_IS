import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/services/usuario_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/widgets/toastification.dart'; // Importamos el servicio de Toasts

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

  // Códigos de operadora venezolanos (incluye 0422)
  final List<String> _codigosOperadora = [
    '0412',
    '0422',
    '0416',
    '0426',
    '0424',
    '0414',
  ];
  String _codigoSeleccionado = '0412';

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

  // ======================================================================
  // ====== ⬇️ FUNCIÓN _showSnack REEMPLAZADA POR TOASTS ⬇️ ======
  // ======================================================================
  void _showSuccessToast(String message) {
    if (!mounted) return;
    ReservationToastService.showProfileUpdateSuccess(context);
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    ReservationToastService.showProfileUpdateError(context, message);
  }
  // ======================================================================
  // ====== ⬆️ FIN DE LA ACTUALIZACIÓN ⬆️ ======
  // ======================================================================

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _service.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _nombreCtrl.text = p.nombre ?? '';
        _apellidoCtrl.text = p.apellido ?? '';

        // Separar código (4 dígitos) y número (7 dígitos)
        final telefonoCompleto = p.telefono ?? '';
        if (telefonoCompleto.length >= 4) {
          final codigo = telefonoCompleto.substring(0, 4);
          if (_codigosOperadora.contains(codigo)) {
            _codigoSeleccionado = codigo;
            _telefonoCtrl.text = telefonoCompleto.substring(4);
          } else {
            _telefonoCtrl.text = telefonoCompleto;
          }
        } else {
          _telefonoCtrl.text = telefonoCompleto;
        }
      });
    } catch (e) {
      if (mounted) _showErrorToast('Error cargando perfil: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _profile == null) return;
    setState(() => _saving = true);
    try {
      final telefonoCompleto = _telefonoCtrl.text.trim().isEmpty
          ? null
          : _codigoSeleccionado + _telefonoCtrl.text.trim();

      final updated = _profile!.copyWith(
        nombre: _nombreCtrl.text.trim().isEmpty
            ? null
            : _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim().isEmpty
            ? null
            : _apellidoCtrl.text.trim(),
        telefono: telefonoCompleto,
      );
      await _service.updateCurrentUserProfile(updated);
      _showSuccessToast('Perfil actualizado');
      await _load();
    } catch (e) {
      _showErrorToast('Error al guardar: $e');
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
        _showErrorToast('No se pudo leer el archivo seleccionado');
        return;
      }

      final String url = await _service.uploadAvatarBytes(
        bytes: bytes,
        fileExt: ext,
      );
      if (mounted) {
        setState(() => _profile = _profile?.copyWith(fotoUrl: url));
      }
      _showSuccessToast('Foto actualizada');
    } catch (e) {
      _showErrorToast('Error subiendo foto: $e');
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteAvatar();
      if (mounted) {
        setState(() => _profile = _profile?.copyWith(fotoUrl: null));
      }
      _showSuccessToast('Foto eliminada');
    } catch (e) {
      _showErrorToast('Error eliminando foto: $e');
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

  // Validaciones (nombre/apellido obligatorios; teléfono opcional con 7 dígitos numéricos)
  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.length > 50)
      return 'El nombre no puede tener más de 50 caracteres';
    final nombreRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nombreRegExp.hasMatch(trimmedValue))
      return 'Solo se permiten letras y espacios en el nombre';
    return null;
  }

  String? _validateApellido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El apellido es obligatorio';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.length > 50)
      return 'El apellido no puede tener más de 50 caracteres';
    final apellidoRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!apellidoRegExp.hasMatch(trimmedValue))
      return 'Solo se permiten letras y espacios en el apellido';
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    final trimmedValue = value.trim();
    final soloNumerosRegExp = RegExp(r'^[0-9]+$');
    if (!soloNumerosRegExp.hasMatch(trimmedValue)) {
      return 'Solo se permiten números en el teléfono';
    }
    if (trimmedValue.length != 7) {
      return 'El número debe tener 7 dígitos (ej: 1234567)';
    }
    return null;
  }

  // Bandera simple de Venezuela
  Widget _buildBanderaVenezuela() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 8,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFCF142B),
                  Color(0xFF00247D),
                  Color(0xFFFCE300),
                ],
                stops: [0.33, 0.66, 1.0],
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'VE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Campo Teléfono con selector de código
  Widget _buildTelefonoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teléfono',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Selector de código + bandera
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildBanderaVenezuela(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _codigoSeleccionado,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.unimetBlue,
                          size: 20,
                        ),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _codigoSeleccionado = newValue;
                            });
                          }
                        },
                        items: _codigosOperadora.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Número (7 dígitos)
            Expanded(
              child: TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '1234567',
                  prefixIcon: const Icon(
                    Icons.phone_iphone,
                    color: AppColors.unimetBlue,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: AppColors.unimetBlue,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                validator: _validateTelefono,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Teléfono completo: $_codigoSeleccionado${_telefonoCtrl.text.isNotEmpty ? _telefonoCtrl.text : "..."}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          'Operadoras venezolanas',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final String foto = _profile?.fotoUrl ?? '';
    final String initials = _initials(_profile?.nombre, _profile?.apellido);
    final String name =
        ((_profile?.nombre ?? '').isEmpty && (_profile?.apellido ?? '').isEmpty)
        ? 'Estudiante'
        : '${_profile?.nombre ?? ''} ${_profile?.apellido ?? ''}';
    final String correo = _profile?.correo ?? '';

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
        const SizedBox(height: 8), // Espacio entre nombre y correo
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
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        resizeToAvoidBottomInset: false, // Evita que la UI se redimensione
        appBar: AppBar(
          title: const Text(
            'Mi Perfil',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ), // <-- Título en negritas
          ),
          backgroundColor: AppColors.unimetBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 90.0, // <-- 1. Altura intermedia
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30), // <-- Esquinas redondeadas
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // Evita que la UI se redimensione
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ), // <-- Título en negritas
        ),
        backgroundColor: AppColors.unimetBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 90.0, // <-- 1. Altura intermedia
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30), // <-- Esquinas redondeadas
          ),
        ),
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
              color: Colors.white, // Aseguramos color de fondo
              surfaceTintColor: Colors.white, // Evita tinte en Material 3
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200), // Borde sutil
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: _input('Nombre', Icons.person_outline),
                        validator: _validateNombre,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidoCtrl,
                        decoration: _input('Apellido', Icons.person),
                        validator: _validateApellido,
                      ),
                      const SizedBox(height: 12),
                      _buildTelefonoField(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.white, // Aseguramos color de fondo
              surfaceTintColor: Colors.white, // Evita tinte en Material 3
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200), // Borde sutil
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: _ReadOnlyRow(icon: Icons.badge_outlined, label: 'Rol'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.unimetBlue, // Color primario
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // ⬇️ INICIO DEL CAMBIO ⬇️
            // Espacio extra al final (REDUCIDO A 5%)
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            // ⬆️ FIN DEL CAMBIO ⬆️
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Busca el _profile en el estado ancestro
    final profile = context
        .findAncestorStateOfType<_UserProfileScreenState>()
        ?._profile;
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
