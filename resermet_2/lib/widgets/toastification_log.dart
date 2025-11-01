import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../utils/app_colors.dart';

class LoginToastService {
  // 1. LOGIN EXITOSO--funciona
  static void showLoginSuccess(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: const Text('Sesión Iniciada'),
      description: const Text('Has iniciado sesión correctamente'),
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: AppColors.toastificationGreen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(
        Icons.check_circle,
        color: AppColors.toastificationGreen,
      ),
    );
  }

  // 2. REGISTRO EXITOSO --funciona
  static void showRegistrationSuccess(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: const Text('Registro Exitoso'),
      description: const Text(
        'Te has registrado correctamente. Revisa tu correo para validar tu cuenta.',
      ),
      autoCloseDuration: const Duration(seconds: 8),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: AppColors.toastificationGreen,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.email, color: AppColors.toastificationGreen),
    );
  }

  // 3. ERROR EN LOGIN (campos vacíos o inválidos)-- esta fino
  static void showLoginError(BuildContext context, {String? message}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: const Text('Error en Login'),
      description: Text(message ?? 'Completa todos los campos correctamente'),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.error, color: Colors.red),
    );
  }

  // 4. ERROR EN REGISTRO (campos vacíos o inválidos)-- fino
  static void showRegistrationError(BuildContext context, {String? message}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: const Text('Error en Registro'),
      description: Text(message ?? 'Completa todos los campos correctamente'),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.person_add_disabled, color: Colors.red),
    );
  }

  // ADVERTENCIA PARA CORREO NO CONFIRMADO --esta fino
  static void showEmailNotVerified(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flat,
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
      icon: const Icon(Icons.warning, color: Colors.amberAccent),
    );
  }

  // 📧 EMAIL DE RECUPERACIÓN ENVIADO
  static void showRecoveryEmailSent(BuildContext context, {String? message}) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: const Text('Email Enviado'),
      description: Text(
        message ?? 'Revisa tu correo para restablecer tu contraseña',
      ),
      autoCloseDuration: const Duration(seconds: 5),
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.blue,
      alignment: Alignment.topRight,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.email_outlined, color: Colors.white),
    );
  }

  // CREDENCIALES INCORRECTAS
  static void showInvalidCredentials(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: const Text('Credenciales Incorrectas'),
      description: const Text('El correo o contraseña son incorrectos'),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      borderRadius: BorderRadius.circular(12),
      primaryColor: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      alignment: Alignment.topCenter,
      icon: const Icon(Icons.lock, color: Colors.red),
    );
  }
}
