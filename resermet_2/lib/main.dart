import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Importamos la pantalla principal con la navegación
import 'utils/app_colors.dart'; // Importamos las constantes de colores

void main()  {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reservas UNIMET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema principal con el azul de la UNIMET
        primaryColor: AppColors.unimetBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.unimetBlue,
          primary: AppColors.unimetBlue,
          secondary: AppColors.unimetOrange,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.unimetBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        // Estilo para botones de elevación
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.unimetBlue, // Fondo azul
            foregroundColor: Colors.white, // Texto blanco
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home:
          const MainScreen(), // Llamamos a la pantalla que contiene el BottomNavigationBar
    );
  }
}
