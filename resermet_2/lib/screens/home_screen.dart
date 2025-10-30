import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importaciones existentes
import 'my_reservations.dart';
import 'reservations/reservation_screen.dart';
import 'admin/admin_home_screen.dart';
import 'login.dart';
import 'package:resermet_2/screens/user_profile_screen.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'reservations/reservation_form_cubiculo.dart';
import 'reservations/reservation_form_console.dart';
import 'reservations/reservation_form_equipment.dart';
import 'package:resermet_2/services/reserva_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final resp = await Supabase.instance.client
            .from('usuario')
            .select('rol')
            .eq('id_usuario', user.id)
            .maybeSingle();

        if (resp is Map<String, dynamic>) {
          final role = resp['rol'] as String?;
          if (mounted) setState(() => _isAdmin = role == 'administrador');
        }
      }
    } catch (e) {
      debugPrint('Error verificando rol: $e');
    }
  }

  List<Widget> get _widgetOptions {
    final screens = <Widget>[
      const HomeScreen(),
      const BookingScreen(),
      const MyBookingsScreen(),
    ];
    if (_isAdmin) screens.add(const AdminHomeScreen());
    return screens;
  }

  List<BottomNavigationBarItem> get _bottomNavItems {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_rounded),
        label: 'Reservar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_rounded),
        label: 'Mis Reservas',
      ),
    ];
    if (_isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings_rounded),
        label: 'Admin',
      ));
    }
    return items;
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(0.55),
        backgroundColor: cs.surface,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}

// 🏠 HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _reservaService = ReservaService();
  List<Map<String, dynamic>> _reservas = [];
  List<Map<String, dynamic>> _reservasMostradas = [];

  @override
  void initState() {
    super.initState();
    _cargarReservas();
  }

  // Método helper para navegación consistente
  void _navigateToReservationForm(BuildContext context, {
    required Widget formScreen,
    required String title,
    required Color color,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          body: formScreen,
        ),
      ),
    );
  }

  Future<String> _getNombre() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Usuario';
    try {
      final resp = await Supabase.instance.client
          .from('usuario')
          .select('nombre')
          .eq('id_usuario', user.id)
          .maybeSingle();

      if (resp is Map) {
        final map = Map<String, dynamic>.from(resp as Map);
        final n = (map['nombre'] as String?)?.trim() ?? '';
        return n.isEmpty ? 'Usuario' : n;
      }
    } catch (_) {}
    return 'Usuario';
  }

  Future<void> _cargarReservas() async {
    try {
      final data = await _reservaService.getMisReservasRaw();
      final now = DateTime.now().toUtc();

      // Filtrar canceladas y solo activas/futuras
      final filtradas = <Map<String, dynamic>>[];
      for (var r in data) {
        final inicio = DateTime.tryParse('${r['inicio']}')?.toUtc();
        final fin = DateTime.tryParse('${r['fin']}')?.toUtc();
        if (inicio == null || fin == null) continue;
        final estado = ('${r['estado'] ?? ''}').toLowerCase();
        if (estado == 'cancelada') continue;

        final esFutura = now.isBefore(inicio);
        final esActiva = now.isAfter(inicio) && now.isBefore(fin);

        if (esFutura || esActiva) {
          // Enriquecemos el registro con etiqueta/color
          final enriched = Map<String, dynamic>.from(r);
          enriched['_etiqueta'] = esActiva ? 'ACTIVA' : 'FUTURA';
          enriched['_color'] = esActiva ? Colors.green : Colors.orange;
          enriched['_inicio'] = inicio;
          enriched['_fin'] = fin;
          filtradas.add(enriched);
        }
      }

      // Orden: primero ACTIVAS por fin más cercano, luego FUTURAS por inicio más cercano
      filtradas.sort((a, b) {
        final ea = a['_etiqueta'] as String;
        final eb = b['_etiqueta'] as String;
        if (ea != eb) {
          // ACTIVA antes que FUTURA
          return ea == 'ACTIVA' ? -1 : 1;
        }
        if (ea == 'ACTIVA') {
          final fa = (a['_fin'] as DateTime);
          final fb = (b['_fin'] as DateTime);
          return fa.compareTo(fb);
        } else {
          final ia = (a['_inicio'] as DateTime);
          final ib = (b['_inicio'] as DateTime);
          return ia.compareTo(ib);
        }
      });

      if (mounted) {
        setState(() {
          _reservas = filtradas;
          _reservasMostradas = filtradas.take(3).toList(); // 👈 SOLO PRIMERAS 3
        });
      }
    } catch (e) {
      debugPrint('Error cargando reservas: $e');
    }
  }

  // 👇 FUNCIÓN MEJORADA - Iconos más precisos según el tipo de artículo
  (IconData, Color) _iconoYColorPorArticulo(Map<String, dynamic>? art) {
    final nombre = (art?['nombre'] ?? '').toString().toLowerCase();
    final tipo = (art?['tipo'] ?? art?['categoria'] ?? art?['tipo_articulo'] ?? '')
        .toString()
        .toLowerCase();

    // Primero verificar por nombre específico
    if (nombre.contains('ps') || 
        nombre.contains('xbox') || 
        nombre.contains('nintendo') ||
        nombre.contains('consola') ||
        tipo.contains('consola')) {
      return (Icons.sports_esports_rounded, AppColors.unimetOrange);
    }
    
    if (nombre.contains('cubículo') || 
        nombre.contains('cubiculo') || 
        nombre.contains('sala') ||
        nombre.contains('estudio') ||
        tipo.contains('cubículo') ||
        tipo.contains('sala')) {
      return (Icons.meeting_room_rounded, AppColors.unimetBlue);
    }
    
    if (nombre.contains('balón') || 
        nombre.contains('balon') || 
        nombre.contains('pelota') ||
        nombre.contains('raqueta') ||
        nombre.contains('equipo') ||
        tipo.contains('deportivo') ||
        tipo.contains('equipo')) {
      return (Icons.sports_soccer_rounded, Colors.green);
    }

    // Por defecto
    return (Icons.event_available_rounded, Colors.teal);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔵 Tarjeta superior MÁS COMPACTA
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.22,
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
          decoration: BoxDecoration(
            color: AppColors.unimetBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(45),
              bottomRight: Radius.circular(45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.unimetBlue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  FutureBuilder<String>(
                    future: _getNombre(),
                    builder: (context, snap) {
                      final nombre = snap.data ?? 'Usuario';
                      return Text(
                        'Hola, $nombre',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Bienvenido a RESERMET',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  const Text(
                    '¿Qué deseas reservar hoy?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 0,
                child: Row(
                  children: [
                    // Icono de perfil con borde sutil
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.8,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.account_circle_rounded,
                            color: Colors.white, size: 24),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const UserProfileScreen()),
                        ),
                      ),
                    ),
                    // Icono de logout con borde sutil
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.8,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded, 
                            color: Colors.white, size: 24),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cerrar sesión'),
                              content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Cerrar sesión'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await Supabase.instance.client.auth.signOut();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 🔽 Contenido
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accesos directos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleButton(
                      icon: Icons.meeting_room_rounded,
                      label: 'Cubículos',
                      color: AppColors.unimetBlue,
                      onTap: () => _navigateToReservationForm(
                        context,
                        formScreen: const ReservationFormCubiculo(),
                        title: 'Cubículos de Estudio',
                        color: AppColors.unimetBlue,
                      ),
                    ),
                    _buildCircleButton(
                      icon: Icons.sports_esports_rounded,
                      label: 'Consolas',
                      color: AppColors.unimetOrange,
                      onTap: () => _navigateToReservationForm(
                        context,
                        formScreen: const ReservationFormConsole(),
                        title: 'Consolas de Videojuegos',
                        color: AppColors.unimetOrange,
                      ),
                    ),
                    _buildCircleButton(
                      icon: Icons.sports_soccer_rounded,
                      label: 'Equipos',
                      color: Colors.blue.shade400,
                      onTap: () => _navigateToReservationForm(
                        context,
                        formScreen: const ReservationFormEquipment(),
                        title: 'Artículos Deportivos',
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 📋 Sección RESERVAS (LIMITADA A 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reservas Activas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${_reservas.length} reservas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_reservas.isEmpty)
                  Text(
                    'No tienes reservas activas ni futuras.',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  Column(
                    children: _reservasMostradas.map((r) {
                      final inicioLocal =
                          (r['_inicio'] as DateTime).toLocal();
                      final finLocal = (r['_fin'] as DateTime).toLocal();
                      String nombre = 'Artículo';
                      IconData icono = Icons.event;
                      Color colorIcono = Colors.grey;

                      if (r['articulo'] is Map) {
                        final art =
                            Map<String, dynamic>.from(r['articulo'] as Map);
                        nombre = (art['nombre'] ?? 'Artículo').toString();
                        final (iconoObtenido, colorObtenido) = _iconoYColorPorArticulo(art);
                        icono = iconoObtenido;
                        colorIcono = colorObtenido;
                      }

                      final etiqueta = r['_etiqueta'] as String;
                      final colorEstado = r['_color'] as Color;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: colorIcono.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icono, color: colorIcono, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_fechaCorta(inicioLocal)} ${_hhmm(inicioLocal)} - ${_hhmm(finLocal)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorEstado.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        etiqueta,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorEstado,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.more_vert_rounded, 
                                    color: Colors.grey.shade500),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // 👇 BOTÓN MÁS ARRIBA Y MENSAJE CONDICIONAL
                if (_reservas.length > 3) ...[
                  const SizedBox(height: 8), // 👈 MENOS ESPACIO
                  Center(
                    child: Text(
                      '+ ${_reservas.length - 3} reservas más...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8), // 👈 MENOS ESPACIO
                ],
                
                const SizedBox(height: 8), // 👈 ESPACIO REDUCIDO
                
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.unimetBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.unimetBlue.withOpacity(0.3),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        final mainState =
                            context.findAncestorStateOfType<_MainScreenState>();
                        if (mainState != null) mainState._onItemTapped(2);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver todas mis reservas',
                            style: TextStyle(
                              color: AppColors.unimetBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: AppColors.unimetBlue),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fechaCorta(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(.12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}