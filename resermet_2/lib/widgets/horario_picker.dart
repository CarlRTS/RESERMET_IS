import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HorarioPicker extends StatefulWidget {
  final TimeOfDay? horaInicial;
  final ValueChanged<TimeOfDay> onHoraSeleccionada;
  final String titulo;
  final String textoBoton;

  const HorarioPicker({
    Key? key,
    this.horaInicial,
    required this.onHoraSeleccionada,
    this.titulo = 'Seleccionar Horario',
    this.textoBoton = 'Seleccionar Hora',
  }) : super(key: key);

  @override
  _HorarioPickerState createState() => _HorarioPickerState();

  // Método estático para mostrar el picker como diálogo
  static Future<void> mostrarPicker({
    required BuildContext context,
    required ValueChanged<TimeOfDay> onHoraSeleccionada,
    TimeOfDay? horaInicial,
    String titulo = 'Seleccionar Horario',
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
        ),
      ),
    );
  }
}

class _HorarioPickerState extends State<HorarioPicker> {
  late int _horaSeleccionada;
  late int _minutoSeleccionado;

  // Generar lista de horas (7am a 5pm)
  List<int> get horas => List.generate(11, (index) => index + 7);
  
  // Generar lista de minutos (0, 15, 30, 45)
  List<int> get minutos => [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    
    // Inicializar con hora proporcionada o por defecto (7:00 AM)
    final horaInicial = widget.horaInicial ?? const TimeOfDay(hour: 7, minute: 0);
    _horaSeleccionada = _limitarHora(horaInicial.hour);
    _minutoSeleccionado = _limitarMinuto(horaInicial.minute);
  }

  // Limitar hora al rango 7-17 (7am - 5pm)
  int _limitarHora(int hora) {
    if (hora < 7) return 7;
    if (hora > 17) return 17;
    return hora;
  }

  // Limitar minuto a los valores disponibles (0, 15, 30, 45)
  int _limitarMinuto(int minuto) {
    if (minuto <= 0) return 0;
    if (minuto <= 15) return 15;
    if (minuto <= 30) return 30;
    if (minuto <= 45) return 45;
    return 0;
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
    int horaDisplay = _horaSeleccionada > 12 ? _horaSeleccionada - 12 : _horaSeleccionada;
    return '$horaDisplay:${formatearMinuto(_minutoSeleccionado)} $periodo';
  }

  TimeOfDay get timeOfDaySeleccionado {
    return TimeOfDay(hour: _horaSeleccionada, minute: _minutoSeleccionado);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header con título
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            border: Border(
              bottom: BorderSide(color: CupertinoColors.systemGrey4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                horaCompleta,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                    });
                  },
                  children: horas.map((hora) {
                    return Center(
                      child: Text(
                        formatearHora(hora),
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Separador
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  ':',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              
              // Picker de Minutos
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: minutos.indexOf(_minutoSeleccionado),
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _minutoSeleccionado = minutos[index];
                    });
                  },
                  children: minutos.map((minuto) {
                    return Center(
                      child: Text(
                        formatearMinuto(minuto),
                        style: const TextStyle(fontSize: 20),
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
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            border: Border(
              top: BorderSide(color: CupertinoColors.systemGrey4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  onPressed: () {
                    widget.onHoraSeleccionada(timeOfDaySeleccionado);
                    Navigator.of(context).pop();
                  },
                  child: Text(widget.textoBoton),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}