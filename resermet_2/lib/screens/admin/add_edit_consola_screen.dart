// lib/screens/admin/add_edit_consola_screen.dart
import 'package:flutter/material.dart';
import '../../models/consola.dart';
import '../../services/consola_service.dart';

class AddEditConsolaScreen extends StatefulWidget {
  final Consola? consola;
  final VoidCallback onConsolaSaved;

  const AddEditConsolaScreen({
    super.key,
    this.consola,
    required this.onConsolaSaved,
  });

  @override
  State<AddEditConsolaScreen> createState() => _AddEditConsolaScreenState();
}

class _AddEditConsolaScreenState extends State<AddEditConsolaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consolaService = ConsolaService();

  final _nombreController = TextEditingController();
  final _modeloController = TextEditingController();
  final _cantidadTotalController = TextEditingController();
  final _cantidadDisponibleController = TextEditingController();
  String _estado = 'disponible';
  final _idAreaController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.consola != null) {
      // Modo edición - llenar con datos existentes
      _nombreController.text = widget.consola!.nombre;
      _modeloController.text = widget.consola!.modelo;
      _cantidadTotalController.text = widget.consola!.cantidadTotal.toString();
      _cantidadDisponibleController.text = widget.consola!.cantidadDisponible.toString();
      _estado = widget.consola!.estado;
      _idAreaController.text = widget.consola!.idArea.toString();
    } else {
      // Modo creación - valores por defecto
      _idAreaController.text = '3'; // ID área para CDD
      _cantidadTotalController.text = '1';
      _cantidadDisponibleController.text = '1';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _modeloController.dispose();
    _cantidadTotalController.dispose();
    _cantidadDisponibleController.dispose();
    _idAreaController.dispose();
    super.dispose();
  }

  Future<void> _saveConsola() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final consola = Consola(
        idObjeto: widget.consola?.idObjeto ?? 0,
        nombre: _nombreController.text,
        modelo: _modeloController.text,
        cantidadTotal: int.parse(_cantidadTotalController.text),
        cantidadDisponible: int.parse(_cantidadDisponibleController.text),
        estado: _estado,
        idArea: int.parse(_idAreaController.text),
      );

      if (widget.consola == null) {
        // Crear nuevo
        await _consolaService.createConsola(consola);
      } else {
        // Actualizar existente
        await _consolaService.updateConsola(consola);
      }

      widget.onConsolaSaved();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.consola == null 
              ? 'Consola creada exitosamente' 
              : 'Consola actualizada exitosamente'),
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
        title: Text(widget.consola == null 
            ? 'Agregar Consola' 
            : 'Editar Consola'),
        backgroundColor: Colors.green,
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
                        labelText: 'Nombre de la Consola',
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
                      controller: _modeloController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el modelo';
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
                      onPressed: _saveConsola,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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
                          : Text(widget.consola == null 
                              ? 'Crear Consola' 
                              : 'Actualizar Consola'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}