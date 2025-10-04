// lib/screens/admin/consolas_list_screen.dart
import 'package:flutter/material.dart';
import '../../../models/consola.dart';
import '../../../services/consola_service.dart';
import './add_edit_consola_screen.dart';

class ConsolasListScreen extends StatefulWidget {
  const ConsolasListScreen({super.key});

  @override
  State<ConsolasListScreen> createState() => _ConsolasListScreenState();
}

class _ConsolasListScreenState extends State<ConsolasListScreen> {
  final ConsolaService _consolaService = ConsolaService();
  List<Consola> _consolas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsolas();
  }

  Future<void> _loadConsolas() async {
    try {
      final consolas = await _consolaService.getConsolas();
      setState(() {
        _consolas = consolas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Error al cargar consolas: $e');
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

  void _showDeleteConfirmation(Consola consola) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Consola'),
          content: Text('¿Estás seguro de eliminar "${consola.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteConsola(consola);
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

  Future<void> _deleteConsola(Consola consola) async {
    try {
      await _consolaService.deleteConsola(consola.idObjeto);
      _showSuccessSnackbar('Consola eliminada exitosamente');
      _loadConsolas();
    } catch (e) {
      _showErrorSnackbar('Error al eliminar consola: $e');
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

  void _navigateToAddConsola() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditConsolaScreen(
          onConsolaSaved: _loadConsolas,
        ),
      ),
    );
  }

  void _navigateToEditConsola(Consola consola) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditConsolaScreen(
          consola: consola,
          onConsolaSaved: _loadConsolas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Consolas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddConsola,
            tooltip: 'Agregar Consola',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consolas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay consolas registradas',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _consolas.length,
                  itemBuilder: (context, index) {
                    final consola = _consolas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.gamepad, color: Colors.green),
                        title: Text(
                          consola.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modelo: ${consola.modelo}'),
                            Text('Total: ${consola.cantidadTotal} unidades'),
                            Text('Disponibles: ${consola.cantidadDisponible} unidades'),
                            Text('Estado: ${consola.estado}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _navigateToEditConsola(consola),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(consola),
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