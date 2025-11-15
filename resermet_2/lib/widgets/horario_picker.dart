import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:resermet_2/utils/app_colors.dart';

class HorarioPicker extends StatefulWidget {
  final TimeOfDay? horaInicial;
  final ValueChanged<TimeOfDay> onHoraSeleccionada;
  final String titulo;
  final String textoBoton;
  final Color? colorTitulo;
  final Color? colorHoraSeleccionada;
  final Color? colorSeparador;

  const HorarioPicker({
    Key? key,
    this.horaInicial,
    required this.onHoraSeleccionada,
    this.titulo = 'Seleccionar Horario',
    this.textoBoton = 'Seleccionar Hora',
    this.colorTitulo,
    this.colorHoraSeleccionada,
    this.colorSeparador,
  }) : super(key: key);

  @override
  _HorarioPickerState createState() => _HorarioPickerState();

  // Método estático para mostrar el picker como diálogo
  static Future<void> mostrarPicker({
    required BuildContext context,
    required ValueChanged<TimeOfDay> onHoraSeleccionada,
    TimeOfDay? horaInicial,
    String titulo = 'Seleccionar Horario',
    Color? colorTitulo,
    Color? colorHoraSeleccionada,
    Color? colorSeparador,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: HorarioPicker(
          horaInicial: horaInicial,
          onHoraSeleccionada: onHoraSeleccionada,
          titulo: titulo,
          textoBoton: 'Confirmar',
          colorTitulo: colorTitulo,
          colorHoraSeleccionada: colorHoraSeleccionada,
          colorSeparador: colorSeparador,
        ),
      ),
    );
  }
}

class _HorarioPickerState extends State<HorarioPicker> {
  late int _horaSeleccionada;
  late int _minutoSeleccionado;

  late DateTime _ahora;
  late TimeOfDay _horaInicioValida;

  @override
  void initState() {
    super.initState();
    _ahora = DateTime.now();

    // 1. Calcular la primera hora de inicio válida
    _horaInicioValida = _calcularHoraInicioValida(_ahora);

    // 2. Determinar la hora inicial del picker
    TimeOfDay horaInicialPicker = widget.horaInicial ?? _horaInicioValida;

    // 3. Si la hora inicial proporcionada es anterior a la hora válida, usar la válida
    if (_esHoraAnterior(horaInicialPicker, _horaInicioValida)) {
      horaInicialPicker = _horaInicioValida;
    }

    // 4. Limitar al rango (7am - 4:30pm)
    if (_esHoraAnterior(
      horaInicialPicker,
      const TimeOfDay(hour: 7, minute: 0),
    )) {
      horaInicialPicker = const TimeOfDay(hour: 7, minute: 0);
    }
    final horaFin = const TimeOfDay(hour: 16, minute: 30);
    if (_esHoraAnterior(horaFin, horaInicialPicker)) {
      horaInicialPicker = horaFin;
    }

    // 5. Asignar valores
    _horaSeleccionada = horaInicialPicker.hour;
    // `minutosDisponibles` depende de `_horaSeleccionada`, que acabamos de asignar.
    _minutoSeleccionado = _limitarMinuto(horaInicialPicker.minute);

    // 6. Asegurarse de que la hora seleccionada esté en la lista de horas válidas
    final horasValidas = horas;
    if (horasValidas.isNotEmpty && !horasValidas.contains(_horaSeleccionada)) {
      _horaSeleccionada = horasValidas.first;
      _minutoSeleccionado = _limitarMinuto(0);
    }
  }

  // --- Lógica de cálculo de hora ---

  TimeOfDay _calcularHoraInicioValida(DateTime ahora) {
    int hora = ahora.hour;
    int minuto = ahora.minute;

    // Redondear al siguiente intervalo de 5 minutos si no es exacto
    if (minuto % 5 != 0) {
      minuto = (minuto / 5).ceil() * 5;
      if (minuto >= 60) {
        hora += 1;
        minuto = 0;
      }
    }

    // Aplicar límites de apertura (7 AM)
    if (hora < 7) {
      hora = 7;
      minuto = 0;
    }

    // Aplicar límites de cierre (4:30 PM)
    if (hora > 16 || (hora == 16 && minuto > 30)) {
      // Ya no hay reservas hoy.
      hora = 16;
      minuto = 30; // Fijar en la última hora posible
    }

    return TimeOfDay(hour: hora, minute: minuto);
  }

  bool _esHoraAnterior(TimeOfDay horaA, TimeOfDay horaB) {
    if (horaA.hour < horaB.hour) return true;
    if (horaA.hour == horaB.hour && horaA.minute < horaB.minute) return true;
    return false;
  }

  // --- Getters dinámicos para horas y minutos ---

  // Generar lista de horas (desde _horaInicioValida hasta 4pm)
  List<int> get horas {
    final int horaMinima = _horaInicioValida.hour;
    // Si la hora de inicio válida ya pasó las 4pm
    if (horaMinima > 16) return [16]; // Devolver solo 16

    return List.generate(16 - horaMinima + 1, (index) => index + horaMinima);
  }

  // Lista completa de minutos
  List<int> get minutosCompletos => [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];

  // Minutos disponibles según la hora seleccionada
  List<int> get minutosDisponibles {
    List<int> minutosBase = minutosCompletos;

    // 1. Restricción de cierre (4:30 PM)
    if (_horaSeleccionada == 16) {
      minutosBase = [0, 5, 10, 15, 20, 25, 30];
    }

    // 2. Restricción de hora actual (solo si es la primera hora válida)
    if (_horaSeleccionada == _horaInicioValida.hour) {
      // Filtrar minutos que son >= minuto de inicio válido
      final minutosFiltrados = minutosBase
          .where((min) => min >= _horaInicioValida.minute)
          .toList();

      // Si la lista queda vacía (ej: son 4:32 PM),
      // devolvemos el último minuto para evitar un crash.
      if (minutosFiltrados.isEmpty && _horaSeleccionada == 16) {
        return [30];
      }
      return minutosFiltrados;
    }

    // 3. Si la hora seleccionada es futura (ya filtrada por `get horas`),
    // se muestran todos los minutos de esa hora (respetando el cierre si es 4pm).
    return minutosBase;
  }

  // --- Funciones de utilidad y actualización ---

  // Limitar hora al rango dinámico
  int _limitarHora(int hora) {
    final horasValidas = horas;
    if (horasValidas.isEmpty) return 16; // Caso de emergencia
    if (hora < horasValidas.first) return horasValidas.first;
    if (hora > horasValidas.last) return horasValidas.last;
    return hora;
  }

  // Limitar minuto a los valores disponibles
  int _limitarMinuto(int minuto) {
    final minutosValidos = minutosDisponibles;
    if (minutosValidos.isEmpty) {
      // No debería pasar, pero si pasa, devolver el último minuto posible de 4pm
      return 30;
    }

    // Encontrar el minuto válido más cercano (igual o mayor)
    for (int minutoValido in minutosValidos) {
      if (minuto <= minutoValido) {
        return minutoValido;
      }
    }

    // Si no encuentra (ej: minuto es 58), usar el último minuto válido
    return minutosValidos.last;
  }

  // Actualizar minutos cuando cambia la hora
  void _actualizarMinutosAlCambiarHora() {
    final minutosValidos = minutosDisponibles;
    if (minutosValidos.isEmpty) {
      // Caso de emergencia, aunque no debería ocurrir con la nueva lógica de `horas`
      setState(() {
        _minutoSeleccionado = 30;
      });
      return;
    }

    // Si el minuto actual no está en los disponibles, ajustarlo al PRIMERO disponible
    if (!minutosValidos.contains(_minutoSeleccionado)) {
      setState(() {
        _minutoSeleccionado = minutosValidos.first;
      });
    }
  }

  // --- Formateo ---

  String formatearHora(int hora) {
    if (hora < 12) {
      return '$hora AM';
    } else if (hora == 12) {
      return '$hora PM';
    } else {
      return '${hora - 12} PM';
    }
  }

  String formatearMinuto(int minuto) {
    return minuto.toString().padLeft(2, '0');
  }

  String get horaCompleta {
    final horaDisplay = _horaSeleccionada > 12
        ? _horaSeleccionada - 12
        : _horaSeleccionada;
    final periodo = _horaSeleccionada < 12 ? 'AM' : 'PM';
    // Caso especial 12 AM (medianoche) no aplica, 12 PM (mediodía) está bien

    return '$horaDisplay:${formatearMinuto(_minutoSeleccionado)} $periodo';
  }

  TimeOfDay get timeOfDaySeleccionado {
    return TimeOfDay(hour: _horaSeleccionada, minute: _minutoSeleccionado);
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    // Estilos (sin cambios)
    final Color effectiveTitleColor =
        widget.colorTitulo ?? CupertinoColors.systemGrey;
    final Color effectiveHoraColor =
        widget.colorHoraSeleccionada ?? CupertinoColors.systemBlue;
    final Color effectiveSeparadorColor =
        widget.colorSeparador ?? effectiveTitleColor;

    final TextStyle titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: effectiveTitleColor,
    );
    final TextStyle horaStyle = TextStyle(
      fontSize: 16,
      color: effectiveHoraColor,
      fontWeight: FontWeight.w600,
    );
    final TextStyle separadorStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: effectiveSeparadorColor,
    );
    final TextStyle pickerTextStyle = const TextStyle(fontSize: 20);

    // Obtener las listas ANTES de construir los pickers
    final List<int> horasActuales = horas;
    final List<int> minutosActuales = minutosDisponibles;

    // Calcular índices para los scroll controllers
    // Asegurarse de que el índice no sea -1 si la lista está cambiando
    int initialHourIndex = horasActuales.indexOf(_horaSeleccionada);
    if (initialHourIndex == -1 && horasActuales.isNotEmpty) {
      initialHourIndex = 0;
    } else if (horasActuales.isEmpty) {
      initialHourIndex = 0; // fallback
    }

    int initialMinuteIndex = minutosActuales.indexOf(_minutoSeleccionado);
    if (initialMinuteIndex == -1 && minutosActuales.isNotEmpty) {
      initialMinuteIndex = 0;
    } else if (minutosActuales.isEmpty) {
      initialMinuteIndex = 0; // fallback
    }

    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (sin cambios)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemGrey6,
              border: Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.titulo, style: titleStyle),
                Text(horaCompleta, style: horaStyle),
              ],
            ),
          ),

          // Picker de horas y minutos
          Expanded(
            child: Row(
              children: [
                // Picker de Horas (Dinámico)
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: initialHourIndex,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      if (horasActuales.isNotEmpty) {
                        setState(() {
                          _horaSeleccionada = horasActuales[index];
                          _actualizarMinutosAlCambiarHora();
                        });
                      }
                    },
                    children: horasActuales.isNotEmpty
                        ? horasActuales.map((hora) {
                            return Center(
                              child: Text(
                                formatearHora(hora),
                                style: pickerTextStyle,
                              ),
                            );
                          }).toList()
                        // Caso de emergencia: si no hay horas, mostrar la última
                        : [
                            Center(
                              child: Text(
                                formatearHora(16),
                                style: pickerTextStyle,
                              ),
                            ),
                          ],
                  ),
                ),

                // Separador (sin cambios)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(':', style: separadorStyle),
                ),

                // Picker de Minutos (Dinámico)
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: initialMinuteIndex,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      if (minutosActuales.isNotEmpty) {
                        setState(() {
                          _minutoSeleccionado = minutosActuales[index];
                        });
                      }
                    },
                    children: minutosActuales.isNotEmpty
                        ? minutosActuales.map((minuto) {
                            return Center(
                              child: Text(
                                formatearMinuto(minuto),
                                style: pickerTextStyle,
                              ),
                            );
                          }).toList()
                        // Caso de emergencia: si no hay minutos, mostrar el último
                        : [
                            Center(
                              child: Text(
                                formatearMinuto(30),
                                style: pickerTextStyle,
                              ),
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción (sin cambios)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemGrey6,
              border: Border(
                top: BorderSide(color: CupertinoColors.systemGrey4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    color: CupertinoColors.systemGrey5,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoButton(
                    color: AppColors.unimetBlueSecondary,
                    onPressed: () {
                      widget.onHoraSeleccionada(timeOfDaySeleccionado);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
