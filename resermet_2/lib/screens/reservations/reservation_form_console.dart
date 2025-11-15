import 'package:flutter/material.dart';
import 'package:resermet_2/models/consola.dart';
import 'package:resermet_2/services/consola_service.dart';
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
  // === Paleta unificada (UNIMET) y tipografías suaves ===
  static const Color _blue = AppColors.unimetBlue; // azul UNIMET
  static const Color _blueSoft = Color(0xFFE9F2FF); // fondo info suave
  static const Color _fieldBg = Color(0xFFF8FAFF); // fondo inputs
  static const Color _textPrimary = Color(0xFF3F4A58); // gris-azul legible
  static const Color _textSecondary = Color(0xFF5B677A); // gris-azul suave

  final _formKey = GlobalKey<FormState>();
  final ConsolaService _consolaService = ConsolaService();

  // Controladores
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Estado
  List<Consola> _consolasDisponibles = [];
  Consola? _consolaSeleccionada;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  String? _selectedGame;

  DateTime get _fechaActual => DateTime.now();
  String get _fechaFormateada =>
      "${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}";

  // Duraciones dinámicas (se actualizan según hora)
  List<String> _duracionesDisponibles = [
    '30 min',
    '1 hora',
    '1.5 horas',
    '2 horas',
  ];

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Hora límite para reservas (5:00 PM)
  final TimeOfDay _horaLimite = TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _cargarConsolasDisponibles();
  }

  Future<void> _cargarConsolasDisponibles() async {
    try {
      final consolas = await _consolaService.getConsolas();
      final consolasDisponibles = consolas
          .where((c) => c.cantidadDisponible > 0)
          .toList();

      setState(() {
        _consolasDisponibles = consolasDisponibles;
        _isLoading = false;
        if (_consolasDisponibles.isNotEmpty) {
          _consolaSeleccionada = _consolasDisponibles.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar las consolas disponibles');
    }
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

  void _actualizarDuracionesDisponibles() {
    if (_selectedTime == null) return;

    final int totalMinutos = _selectedTime!.hour * 60 + _selectedTime!.minute;

    // Reglas de restricción por hora
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
      },
    );
  }

  void _mostrarError(String mensaje) {
    ReservationToastService.showReservationError(context, mensaje);
  }

  void _mostrarHorarioNoDisponible(String mensaje) {
    ReservationToastService.showScheduleWarning(context, mensaje);
  }

  // ======================================================================
  // ====== ⬇️ 1. FUNCIÓN DE SIMULACIÓN (ACTUALIZADA CON XBOX) ======
  // ======================================================================

  /// Devuelve una lista de juegos compatibles para la consola seleccionada.
  List<String> _getJuegosCompatibles(Consola? consola) {
    if (consola == null) {
      return []; // Lista vacía si no hay consola
    }

    // Simulación de datos basada en el nombre de la consola
    final nombreConsola = consola.nombre.toLowerCase();

    // --- JUEGOS DE PLAYSTATION (PS5 / PS4) ---
    // (Incluye los "juegos normales" que pediste)
    if (nombreConsola.contains('ps5') ||
        nombreConsola.contains('ps4') ||
        nombreConsola.contains('playstation')) {
      return [
        'FC 24',
        'FIFA 21',
        'NBA 2K24',
        'Mortal Kombat 1',
        'Spider-Man 2',
        'Call of Duty: Modern Warfare III',
        'Otro juego',
      ];
    }

    // --- JUEGOS DE NINTENDO SWITCH ---
    if (nombreConsola.contains('switch') ||
        nombreConsola.contains('nintendo')) {
      return [
        'Super Smash Bros.',
        'Mario Kart',
        'Zelda: Tears of the Kingdom',
        'Otro juego',
      ];
    }

    // --- JUEGOS DE XBOX ---
    // (Incluye Halo como pediste)
    if (nombreConsola.contains('xbox')) {
      return [
        'Halo Infinite',
        'Forza Motorsport',
        'FC 24', // (Juego Multiplataforma)
        'Otro juego',
      ];
    }

    // Si no coincide con nada, solo "Otro"
    return ['Otro juego'];
  }
  // ======================================================================
  // ====== ⬆️ FIN DE LA FUNCIÓN DE SIMULACIÓN ======
  // ======================================================================

  // ====== CREAR RESERVA======
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

    if (_consolaSeleccionada == null) {
      _mostrarError('Por favor selecciona una consola');
      return;
    }
    if (_selectedTime == null || _selectedDuration == null) {
      _mostrarError('Por favor completa la hora y duración de la reserva');
      return;
    }
    // El propósito ahora es obligatorio
    if (_purposeController.text.trim().isEmpty) {
      _mostrarError('Por favor describe el propósito de uso');
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

      final inicioIso = inicioLocal.toUtc().toIso8601String();
      final finIso = finLocal.toUtc().toIso8601String();

      // Combinamos el propósito y el juego seleccionado (si existe)
      final String propositoFinal;
      final textoProposito = _purposeController.text.trim();

      if (_selectedGame != null &&
          _selectedGame!.isNotEmpty &&
          _selectedGame != 'Otro juego') {
        // Si hay juego específico, se vuelve la parte principal
        propositoFinal = 'Juego: $_selectedGame. Propósito: $textoProposito';
      } else {
        // Si no hay juego, o es "Otro juego", solo es el propósito
        propositoFinal = textoProposito;
      }

      final reservaData = {
        'id_articulo': _consolaSeleccionada!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicioIso,
        'fin': finIso,
        'compromiso_estudiante':
            propositoFinal, // <-- Usamos el propósito final
        'estado': 'activa',
      };

      await Supabase.instance.client.from('reserva').insert(reservaData);

      ReservationToastService.dismissAll();
      ReservationToastService.showReservationSuccess(
        context,
        _consolaSeleccionada!.nombre,
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

  // ====== Helpers visuales (estilo unificado) ======
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

  InputDecoration _inputDec({
    required String label,
    String? hint,
    IconData? prefix,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal (🔵 ahora en azul UNIMET)
              Text(
                'Reserva tu Consola',
                style: text.titleLarge?.copyWith(
                  color: _blue, // <- azul UNIMET
                  fontWeight: FontWeight.w800,
                  fontSize: 23,
                  height: 1.22,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona la consola y completa los datos de reserva',
                style: text.bodyMedium?.copyWith(
                  color: _textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // ====== Selección de consola ======
              _modernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.videogame_asset_rounded,
                      title: 'Seleccionar Consola',
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: _blue),
                      )
                    else if (_consolasDisponibles.isEmpty)
                      const Text(
                        'No hay consolas disponibles en este momento',
                        style: TextStyle(color: _textSecondary),
                      )
                    else
                      DropdownButtonFormField<Consola>(
                        value: _consolaSeleccionada,
                        isExpanded: true,
                        itemHeight: null,
                        menuMaxHeight: 320,
                        borderRadius: BorderRadius.circular(16),
                        decoration: _inputDec(
                          label: 'Consolas disponibles',
                          hint: 'Elige una consola',
                          prefix: Icons.videogame_asset_rounded,
                        ),
                        selectedItemBuilder: (context) =>
                            _consolasDisponibles.map((c) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  c.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                        items: _consolasDisponibles.map((consola) {
                          return DropdownMenuItem<Consola>(
                            value: consola,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  consola.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'Modelo: ${consola.modelo}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Disponibles: ${consola.cantidadDisponible}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _consolaSeleccionada = newValue;
                            // ¡ESTA ES LA LÍNEA CLAVE QUE CUMPLE EL REQUISITO!
                            _selectedGame = null;
                          });
                        },
                        validator: (value) => value == null
                            ? 'Por favor selecciona una consola'
                            : null,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ====== Info de la consola seleccionada ======
              if (_consolaSeleccionada != null) ...[
                _modernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        icon: Icons.info_rounded,
                        title: 'Información de la Consola',
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _blueSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _blue.withOpacity(.12)),
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: _blue,
                          ),
                        ),
                        title: Text(
                          _consolaSeleccionada!.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _textPrimary,
                            height: 1.2,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Modelo: ${_consolaSeleccionada!.modelo}',
                              style: const TextStyle(color: _textSecondary),
                            ),
                            const SizedBox(height: 2),
                            // ✅ Disponibilidad en VERDE aquí también
                            Text(
                              'Disponibles: ${_consolaSeleccionada!.cantidadDisponible} unidades',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'Total en inventario: ${_consolaSeleccionada!.cantidadTotal}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: _textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ====== Detalles de la reserva ======
              _modernCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                        label: 'Fecha de reserva',
                        prefix: Icons.event_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Hora (ÚNICO CAMPO RESTRINGIDO)
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

                    // Duración (AHORA SIEMPRE HABILITADO)
                    DropdownButtonFormField<String>(
                      value: _selectedDuration,
                      isExpanded: true,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(16),
                      decoration: _inputDec(
                        label: 'Duración de uso',
                        prefix: Icons.timer_rounded,
                      ),
                      items: _duracionesDisponibles
                          .map(
                            (duracion) => DropdownMenuItem(
                              value: duracion,
                              child: Text(
                                duracion,
                                style: const TextStyle(color: _textPrimary),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) =>
                          setState(() => _selectedDuration = newValue),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Por favor selecciona una duración'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // ======================================================================
                    // ====== ⬇️ 2. DROPDOWN DE JUEGOS (DINÁMICO) ======
                    // ======================================================================
                    DropdownButtonFormField<String>(
                      value:
                          _selectedGame, // El valor sigue siendo _selectedGame
                      isExpanded: true,
                      itemHeight: null,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(16),
                      decoration: _inputDec(
                        label: 'Juego (opcional)',
                        hint: 'Selecciona un juego',
                        prefix: Icons.games_rounded,
                      ),

                      // Los 'items' ahora se generan dinámicamente
                      items: [
                        // 1. La opción nula ("Ningún juego") siempre está
                        const DropdownMenuItem(
                          value: null, // El valor es null para "Ninguno"
                          child: Text('Ningún juego específico'),
                        ),
                        // 2. El resto de la lista se genera con la función
                        ..._getJuegosCompatibles(_consolaSeleccionada)
                            .map(
                              (juego) => DropdownMenuItem(
                                value: juego,
                                child: Text(juego),
                              ),
                            )
                            .toList(),
                      ],
                      // El onChanged sigue igual, solo actualiza _selectedGame
                      onChanged: (newValue) =>
                          setState(() => _selectedGame = newValue),
                    ),

                    // ======================================================================
                    // ====== ⬆️ FIN DE LA MODIFICACIÓN DEL DROPDOWN ======
                    // ======================================================================
                    const SizedBox(height: 14),

                    // Propósito (AHORA SIEMPRE HABILITADO)
                    TextFormField(
                      controller: _purposeController,
                      maxLines: 3,
                      decoration: _inputDec(
                        label: 'Propósito de uso',
                        hint: 'Describe para qué usarás la consola...',
                        prefix: Icons.description_rounded,
                      ),
                      // El propósito es obligatorio
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Por favor describe el propósito de uso'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ====== Botón de confirmación ======
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSubmitting ||
                          _consolasDisponibles.isEmpty ||
                          _yaPasoHoraLimite
                      ? null
                      : _crearReserva,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
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
                        ? 'Procesando…'
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
                    backgroundColor:
                        _isSubmitting ||
                            _consolasDisponibles.isEmpty ||
                            _yaPasoHoraLimite
                        ? Colors.grey
                        : _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ====== Información adicional ======
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _blueSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _blue.withOpacity(.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_rounded, color: _blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Información importante',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• La reserva estará pendiente de confirmación\n'
                      '• Debes presentar tu identificación y carnet al recoger la consola\n'
                      '• El tiempo de uso comienza a partir de la hora seleccionada\n'
                      '• Puedes solicitar juegos específicos de forma opcional\n'
                      '• No se permiten reservas después de las 5:00 PM',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
