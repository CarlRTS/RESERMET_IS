import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login.dart';
import 'package:resermet_2/screens/new_password_screen.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';

// navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey,
      home: const AuthGate(),
    );
  }
}

// 🚪 AuthGate: Esta es la lógica corregida y robusta.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Pantalla de carga mientras se resuelve
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final AuthState authState = snapshot.data!;
        final Session? session = authState.session;
        final AuthChangeEvent event = authState.event;

        // 2. ¡LÓGICA CORRECTA!
        // Si el EVENTO es 'passwordRecovery', RETORNA la pantalla.
        // NO NAVEGUES.
        // Al retornarla, este StreamBuilder sigue vivo y escuchando.
        if (event == AuthChangeEvent.passwordRecovery) {
          print(
            '🔐 Evento detectado: PasswordRecovery. Mostrando NewPasswordScreen.',
          );
          return const NewPasswordScreen();
        }

        // 3. Si NO es un evento de recovery, revisamos la sesión.
        // (Esto funcionará para el Login y para después de
        // actualizar la contraseña).
        if (session != null) {
          print('✅ Sesión detectada. Mostrando MainScreen.');
          return const MainScreen();
        }

        // 4. Si no hay sesión → LoginScreen
        print('⚪️ No hay sesión. Mostrando LoginScreen.');
        return const LoginScreen();
      },
    );
  }
}
