import 'package:flutter/material.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationFormConsole extends StatefulWidget {
  const ReservationFormConsole({super.key});

  @override
  State<ReservationFormConsole> createState() => _ReservationFormConsoleState();
}

class _ReservationFormConsoleState extends State<ReservationFormConsole> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Datos de ejemplo para las consolas
  final List<Map<String, String>> availableConsoles = [
    {
      'id': '1',
      'name': 'PlayStation 5',
      'model': 'PS5 Standard',
      'available': '3',
    },
    {
      'id': '2',
      'name': 'Xbox Series X',
      'model': 'Xbox X 1TB',
      'available': '2',
    },
    {
      'id': '3',
      'name': 'Nintendo Switch',
      'model': 'Switch OLED',
      'available': '5',
    },
    {'id': '4', 'name': 'PlayStation 4', 'model': 'PS4 Pro', 'available': '1'},
  ];

  String? selectedConsoleId;
  Map<String, String>? selectedConsole;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;

  @override
  void initState() {
    super.initState();
    // Seleccionar la primera consola por defecto
    if (availableConsoles.isNotEmpty) {
      selectedConsoleId = availableConsoles[0]['id'];
      selectedConsole = availableConsoles[0];
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  // Simulación de envío del formulario
  void _submitReservation() {
    if (_formKey.currentState!.validate()) {
      // Mostrar diálogo de confirmación
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Reserva Confirmada'),
            content: Text(
              'Has reservado ${selectedConsole?['name']} para el ${_dateController.text} a las ${_timeController.text}',
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
                          DropdownButtonFormField<String>(
                            value: selectedConsoleId,
                            decoration: InputDecoration(
                              labelText: 'Consolas Disponibles',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.videogame_asset),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: availableConsoles.map((console) {
                              return DropdownMenuItem<String>(
                                value: console['id'],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      console['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      console['model']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedConsoleId = newValue;
                                selectedConsole = availableConsoles.firstWhere(
                                  (console) => console['id'] == newValue,
                                );
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
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
                  if (selectedConsole != null) ...[
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
                                selectedConsole!['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Modelo: ${selectedConsole!['model']!}'),
                                  Text(
                                    'Disponibles: ${selectedConsole!['available']!} unidades',
                                    style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
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
                      onPressed: _submitReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
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
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• La reserva estará pendiente de confirmación\n'
                          '• Debes presentar tu identificación y carnet al recoger la consola\n'
                          '• El tiempo de uso comienza a partir de la hora seleccionada',
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
