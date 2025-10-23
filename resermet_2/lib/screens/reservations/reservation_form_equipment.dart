import 'package:flutter/material.dart';
import 'package:resermet_2/models/equipo_deportivo.dart';
import 'package:resermet_2/services/equipo_deportivo_service.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/widgets/horario_picker.dart';
import 'package:resermet_2/widgets/horario_picker_helper.dart';
import 'package:resermet_2/widgets/toastification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resermet_2/services/reserva_service.dart';

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

  // Controladores
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  // Estado
  List<EquipoDeportivo> _equiposDisponibles = [];
  EquipoDeportivo? _equipoSeleccionado;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;

  // 💡 NUEVOS ESTADOS DE DISPONIBILIDAD
  int _activeReservations = 0;
  int _stockTotal = 0;
  // -------------------------------------

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

  @override
  void initState() {
    super.initState();
    _cargarEquiposDisponibles();
  }

  //  LÓGICA DE MARCAR FRANJAS HORARIAS (Stock Disponible, Pocos en Existencia, No Disponible)
  (Color, String) get _stockStatus {
    if (_equipoSeleccionado == null ||
        _selectedTime == null ||
        _selectedDuration == null) {
      return (
        Colors.grey,
        'Selecciona hora y duración para verificar la disponibilidad',
      );
    }

    final int available = _stockTotal - _activeReservations;

    // Regla: Pocos en existencia (Amarillo) si queda menos del 30% del stock total
    final int lowStockThreshold = (_stockTotal * 0.3).ceil();

    if (available <= 0) {
      // Rojo: No disponible
      return (Colors.red, 'No disponible - 0 unidades restantes');
    } else if (available <= lowStockThreshold) {
      // Amarillo: Pocos en existencia
      return (
        Colors.orange,
        'Baja disponibilidad - $available unidades restantes',
      );
    } else {
      // Verde: Disponible
      return (Colors.green, 'Disponible - $available unidades restantes');
    }
  }

  // 💡 NUEVO MÉTODO PARA CALCULAR LA DISPONIBILIDAD (ACTUALIZA _activeReservations)
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
          _stockTotal = _equipoSeleccionado!.cantidadTotal; // Inicializar stock
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error cargando equipos: $e');
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar los equipos disponibles');
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  // Actualiza duraciones según la hora elegida
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

  // Selector de hora con tu HorarioPicker
  Future<void> _selectTime(BuildContext context) async {
    HorarioPicker.mostrarPicker(
      context: context,
      horaInicial: _selectedTime ?? TimeOfDay.now(),
      titulo: 'Seleccionar Hora',
      colorTitulo: AppColors.unimetBlue,
      colorHoraSeleccionada: AppColors.unimetBlue,
      onHoraSeleccionada: (picked) {
        setState(() {
          _selectedTime = picked;
          _timeController.text = HorarioPickerHelper.formatearTimeOfDay(picked);
        });
        _actualizarDuracionesDisponibles();
        _calculateAvailability(); // 💡 CALCULAR AL SELECCIONAR HORA
      },
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  // ====== CREAR RESERVA CON VALIDACIÓN DE CONFLICTO AÑADIDA ======
  Future<void> _crearReserva() async {
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

    // Mostrar toast de carga
    ReservationToastService.showLoading(context, 'Procesando tu reserva...');
    setState(() => _isSubmitting = true);

    try {
      // 1) INICIO local con la fecha de hoy + hora seleccionada
      final inicioLocal = DateTime(
        _fechaActual.year,
        _fechaActual.month,
        _fechaActual.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // 2) FIN local según duración
      final finLocal = _calcularFechaFin(inicioLocal, _selectedDuration!);

      // 💡 3) VALIDAR DISPONIBILIDAD DE STOCK (usando la lógica de la UI)
      final conflictoCount = await _reservaService.getActiveReservationsCount(
        idArticulo: _equipoSeleccionado!.idObjeto,
        inicio: inicioLocal,
        fin: finLocal,
      );

      if (conflictoCount >= _equipoSeleccionado!.cantidadTotal) {
        ReservationToastService.dismissAll();
        ReservationToastService.showReservationError(
          context,
          'El Equipo Deportivo "${_equipoSeleccionado!.nombre}" no tiene unidades disponibles en ese horario.',
        );
        if (mounted) setState(() => _isSubmitting = false);
        return; // Detener el proceso
      }
      // ----------------------------------------------------

      // 4) Convertir ambos a UTC
      final inicioIso = inicioLocal.toUtc().toIso8601String();
      final finIso = finLocal.toUtc().toIso8601String();

      // 5) Insert SIN 'rango' (GENERATED) y con fecha_reserva UTC YYYY-MM-DD
      final reservaData = {
        'id_articulo': _equipoSeleccionado!.idObjeto,
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
        _equipoSeleccionado!.nombre,
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

      _mostrarError('Error al crear la reserva: ${e.message}');
    } catch (e) {
      // Cerrar toast de carga y mostrar error genérico
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

  // Cálculo de fin desde la duración
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
    // Obtener el status para la UI
    final status = _stockStatus;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
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
                          // 💡 INDICADOR DE CARGA: Muestra el indicador mientras se cargan los equipos
                          const Center(child: CircularProgressIndicator())
                        else if (_equiposDisponibles.isEmpty)
                          const Text(
                            'No hay equipos disponibles en este momento',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          DropdownButtonFormField<EquipoDeportivo>(
                            value: _equipoSeleccionado,
                            isExpanded: true,
                            itemHeight: null,
                            menuMaxHeight: 320,
                            decoration: InputDecoration(
                              labelText: 'Equipos Disponibles',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.sports_tennis_sharp),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),

                            // Lo que se ve CUANDO EL CAMPO ESTÁ CERRADO (una sola línea)
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
                                      ),
                                    ),
                                  );
                                }).toList(),

                            items: _equiposDisponibles.map((equipo) {
                              return DropdownMenuItem<EquipoDeportivo>(
                                value: equipo,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    // 💡 Muestra el número exacto de unidades disponibles
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
                                //  AL CAMBIAR EL ARTÍCULO, ACTUALIZAR STOCK
                                _calculateAvailability();
                              });
                            },
                            validator: (value) => value == null
                                ? 'Por favor selecciona un equipo'
                                : null,
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
                            ' Información del item',
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
                                Text(
                                  'Tipo: ${_equipoSeleccionado!.tipoEquipo}',
                                ),
                                Text(
                                  'Disponibles: ${_equipoSeleccionado!.cantidadDisponible} unidades',
                                  style: TextStyle(
                                    color:
                                        _equipoSeleccionado!
                                                .cantidadDisponible >
                                            0
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

                        // Fecha (hoy, solo lectura)
                        TextFormField(
                          initialValue: _fechaFormateada,
                          decoration: InputDecoration(
                            labelText: 'Fecha de reserva',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          readOnly: true,
                          enabled: false,
                        ),

                        const SizedBox(height: 16),

                        // Hora (picker)
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
                          readOnly: true,
                          onTap: () => _selectTime(context),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Por favor selecciona una hora'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Duración (dinámica)
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
                          items: _duracionesDisponibles
                              .map(
                                (duracion) => DropdownMenuItem(
                                  value: duracion,
                                  child: Text(duracion),
                                ),
                              )
                              .toList(),
                          onChanged: (newValue) {
                            setState(() => _selectedDuration = newValue);
                            // 💡 CALCULAR AL CAMBIAR DURACIÓN
                            _calculateAvailability();
                          },
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Por favor selecciona una duración'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        //  INDICADOR DE DISPONIBILIDAD/STOCK CON COLOR
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: status.$1.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: status.$1.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2, color: status.$1),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  status
                                      .$2, // Mensaje (Disponible / Baja Disponibilidad / No Disponible)
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status.$1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Propósito
                        TextFormField(
                          controller: _purposeController,
                          decoration: InputDecoration(
                            labelText: 'Actividad o deporte',
                            hintText:
                                'Describe la actividad o deporte para el que usarás el equipo...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.description),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLines: 3,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Por favor describe la actividad'
                              : null,
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
                    //  DESHABILITAR SI NO ESTÁ DISPONIBLE (ROJO) O CARGANDO
                    onPressed:
                        _isSubmitting ||
                            status.$1 == Colors.red ||
                            _equiposDisponibles.isEmpty
                        ? null
                        : _crearReserva,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isSubmitting || _equiposDisponibles.isEmpty
                          ? Colors.grey
                          : status.$1, // Usar color del stock
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
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
    );
  }
}
