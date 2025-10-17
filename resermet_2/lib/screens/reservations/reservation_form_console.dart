import 'package:flutter/material.dart';
import 'package:resermet_2/models/consola.dart';
import 'package:resermet_2/services/consola_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/widgets/horario_picker.dart';
import 'package:resermet_2/widgets/horario_picker_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationFormConsole extends StatefulWidget {
  const ReservationFormConsole({super.key});

  @override
  State<ReservationFormConsole> createState() => _ReservationFormConsoleState();
}

class _ReservationFormConsoleState extends State<ReservationFormConsole> {
  final _formKey = GlobalKey<FormState>();
  final ConsolaService _consolaService =
      ConsolaService(); // Instanciar servicio

  // Controladores para los campos de texto
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Variables para consolas reales
  List<Consola> _consolasDisponibles = [];
  Consola? _consolaSeleccionada;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  String? _selectedGame;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cargarConsolasDisponibles();
  }

  // Método para cargar consolas desde la base de datos
  Future<void> _cargarConsolasDisponibles() async {
    try {
      final consolas = await _consolaService.getConsolas();

      // Filtrar consolas disponibles (cantidadDisponible > 0)
      final consolasDisponibles = consolas
          .where((consola) => consola.cantidadDisponible > 0)
          .toList();

      setState(() {
        _consolasDisponibles = consolasDisponibles;
        _isLoading = false;

        // Seleccionar la primera consola disponible por defecto
        if (_consolasDisponibles.isNotEmpty) {
          _consolaSeleccionada = _consolasDisponibles[0];
        }
      });
    } catch (e) {
      print('Error cargando consolas: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar las consolas disponibles');
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
    HorarioPicker.mostrarPicker(
      context: context,
      horaInicial: _selectedTime ?? TimeOfDay.now(),
      titulo: 'Seleccionar Hora',
      onHoraSeleccionada: (picked) {
        setState(() {
          _selectedTime = picked;
          _timeController.text = HorarioPickerHelper.formatearTimeOfDay(picked);
        });
      },
    );
  }

  // Método para mostrar errores
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  // Método para crear reserva en la base de datos
  Future<void> _crearReserva() async {
    if (_consolaSeleccionada == null) {
      _mostrarError('Por favor selecciona una consola');
      return;
    }

    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedDuration == null) {
      _mostrarError('Por favor completa todos los campos de fecha y hora');
      return;
    }

    // OBTENER EL USUARIO ACTUAL
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _mostrarError('Debes iniciar sesión para hacer una reserva');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fechaInicio = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final fechaFin = _calcularFechaFin(fechaInicio, _selectedDuration!);

      // Crear objeto de reserva
      final reservaData = {
        'id_articulo': _consolaSeleccionada!.idObjeto,
        'id_usuario': user.id,
        'fecha_reserva': DateTime.now().toIso8601String().split('T')[0],
        'inicio': fechaInicio.toIso8601String(),
        'fin': fechaFin.toIso8601String(),
        'compromiso_estudiante': _purposeController.text,
        'estado': 'activa',
      };

      // Insertar en la base de datos
      await Supabase.instance.client.from('reserva').insert(reservaData);

      // Mostrar confirmación
      _mostrarConfirmacion();
    } catch (e) {
      print('Error creando reserva: $e');
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Has reservado ${_consolaSeleccionada!.nombre}'),
              Text('Fecha: ${_dateController.text}'),
              Text('Hora: ${_timeController.text}'),
              if (_selectedGame != null) Text('Juego: $_selectedGame'),
            ],
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
          'Reservar Consola',
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
                    'Reserva tu Consola',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.unimetBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona la consola y completa los datos de reserva',
                    style: TextStyle(color: AppColors.unimetBlue, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Tarjeta de selección de consola
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
                                Icons.sports_esports,
                                color: Colors.green,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Seleccionar Consola',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_consolasDisponibles.isEmpty)
                            const Text(
                              'No hay consolas disponibles en este momento',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            DropdownButtonFormField<Consola>(
                              value: _consolaSeleccionada,
                              decoration: InputDecoration(
                                labelText: 'Consolas Disponibles',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.videogame_asset),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              items: _consolasDisponibles.map((consola) {
                                return DropdownMenuItem<Consola>(
                                  value: consola,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        consola.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Modelo: ${consola.modelo}', // ← CAMBIADO: modelo en lugar de plataforma
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Disponibles: ${consola.cantidadDisponible}', // ← AGREGADO: cantidad disponible
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
                                  _consolaSeleccionada = newValue;
                                  _selectedGame = null;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor selecciona una consola';
                                }
                                return null;
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Información de la consola seleccionada
                  if (_consolaSeleccionada != null) ...[
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
                              '📋 Información de la Consola',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sports_esports,
                                  color: Colors.blue,
                                ),
                              ),
                              title: Text(
                                _consolaSeleccionada!.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modelo: ${_consolaSeleccionada!.modelo}',
                                  ), // ← CAMBIADO: modelo
                                  Text(
                                    'Disponibles: ${_consolaSeleccionada!.cantidadDisponible} unidades',
                                    style: TextStyle(
                                      color:
                                          _consolaSeleccionada!
                                                  .cantidadDisponible >
                                              0
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Total en inventario: ${_consolaSeleccionada!.cantidadTotal}',
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

                  // Campos del formulario
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
                                Icons.calendar_today,
                                color: Colors.orange,
                                size: 24,
                              ),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor selecciona una fecha';
                              }
                              return null;
                            },
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor selecciona una hora';
                              }
                              return null;
                            },
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
                              DropdownMenuItem(
                                value: '30 min',
                                child: Text('30 minutos'),
                              ),
                              DropdownMenuItem(
                                value: '1 hora',
                                child: Text('1 hora'),
                              ),
                              DropdownMenuItem(
                                value: '1.5 horas',
                                child: Text('1.5 horas'),
                              ),
                              DropdownMenuItem(
                                value: '2 horas',
                                child: Text('2 horas'),
                              ),
                            ],
                            onChanged: (newValue) {
                              setState(() {
                                _selectedDuration = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor selecciona una duración';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Dropdown para juego (opcional) - Mantenido de tu código original
                          // Nota: Para conectar esto a la base de datos, necesitarías una tabla de juegos
                          // Por ahora lo dejamos como campo de texto libre
                          DropdownButtonFormField<String>(
                            value: _selectedGame,
                            decoration: InputDecoration(
                              labelText: 'Juego (opcional)',
                              hintText: 'Selecciona un juego',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.games),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Ningún juego específico'),
                              ),
                              DropdownMenuItem(
                                value: 'FIFA 24',
                                child: Text('FIFA 24'),
                              ),
                              DropdownMenuItem(
                                value: 'Call of Duty: Modern Warfare III',
                                child: Text('Call of Duty: Modern Warfare III'),
                              ),
                              DropdownMenuItem(
                                value: 'Spider-Man 2',
                                child: Text('Spider-Man 2'),
                              ),
                              DropdownMenuItem(
                                value: 'Otro juego',
                                child: Text('Otro juego'),
                              ),
                            ],
                            onChanged: (newValue) {
                              setState(() {
                                _selectedGame = newValue;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Campo de propósito
                          TextFormField(
                            controller: _purposeController,
                            decoration: InputDecoration(
                              labelText: 'Propósito de uso',
                              hintText:
                                  'Describe para qué usarás la consola...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.description),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor describe el propósito de uso';
                              }
                              return null;
                            },
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
                      onPressed: _isSubmitting || _consolasDisponibles.isEmpty
                          ? null
                          : _crearReserva,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isSubmitting || _consolasDisponibles.isEmpty
                            ? Colors.grey
                            : Colors.green,
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
                                Icon(Icons.check_circle, color: Colors.white),
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
                            Icon(Icons.info, color: Colors.blue, size: 20),
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
                          '• Debes presentar tu identificación y carnet al recoger la consola\n'
                          '• El tiempo de uso comienza a partir de la hora seleccionada\n'
                          '• Puedes solicitar juegos específicos de forma opcional',
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
