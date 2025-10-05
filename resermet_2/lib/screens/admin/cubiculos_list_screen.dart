import 'package:flutter/material.dart';
import '../../models/cubiculo.dart';
import '../../services/cubiculo_service.dart';
import 'add_edit_cubiculo_screen.dart';

class CubiculosListScreen extends StatefulWidget {
  const CubiculosListScreen({super.key});

  @override
  State<CubiculosListScreen> createState() => _CubiculosListScreenState();
}

class _CubiculosListScreenState extends State<CubiculosListScreen> {
  final CubiculoService _cubiculoService = CubiculoService();
  List<Cubiculo> _cubiculos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCubiculos();
  }

  Future<void> _loadCubiculos() async {
    try {
      final cubiculos = await _cubiculoService.getCubiculos();
      setState(() {
        _cubiculos = cubiculos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Error al cargar cubículos: $e');
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

  void _showDeleteConfirmation(Cubiculo cubiculo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Cubículo'),
          content: Text('¿Estás seguro de eliminar "${cubiculo.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCubiculo(cubiculo);
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

  Future<void> _deleteCubiculo(Cubiculo cubiculo) async {
    try {
      await _cubiculoService.deleteCubiculo(cubiculo.idObjeto);
      _showSuccessSnackbar('Cubículo eliminado exitosamente');
      _loadCubiculos();
    } catch (e) {
      _showErrorSnackbar('Error al eliminar cubículo: $e');
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

  void _navigateToAddCubiculo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCubiculoScreen(
          onItemSaved: _loadCubiculos,
        ),
      ),
    );
  }

  void _navigateToEditCubiculo(Cubiculo cubiculo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCubiculoScreen(
          item: cubiculo,
          onItemSaved: _loadCubiculos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cubículos'),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddCubiculo,
            tooltip: 'Agregar Cubículo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cubiculos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay cubículos registrados',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _cubiculos.length,
                  itemBuilder: (context, index) {
                    final cubiculo = _cubiculos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.meeting_room, color: Color(0xFF0033A0)),
                        title: Text(
                          cubiculo.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ubicación: ${cubiculo.ubicacion}'),
                            Text('Capacidad: ${cubiculo.capacidad} personas'),
                            Text('Estado: ${cubiculo.estado}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _navigateToEditCubiculo(cubiculo),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(cubiculo),
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