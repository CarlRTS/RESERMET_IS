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

  // Generar lista de horas (7am a 4pm)
  List<int> get horas => List.generate(10, (index) => index + 7);

  // Lista completa de minutos disponibles
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
    // Si es las 4:00 PM (hora 16), solo mostrar minutos hasta 30
    if (_horaSeleccionada == 16) {
      return [0, 5, 10, 15, 20, 25, 30]; // ← Solo hasta 30 min
    }
    // Para otras horas, mostrar todos los minutos
    return minutosCompletos;
  }

  @override
  void initState() {
    super.initState();

    // Inicializar con hora proporcionada o por defecto (7:00 AM)
    final horaInicial =
        widget.horaInicial ?? const TimeOfDay(hour: 7, minute: 0);
    _horaSeleccionada = _limitarHora(horaInicial.hour);
    _minutoSeleccionado = _limitarMinuto(horaInicial.minute);
  }

  // Limitar hora al rango 7-16 (7am - 4pm)
  int _limitarHora(int hora) {
    if (hora < 7) return 7;
    if (hora > 16) return 16;
    return hora;
  }

  // Limitar minuto a los valores disponibles según la hora
  int _limitarMinuto(int minuto) {
    final minutosValidos = minutosDisponibles;

    // Encontrar el minuto válido más cercano
    for (int minutoValido in minutosValidos) {
      if (minuto <= minutoValido) {
        return minutoValido;
      }
    }

    // Si no encuentra, usar el último minuto válido
    return minutosValidos.last;
  }

  // Actualizar minutos cuando cambia la hora
  void _actualizarMinutosAlCambiarHora() {
    final minutosValidos = minutosDisponibles;

    // Si el minuto actual no está en los disponibles, ajustarlo al más cercano
    if (!minutosValidos.contains(_minutoSeleccionado)) {
      // Encontrar el minuto válido más cercano
      int minutoMasCercano = minutosValidos.first;
      for (int minutoValido in minutosValidos) {
        if ((minutoValido - _minutoSeleccionado).abs() <
            (minutoMasCercano - _minutoSeleccionado).abs()) {
          minutoMasCercano = minutoValido;
        }
      }

      setState(() {
        _minutoSeleccionado = minutoMasCercano;
      });
    }
  }

  // Formatear hora para mostrar (AM/PM)
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
    String periodo = _horaSeleccionada < 12 ? 'AM' : 'PM';
    int horaDisplay = _horaSeleccionada > 12
        ? _horaSeleccionada - 12
        : _horaSeleccionada;
    return '$horaDisplay:${formatearMinuto(_minutoSeleccionado)} $periodo';
  }

  TimeOfDay get timeOfDaySeleccionado {
    return TimeOfDay(hour: _horaSeleccionada, minute: _minutoSeleccionado);
  }

  @override
  Widget build(BuildContext context) {
    // Pre-calcular todos los estilos para evitar warnings
    final Color effectiveTitleColor =
        widget.colorTitulo ?? CupertinoColors.systemGrey;
    final Color effectiveHoraColor =
        widget.colorHoraSeleccionada ?? CupertinoColors.systemBlue;
    final Color effectiveSeparadorColor =
        widget.colorSeparador ?? effectiveTitleColor;

    // Pre-definir todos los TextStyles
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

    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con título
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
                // Picker de Horas
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: horas.indexOf(_horaSeleccionada),
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _horaSeleccionada = horas[index];
                        // Actualizar minutos automáticamente al cambiar hora
                        _actualizarMinutosAlCambiarHora();
                      });
                    },
                    children: horas.map((hora) {
                      return Center(
                        child: Text(
                          formatearHora(hora),
                          style: pickerTextStyle,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Separador
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(':', style: separadorStyle),
                ),

                // Picker de Minutos - AHORA USAR minutosDisponibles
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: minutosDisponibles.indexOf(
                        _minutoSeleccionado,
                      ),
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _minutoSeleccionado = minutosDisponibles[index];
                      });
                    },
                    children: minutosDisponibles.map((minuto) {
                      return Center(
                        child: Text(
                          formatearMinuto(minuto),
                          style: pickerTextStyle,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción
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
