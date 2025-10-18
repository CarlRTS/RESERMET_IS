import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../utils/app_colors.dart';

class LoginToastService {
  // 1. LOGIN EXITOSO
  static void showLoginSuccess(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text('Sesión Iniciada'),
      description: const Text('Has iniciado sesión correctamente'),
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: AppColors.toastificationGreen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  // 2. REGISTRO EXITOSO
  static void showRegistrationSuccess(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text('Registro Exitoso'),
      description: const Text(
        'Te has registrado correctamente. Revisa tu correo para validar tu cuenta.',
      ),
      autoCloseDuration: const Duration(seconds: 6),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: AppColors.toastificationGreen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.email, color: Colors.white),
    );
  }

  // 3. ERROR EN LOGIN (campos vacíos o inválidos)
  static void showLoginError(BuildContext context, {String? message}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Error en Login'),
      description: Text(message ?? 'Completa todos los campos correctamente'),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // 4. ERROR EN REGISTRO (campos vacíos o inválidos)
  static void showRegistrationError(BuildContext context, {String? message}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Error en Registro'),
      description: Text(message ?? 'Completa todos los campos correctamente'),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.person_add_disabled, color: Colors.white),
    );
  }

  // ADVERTENCIA PARA CORREO NO CONFIRMADO
  static void showEmailNotVerified(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      title: const Text('Correo no Verificado'),
      description: const Text(
        'Revisa tu bandeja de entrada y confirma tu correo electrónico',
      ),
      autoCloseDuration: const Duration(seconds: 6),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.amberAccent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }

  // CREDENCIALES INCORRECTAS
  static void showInvalidCredentials(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Credenciales Incorrectas'),
      description: const Text('El correo o contraseña son incorrectos'),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.lock, color: Colors.white),
    );
  }
}
