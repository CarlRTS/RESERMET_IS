import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart'; // 👈 Importación de app_links
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks; // 👈 Declara AppLinks

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks(); // 👈 Inicializa AppLinks
    _handleDeepLinks();
  }

  void _handleDeepLinks() async {
    try {
      // Manejar el link inicial si la app fue abierta desde un link
      final initialLink = await _appLinks.getInitialAppLink(); // 👈 Cambiado
      if (initialLink != null) {
        _handlePasswordResetLink(initialLink.path); // 👈 Usa .path
      }

      // Escuchar links mientras la app está en primer plano
      _appLinks.uriLinkStream.listen((Uri? uri) {
        // 👈 Cambiado
        if (uri != null && mounted) {
          _handlePasswordResetLink(uri.toString()); // 👈 Convierte a String
        }
      });
    } catch (e) {
      print('Error handling deep links: $e');
    }
  }

  void _handlePasswordResetLink(String link) {
    // Verificar si es un link de reset de contraseña
    if (link.contains('reset-password')) {
      // Navegar a la pantalla de nueva contraseña
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const NewPasswordScreen()),
            (route) => false,
          );
        });
      }
    }
  }

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

// 🚪 AuthGate: decide si mostrar Login o MainScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
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
