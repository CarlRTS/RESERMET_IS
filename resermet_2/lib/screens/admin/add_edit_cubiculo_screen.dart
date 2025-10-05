import 'package:flutter/material.dart';
import '../../models/cubiculo.dart';
import '../../services/cubiculo_service.dart';
import 'base_form_screen.dart';

class AddEditCubiculoScreen extends BaseFormScreen<Cubiculo> {
  const AddEditCubiculoScreen({
    super.key,
    super.item,
    required super.onItemSaved,
  }) : super(
          screenTitle: item == null ? 'Agregar Cubículo' : 'Editar Cubículo',
          appBarColor: const Color(0xFF0033A0),
        );

  @override
  State<AddEditCubiculoScreen> createState() => _AddEditCubiculoScreenState();
}

class _AddEditCubiculoScreenState extends BaseFormScreenState<Cubiculo, AddEditCubiculoScreen> {
  final CubiculoService _cubiculoService = CubiculoService();
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _capacidadController = TextEditingController();
  String _estado = 'disponible';
  final _idAreaController = TextEditingController();

  @override
  void initState() {
    _idAreaController.text = '1';
    super.initState();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _capacidadController.dispose();
    _idAreaController.dispose();
    super.dispose();
  }

  @override
  Cubiculo createItem() {
    return Cubiculo(
      idObjeto: widget.item?.idObjeto ?? 0,
      nombre: _nombreController.text,
      ubicacion: _ubicacionController.text,
      capacidad: int.parse(_capacidadController.text),
      estado: _estado,
      idArea: int.parse(_idAreaController.text),
    );
  }

  @override
  Future<void> saveItem(Cubiculo cubiculo) async {
    if (widget.item == null) {
      await _cubiculoService.createCubiculo(cubiculo);
    } else {
      await _cubiculoService.updateCubiculo(cubiculo);
    }
  }

  @override
  void populateFormFields(Cubiculo cubiculo) {
    _nombreController.text = cubiculo.nombre;
    _ubicacionController.text = cubiculo.ubicacion;
    _capacidadController.text = cubiculo.capacidad.toString();
    _estado = cubiculo.estado;
    _idAreaController.text = cubiculo.idArea.toString();
  }

  @override
  List<Widget> buildFormFields() {
    return [
      TextFormField(
        controller: _nombreController,
        decoration: const InputDecoration(labelText: 'Nombre del Cubículo', border: OutlineInputBorder()),
        validator: (value) => requiredValidator(value, 'el nombre'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _ubicacionController,
        decoration: const InputDecoration(labelText: 'Ubicación', border: OutlineInputBorder()),
        validator: (value) => requiredValidator(value, 'la ubicación'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _capacidadController,
        decoration: const InputDecoration(labelText: 'Capacidad', border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (value) => numberValidator(value, 'la capacidad'),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _estado,
        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
          DropdownMenuItem(value: 'prestado', child: Text('Prestado')),
          DropdownMenuItem(value: 'en_mantenimiento', child: Text('En Mantenimiento')),
        ],
        onChanged: (value) => setState(() => _estado = value!),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _idAreaController,
        decoration: const InputDecoration(labelText: 'ID Área', border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (value) => numberValidator(value, 'el ID del área'),
      ),
    ];
  }
}