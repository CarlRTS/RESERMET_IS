import 'package:flutter/material.dart';
import 'package:resermet_2/models/consola.dart';
import 'package:resermet_2/services/consola_service.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/widgets/horario_picker.dart';
import 'package:resermet_2/widgets/horario_picker_helper.dart';
import 'package:resermet_2/widgets/toastification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationFormConsole extends StatefulWidget {
  const ReservationFormConsole({super.key});

  @override
  State<ReservationFormConsole> createState() => _ReservationFormConsoleState();
}

class _ReservationFormConsoleState extends State<ReservationFormConsole> {
  final _formKey = GlobalKey<FormState>();
  final ConsolaService _consolaService = ConsolaService();
  final ReservaService _reservaService = ReservaService();

  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  List<Consola> _consolasDisponibles = [];
  Consola? _consolaSeleccionada;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  String? _selectedGame;
  bool _aceptoAcuerdo = false;
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
    _cargarConsolasDisponibles();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _cargarConsolasDisponibles() async {
    try {
      final consolas = await _consolaService.getConsolas();
      final disponibles = consolas.where((c) => c.cantidadDisponible > 0).toList();
      setState(() {
        _consolasDisponibles = disponibles;
        _isLoading = false;
        if (disponibles.isNotEmpty) _consolaSeleccionada = disponibles.first;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar las consolas disponibles');
    }
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
      },
    );
  }

  void _mostrarError(String mensaje) =>
      ReservationToastService.showReservationError(context, mensaje);

  void _mostrarHorarioNoDisponible(String mensaje) =>
      ReservationToastService.showScheduleWarning(context, mensaje);

  Future<void> _crearReserva() async {
    if (_yaPasoHoraLimite) {
      _mostrarHorarioNoDisponible('No se pueden hacer reservas después de las 5:00 PM');
      return;
    }
    if (_selectedTime != null && _esHoraDespuesDeLimite(_selectedTime!)) {
      _mostrarHorarioNoDisponible('No se pueden hacer reservas después de las 5:00 PM');
      return;
    }
    if (_consolaSeleccionada == null) {
      _mostrarError('Por favor selecciona una consola');
      return;
    }
    if (_selectedTime == null || _selectedDuration == null) {
      _mostrarError('Por favor completa la hora y duración de la reserva');
      return;
    }
    if (!_aceptoAcuerdo) {
      _mostrarError('Debes aceptar el acuerdo de responsabilidad para continuar');
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
      final inicioIso = inicioLocal.toUtc().toIso8601String();
      final finIso = finLocal.toUtc().toIso8601String();

      final conflictoCount = await _reservaService.getActiveReservationsCount(
        idArticulo: _consolaSeleccionada!.idObjeto,
        inicio: inicioLocal,
        fin: finLocal,
      );

      if (conflictoCount >= _consolaSeleccionada!.cantidadTotal) {
        ReservationToastService.dismissAll();
        ReservationToastService.showReservationError(
          context,
          'La consola "${_consolaSeleccionada!.nombre}" no tiene unidades disponibles en ese horario.',
        );
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      final textoProposito = _purposeController.text.trim().isEmpty
          ? 'Sin especificar'
          : _purposeController.text.trim();

      final propositoFinal = (_selectedGame != null &&
              _selectedGame!.isNotEmpty &&
              _selectedGame != 'Otro juego')
          ? 'Juego: $_selectedGame. Propósito: $textoProposito'
          : textoProposito;

      await Supabase.instance.client.from('reserva').insert({
        'id_articulo': _consolaSeleccionada!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicioIso,
        'fin': finIso,
        'compromiso_estudiante': propositoFinal,
        'estado': 'activa',
      });

      ReservationToastService.dismissAll();
      ReservationToastService.showReservationSuccess(context, _consolaSeleccionada!.nombre);
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
    return Container(
      color: Colors.grey.shade50,
      child: Form(
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
                        Icons.sports_esports_rounded,
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
                            'Game Room',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Solicitud de consola · $_fechaFormateada',
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
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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

                    // Selección de consola
                    _sectionTitle('CONSOLA'),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: AppColors.unimetBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (_consolasDisponibles.isEmpty)
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
                              'No hay consolas disponibles en este momento',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<Consola>(
                        value: _consolaSeleccionada,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        borderRadius: BorderRadius.circular(12),
                        decoration: _field(
                          label: 'Selecciona una consola',
                          icon: Icons.videogame_asset_rounded,
                        ),
                        selectedItemBuilder: (context) =>
                            _consolasDisponibles.map((c) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${c.nombre} · ${c.cantidadDisponible} disp.',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                        items: _consolasDisponibles.map((c) => DropdownMenuItem<Consola>(
                          value: c,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(
                                '${c.modelo} · ${c.cantidadDisponible}/${c.cantidadTotal} disponibles',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() { _consolaSeleccionada = v; _selectedGame = null; }),
                        validator: (v) => v == null ? 'Por favor selecciona una consola' : null,
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
                                : (v) => setState(() => _selectedDuration = v),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Selecciona duración'
                                : null,
                          ),
                        ),
                      ],
                    ),

                    _divider(),

                    // Juego
                    _sectionTitle('JUEGO (OPCIONAL)'),
                    DropdownButtonFormField<String>(
                      value: _selectedGame,
                      isExpanded: true,
                      menuMaxHeight: 280,
                      borderRadius: BorderRadius.circular(12),
                      decoration: _field(
                        label: 'Selecciona un juego',
                        icon: Icons.games_rounded,
                        enabled: !_yaPasoHoraLimite,
                      ),
                      onChanged: _yaPasoHoraLimite
                          ? null
                          : (v) => setState(() => _selectedGame = v),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Ningún juego específico')),
                        ...(_consolaSeleccionada?.juegosCompatibles ?? []).map(
                          (j) => DropdownMenuItem(value: j, child: Text(j)),
                        ),
                        const DropdownMenuItem(value: 'Otro juego', child: Text('Otro juego (no listado)')),
                      ],
                    ),

                    _divider(),

                    // Propósito
                    _sectionTitle('PROPÓSITO (OPCIONAL)'),
                    TextFormField(
                      controller: _purposeController,
                      maxLines: 3,
                      enabled: !_yaPasoHoraLimite,
                      decoration: _field(
                        label: 'Describe el uso',
                        hint: 'Ej: Torneo de Mario Kart con amigos...',
                        icon: Icons.edit_note_rounded,
                        enabled: !_yaPasoHoraLimite,
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
                      'En caso de extravío o daño deberás reponerlo. '
                      'Los juegos no son transferibles a otros estudiantes.',
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
                  onPressed: _isSubmitting || _consolasDisponibles.isEmpty || _yaPasoHoraLimite
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
                              : _consolasDisponibles.isEmpty
                              ? 'Sin consolas disponibles'
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