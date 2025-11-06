// lib/screens/admin/reporte_reservas_screen.dart
import 'package:flutter/material.dart';
import 'package:resermet_2/services/reserva_service.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart'; // Para el Gráfico de Pastel

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
  int _filtroAreaSeleccionada = 0; // 0 = Todos

  // Fechas seleccionadas (inicio = Domingo, fin = Sábado)
  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  // Para el gráfico de pastel
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fechaInicio = DateTime(now.year, now.month, now.day - (now.weekday % 7));
    _fechaFin = _fechaInicio.add(const Duration(days: 6));
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
        filtroArea: _filtroAreaSeleccionada, // Pasa el filtro
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

  // Selector de semana con el calendario pop-up
  Future<void> _seleccionarSemana() async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'SELECCIONA CUALQUIER DÍA DE LA SEMANA',
    );

    if (newDate != null) {
      final inicioSemana = DateTime(
          newDate.year, newDate.month, newDate.day - (newDate.weekday % 7));
      final finSemana = inicioSemana.add(const Duration(days: 6));

      setState(() {
        _fechaInicio = inicioSemana;
        _fechaFin = finSemana;
      });
      _fetchReporte();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Semanal de Reservas'),
        backgroundColor: UnimetPalette.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReporte,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterRow(), // Widget que contiene ambos filtros
            const SizedBox(height: 16),

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

  // Widget selector de fecha Y filtro de área
  Widget _buildFilterRow() {
    final textTheme = Theme.of(context).textTheme;
    final formatoFecha =
        '${_getNombreMesAbrev(_fechaInicio.month)} ${_fechaInicio.day} - ${_getNombreMesAbrev(_fechaFin.month)} ${_fechaFin.day}, ${_fechaFin.year}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Fila 1: Selector de Semana
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semana Seleccionada',
                        style: textTheme.labelMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      Text(
                        formatoFecha,
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
                  onPressed: _seleccionarSemana,
                  style: FilledButton.styleFrom(
                    backgroundColor: UnimetPalette.secondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Fila 2: Filtro de Área
            DropdownButtonFormField<int>(
              value: _filtroAreaSeleccionada,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Todos los Artículos')),
                DropdownMenuItem(value: 1, child: Text('Cubículos')),
                DropdownMenuItem(value: 3, child: Text('Consolas')),
                DropdownMenuItem(value: 2, child: Text('Equipos Deportivos')),
              ],
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _filtroAreaSeleccionada = newValue;
                  });
                  _fetchReporte(); // Vuelve a cargar el reporte con el nuevo filtro
                }
              },
              decoration: const InputDecoration(
                labelText: 'Filtrar por tipo de artículo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }


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
              'No hay datos para esta semana o filtro.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- SECCIÓN DE CONTENIDO (CON GRÁFICOS) ---
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

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,

          // --- ¡CORREGIDO! ---
          // Se cambió (1 / .6) por (1 / .8) para dar más altura
          // a las tarjetas y evitar el 'bottom overflow'.
          childAspectRatio: (1 / .8),

          children: [
            _buildKpiCard(
              label: 'Total Reservas',
              value: _stats.totalReservas.toString(),
              icon: Icons.bookmark_add_rounded,
              color: UnimetPalette.primary,
            ),
            _buildKpiCard(
              label: 'Total de Horas',
              value: _stats.totalHoras.toStringAsFixed(1),
              icon: Icons.timer_rounded,
              color: Colors.teal.shade700,
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

        // 2. Sección de Análisis
        Text(
          'Análisis de Reservas',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: UnimetPalette.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // --- (Selector de gráfico eliminado) ---

        // Si el filtro es "Todos", muestra el gráfico de pastel.
        if (_filtroAreaSeleccionada == 0) ...[
          _buildPieChartCard(),
          const SizedBox(height: 16),
        ],

        // Mostrar siempre el mapa de calor de horas pico
        _buildHoraCard(),
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
      color: color.withOpacity(0.05),
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
            const Spacer(),
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

  // --- Gráfico de Pastel ---
  Widget _buildPieChartCard() {
    const pieColors = {
      'cubiculos': Colors.blue,
      'consolas': Colors.purple,
      'equipos': Colors.orange,
    };

    final pieSections = [
      PieChartSectionData(
        value: _stats.graficoTipo.cubiculos.toDouble(),
        title: '${_stats.graficoTipo.cubiculos}',
        color: pieColors['cubiculos'],
        radius: _touchedIndex == 0 ? 60.0 : 50.0,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: _stats.graficoTipo.consolas.toDouble(),
        title: '${_stats.graficoTipo.consolas}',
        color: pieColors['consolas'],
        radius: _touchedIndex == 1 ? 60.0 : 50.0,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: _stats.graficoTipo.equipos.toDouble(),
        title: '${_stats.graficoTipo.equipos}',
        color: pieColors['equipos'],
        radius: _touchedIndex == 2 ? 60.0 : 50.0,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desglose por Tipo (Total)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UnimetPalette.primary
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
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
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendIndicator(
                        color: pieColors['cubiculos']!,
                        text: 'Cubículos',
                        value: _stats.graficoTipo.cubiculos.toString(),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendIndicator(
                        color: pieColors['consolas']!,
                        text: 'Consolas',
                        value: _stats.graficoTipo.consolas.toString(),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendIndicator(
                        color: pieColors['equipos']!,
                        text: 'Equipos',
                        value: _stats.graficoTipo.equipos.toString(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ¡NUEVO MAPA DE CALOR (Heat Map) PARA HORARIOS PICO! ---
  Widget _buildHoraCard() {
    // 1. Encontrar el valor máximo para la escala de color
    double maxTotal = 1; // Evitar división por cero
    if (_stats.graficoHora.isNotEmpty) {
      maxTotal = _stats.graficoHora
          .map((h) => h.total)
          .reduce((a, b) => a > b ? a : b)
          .toDouble();
    }
    if (maxTotal == 0) maxTotal = 1; // Evitar división por cero si todo es 0

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horarios Más Populares',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UnimetPalette.primary
              ),
            ),
            const Divider(height: 20),

            // El "Heat Map"
            Wrap(
              spacing: 8.0, // Espacio horizontal
              runSpacing: 8.0, // Espacio vertical
              children: _stats.graficoHora.map((dataHora) {

                // 2. Calcular la intensidad del color (de 0.0 a 1.0)
                final double opacidad = (dataHora.total / maxTotal).clamp(0.0, 1.0);

                // 3. Definir el color. 0 = gris, >0 = azul
                final Color colorFondo = dataHora.total == 0
                    ? Colors.grey.shade200
                // Usamos opacidad. clamp(0.15, 1.0) para que nunca sea invisible
                    : UnimetPalette.primary.withOpacity(opacidad.clamp(0.15, 1.0));

                // 4. Definir color del texto (blanco sobre oscuro, negro sobre claro)
                final Color colorTexto = (dataHora.total == 0)
                    ? Colors.black54
                    : (opacidad > 0.6 ? Colors.white : Colors.black87);


                return Container(
                  width: 75, // Ancho fijo para cada "caja"
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorFondo,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${dataHora.hora}:00', // "7:00"
                        style: TextStyle(
                          color: colorTexto,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${dataHora.total} res.', // "5 res."
                        style: TextStyle(
                          color: colorTexto.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLegendIndicator({
    required Color color,
    required String text,
    String? value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(2),
            color: color,
          ),
        ),
        const SizedBox(width: 10),

        // --- ¡CORREGIDO! ---
        // Se envuelve el texto en Flexible para que se trunque
        // con '...' si es muy largo, evitando el 'right overflow'.
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),

        if (value != null) ...[
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ]
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
