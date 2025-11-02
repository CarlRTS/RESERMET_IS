import 'package:flutter/material.dart';
import 'package:resermet_2/models/cubiculo.dart';
import 'package:resermet_2/services/cubiculo_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resermet_2/widgets/horario_picker.dart';
import 'package:resermet_2/widgets/toastification.dart';
import 'package:resermet_2/models/user_profile.dart';
import 'package:resermet_2/widgets/user_multi_picker_sheet.dart';

// Imports añadidos para la validación
// import 'package:resermet_2/models/reserva.dart'; // <-- YA NO SE NECESITA EL MODELO AQUÍ
import 'package:resermet_2/services/reserva_service.dart';

class ReservationFormCubiculo extends StatefulWidget {
  const ReservationFormCubiculo({super.key});

  @override
  State<ReservationFormCubiculo> createState() =>
      _ReservationFormCubiculoState();
}

class _ReservationFormCubiculoState extends State<ReservationFormCubiculo> {
  final _formKey = GlobalKey<FormState>();
  final CubiculoService _cubiculoService = CubiculoService();
  final ReservaService _reservaService = ReservaService();

  // Controladores
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  final List<UserProfile> _acompanantes = [];
  static const int _maxAcompanantes = 6;

  // Estado
  List<Cubiculo> _cubiculosDisponibles = [];
  List<int> _allCubiculoIds = []; // <-- AÑADIDO: Para la verificación rápida
  Cubiculo? _cubiculoSeleccionado;
  TimeOfDay? _selectedTime;
  String? _selectedDuration = '1 hora';

  // Fecha (hoy)
  DateTime get _fechaActual => DateTime.now();
  String get _fechaFormateada =>
      "${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}";

  // Variables de estado de carga
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _tieneReservaActiva = false;

  // Lógica de duración original
  final List<String> _allDurations = [
    '30 min',
    '1 hora',
    '1.5 horas',
    '2 horas',
  ];

  List<String> get _durationsAvailable {
    if (_selectedTime == null) return _allDurations;

    final hora = _selectedTime!.hour;
    final minuto = _selectedTime!.minute;

    final minutosDesdeInicio = (hora - 7) * 60 + minuto;
    const minutosMaximos = 600;
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

  // --- MÉTODO _loadPageData MODIFICADO (Carga secuencial) ---
  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar cubículos PRIMERO (para obtener sus IDs)
      await _cargarCubiculosDisponibles(setLoading: false);
      // 2. Verificar reservas DESPUÉS (usando los IDs)
      await _verificarReservaActiva(setLoading: false);
    } catch (e) {
      _showSnackbar('Error al cargar datos iniciales: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MÉTODO _verificarReservaActiva MODIFICADO (Lógica rápida) ---
  Future<void> _verificarReservaActiva({bool setLoading = true}) async {
    if (setLoading) setState(() => _isLoading = true);
    try {
      // 1. Usar el método 'Raw' (más rápido, no carga objetos)
      final misReservasRaw = await _reservaService.getMisReservasRaw();

      // 2. Comprobar si alguna reserva activa coincide con un ID de cubículo
      final reservaActiva = misReservasRaw.any((r) {
        final estado = r['estado'];
        final idArticulo = r['id_articulo'];

        // La comprobación clave:
        return estado == 'activa' && _allCubiculoIds.contains(idArticulo);
      });

      if (mounted) {
        setState(() => _tieneReservaActiva = reservaActiva);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error al verificar sus reservas: $e', Colors.red);
      }
    }
  }

  // --- MÉTODO _cargarCubiculosDisponibles MODIFICADO (Guarda IDs) ---
  Future<void> _cargarCubiculosDisponibles({bool setLoading = true}) async {
    try {
      final cubiculos = await _cubiculoService.getCubiculos();
      if (mounted) {
        setState(() {
          // Guardar TODOS los IDs de cubículos para la verificación
          _allCubiculoIds = cubiculos.map((c) => c.idObjeto).toList();

          // Filtrar solo los disponibles para el Dropdown
          _cubiculosDisponibles = cubiculos
              .where((c) => c.estado == 'disponible')
              .toList();

          if (_cubiculosDisponibles.isNotEmpty) {
            _cubiculoSeleccionado = _cubiculosDisponibles.first;
          }
        });
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error al cargar cubículos: $e', Colors.red);
    }
  }

  // Método _selectTime
  Future<void> _selectTime() async {
    await HorarioPicker.mostrarPicker(
      context: context,
      onHoraSeleccionada: (TimeOfDay selectedTime) {
        setState(() {
          _selectedTime = selectedTime;
          _timeController.text = selectedTime.format(context);

          if (!_durationsAvailable.contains(_selectedDuration)) {
            _selectedDuration = _durationsAvailable.isNotEmpty
                ? _durationsAvailable.first
                : null;
          }
        });
      },
      horaInicial: _selectedTime,
      titulo: 'Seleccionar Hora de Inicio',
    );
  }

  // selector de acompanantes
  Future<void> _pickAcompanantes() async {
    final selected = await showModalBottomSheet<List<UserProfile>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UserMultiPickerSheet(initialSelected: _acompanantes),
    );

    if (selected != null) {
      final uid = Supabase.instance.client.auth.currentUser?.id;

      // 1) quita duplicados por id
      final map = <String, UserProfile>{
        for (final u in selected) u.idUsuario: u,
      };

      // 2) quita al titular si aparece
      if (uid != null) map.remove(uid);

      // 3) apaga en 6 máximo
      final list = map.values.toList();
      if (list.length > _maxAcompanantes) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Máximo 6 acompañantes')));
        list.removeRange(_maxAcompanantes, list.length);
      }

      setState(() {
        _acompanantes
          ..clear()
          ..addAll(list);
      });
    }
  }

  // --- MÉTODO _submitReservation MODIFICADO  ---
  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate() ||
        _cubiculoSeleccionado == null ||
        _selectedTime == null ||
        _selectedDuration == null) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnackbar('Debes iniciar sesión para hacer una reserva', Colors.red);
      return;
    }

    ReservationToastService.showLoading(context, 'Verificando reserva...');
    setState(() => _isSubmitting = true);

    // --- INICIO: VALIDACIÓN MODIFICADA ---
    bool tieneActiva;
    try {
      // 1. Usar el método 'Raw'
      final misReservasRaw = await _reservaService.getMisReservasRaw();

      // 2. Misma lógica de verificación rápida
      tieneActiva = misReservasRaw.any((r) {
        final estado = r['estado'];
        final idArticulo = r['id_articulo'];
        return estado == 'activa' && _allCubiculoIds.contains(idArticulo);
      });
    } catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error al verificar tus reservas existentes.',
      );
      _showSnackbar('Error al verificar: $e', Colors.red);
      setState(() => _isSubmitting = false);
      return;
    }

    if (tieneActiva) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Ya tienes un cubículo con reserva activa.',
      );
      _showSnackbar(
        'No puedes reservar otro cubículo hasta finalizar el actual.',
        Colors.orange,
      );
      setState(() {
        _tieneReservaActiva = true;
        _isSubmitting = false;
      });
      return;
    }

    // --- FIN: VALIDACIÓN MODIFICADA ---

    ReservationToastService.showLoading(context, 'Procesando tu reserva...');

    try {
      // Lógica de creación de reserva
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

      // Validaciones rápidas
      if (_acompanantes.length > _maxAcompanantes) {
        _showSnackbar('Máximo 6 acompañantes', Colors.orange);
        return;
      }
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null && _acompanantes.any((u) => u.idUsuario == uid)) {
        _showSnackbar('No puedes agregarte como acompañante', Colors.orange);
        _acompanantes.removeWhere((u) => u.idUsuario == uid);
        return;
      }

      final companionIds = _acompanantes.map((u) => u.idUsuario).toList();

      final reservaData = {
        'id_articulo': _cubiculoSeleccionado!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicioIso,
        'fin': finIso,
        'compromiso_estudiante': _purposeController.text,
        'estado': 'activa',
        if (companionIds.isNotEmpty) 'companions_user_ids': companionIds,
      };

      await Supabase.instance.client.from('reserva').insert(reservaData);

      ReservationToastService.dismissAll();
      ReservationToastService.showReservationSuccess(
        context,
        _cubiculoSeleccionado!.nombre,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error de conexión con la base de datos',
      );
      _showSnackbar('Error de Supabase: ${e.message}', Colors.red);
    } catch (e) {
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error inesperado al procesar la reserva',
      );
      _showSnackbar('Error al procesar reserva: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- Métodos Helper ---
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

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String get _duracionLabelText {
    if (_selectedTime == null) return 'Duración (Máx. 2 horas)';
    final maxDuracion = _durationsAvailable.isNotEmpty
        ? _durationsAvailable.last
        : 'No disponible';
    return 'Duración (Máx. $maxDuracion)';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Formulario de Reserva de Cubículo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 1) Cubículo
                      DropdownButtonFormField<Cubiculo>(
                        decoration: const InputDecoration(
                          labelText: 'Cubículo a Reservar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                        value: _cubiculoSeleccionado,
                        hint: const Text('Selecciona un cubículo'),
                        items: _cubiculosDisponibles.map((Cubiculo cubiculo) {
                          return DropdownMenuItem<Cubiculo>(
                            value: cubiculo,
                            child: Text(
                              '${cubiculo.nombre} (Cap: ${cubiculo.capacidad} pers.)',
                            ),
                          );
                        }).toList(),
                        onChanged: (Cubiculo? newValue) {
                          setState(() => _cubiculoSeleccionado = newValue);
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona un cubículo.' : null,
                      ),
                      const SizedBox(height: 16),

                      // 2) Fecha
                      TextFormField(
                        initialValue: _fechaFormateada,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Reserva',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3) Hora
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: _selectTime,
                        decoration: const InputDecoration(
                          labelText: 'Hora de Inicio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Selecciona una hora.' : null,
                      ),
                      const SizedBox(height: 16),

                      // 4) Duración
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: _duracionLabelText,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.timelapse),
                        ),
                        value: _durationsAvailable.contains(_selectedDuration)
                            ? _selectedDuration
                            : (_durationsAvailable.isNotEmpty
                                  ? _durationsAvailable.first
                                  : null),
                        items: _durationsAvailable.map((String duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() => _selectedDuration = newValue);
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona una duración.' : null,
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: Acompañantes --- //
                      GestureDetector(
                        onTap: _pickAcompanantes,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Estudiantes acompañantes (opcional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText: 'Máximo $_maxAcompanantes estudiantes',
                          ),
                          child: _acompanantes.isEmpty
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.group_add_outlined,
                                      color: AppColors.unimetBlue,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Agregar estudiantes',
                                      style: TextStyle(
                                        color: AppColors.unimetBlue,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _acompanantes.map((u) {
                                        final nombreCompleto = [
                                          if ((u.nombre ?? '').isNotEmpty)
                                            u.nombre,
                                          if ((u.apellido ?? '').isNotEmpty)
                                            u.apellido,
                                        ].whereType<String>().join(' ').trim();

                                        return Chip(
                                          label: Text(
                                            nombreCompleto.isNotEmpty
                                                ? nombreCompleto
                                                : u.correo,
                                          ),
                                          onDeleted: () => setState(
                                            () => _acompanantes.removeWhere(
                                              (x) => x.idUsuario == u.idUsuario,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Editar lista',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      // 6) Acompañantes

                      // 6) Propósito
                      TextFormField(
                        controller: _purposeController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Propósito de la Reserva (Opcional)',
                          hintText: 'Ej: Estudio en grupo, trabajo de tesis...',
                          border: OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 50.0),
                            child: Icon(Icons.lightbulb_outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.lightBlue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Información importante',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.unimetBlue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• La reserva estará pendiente de confirmación.\n'
                              '• El tiempo máximo de reserva es de 2 horas.\n'
                              '• Horario disponible: 7:00 AM - 5:00 PM\n'
                              '• Debes presentar tu carnet al ocupar el cubículo.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // --- BOTÓN (Actualizado con la lógica) ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting || _tieneReservaActiva
                              ? null
                              : _submitReservation,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isSubmitting
                                ? 'Procesando...'
                                : _tieneReservaActiva
                                ? 'Ya tienes una reserva activa'
                                : 'Solicitar Reserva',
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tieneReservaActiva
                                ? Colors.grey
                                : AppColors.unimetBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
