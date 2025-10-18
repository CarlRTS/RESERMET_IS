import 'package:flutter/material.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:toastification/toastification.dart';

class ReservationToastService {
  // RESERVA EXITOSA
  static void showReservationSuccess(
    BuildContext context,
    String cubiculoNombre,
  ) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text('Reserva Confirmada'),
      description: Text('Cubículo "$cubiculoNombre" reservado exitosamente'),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: AppColors.toastificationGreen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // ❌ ERROR EN RESERVA
  static void showReservationError(BuildContext context, String errorMessage) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: const Text('Error en Reserva'),
      description: Text(errorMessage),
      autoCloseDuration: const Duration(seconds: 6),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.red,
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  // ⚠️ ADVERTENCIA - HORARIO NO DISPONIBLE
  static void showScheduleWarning(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      title: const Text('Horario No Disponible'),
      description: Text(message),
      autoCloseDuration: const Duration(seconds: 5),
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.orange,
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  // ℹ️ INFORMACIÓN - RESERVA PENDIENTE
  static void showPendingReservation(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: const Text('Reserva en Proceso'),
      description: const Text('Tu reserva está siendo procesada...'),
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(12),
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  // 📱 ESTADOS DE CONEXIÓN
  static void showNetworkError(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: const Text('Sin Conexión'),
      description: const Text('Verifica tu conexión a internet'),
      autoCloseDuration: const Duration(seconds: 5),
      primaryColor: Colors.red,
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  static void showNetworkRestored(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      title: const Text('Conexión Restaurada'),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  // 🕒 RECORDATORIOS TEMPORALES
  static void showReservationReminder(
    BuildContext context,
    String time,
    String cubiculo,
  ) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: const Text('Recordatorio de Reserva'),
      description: Text('Tienes el cubículo $cubiculo a las $time'),
      autoCloseDuration: const Duration(seconds: 6),
      primaryColor: Colors.blue,
      showProgressBar: true,
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  // RESERVA CANCELADA
  static void showCancellationSuccess(BuildContext context, String cubiculo) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: const Text('Reserva Cancelada'),
      description: Text('Cubículo $cubiculo liberado'),
      autoCloseDuration: const Duration(seconds: 4),
      primaryColor: Colors.green,
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  // 🔄 CARGANDO (Toast persistente)
  static void showLoading(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(message),
      description: const Text('Por favor espera...'),
      autoCloseDuration: null, // No se cierra automáticamente
      primaryColor: Colors.blue,
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  static void dismissAll() {
    toastification.dismissAll(); // ← Sin parámetros
  }
}
