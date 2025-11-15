import 'package:flutter/material.dart';
import 'package:resermet_2/models/equipo_deportivo.dart';
import 'package:resermet_2/services/equipo_deportivo_service.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/widgets/horario_picker.dart';
import 'package:resermet_2/widgets/horario_picker_helper.dart';
import 'package:resermet_2/widgets/toastification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationFormEquipment extends StatefulWidget {
  const ReservationFormEquipment({super.key});

  @override
  State<ReservationFormEquipment> createState() =>
      _ReservationFormEquipmentState();
}

class _ReservationFormEquipmentState extends State<ReservationFormEquipment> {
  // ==== Paleta y tipografías (azul UNIMET, letras suaves) ====
  static const Color _blue = AppColors.unimetBlue;
  static const Color _blueSoft = Color(0xFFE9F2FF);
  static const Color _fieldBg = Color(0xFFF8FAFF);
  static const Color _textPrimary = Color(0xFF3F4A58);
  static const Color _textSecondary = Color(0xFF5B677A);

  final _formKey = GlobalKey<FormState>();
  final EquipoDeportivoService _equipoService = EquipoDeportivoService();
  final ReservaService _reservaService = ReservaService();

  // Controladores
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Estado
  List<EquipoDeportivo> _equiposDisponibles = [];
  EquipoDeportivo? _equipoSeleccionado;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;

  // Disponibilidad
  int _activeReservations = 0;
  int _stockTotal = 0;

  // Duraciones dinámicas
  List<String> _duracionesDisponibles = [
    '30 min',
    '1 hora',
    '1.5 horas',
    '2 horas',
  ];

  // Fecha (hoy) solo para mostrar
  DateTime get _fechaActual => DateTime.now();
  String get _fechaFormateada =>
      "${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}";

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Hora límite para reservas (5:00 PM)
  final TimeOfDay _horaLimite = TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _cargarEquiposDisponibles();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

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

  // ====== UI Helpers ======
  Card _modernCard({required Widget child, EdgeInsets? padding}) {
    return Card(
      elevation: 5,
      shadowColor: _blue.withOpacity(.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  InputDecoration _inputDec({
    required String label,
    String? hint,
    IconData? prefix,
    IconData? suffix,
    bool? enabled,
  }) {
    final isDisabled = enabled == false;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: isDisabled ? _textSecondary : _textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: .2,
      ),
      hintStyle: TextStyle(
        color: isDisabled ? _textSecondary.withOpacity(0.7) : _textSecondary,
      ),
      prefixIcon: prefix != null
          ? Icon(prefix, color: isDisabled ? _textSecondary : _blue)
          : null,
      suffixIcon: suffix != null
          ? Icon(
              suffix,
              color: isDisabled
                  ? _textSecondary.withOpacity(0.7)
                  : _textSecondary,
            )
          : null,
      filled: true,
      fillColor: isDisabled ? Colors.grey.shade100 : _fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDisabled ? Colors.grey.shade400 : _blue,
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _blue, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
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
                color: _fieldBg,
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

  // ====== Estado de stock (color + mensaje) ======
  (Color, String) get _stockStatus {
    if (_equipoSeleccionado == null ||
        _selectedTime == null ||
        _selectedDuration == null) {
      return (
        _textSecondary,
        'Selecciona hora y duración para verificar la disponibilidad',
      );
    }

    final int available = _stockTotal - _activeReservations;
    final int lowStockThreshold = (_stockTotal * 0.3).ceil(); // <30% es bajo

    if (available <= 0) {
      return (Colors.red.shade600, 'No disponible - 0 unidades restantes');
    } else if (available <= lowStockThreshold) {
      return (
        Colors.orange.shade700,
        'Baja disponibilidad - $available unidades',
      );
    } else {
      return (Colors.green.shade700, 'Disponible - $available unidades');
    }
  }

  // ====== Lógica de disponibilidad según rango ======
  void _calculateAvailability() async {
    if (_equipoSeleccionado == null ||
        _selectedTime == null ||
        _selectedDuration == null) {
      setState(() {
        _activeReservations = 0;
        _stockTotal = _equipoSeleccionado?.cantidadTotal ?? 0;
      });
      return;
    }

    final inicioLocal = DateTime(
      _fechaActual.year,
      _fechaActual.month,
      _fechaActual.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final finLocal = _calcularFechaFin(inicioLocal, _selectedDuration!);

    final count = await _reservaService.getActiveReservationsCount(
      idArticulo: _equipoSeleccionado!.idObjeto,
      inicio: inicioLocal,
      fin: finLocal,
    );

    setState(() {
      _activeReservations = count;
      _stockTotal = _equipoSeleccionado!.cantidadTotal;
    });
  }

  // ====== Cargar listado ======
  Future<void> _cargarEquiposDisponibles() async {
    try {
      final equipos = await _equipoService.getEquiposDeportivos();
      final equiposDisponibles = equipos
          .where((equipo) => equipo.cantidadDisponible > 0)
          .toList();

      setState(() {
        _equiposDisponibles = equiposDisponibles;
        _isLoading = false;
        if (_equiposDisponibles.isNotEmpty) {
          _equipoSeleccionado = _equiposDisponibles[0];
          _stockTotal = _equipoSeleccionado!.cantidadTotal;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar los equipos disponibles');
    }
  }

  // ====== Duraciones dinámicas ======
  void _actualizarDuracionesDisponibles() {
    if (_selectedTime == null) return;

    final int totalMinutos = _selectedTime!.hour * 60 + _selectedTime!.minute;

    if (totalMinutos > 16 * 60) {
      _duracionesDisponibles = ['30 min'];
    } else if (totalMinutos > 15 * 60 + 30) {
      _duracionesDisponibles = ['30 min', '1 hora'];
    } else if (totalMinutos > 15 * 60) {
      _duracionesDisponibles = ['30 min', '1 hora', '1.5 horas'];
    } else {
      _duracionesDisponibles = ['30 min', '1 hora', '1.5 horas', '2 horas'];
    }

    if (!_duracionesDisponibles.contains(_selectedDuration)) {
      _selectedDuration = null;
    }
    setState(() {});
  }

  // ====== Selectores ======
  Future<void> _selectTime(BuildContext context) async {
    // Verificar si ya pasaron las 5 PM
    if (_yaPasoHoraLimite) {
      _mostrarHorarioNoDisponible(
        'No se pueden hacer reservas después de las 5:00 PM',
      );
      return;
    }

    HorarioPicker.mostrarPicker(
      context: context,
      horaInicial: _selectedTime ?? TimeOfDay.now(),
      titulo: 'Seleccionar Hora',
      colorTitulo: _blue,
      colorHoraSeleccionada: _blue,
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
          _timeController.text = HorarioPickerHelper.formatearTimeOfDay(picked);
        });
        _actualizarDuracionesDisponibles();
        _calculateAvailability();
      },
    );
  }

  // ====== Crear reserva (con validación de stock) ======
  Future<void> _crearReserva() async {
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

    if (_equipoSeleccionado == null) {
      _mostrarError('Por favor selecciona un equipo');
      return;
    }
    if (_selectedTime == null || _selectedDuration == null) {
      _mostrarError('Por favor completa la hora y duración de la reserva');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _mostrarError('Debes iniciar sesión para hacer una reserva');
      return;
    }

    ReservationToastService.showLoading(context, 'Procesando tu reserva...');
    setState(() => _isSubmitting = true);

    try {
      final inicioLocal = DateTime(
        _fechaActual.year,
        _fechaActual.month,
        _fechaActual.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final finLocal = _calcularFechaFin(inicioLocal, _selectedDuration!);

      final conflictoCount = await _reservaService.getActiveReservationsCount(
        idArticulo: _equipoSeleccionado!.idObjeto,
        inicio: inicioLocal,
        fin: finLocal,
      );

      if (conflictoCount >= _equipoSeleccionado!.cantidadTotal) {
        ReservationToastService.dismissAll();
        ReservationToastService.showReservationError(
          context,
          'El equipo "${_equipoSeleccionado!.nombre}" no tiene unidades disponibles en ese horario.',
        );
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      final reservaData = {
        'id_articulo': _equipoSeleccionado!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicioLocal.toUtc().toIso8601String(),
        'fin': finLocal.toUtc().toIso8601String(),
        'compromiso_estudiante': _purposeController.text,
        'estado': 'activa',
      };

      await Supabase.instance.client.from('reserva').insert(reservaData);

      ReservationToastService.dismissAll();
      ReservationToastService.showReservationSuccess(
        context,
        _equipoSeleccionado!.nombre,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error de conexión con la base de datos',
      );
      _mostrarError('Error al crear la reserva: ${e.message}');
    } catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error inesperado al procesar la reserva',
      );
      _mostrarError('Error al crear la reserva: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ====== Utilidades ======
  void _mostrarError(String mensaje) {
    ReservationToastService.showReservationError(context, mensaje);
  }

  void _mostrarHorarioNoDisponible(String mensaje) {
    ReservationToastService.showScheduleWarning(context, mensaje);
  }

  DateTime _calcularFechaFin(DateTime fechaInicio, String duracion) {
    switch (duracion) {
      case '30 min':
        return fechaInicio.add(const Duration(minutes: 30));
      case '1 hora':
        return fechaInicio.add(const Duration(hours: 1));
      case '1.5 horas':
        return fechaInicio.add(const Duration(minutes: 90));
      case '2 horas':
        return fechaInicio.add(const Duration(hours: 2));
      default:
        return fechaInicio.add(const Duration(hours: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _stockStatus;

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
                    children: [
                      // Título
                      Text(
                        'Reserva tu Equipo Deportivo',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                          height: 1.22,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Selección de equipo
                      _modernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              icon: Icons.sports_soccer_rounded,
                              title: 'Seleccionar Equipo',
                            ),
                            const SizedBox(height: 16),
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (_equiposDisponibles.isEmpty)
                              Text(
                                'No hay equipos disponibles en este momento',
                                style: TextStyle(color: _textSecondary),
                              )
                            else
                              DropdownButtonFormField<EquipoDeportivo>(
                                value: _equipoSeleccionado,
                                isExpanded: true,
                                itemHeight: null,
                                menuMaxHeight: 320,
                                borderRadius: BorderRadius.circular(16),
                                decoration: _inputDec(
                                  label: 'Equipos disponibles',
                                  prefix: Icons.sports_tennis_rounded,
                                ),
                                selectedItemBuilder: (context) =>
                                    _equiposDisponibles.map((e) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          e.nombre,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _textPrimary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                items: _equiposDisponibles.map((equipo) {
                                  return DropdownMenuItem<EquipoDeportivo>(
                                    value: equipo,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          equipo.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Tipo: ${equipo.tipoEquipo}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Disponibles: ${equipo.cantidadDisponible}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _equipoSeleccionado = newValue;
                                    _stockTotal =
                                        _equipoSeleccionado?.cantidadTotal ?? 0;
                                  });
                                  _calculateAvailability();
                                },
                                validator: (value) => value == null
                                    ? 'Por favor selecciona un equipo'
                                    : null,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info del equipo seleccionado (opcional)
                      if (_equipoSeleccionado != null)
                        _modernCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(
                                icon: Icons.info_rounded,
                                title: 'Información del equipo',
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _blueSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.sports_tennis_rounded,
                                    color: _blue,
                                  ),
                                ),
                                title: Text(
                                  _equipoSeleccionado!.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _textPrimary,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tipo: ${_equipoSeleccionado!.tipoEquipo}',
                                      style: const TextStyle(
                                        color: _textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Disponibles ahora: ${_equipoSeleccionado!.cantidadDisponible}',
                                      style: TextStyle(
                                        color:
                                            _equipoSeleccionado!
                                                    .cantidadDisponible >
                                                0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_equipoSeleccionado!.cantidadTotal > 0)
                                      Text(
                                        'Total en inventario: ${_equipoSeleccionado!.cantidadTotal}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Detalles de la reserva
                      _modernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              icon: Icons.calendar_month_rounded,
                              title: 'Detalles de la Reserva',
                            ),
                            const SizedBox(height: 16),

                            // Fecha (hoy, solo lectura)
                            TextFormField(
                              initialValue: _fechaFormateada,
                              readOnly: true,
                              enabled: false,
                              decoration: _inputDec(
                                label: 'Fecha de reserva',
                                prefix: Icons.event_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Hora (picker)
                            TextFormField(
                              controller: _timeController,
                              readOnly: true,
                              onTap: () {
                                if (_yaPasoHoraLimite) {
                                  _mostrarHorarioNoDisponible(
                                    'No se pueden hacer reservas después de las 5:00 PM',
                                  );
                                } else {
                                  _selectTime(context);
                                }
                              },
                              decoration: _inputDec(
                                label: 'Hora de inicio',
                                hint: _yaPasoHoraLimite
                                    ? 'Horario no disponible después de 5:00 PM'
                                    : 'Selecciona la hora',
                                prefix: Icons.access_time_rounded,
                                suffix: Icons.keyboard_arrow_down_rounded,
                                enabled: !_yaPasoHoraLimite,
                              ),
                              validator: (value) {
                                if (_yaPasoHoraLimite) {
                                  return 'No se permiten reservas después de las 5:00 PM';
                                }
                                return (value == null || value.isEmpty)
                                    ? 'Por favor selecciona una hora'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Duración (dinámica)
                            DropdownButtonFormField<String>(
                              value: _selectedDuration,
                              menuMaxHeight: 320,
                              borderRadius: BorderRadius.circular(16),
                              decoration: _inputDec(
                                label: 'Duración de uso',
                                prefix: Icons.timelapse_rounded,
                              ),
                              items: _duracionesDisponibles
                                  .map(
                                    (duracion) => DropdownMenuItem(
                                      value: duracion,
                                      child: Text(
                                        duracion,
                                        style: const TextStyle(
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (newValue) {
                                setState(() => _selectedDuration = newValue);
                                _calculateAvailability();
                              },
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Por favor selecciona una duración'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Indicador de stock
                            Builder(
                              builder: (context) {
                                final (color, message) = status;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: color.withOpacity(.45),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_rounded,
                                        color: color,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          message,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Propósito
                            TextFormField(
                              controller: _purposeController,
                              maxLines: 3,
                              decoration: _inputDec(
                                label: 'Propósito de uso',
                                hint: 'Describe para qué usarás el equipo...',
                                prefix: Icons.description_rounded,
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Por favor describe la actividad'
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Nota informativa
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _blueSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _blue.withOpacity(.25)),
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
                                '• La reserva estará pendiente de confirmación\n'
                                '• Debes presentar tu identificación y carnet al recoger el equipo\n'
                                '• Eres responsable del equipo durante el préstamo\n'
                                '• Reporta cualquier daño o anomalía al personal\n'
                                '• No se permiten reservas después de las 5:00 PM',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Botón de confirmación
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSubmitting ||
                                  _equiposDisponibles.isEmpty ||
                                  _stockStatus.$1 == Colors.red.shade600 ||
                                  _yaPasoHoraLimite
                              ? null
                              : _crearReserva,
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
                                : _isSubmitting
                                ? 'Procesando...'
                                : 'Confirmar Reserva',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: .2,
                              height: 1.1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSubmitting || _yaPasoHoraLimite
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
}
