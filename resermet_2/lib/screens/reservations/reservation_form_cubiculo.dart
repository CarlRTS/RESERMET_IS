import 'package:flutter/material.dart';
import 'package:resermet_2/models/cubiculo.dart';
import 'package:resermet_2/services/cubiculo_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resermet_2/widgets/horario_picker.dart';
import 'package:resermet_2/widgets/toastification.dart';

class ReservationFormCubiculo extends StatefulWidget {
  const ReservationFormCubiculo({super.key});

  @override
  State<ReservationFormCubiculo> createState() =>
      _ReservationFormCubiculoState();
}

class _ReservationFormCubiculoState extends State<ReservationFormCubiculo> {
  final _formKey = GlobalKey<FormState>();
  final CubiculoService _cubiculoService = CubiculoService();

  // Controladores
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Estado
  List<Cubiculo> _cubiculosDisponibles = [];
  Cubiculo? _cubiculoSeleccionado;
  TimeOfDay? _selectedTime;
  String? _selectedDuration = '1 hora'; // por defecto

  // Fecha (hoy) solo para mostrar
  DateTime get _fechaActual => DateTime.now();
  String get _fechaFormateada =>
      "${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}";

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Duraciones posibles (máx. 2h)
  final List<String> _allDurations = [
    '30 min',
    '1 hora',
    '1.5 horas',
    '2 horas',
  ];

  // Duraciones disponibles segun hora elegida y cierre (17:00)
  List<String> get _durationsAvailable {
    if (_selectedTime == null) return _allDurations;

    final hora = _selectedTime!.hour;
    final minuto = _selectedTime!.minute;

    // Centro abre 7:00 y cierra 17:00 => 10h (=600 min) desde 7:00
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
    _cargarCubiculosDisponibles();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _cargarCubiculosDisponibles() async {
    try {
      final cubiculos = await _cubiculoService.getCubiculos();
      setState(() {
        _cubiculosDisponibles = cubiculos
            .where((c) => c.estado == 'disponible')
            .toList();
        _isLoading = false;
        if (_cubiculosDisponibles.isNotEmpty) {
          _cubiculoSeleccionado = _cubiculosDisponibles.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error al cargar cubículos: $e', Colors.red);
    }
  }

  // Selector de hora (actualiza duraciones válidas)
  Future<void> _selectTime() async {
    await HorarioPicker.mostrarPicker(
      context: context,
      onHoraSeleccionada: (TimeOfDay selectedTime) {
        setState(() {
          _selectedTime = selectedTime;
          _timeController.text = selectedTime.format(context);

          // Asegurar que la duración elegida siga siendo válida
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

  // ====== ENVIAR RESERVA CON TOASTS ======
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

    //Mostrar toast de carga
    ReservationToastService.showLoading(context, 'Procesando tu reserva...');
    setState(() => _isSubmitting = true);

    try {
      // 1) INICIO local (fecha hoy + hora seleccionada)
      final inicioLocal = DateTime(
        _fechaActual.year,
        _fechaActual.month,
        _fechaActual.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // 2) FIN local desde duración
      final finLocal = _calcularFechaFin(inicioLocal, _selectedDuration!);

      // 3) Convertir ambos a UTC
      final inicioIso = inicioLocal.toUtc().toIso8601String();
      final finIso = finLocal.toUtc().toIso8601String();

      // 4) Insert SIN 'rango' (GENERATED) y con fecha_reserva en UTC YYYY-MM-DD
      final reservaData = {
        'id_articulo': _cubiculoSeleccionado!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicioIso,
        'fin': finIso,
        'compromiso_estudiante': _purposeController.text,
        'estado': 'activa',
      };

      await Supabase.instance.client.from('reserva').insert(reservaData);

      // Cerrar toast de carga y mostrar éxito
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationSuccess(
        context,
        _cubiculoSeleccionado!.nombre,
      );

      // Esperar un poco para que el usuario vea el toast de éxito
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      // Cerrar toast de carga y mostrar error
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error de conexión con la base de datos',
      );

      // También mantener el snackbar original para debugging
      _showSnackbar('Error de Supabase: ${e.message}', Colors.red);
    } catch (e) {
      // Cerrar toast de carga y mostrar error genérico
      ReservationToastService.dismissAll();
      ReservationToastService.showReservationError(
        context,
        'Error inesperado al procesar la reserva',
      );

      // También mantener el snackbar original para debugging
      _showSnackbar('Error al procesar reserva: $e', Colors.red);
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

                      // 2) Fecha hoy (solo lectura)
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

                      // 3) Hora (HorarioPicker)
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

                      // 4) Duración (dinámica)
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

                      // 5) Propósito (opcional)
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

                      // Confirmar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitReservation,
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
                                : 'Solicitar Reserva',
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.unimetBlue,
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
