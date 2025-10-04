// lib/screens/admin/add_edit_equipo_screen.dart
import 'package:flutter/material.dart';
import '../../models/equipo_deportivo.dart';
import '../../services/equipo_deportivo_service.dart';

class AddEditEquipoScreen extends StatefulWidget {
  final EquipoDeportivo? equipo;
  final VoidCallback onEquipoSaved;

  const AddEditEquipoScreen({
    super.key,
    this.equipo,
    required this.onEquipoSaved,
  });

  @override
  State<AddEditEquipoScreen> createState() => _AddEditEquipoScreenState();
}

class _AddEditEquipoScreenState extends State<AddEditEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipoService = EquipoDeportivoService();

  final _nombreController = TextEditingController();
  final _tipoEquipoController = TextEditingController();
  final _cantidadTotalController = TextEditingController();
  final _cantidadDisponibleController = TextEditingController();
  String _estado = 'disponible';
  final _idAreaController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.equipo != null) {
      // Modo edición - llenar con datos existentes
      _nombreController.text = widget.equipo!.nombre;
      _tipoEquipoController.text = widget.equipo!.tipoEquipo;
      _cantidadTotalController.text = widget.equipo!.cantidadTotal.toString();
      _cantidadDisponibleController.text = widget.equipo!.cantidadDisponible.toString();
      _estado = widget.equipo!.estado;
      _idAreaController.text = widget.equipo!.idArea.toString();
    } else {
      // Modo creación - valores por defecto
      _idAreaController.text = '2'; // ID área para gimnasio
      _cantidadTotalController.text = '1';
      _cantidadDisponibleController.text = '1';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoEquipoController.dispose();
    _cantidadTotalController.dispose();
    _cantidadDisponibleController.dispose();
    _idAreaController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final equipo = EquipoDeportivo(
        idObjeto: widget.equipo?.idObjeto ?? 0,
        nombre: _nombreController.text,
        tipoEquipo: _tipoEquipoController.text,
        cantidadTotal: int.parse(_cantidadTotalController.text),
        cantidadDisponible: int.parse(_cantidadDisponibleController.text),
        estado: _estado,
        idArea: int.parse(_idAreaController.text),
      );

      if (widget.equipo == null) {
        // Crear nuevo
        await _equipoService.createEquipoDeportivo(equipo);
      } else {
        // Actualizar existente
        await _equipoService.updateEquipoDeportivo(equipo);
      }

      widget.onEquipoSaved();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.equipo == null 
              ? 'Equipo deportivo creado exitosamente' 
              : 'Equipo deportivo actualizado exitosamente'),
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
        title: Text(widget.equipo == null 
            ? 'Agregar Equipo Deportivo' 
            : 'Editar Equipo Deportivo'),
        backgroundColor: Colors.orange,
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
                        labelText: 'Nombre del Equipo',
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
                      controller: _tipoEquipoController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Equipo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el tipo de equipo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cantidadTotalController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Total',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la cantidad total';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor ingresa un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cantidadDisponibleController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Disponible',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la cantidad disponible';
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
                          value: 'en_mantenimiento',
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
                        if (int.tryParse(value) == null) {
                          return 'Por favor ingresa un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveEquipo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
                          : Text(widget.equipo == null 
                              ? 'Crear Equipo' 
                              : 'Actualizar Equipo'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}