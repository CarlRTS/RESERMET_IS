import 'package:flutter/material.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'cubiculos_list_screen.dart';
import 'consolas_list_screen.dart';
import 'equipos_list_screen.dart';
import 'reservas_activas_screen.dart';
import 'users_list_screen.dart';
import 'reporte_reservas_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // ===== HEADER =====
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.unimetBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel de Administración',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'RESERMET · Gestión de recursos',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ===== SECCIÓN: MONITOREO =====
                _sectionLabel('Monitoreo'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTile(
                        context,
                        icon: Icons.bar_chart_rounded,
                        title: 'Reportes',
                        subtitle: 'Estadísticas de uso',
                        color: AppColors.unimetBlue,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ReporteReservasScreen())),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildTile(
                        context,
                        icon: Icons.schedule_rounded,
                        title: 'Reservas',
                        subtitle: 'Activas ahora',
                        color: AppColors.unimetOrange,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ReservasActivasScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildWideRow(
                  context,
                  icon: Icons.people_alt_rounded,
                  title: 'Usuarios',
                  subtitle: 'Buscar y gestionar perfiles de estudiantes',
                  color: AppColors.unimetBlue,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UsersListScreen())),
                ),

                const SizedBox(height: 32),

                // ===== SECCIÓN: INVENTARIO =====
                _sectionLabel('Inventario'),
                const SizedBox(height: 12),
                _buildWideRow(
                  context,
                  icon: Icons.meeting_room_rounded,
                  title: 'Cubículos de Estudio',
                  subtitle: 'Gestionar espacios individuales y grupales',
                  color: AppColors.unimetOrange,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CubiculosListScreen())),
                ),
                const SizedBox(height: 14),
                _buildWideRow(
                  context,
                  icon: Icons.sports_esports_rounded,
                  title: 'Consolas y Juegos',
                  subtitle: 'Gestionar equipos de la Game Room',
                  color: AppColors.unimetBlue,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ConsolasListScreen())),
                ),
                const SizedBox(height: 14),
                _buildWideRow(
                  context,
                  icon: Icons.sports_rounded,
                  title: 'Equipos Deportivos',
                  subtitle: 'Gestionar implementos y material deportivo',
                  color: AppColors.unimetOrange,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EquiposListScreen())),
                ),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.unimetBlue,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}