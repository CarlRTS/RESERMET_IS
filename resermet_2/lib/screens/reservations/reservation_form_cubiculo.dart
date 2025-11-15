import 'package:flutter/material.dart';
import 'package:resermet_2/models/cubiculo.dart';
import 'package:resermet_2/services/cubiculo_service.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/widgets/horario_picker.dart';
import 'package:resermet_2/widgets/toastification.dart'; // Importamos el servicio de Toasts
import 'package:resermet_2/widgets/user_multi_picker_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationFormCubiculo extends StatefulWidget {
  const ReservationFormCubiculo({super.key});

  @override
  State<ReservationFormCubiculo> createState() =>
      _ReservationFormCubiculoState();
}

class _ReservationFormCubiculoState extends State<ReservationFormCubiculo> {
  // Paleta y tonos de texto (suaves, no "negro" duro)
  static const Color _blue = AppColors.unimetBlue;
  static const Color _surfaceField = Color(0xFFF8FAFF);
  static const Color _infoBg = Color(0xFFE8F1FC);
  static const Color _textPrimary = Color(0xFF3F4A58); // gris azulado oscuro
  static const Color _textSecondary = Color(0xFF5B677A); // gris azulado medio

  final _formKey = GlobalKey<FormState>();
  final CubiculoService _cubiculoService = CubiculoService();
  final ReservaService _reservaService = ReservaService();

  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  final List<UserProfile> _acompanantes = [];
  static const int _maxAcompanantes = 6;

  List<Cubiculo> _cubiculosDisponibles = [];
  List<int> _allCubiculoIds = [];
  Cubiculo? _cubiculoSeleccionado;
  TimeOfDay? _selectedTime;
  String? _selectedDuration = '1 hora';

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _tieneReservaActiva = false;

  DateTime get _fechaActual => DateTime.now();
  String get _fechaFormateada =>
      "${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}";

  final List<String> _allDurations = [
    '30 min',
    '1 hora',
    '1.5 horas',
    '2 horas',
  ];

  // Hora límite para reservas (5:00 PM)
  final TimeOfDay _horaLimite = TimeOfDay(hour: 17, minute: 0);

  // Verificar si ya pasó la hora límite
  bool get _yaPasoHoraLimite {
    final now = TimeOfDay.now();
    return now.hour > _horaLimite.hour ||
        (now.hour == _horaLimite.hour && now.minute >= _horaLimite.minute);
  }

  // Verificar si una hora específica pasa el límite
  bool _esHoraDespuesDeLimite(TimeOfDay hora) {
    return hora.hour > _horaLimite.hour ||
        (hora.hour == _horaLimite.hour && hora.minute > _horaLimite.minute);
  }

  List<String> get _durationsAvailable {
    if (_selectedTime == null) return _allDurations;
    final hora = _selectedTime!.hour;
    final minuto = _selectedTime!.minute;
    final minutosDesdeInicio =
        (hora - 0) * 60 + minuto; // 0:00 AM base (sin restricción de 7 AM)
    const minutosMaximos = 1020; // hasta 5:00 PM (17 * 60 = 1020 minutos)
    final minutosDisponibles = minutosMaximos - minutosDesdeInicio;
    return _allDurations.where((d) {
      final m = _duracionAMinutos(d);
      return m <= minutosDisponibles && m > 0;
    }).toList();
  }

  int _duracionAMinutos(String duracion) {
    switch (duracion) {
      case '30 min':
        return 30;
      case '1 hora':
        return 60;
      case '1.5 horas':
        return 90;
      case '2 horas':
        return 120;
      default:
        return 60;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    try {
      await _cargarCubiculosDisponibles(setLoading: false);
      await _verificarReservaActiva(setLoading: false);
    } catch (e) {
      _showErrorToast('Error al cargar datos iniciales: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarCubiculosDisponibles({bool setLoading = true}) async {
    try {
      final cubiculos = await _cubiculoService.getCubiculos();
      if (!mounted) return;
      setState(() {
        _allCubiculoIds = cubiculos.map((c) => c.idObjeto).toList();
        _cubiculosDisponibles = cubiculos
            .where((c) => c.estado == 'disponible')
            .toList();
        if (_cubiculosDisponibles.isNotEmpty) {
          _cubiculoSeleccionado = _cubiculosDisponibles.first;
        }
      });
    } catch (e) {
      if (mounted) _showErrorToast('Error al cargar cubículos: $e');
    }
  }

  Future<void> _verificarReservaActiva({bool setLoading = true}) async {
    try {
      final reservas = await _reservaService.getMisReservasRaw();
      final activa = reservas.any(
        (r) =>
            r['estado'] == 'activa' &&
            _allCubiculoIds.contains(r['id_articulo']),
      );
      if (mounted) setState(() => _tieneReservaActiva = activa);
    } catch (e) {
      if (mounted) _showErrorToast('Error al verificar reservas: $e');
    }
  }

  Future<void> _selectTime() async {
    // Verificar si ya pasaron las 5 PM
    if (_yaPasoHoraLimite) {
      _mostrarHorarioNoDisponible(
        'No se pueden hacer reservas después de las 5:00 PM',
      );
      return;
    }

    // Mostrar el picker (sin restricción de 7 AM)
    await HorarioPicker.mostrarPicker(
      context: context,
      onHoraSeleccionada: (picked) {
        // Validar que la hora seleccionada no sea después de las 5 PM
        if (_esHoraDespuesDeLimite(picked)) {
          _mostrarHorarioNoDisponible(
            'No se pueden hacer reservas después de las 5:00 PM',
          );
          return;
        }

        setState(() {
          _selectedTime = picked;
          _timeController.text = picked.format(context);
          if (!_durationsAvailable.contains(_selectedDuration)) {
            _selectedDuration = _durationsAvailable.isNotEmpty
                ? _durationsAvailable.first
                : null;
          }
        });
      },
      titulo: 'Seleccionar Hora de Inicio',
      colorTitulo: _blue,
    );
  }
  // ======================================================================
  // ====== ⬆️ FIN DE LA ACTUALIZACIÓN ⬆️ ======
  // ======================================================================

  Future<void> _pickAcompanantes() async {
    final selected = await showModalBottomSheet<List<UserProfile>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UserMultiPickerSheet(initialSelected: _acompanantes),
    );
    if (selected != null) {
      final uid = Supabase.instance.client.auth.currentUser?.id;

      // Eliminar duplicados y al titular
      final map = <String, UserProfile>{
        for (final u in selected) u.idUsuario: u,
      };
      if (uid != null) map.remove(uid);

      final list = map.values.take(_maxAcompanantes).toList();
      setState(() {
        _acompanantes
          ..clear()
          ..addAll(list);
      });
    }
  }

  Future<void> _submitReservation() async {
    // Validación de hora límite
    if (_yaPasoHoraLimite) {
      _mostrarHorarioNoDisponible(
        'No se pueden hacer reservas después de las 5:00 PM',
      );
      return;
    }

    if (_selectedTime != null && _esHoraDespuesDeLimite(_selectedTime!)) {
      _mostrarHorarioNoDisponible(
        'No se pueden hacer reservas después de las 5:00 PM',
      );
      return;
    }

    if (!_formKey.currentState!.validate() ||
        _cubiculoSeleccionado == null ||
        _selectedTime == null ||
        _selectedDuration == null) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorToast('Debes iniciar sesión para hacer una reserva');
      return;
    }

    ReservationToastService.showLoading(context, 'Procesando tu reserva...');
    setState(() => _isSubmitting = true);

    try {
      final inicio = DateTime(
        _fechaActual.year,
        _fechaActual.month,
        _fechaActual.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final fin = _calcularFechaFin(inicio, _selectedDuration!);

      final data = {
        'id_articulo': _cubiculoSeleccionado!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicio.toUtc().toIso8601String(),
        'fin': fin.toUtc().toIso8601String(),
        'compromiso_estudiante': _purposeController.text,
        'estado': 'activa',
        if (_acompanantes.isNotEmpty)
          'companions_user_ids': _acompanantes.map((a) => a.idUsuario).toList(),
      };

      await Supabase.instance.client.from('reserva').insert(data);

      ReservationToastService.dismissAll();
      ReservationToastService.showReservationSuccess(
        context,
        _cubiculoSeleccionado!.nombre,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error al procesar la reserva',
      );
      _showErrorToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  DateTime _calcularFechaFin(DateTime inicio, String duracion) {
    switch (duracion) {
      case '30 min':
        return inicio.add(const Duration(minutes: 30));
      case '1 hora':
        return inicio.add(const Duration(hours: 1));
      case '1.5 horas':
        return inicio.add(const Duration(minutes: 90));
      case '2 horas':
        return inicio.add(const Duration(hours: 2));
      default:
        return inicio;
    }
  }

  void _showErrorToast(String message) {
    ReservationToastService.showReservationError(context, message);
  }

  void _mostrarHorarioNoDisponible(String mensaje) {
    ReservationToastService.showScheduleWarning(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Formulario de Reserva de Cubículo',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                          height: 1.22,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Cubículo
                      _modernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              icon: Icons.meeting_room_rounded,
                              title: 'Seleccionar Cubículo',
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Cubiculo>(
                              isExpanded: true,
                              value: _cubiculoSeleccionado,
                              hint: Text(
                                'Selecciona un cubículo',
                                style: TextStyle(color: _textSecondary),
                              ),
                              menuMaxHeight: 320,
                              borderRadius: BorderRadius.circular(16),
                              decoration: _inputDec(
                                label: 'Cubículo a Reservar',
                                prefix: Icons.meeting_room_rounded,
                              ),
                              items: _cubiculosDisponibles.map((c) {
                                return DropdownMenuItem<Cubiculo>(
                                  value: c,
                                  child: Text(
                                    '${c.nombre} (Cap: ${c.capacidad} pers.)',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: _textPrimary),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _cubiculoSeleccionado = v),
                              validator: (v) =>
                                  v == null ? 'Selecciona un cubículo.' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Detalles
                      _modernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              icon: Icons.calendar_month_rounded,
                              title: 'Detalles de la Reserva',
                            ),
                            const SizedBox(height: 16),

                            // Fecha
                            TextFormField(
                              initialValue: _fechaFormateada,
                              readOnly: true,
                              enabled: false,
                              decoration: _inputDec(
                                label: 'Fecha de Reserva',
                                prefix: Icons.event_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Hora
                            TextFormField(
                              controller: _timeController,
                              readOnly: true,
                              onTap: () {
                                if (_yaPasoHoraLimite) {
                                  _mostrarHorarioNoDisponible(
                                    'No se pueden hacer reservas después de las 5:00 PM',
                                  );
                                } else {
                                  _selectTime();
                                }
                              },
                              decoration: _inputDec(
                                label: 'Hora de Inicio',
                                hint: _yaPasoHoraLimite
                                    ? 'Horario no disponible después de 5:00 PM'
                                    : 'Selecciona una hora',
                                prefix: Icons.access_time_rounded,
                              ),
                              validator: (v) {
                                if (_yaPasoHoraLimite) {
                                  return 'No se permiten reservas después de las 5:00 PM';
                                }
                                return (v == null || v.isEmpty)
                                    ? 'Selecciona una hora.'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Duración
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value:
                                  _durationsAvailable.contains(
                                    _selectedDuration,
                                  )
                                  ? _selectedDuration
                                  : (_durationsAvailable.isNotEmpty
                                        ? _durationsAvailable.first
                                        : null),
                              menuMaxHeight: 320,
                              borderRadius: BorderRadius.circular(16),
                              decoration: _inputDec(
                                label: _duracionLabelText,
                                prefix: Icons.timelapse_rounded,
                              ),
                              items: _durationsAvailable.map((d) {
                                return DropdownMenuItem<String>(
                                  value: d,
                                  child: Text(
                                    d,
                                    style: const TextStyle(color: _textPrimary),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedDuration = v),
                              validator: (v) =>
                                  v == null ? 'Selecciona una duración.' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Acompañantes (sin overflow)
                      _modernCard(
                        child: Builder(
                          builder: (context) {
                            final maxChipWidth =
                                MediaQuery.of(context).size.width - 160;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader(
                                  icon: Icons.group_rounded,
                                  title: 'Estudiantes acompañantes (opcional)',
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: _pickAcompanantes,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _surfaceField,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _blue,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.group_add_rounded,
                                              color: _blue,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Añadir / editar lista',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: _textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if (_acompanantes.isEmpty)
                                          Text(
                                            'Agregar estudiantes',
                                            style: TextStyle(
                                              color: _textSecondary,
                                              fontSize: 15,
                                            ),
                                          )
                                        else ...[
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _acompanantes.map((u) {
                                              final nombre =
                                                  [
                                                        if ((u.nombre ?? '')
                                                            .isNotEmpty)
                                                          u.nombre,
                                                        if ((u.apellido ?? '')
                                                            .isNotEmpty)
                                                          u.apellido,
                                                      ]
                                                      .whereType<String>()
                                                      .join(' ')
                                                      .trim();
                                              final etiqueta = nombre.isNotEmpty
                                                  ? nombre
                                                  : u.correo;
                                              return Chip(
                                                label: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: maxChipWidth,
                                                  ),
                                                  child: Text(
                                                    etiqueta,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      color: _textPrimary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                onDeleted: () => setState(
                                                  () =>
                                                      _acompanantes.removeWhere(
                                                        (x) =>
                                                            x.idUsuario ==
                                                            u.idUsuario,
                                                      ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                color: _textSecondary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Editar lista',
                                                style: TextStyle(
                                                  color: _textSecondary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Propósito
                      _modernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              icon: Icons.description_rounded,
                              title: 'Propósito (opcional)',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _purposeController,
                              maxLines: 3,
                              decoration: _inputDec(
                                label: 'Propósito de la Reserva (Opcional)',
                                hint:
                                    'Ej: Estudio en grupo, trabajo de tesis...',
                                prefix: Icons.lightbulb_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Info importante
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _infoBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _blue.withOpacity(.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: _blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '• Máximo 2 horas de uso\n'
                                '• Horario: 12:00 AM - 5:00 PM\n' // Actualizado
                                '• Presenta tu carnet al ocupar el cubículo\n'
                                '• No se permiten reservas después de las 5:00 PM', // Nueva línea
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Botón
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSubmitting ||
                                  _tieneReservaActiva ||
                                  _yaPasoHoraLimite
                              ? null
                              : _submitReservation,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _yaPasoHoraLimite
                                ? 'Reservas cerradas después de 5:00 PM'
                                : _tieneReservaActiva
                                ? 'Ya tienes una reserva activa'
                                : _isSubmitting
                                ? 'Procesando...'
                                : 'Solicitar Reserva',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: .2,
                              height: 1.1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _tieneReservaActiva || _yaPasoHoraLimite
                                ? Colors.grey
                                : _blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // === UI helpers ===
  InputDecoration _inputDec({
    required String label,
    String? hint,
    IconData? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: _textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: .2,
      ),
      hintStyle: const TextStyle(color: _textSecondary),
      prefixIcon: prefix != null ? Icon(prefix, color: _blue) : null,
      filled: true,
      fillColor: _surfaceField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _blue, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _blue, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surfaceField,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _blue.withOpacity(.12)),
              ),
              child: Icon(icon, color: _blue, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                softWrap: true,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: .2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 3,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Card _modernCard({required Widget child, EdgeInsets? padding}) {
    return Card(
      elevation: 5,
      shadowColor: _blue.withOpacity(.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  String get _duracionLabelText {
    if (_selectedTime == null) return 'Duración (Máx. 2 horas)';
    final maxDuracion = _durationsAvailable.isNotEmpty
        ? _durationsAvailable.last
        : 'No disponible';
    return 'Duración (Máx. $maxDuracion)';
  }
}
