import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart'; // Importamos la pantalla principal con la navegación
import 'utils/app_colors.dart'; // Importamos las constantes de colores

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xjmgknmtiimpjywwsyon.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqbWdrbm10aWltcGp5d3dzeW9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1Mjc1MjUsImV4cCI6MjA3NTEwMzUyNX0.HWxPeiX5JlSfW_2S7B_9aBmNpM0f85Zi15_QoxWmbbY',
  );
  // Usa Supabase en tu app con: Supabase.instance.client

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
