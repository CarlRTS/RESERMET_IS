import 'package:flutter/material.dart';
import 'package:resermet_2/widgets/horario_picker.dart';

class HorarioPickerHelper {
  // Método rápido para mostrar picker y obtener TimeOfDay
  static Future<TimeOfDay?> seleccionarHorario({
    required BuildContext context,
    TimeOfDay? horaInicial,
    String titulo = 'Seleccionar Horario',
  }) async {
    TimeOfDay? resultado;

    await HorarioPicker.mostrarPicker(
      context: context,
      horaInicial: horaInicial,
      titulo: titulo,
      onHoraSeleccionada: (hora) {
        resultado = hora;
      },
    );

    return resultado;
  }

  // Convertir TimeOfDay a String legible
  static String formatearTimeOfDay(TimeOfDay time) {
    final periodo = time.hour < 12 ? 'AM' : 'PM';
    final hora = time.hour > 12 ? time.hour - 12 : time.hour;
    final minuto = time.minute.toString().padLeft(2, '0');
    return '$hora:$minuto $periodo';
  }

  // Validar si una hora está dentro del rango 7am-5pm
  static bool esHorarioValido(TimeOfDay time) {
    return time.hour >= 7 && time.hour <= 17;
  }
}
