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
  final _formKey = GlobalKey<FormState>();
  final EquipoDeportivoService _equipoService = EquipoDeportivoService();
  final ReservaService _reservaService = ReservaService();

  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  List<EquipoDeportivo> _equiposDisponibles = [];
  EquipoDeportivo? _equipoSeleccionado;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  bool _aceptoAcuerdo = false;
  int _activeReservations = 0;
  int _stockTotal = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  DateTime get _fechaActual => DateTime.now();
  String get _fechaFormateada =>
      "${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}";

  List<String> _duracionesDisponibles = [
    '30 min', '1 hora', '1.5 horas', '2 horas',
  ];

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

  bool get _yaPasoHoraLimite {
    final now = TimeOfDay.now();
    return now.hour > _horaLimite.hour ||
        (now.hour == _horaLimite.hour && now.minute >= _horaLimite.minute);
  }

  bool _esHoraDespuesDeLimite(TimeOfDay hora) {
    return hora.hour > _horaLimite.hour ||
        (hora.hour == _horaLimite.hour && hora.minute > _horaLimite.minute);
  }

  (Color, String) get _stockStatus {
    if (_equipoSeleccionado == null ||
        _selectedTime == null ||
        _selectedDuration == null) {
      return (Colors.grey.shade400, 'Selecciona hora y duración para verificar');
    }
    final int available = _stockTotal - _activeReservations;
    final int lowStockThreshold = (_stockTotal * 0.3).ceil();
    if (available <= 0) {
      return (Colors.red.shade600, 'Sin unidades disponibles en ese horario');
    } else if (available <= lowStockThreshold) {
      return (Colors.orange.shade700, 'Baja disponibilidad · $available unidades');
    } else {
      return (Colors.green.shade600, 'Disponible · $available unidades');
    }
  }

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
      _fechaActual.year, _fechaActual.month, _fechaActual.day,
      _selectedTime!.hour, _selectedTime!.minute,
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

  Future<void> _cargarEquiposDisponibles() async {
    try {
      final equipos = await _equipoService.getEquiposDeportivos();
      final disponibles = equipos.where((e) => e.cantidadDisponible > 0).toList();
      setState(() {
        _equiposDisponibles = disponibles;
        _isLoading = false;
        if (disponibles.isNotEmpty) {
          _equipoSeleccionado = disponibles.first;
          _stockTotal = _equipoSeleccionado!.cantidadTotal;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar los equipos disponibles');
    }
  }

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

  Future<void> _selectTime(BuildContext context) async {
    if (_yaPasoHoraLimite) {
      _mostrarHorarioNoDisponible('No se pueden hacer reservas después de las 5:00 PM');
      return;
    }
    HorarioPicker.mostrarPicker(
      context: context,
      horaInicial: _selectedTime ?? TimeOfDay.now(),
      titulo: 'Seleccionar Hora',
      colorTitulo: AppColors.unimetBlue,
      colorHoraSeleccionada: AppColors.unimetBlue,
      onHoraSeleccionada: (picked) {
        if (_esHoraDespuesDeLimite(picked)) {
          _mostrarHorarioNoDisponible('No se pueden hacer reservas después de las 5:00 PM');
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

  void _mostrarError(String m) =>
      ReservationToastService.showReservationError(context, m);

  void _mostrarHorarioNoDisponible(String m) =>
      ReservationToastService.showScheduleWarning(context, m);

  Future<void> _crearReserva() async {
    if (_yaPasoHoraLimite) {
      _mostrarHorarioNoDisponible('No se pueden hacer reservas después de las 5:00 PM');
      return;
    }
    if (_selectedTime != null && _esHoraDespuesDeLimite(_selectedTime!)) {
      _mostrarHorarioNoDisponible('No se pueden hacer reservas después de las 5:00 PM');
      return;
    }
    if (_equipoSeleccionado == null) {
      _mostrarError('Por favor selecciona un equipo');
      return;
    }
    if (_selectedTime == null || _selectedDuration == null) {
      _mostrarError('Por favor completa la hora y duración');
      return;
    }
    if (!_aceptoAcuerdo) {
      _mostrarError('Debes aceptar el acuerdo de responsabilidad');
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
        _fechaActual.year, _fechaActual.month, _fechaActual.day,
        _selectedTime!.hour, _selectedTime!.minute,
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

      final textoProposito = _purposeController.text.trim().isEmpty
          ? 'Sin especificar'
          : _purposeController.text.trim();

      await Supabase.instance.client.from('reserva').insert({
        'id_articulo': _equipoSeleccionado!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicioLocal.toUtc().toIso8601String(),
        'fin': finLocal.toUtc().toIso8601String(),
        'compromiso_estudiante': textoProposito,
        'estado': 'activa',
      });

      ReservationToastService.dismissAll();
      ReservationToastService.showReservationSuccess(context, _equipoSeleccionado!.nombre);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(context, 'Error de conexión con la base de datos');
      _mostrarError('Error al crear la reserva: ${e.message}');
    } catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(context, 'Error inesperado al procesar la reserva');
      _mostrarError('Error al crear la reserva: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  DateTime _calcularFechaFin(DateTime fechaInicio, String duracion) {
    switch (duracion) {
      case '30 min': return fechaInicio.add(const Duration(minutes: 30));
      case '1 hora': return fechaInicio.add(const Duration(hours: 1));
      case '1.5 horas': return fechaInicio.add(const Duration(minutes: 90));
      case '2 horas': return fechaInicio.add(const Duration(hours: 2));
      default: return fechaInicio.add(const Duration(hours: 1));
    }
  }

  // ===== UI HELPERS =====

  InputDecoration _field({
    required String label,
    String? hint,
    IconData? icon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: enabled ? AppColors.unimetBlue : Colors.grey.shade400, size: 20)
          : null,
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade50,
      labelStyle: TextStyle(
        color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
        fontSize: 14,
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.unimetBlue, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.unimetBlue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.grey.shade100, height: 28);

  @override
  Widget build(BuildContext context) {
    final (stockColor, stockMsg) = _stockStatus;

    return Container(
      color: Colors.grey.shade50,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.unimetBlue))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ===== HEADER =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.unimetBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.sports_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Equipos Deportivos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Solicitud de implemento · $_fechaFormateada',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_yaPasoHoraLimite)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Cerrado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== CARD PRINCIPAL =====
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Selección de equipo
                          _sectionTitle('EQUIPO'),
                          if (_equiposDisponibles.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange.shade600, size: 18),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'No hay equipos disponibles en este momento',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<EquipoDeportivo>(
                              value: _equipoSeleccionado,
                              isExpanded: true,
                              menuMaxHeight: 300,
                              borderRadius: BorderRadius.circular(12),
                              decoration: _field(
                                label: 'Selecciona un equipo',
                                icon: Icons.sports_tennis_rounded,
                              ),
                              selectedItemBuilder: (context) =>
                                  _equiposDisponibles.map((e) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${e.nombre} · ${e.cantidadDisponible} disp.',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )).toList(),
                              items: _equiposDisponibles.map((e) => DropdownMenuItem<EquipoDeportivo>(
                                value: e,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    Text(
                                      '${e.tipoEquipo} · ${e.cantidadDisponible}/${e.cantidadTotal} disponibles',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _equipoSeleccionado = v;
                                  _stockTotal = v?.cantidadTotal ?? 0;
                                });
                                _calculateAvailability();
                              },
                              validator: (v) => v == null ? 'Por favor selecciona un equipo' : null,
                            ),

                          _divider(),

                          // Hora y duración
                          _sectionTitle('HORARIO'),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _timeController,
                                  readOnly: true,
                                  onTap: () => _yaPasoHoraLimite
                                      ? _mostrarHorarioNoDisponible('No se pueden hacer reservas después de las 5:00 PM')
                                      : _selectTime(context),
                                  decoration: _field(
                                    label: 'Hora de inicio',
                                    hint: 'Selecciona',
                                    icon: Icons.access_time_rounded,
                                    enabled: !_yaPasoHoraLimite,
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Selecciona una hora'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDuration,
                                  menuMaxHeight: 240,
                                  borderRadius: BorderRadius.circular(12),
                                  decoration: _field(
                                    label: 'Duración',
                                    icon: Icons.timer_rounded,
                                    enabled: !_yaPasoHoraLimite,
                                  ),
                                  items: _duracionesDisponibles.map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d, style: const TextStyle(fontSize: 14)),
                                  )).toList(),
                                  onChanged: _yaPasoHoraLimite
                                      ? null
                                      : (v) {
                                          setState(() => _selectedDuration = v);
                                          _calculateAvailability();
                                        },
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Selecciona duración'
                                      : null,
                                ),
                              ),
                            ],
                          ),

                          // Indicador de stock
                          if (_selectedTime != null && _selectedDuration != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: stockColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: stockColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_rounded, color: stockColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    stockMsg,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: stockColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          _divider(),

                          // Propósito
                          _sectionTitle('PROPÓSITO (OPCIONAL)'),
                          TextFormField(
                            controller: _purposeController,
                            maxLines: 3,
                            decoration: _field(
                              label: 'Describe el uso',
                              hint: 'Ej: Partido de pádel con compañeros...',
                              icon: Icons.edit_note_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== ACUERDO =====
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, color: AppColors.unimetBlue, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Acuerdo de responsabilidad',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.unimetBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Al retirar el equipo aceptas cuidarlo y devolverlo en las mismas condiciones. '
                            'Debes presentar tu carnet al recogerlo. '
                            'En caso de extravío o daño deberás reponerlo.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => setState(() => _aceptoAcuerdo = !_aceptoAcuerdo),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _aceptoAcuerdo,
                                    onChanged: (v) => setState(() => _aceptoAcuerdo = v ?? false),
                                    activeColor: AppColors.unimetBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: BorderSide(
                                      color: _aceptoAcuerdo ? AppColors.unimetBlue : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Acepto el acuerdo de responsabilidad',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== BOTÓN =====
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ||
                                _equiposDisponibles.isEmpty ||
                                _stockStatus.$1 == Colors.red.shade600 ||
                                _yaPasoHoraLimite
                            ? null
                            : _crearReserva,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.unimetBlue,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _yaPasoHoraLimite
                                    ? 'Reservas cerradas por hoy'
                                    : _equiposDisponibles.isEmpty
                                    ? 'Sin equipos disponibles'
                                    : 'Confirmar reserva',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}