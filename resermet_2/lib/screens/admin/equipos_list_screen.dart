// lib/screens/admin/equipos_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/equipo_deportivo.dart';
import '../../services/equipo_deportivo_service.dart';
import 'add_edit_equipo_screen.dart';

class EquiposListScreen extends StatefulWidget {
  const EquiposListScreen({super.key});

  @override
  State<EquiposListScreen> createState() => _EquiposListScreenState();
}

class _EquiposListScreenState extends State<EquiposListScreen> {
  final EquipoDeportivoService _equipoService = EquipoDeportivoService();
  List<EquipoDeportivo> _equipos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEquipos();
  }

  Future<void> _loadEquipos() async {
    try {
      final equipos = await _equipoService.getEquiposDeportivos();
      setState(() {
        _equipos = equipos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Error al cargar equipos deportivos: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDeleteConfirmation(EquipoDeportivo equipo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Equipo Deportivo'),
          content: Text('¿Estás seguro de eliminar "${equipo.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEquipo(equipo);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEquipo(EquipoDeportivo equipo) async {
    try {
      await _equipoService.deleteEquipoDeportivo(equipo.idObjeto);
      _showSuccessSnackbar('Equipo deportivo eliminado exitosamente');
      _loadEquipos();
    } catch (e) {
      _showErrorSnackbar('Error al eliminar equipo deportivo: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToAddEquipo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEquipoScreen(
          onEquipoSaved: _loadEquipos,
        ),
      ),
    );
  }

  void _navigateToEditEquipo(EquipoDeportivo equipo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEquipoScreen(
          equipo: equipo,
          onEquipoSaved: _loadEquipos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipos Deportivos'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddEquipo,
            tooltip: 'Agregar Equipo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _equipos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay equipos deportivos registrados',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _equipos.length,
                  itemBuilder: (context, index) {
                    final equipo = _equipos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.sports_baseball, color: Colors.orange),
                        title: Text(
                          equipo.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tipo: ${equipo.tipoEquipo}'),
                            Text('Total: ${equipo.cantidadTotal} unidades'),
                            Text('Disponibles: ${equipo.cantidadDisponible} unidades'),
                            Text('Estado: ${equipo.estado}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _navigateToEditEquipo(equipo),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(equipo),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}