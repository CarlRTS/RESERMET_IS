import 'package:flutter/material.dart';
import 'package:resermet_2/models/cubiculo.dart';
import 'package:resermet_2/services/cubiculo_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationFormCubiculo extends StatefulWidget {
  const ReservationFormCubiculo({super.key});

  @override
  State<ReservationFormCubiculo> createState() =>
      _ReservationFormCubiculoState();
}

class _ReservationFormCubiculoState extends State<ReservationFormCubiculo> {
  final _formKey = GlobalKey<FormState>();
  final CubiculoService _cubiculoService = CubiculoService();

  // Controladores para los campos de texto
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Variables de estado del formulario
  List<Cubiculo> _cubiculosDisponibles = [];
  Cubiculo? _cubiculoSeleccionado;

  TimeOfDay? _selectedTime;
  String? _selectedDuration = '1 hora'; // Duración predeterminada

  //Fecha automática
  DateTime get _fechaActual => DateTime.now();
  String get _fechaFormateada =>
      "${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}";

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Opciones de duración
  final List<String> _durations = ['1 hora', '1.5 horas', '2 horas', '3 horas'];

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

  // --- Lógica de Carga y Selección ---

  Future<void> _cargarCubiculosDisponibles() async {
    try {
      final cubiculos = await _cubiculoService.getCubiculos();
      setState(() {
        // Solo cargar cubículos que estén 'disponible'
        _cubiculosDisponibles = cubiculos
            .where((c) => c.estado == 'disponible')
            .toList();
        _isLoading = false;
        if (_cubiculosDisponibles.isNotEmpty) {
          _cubiculoSeleccionado = _cubiculosDisponibles.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackbar('Error al cargar cubículos: $e', Colors.red);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Selecciona la hora de inicio',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  // --- Lógica de Envío (Placeholder) ---

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate() || _cubiculoSeleccionado == null)
      return;

    setState(() => _isSubmitting = true);

    try {
      // Usar _fechaActual automáticamente
      final fechaInicio = DateTime(
        _fechaActual.year,
        _fechaActual.month,
        _fechaActual.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Calcular fecha fin basado en la duración seleccionada
      final fechaFin = _calcularFechaFin(fechaInicio, _selectedDuration!);

      // Crear objeto de reserva
      final reservaData = {
        'id_articulo': _cubiculoSeleccionado!.idObjeto,
        'id_usuario': Supabase.instance.client.auth.currentUser?.id,
        'fecha_reserva': DateTime.now().toIso8601String().split('T')[0],
        'inicio': fechaInicio.toIso8601String(),
        'fin': fechaFin.toIso8601String(),
        'compromiso_estudiante': _purposeController.text,
        'estado': 'activa',
      };

      // Insertar en la base de datos
      await Supabase.instance.client.from('reserva').insert(reservaData);

      _showSnackbar(
        'Reserva de ${_cubiculoSeleccionado!.nombre} enviada para aprobación.',
        Colors.green,
      );
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      _showSnackbar('Error de Supabase: ${e.message}', Colors.red);
    } catch (e) {
      _showSnackbar('Error al procesar reserva: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Método para calcular fecha fin
  DateTime _calcularFechaFin(DateTime fechaInicio, String duracion) {
    switch (duracion) {
      case '1 hora':
        return fechaInicio.add(const Duration(hours: 1));
      case '1.5 horas':
        return fechaInicio.add(const Duration(minutes: 90));
      case '2 horas':
        return fechaInicio.add(const Duration(hours: 2));
      case '3 horas':
        return fechaInicio.add(const Duration(hours: 3));
      default:
        return fechaInicio.add(const Duration(hours: 1));
    }
  }

  // --- Utilidades ---

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Usar un 85% de la altura de la pantalla para el modal
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

                      // 1. Selector de Cubículo
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
                          setState(() {
                            _cubiculoSeleccionado = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona un cubículo.' : null,
                      ),
                      const SizedBox(height: 16),

                      //Campo de Fecha automática
                      TextFormField(
                        initialValue: _fechaFormateada,
                        readOnly: true,
                        enabled: false, // Totalmente no editable
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Reserva',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Campo de Hora (con selector)
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

                      // 4. Duración
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Duración (Máx. 3 horas)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timelapse),
                        ),
                        value: _selectedDuration,
                        items: _durations.map((String duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDuration = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona una duración.' : null,
                      ),
                      const SizedBox(height: 16),

                      // 5. Propósito de la Reserva
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

                      // Información importante
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
                              '• El tiempo máximo de reserva es de 3 horas.\n'
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

                      // Botón de Confirmación
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
