import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart'; // ← Contiene MainScreen
import 'screens/login.dart'; // ← Tu pantalla de login
import 'package:resermet_2/ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xjmgknmtiimpjywwsyon.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqbWdrbm10aWltcGp5d3dzeW9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1Mjc1MjUsImV4cCI6MjA3NTEwMzUyNX0.HWxPeiX5JlSfW_2S7B_9aBmNpM0f85Zi15_QoxWmbbY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RESERMET',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(), // 👈 Maneja si hay sesión o no
    );
  }
}

// 🚪 AuthGate: decide si mostrar Login o MainScreen
// 💡 CORRECCIÓN CLAVE: Usa StreamBuilder para reaccionar a los cambios de Auth.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos StreamBuilder para escuchar el estado de autenticación de Supabase
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Mostrar una pantalla de carga mientras se resuelve el estado inicial
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final AuthState authState = snapshot.data!;
        final Session? session = authState.session;

        // Si hay una sesión activa → MainScreen
        if (session != null) {
          return const MainScreen();
        }

        // Si no hay sesión (o después de un logout) → LoginScreen
        return const LoginScreen();
      },
    );
  }
}
