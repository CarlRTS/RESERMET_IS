// lib/screens/admin/add_edit_cubiculo_screen.dart
import 'package:flutter/material.dart';
import '../../models/cubiculo.dart';
import '../../services/cubiculo_service.dart';

class AddEditCubiculoScreen extends StatefulWidget {
  final Cubiculo? cubiculo;
  final VoidCallback onCubiculoSaved;

  const AddEditCubiculoScreen({
    super.key,
    this.cubiculo,
    required this.onCubiculoSaved,
  });

  @override
  State<AddEditCubiculoScreen> createState() => _AddEditCubiculoScreenState();
}

class _AddEditCubiculoScreenState extends State<AddEditCubiculoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cubiculoService = CubiculoService();

  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _capacidadController = TextEditingController();
  String _estado = 'disponible';
  final _idAreaController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cubiculo != null) {
      // Modo edición - llenar con datos existentes
      _nombreController.text = widget.cubiculo!.nombre;
      _ubicacionController.text = widget.cubiculo!.ubicacion;
      _capacidadController.text = widget.cubiculo!.capacidad.toString();
      _estado = widget.cubiculo!.estado;
      _idAreaController.text = widget.cubiculo!.idArea;
    } else {
      // Modo creación - valores por defecto
      _idAreaController.text = '1'; // ID área por defecto
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _capacidadController.dispose();
    _idAreaController.dispose();
    super.dispose();
  }

  Future<void> _saveCubiculo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cubiculo = Cubiculo(
        idObjeto: widget.cubiculo?.idObjeto ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreController.text,
        ubicacion: _ubicacionController.text,
        capacidad: int.parse(_capacidadController.text),
        estado: _estado,
        idArea: _idAreaController.text,
      );

      if (widget.cubiculo == null) {
        // Crear nuevo
        await _cubiculoService.createCubiculo(cubiculo);
      } else {
        // Actualizar existente
        await _cubiculoService.updateCubiculo(cubiculo);
      }

      widget.onCubiculoSaved();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.cubiculo == null 
              ? 'Cubículo creado exitosamente' 
              : 'Cubículo actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cubiculo == null 
            ? 'Agregar Cubículo' 
            : 'Editar Cubículo'),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Cubículo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ubicacionController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la ubicación';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacidadController,
                      decoration: const InputDecoration(
                        labelText: 'Capacidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la capacidad';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor ingresa un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _estado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'disponible',
                          child: Text('Disponible'),
                        ),
                        DropdownMenuItem(
                          value: 'prestado',
                          child: Text('Prestado'),
                        ),
                        DropdownMenuItem(
                          value: 'en mantenimiento',
                          child: Text('En Mantenimiento'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _estado = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idAreaController,
                      decoration: const InputDecoration(
                        labelText: 'ID Área',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el ID del área';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveCubiculo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0033A0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.cubiculo == null 
                              ? 'Crear Cubículo' 
                              : 'Actualizar Cubículo'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}