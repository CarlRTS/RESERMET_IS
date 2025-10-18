import 'package:flutter/material.dart';
import 'package:resermet_2/models/equipo_deportivo.dart';
import 'package:resermet_2/services/equipo_deportivo_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
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

  // Controladores para los campos de texto
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Variables para equipos deportivos reales
  List<EquipoDeportivo> _equiposDisponibles = [];
  EquipoDeportivo? _equipoSeleccionado;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cargarEquiposDisponibles();
  }

  // Método para cargar equipos desde la base de datos
  Future<void> _cargarEquiposDisponibles() async {
    try {
      final equipos = await _equipoService.getEquiposDeportivos();

      // Filtrar equipos disponibles (cantidad_disponible > 0)
      final equiposDisponibles =
          equipos.where((equipo) => equipo.cantidadDisponible > 0).toList();

      setState(() {
        _equiposDisponibles = equiposDisponibles;
        _isLoading = false;

        // Seleccionar el primer equipo disponible por defecto
        if (_equiposDisponibles.isNotEmpty) {
          _equipoSeleccionado = _equiposDisponibles[0];
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error cargando equipos: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar los equipos disponibles');
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  // Método para seleccionar fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // Método para seleccionar hora
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  // Método para mostrar errores
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  // ================== CREAR RESERVA (UTC) ==================
  Future<void> _crearReserva() async {
    if (_equipoSeleccionado == null) {
      _mostrarError('Por favor selecciona un equipo');
      return;
    }

    if (_selectedDate == null || _selectedTime == null || _selectedDuration == null) {
      _mostrarError('Por favor completa todos los campos de fecha y hora');
      return;
    }

    // Usuario actual
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _mostrarError('Debes iniciar sesión para hacer una reserva');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1) Construir INICIO en hora local
      final inicioLocal = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // 2) Calcular FIN en local a partir de la duración
      final finLocal = _calcularFechaFin(inicioLocal, _selectedDuration!);

      // 3) Convertir AMBOS a UTC para guardar correctamente
      final inicioIso = inicioLocal.toUtc().toIso8601String();
      final finIso = finLocal.toUtc().toIso8601String();

      // 4) Construir payload (SIN 'rango' porque es columna GENERATED)
      final reservaData = {
        'id_articulo': _equipoSeleccionado!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toUtc().toIso8601String().split('T')[0],
        'inicio': inicioIso, // UTC
        'fin': finIso,       // UTC
        'compromiso_estudiante': _purposeController.text,
        'estado': 'activa',
      };

      // 5) Insert en la tabla reserva
      await Supabase.instance.client.from('reserva').insert(reservaData);

      // 6) (Opcional/Recomendado) marcar el artículo como prestado
      await Supabase.instance.client
          .from('articulo')
          .update({'estado': 'prestado'})
          .eq('id_articulo', _equipoSeleccionado!.idObjeto);

      // 7) Confirmación
      _mostrarConfirmacion();
    } on PostgrestException catch (e) {
      _mostrarError('Error al crear la reserva: ${e.message}');
    } catch (e) {
      _mostrarError('Error al crear la reserva: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Método para calcular fecha fin basado en la duración
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

  // Método para mostrar confirmación
  void _mostrarConfirmacion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reserva Confirmada'),
          content: Text(
            'Has reservado ${_equipoSeleccionado?.nombre} para el ${_dateController.text} a las ${_timeController.text}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Regresar a pantalla anterior
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reservar Equipo Deportivo',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.unimetOrange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.unimetLightGray],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Text(
                    'Reserva tu Equipo Deportivo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.unimetBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona el equipo y completa los datos de reserva',
                    style: TextStyle(color: AppColors.unimetBlue, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Tarjeta de selección de equipo
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                color: AppColors.unimetBlueSecondary,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Seleccionar item',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.unimetBlueSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_equiposDisponibles.isEmpty)
                            const Text(
                              'No hay equipos disponibles en este momento',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            DropdownButtonFormField<EquipoDeportivo>(
                              value: _equipoSeleccionado,
                              decoration: InputDecoration(
                                labelText: 'Equipos Disponibles',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.sports_tennis_sharp,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
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
                                        ),
                                      ),
                                      Text(
                                        'Tipo: ${equipo.tipoEquipo}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Disponibles: ${equipo.cantidadDisponible}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _equipoSeleccionado = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor selecciona un equipo';
                                }
                                return null;
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Información del equipo seleccionado
                  if (_equipoSeleccionado != null) ...[
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📋 Información del item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.lightBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sports_tennis_sharp,
                                  color: Colors.lightBlue,
                                ),
                              ),
                              title: Text(
                                _equipoSeleccionado!.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tipo: ${_equipoSeleccionado!.tipoEquipo}'),
                                  Text(
                                    'Disponibles: ${_equipoSeleccionado!.cantidadDisponible} unidades',
                                    style: TextStyle(
                                      color: _equipoSeleccionado!.cantidadDisponible > 0
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_equipoSeleccionado!.cantidadTotal > 0)
                                    Text(
                                      'Total en inventario: ${_equipoSeleccionado!.cantidadTotal}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Campos del formulario (fecha, hora, duración, propósito)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.orange, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Detalles de la Reserva',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Campo de fecha
                          TextFormField(
                            controller: _dateController,
                            decoration: InputDecoration(
                              labelText: 'Fecha de reserva',
                              hintText: 'Selecciona la fecha',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onTap: () => _selectDate(context),
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Por favor selecciona una fecha' : null,
                          ),

                          const SizedBox(height: 16),

                          // Campo de hora
                          TextFormField(
                            controller: _timeController,
                            decoration: InputDecoration(
                              labelText: 'Hora de inicio',
                              hintText: 'Selecciona la hora',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.access_time),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onTap: () => _selectTime(context),
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Por favor selecciona una hora' : null,
                          ),

                          const SizedBox(height: 16),

                          // Dropdown de duración
                          DropdownButtonFormField<String>(
                            value: _selectedDuration,
                            decoration: InputDecoration(
                              labelText: 'Duración de uso',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.timer),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: const [
                              DropdownMenuItem(value: '30 min', child: Text('30 minutos')),
                              DropdownMenuItem(value: '1 hora', child: Text('1 hora')),
                              DropdownMenuItem(value: '1.5 horas', child: Text('1.5 horas')),
                              DropdownMenuItem(value: '2 horas', child: Text('2 horas')),
                            ],
                            onChanged: (newValue) => setState(() => _selectedDuration = newValue),
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Por favor selecciona una duración' : null,
                          ),

                          const SizedBox(height: 16),

                          // Campo de propósito
                          TextFormField(
                            controller: _purposeController,
                            decoration: const InputDecoration(
                              labelText: 'Actividad o deporte',
                              hintText: 'Describe la actividad o deporte para el que usarás el equipo...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                              filled: true,
                            ),
                            maxLines: 3,
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Por favor describe la actividad' : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botón de confirmación
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _equiposDisponibles.isEmpty
                          ? null
                          : _crearReserva,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isSubmitting || _equiposDisponibles.isEmpty ? Colors.grey : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_tennis, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Confirmar Reserva',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Información adicional
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.lightBlue, size: 20),
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
                          '• La reserva estará pendiente de confirmación\n'
                          '• Debes presentar tu identificación y carnet al recoger el equipo\n'
                          '• Eres responsable del equipo durante el tiempo de préstamo\n'
                          '• Reporta cualquier daño o anomalía al personal',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
