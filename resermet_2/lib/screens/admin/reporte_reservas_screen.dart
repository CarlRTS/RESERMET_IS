// lib/screens/admin/reporte_reservas_screen.dart
import 'package:flutter/material.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart'; // Para los gráficos

class ReporteReservasScreen extends StatefulWidget {
  const ReporteReservasScreen({super.key});

  @override
  State<ReporteReservasScreen> createState() => _ReporteReservasScreenState();
}

class _ReporteReservasScreenState extends State<ReporteReservasScreen> {
  final _reservaService = ReservaService();

  // Estado de la UI
  bool _isLoading = false;
  String? _error;
  ReporteStats _stats = ReporteStats.empty();

  // Fechas seleccionadas (inicio = Domingo, fin = Sábado)
  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  // Para el gráfico de pastel
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    // Por defecto, mostrar la semana actual
    final now = DateTime.now();
    // Calculamos el inicio de la semana (Domingo)
    _fechaInicio =
        DateTime(now.year, now.month, now.day - (now.weekday % 7));
    // Calculamos el fin de la semana (Sábado)
    _fechaFin = _fechaInicio.add(const Duration(days: 6));

    // Cargar los datos iniciales
    _fetchReporte();
  }

  Future<void> _fetchReporte() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _reservaService.getEstadisticasReservas(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- UI ---

  // Selector de semana: el usuario elije CUALQUIER día, y calculamos su semana
  Future<void> _seleccionarSemana() async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2023), // Año de inicio de tu app
      lastDate: DateTime(now.year + 1),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'SELECCIONA CUALQUIER DÍA DE LA SEMANA',
    );

    if (newDate != null) {
      // Día seleccionado (ej. Martes 28)
      // Calculamos el inicio de esa semana (Domingo 26)
      final inicioSemana = DateTime(
          newDate.year, newDate.month, newDate.day - (newDate.weekday % 7));
      // Calculamos el fin de esa semana (Sábado 1)
      final finSemana = inicioSemana.add(const Duration(days: 6));

      setState(() {
        _fechaInicio = inicioSemana;
        _fechaFin = finSemana;
      });
      // Volver a cargar los datos
      _fetchReporte();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Semanal de Reservas'),
        backgroundColor: UnimetPalette.primary, // Usando tu paleta
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReporte,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Selector de Fecha (Restaurado)
            _buildDatePicker(),
            const SizedBox(height: 16),

            // 2. Contenido (Loading, Error o Datos)
            if (_isLoading)
              const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ))
            else if (_error != null)
              _buildErrorState()
            else if (_stats.totalReservas == 0)
                _buildEmptyState()
              else
                _buildStatsContent(),
          ],
        ),
      ),
    );
  }

  // --- (WIDGET RESTAURADO A LA VERSIÓN CON BOTÓN) ---
  Widget _buildDatePicker() {
    final textTheme = Theme.of(context).textTheme;

    // Formato de fecha para la semana
    final formatoFecha =
        '${_getNombreMesAbrev(_fechaInicio.month)} ${_fechaInicio.day} - ${_getNombreMesAbrev(_fechaFin.month)} ${_fechaFin.day}, ${_fechaFin.year}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded( // Para que el texto no se desborde
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semana Seleccionada',
                    style: textTheme.labelMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  Text(
                    formatoFecha, // Muestra el rango semanal
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text('Cambiar'),
              onPressed: _seleccionarSemana, // Abre el DatePicker
              style: FilledButton.styleFrom(
                backgroundColor: UnimetPalette.secondary, // Usando tu paleta
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- (FIN DEL WIDGET RESTAURADO) ---

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text('Error al cargar el reporte:'),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _fetchReporte,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 60),
            const SizedBox(height: 16),
            Text(
              'No se encontraron reservas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            Text(
              'No hay datos para la semana seleccionada.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- SECCIÓN DE CONTENIDO ---
  Widget _buildStatsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Resumen de Estados (KPI Grid)
        Text(
          'Resumen Semanal',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: UnimetPalette.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Rejilla de KPIs
        GridView.count(
          crossAxisCount: 3, // 3 columnas
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildKpiCard(
              label: 'Total',
              value: _stats.totalReservas.toString(),
              icon: Icons.bookmark_add_rounded,
              color: UnimetPalette.primary,
            ),
            _buildKpiCard(
              label: 'Finalizadas',
              value: _stats.finalizadas.toString(),
              icon: Icons.check_circle_rounded,
              color: Colors.green.shade700,
            ),
            _buildKpiCard(
              label: 'Canceladas',
              value: _stats.canceladas.toString(),
              icon: Icons.cancel_rounded,
              color: Colors.red.shade700,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 2. Desglose por Artículo (Gráfico de Pastel)
        Text(
          'Desglose por Artículo',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: UnimetPalette.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPieChartCard(),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      color: color.withOpacity(0.05), // Fondo sutil
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    // Colores para el gráfico
    const pieColors = {
      'cubiculos': Colors.blue,
      'consolas': Colors.purple,
      'equipos': Colors.orange,
    };

    // Lista de secciones del gráfico
    final pieSections = [
      PieChartSectionData(
        value: _stats.cubiculos.toDouble(),
        title: '${_stats.cubiculos}',
        color: pieColors['cubiculos'],
        radius: _touchedIndex == 0 ? 60.0 : 50.0,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: _stats.consolas.toDouble(),
        title: '${_stats.consolas}',
        color: pieColors['consolas'],
        radius: _touchedIndex == 1 ? 60.0 : 50.0,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: _stats.equipos.toDouble(),
        title: '${_stats.equipos}',
        color: pieColors['equipos'],
        radius: _touchedIndex == 2 ? 60.0 : 50.0,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // El Gráfico
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: pieSections,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // La Leyenda
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendIndicator(
                    color: pieColors['cubiculos']!,
                    text: 'Cubículos',
                  ),
                  const SizedBox(height: 8),
                  _buildLegendIndicator(
                    color: pieColors['consolas']!,
                    text: 'Consolas',
                  ),
                  const SizedBox(height: 8),
                  _buildLegendIndicator(
                    color: pieColors['equipos']!,
                    text: 'Equipos',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  // --- Helpers de Fecha ---
  String _getNombreMesAbrev(int month) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return meses[month - 1];
  }

  String _getNombreMes(int month) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[month - 1];
  }
}