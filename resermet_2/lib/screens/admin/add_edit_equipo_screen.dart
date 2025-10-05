import 'package:flutter/material.dart';
import '../../models/equipo_deportivo.dart';
import '../../services/equipo_deportivo_service.dart';
import 'base_form_screen.dart';

class AddEditEquipoScreen extends BaseFormScreen<EquipoDeportivo> {
  const AddEditEquipoScreen({
    super.key,
    super.item,
    required super.onItemSaved,
  }) : super(
          screenTitle: item == null ? 'Agregar Equipo Deportivo' : 'Editar Equipo Deportivo',
          appBarColor: Colors.orange,
        );

  @override
  State<AddEditEquipoScreen> createState() => _AddEditEquipoScreenState();
}

class _AddEditEquipoScreenState extends BaseFormScreenState<EquipoDeportivo, AddEditEquipoScreen> {
  final EquipoDeportivoService _equipoService = EquipoDeportivoService();
  final _nombreController = TextEditingController();
  final _tipoEquipoController = TextEditingController();
  final _cantidadTotalController = TextEditingController();
  final _cantidadDisponibleController = TextEditingController();
  String _estado = 'disponible';
  final _idAreaController = TextEditingController();

  @override
  void initState() {
    _idAreaController.text = '2';
    _cantidadTotalController.text = '1';
    _cantidadDisponibleController.text = '1';
    super.initState();
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

  @override
  EquipoDeportivo createItem() {
    return EquipoDeportivo(
      idObjeto: widget.item?.idObjeto ?? 0,
      nombre: _nombreController.text,
      tipoEquipo: _tipoEquipoController.text,
      cantidadTotal: int.parse(_cantidadTotalController.text),
      cantidadDisponible: int.parse(_cantidadDisponibleController.text),
      estado: _estado,
      idArea: int.parse(_idAreaController.text),
    );
  }

  @override
  Future<void> saveItem(EquipoDeportivo equipo) async {
    if (widget.item == null) {
      await _equipoService.createEquipoDeportivo(equipo);
    } else {
      await _equipoService.updateEquipoDeportivo(equipo);
    }
  }

  @override
  void populateFormFields(EquipoDeportivo equipo) {
    _nombreController.text = equipo.nombre;
    _tipoEquipoController.text = equipo.tipoEquipo;
    _cantidadTotalController.text = equipo.cantidadTotal.toString();
    _cantidadDisponibleController.text = equipo.cantidadDisponible.toString();
    _estado = equipo.estado;
    _idAreaController.text = equipo.idArea.toString();
  }

  @override
  List<Widget> buildFormFields() {
    return [
      TextFormField(
        controller: _nombreController,
        decoration: const InputDecoration(labelText: 'Nombre del Equipo', border: OutlineInputBorder()),
        validator: (value) => requiredValidator(value, 'el nombre'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _tipoEquipoController,
        decoration: const InputDecoration(labelText: 'Tipo de Equipo', border: OutlineInputBorder()),
        validator: (value) => requiredValidator(value, 'el tipo de equipo'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _cantidadTotalController,
        decoration: const InputDecoration(labelText: 'Cantidad Total', border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (value) => numberValidator(value, 'la cantidad total'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _cantidadDisponibleController,
        decoration: const InputDecoration(labelText: 'Cantidad Disponible', border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (value) => numberValidator(value, 'la cantidad disponible'),
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