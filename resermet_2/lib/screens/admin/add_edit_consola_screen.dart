// 📍 REEMPLAZAR ARCHIVO: lib/screens/admin/add_edit_consola_screen.dart
import 'package:flutter/material.dart';
import '../../models/consola.dart';
import '../../services/consola_service.dart';
import 'base_form_screen.dart';

class AddEditConsolaScreen extends BaseFormScreen<Consola> {
  const AddEditConsolaScreen({
    super.key,
    super.item,
    required super.onItemSaved,
  }) : super(
    screenTitle: item == null ? 'Agregar Consola' : 'Editar Consola',
    appBarColor: Colors.green,
  );

  @override
  State<AddEditConsolaScreen> createState() => _AddEditConsolaScreenState();
}

class _AddEditConsolaScreenState extends BaseFormScreenState<Consola, AddEditConsolaScreen> {
  final ConsolaService _consolaService = ConsolaService();
  final _nombreController = TextEditingController();
  final _modeloController = TextEditingController();
  final _cantidadTotalController = TextEditingController();
  final _cantidadDisponibleController = TextEditingController();
  String _estado = 'disponible';
  final _idAreaController = TextEditingController();

  // 1. AÑADIR CONTROLADOR PARA LOS JUEGOS
  final _juegosController = TextEditingController();

  @override
  void initState() {
    _idAreaController.text = '3';
    _cantidadTotalController.text = '1';
    _cantidadDisponibleController.text = '1';
    super.initState();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _modeloController.dispose();
    _cantidadTotalController.dispose();
    _cantidadDisponibleController.dispose();
    _idAreaController.dispose();
    _juegosController.dispose(); // 2. AÑADIR DISPOSE
    super.dispose();
  }

  @override
  Consola createItem() {
    // 3. CONVERTIR EL TEXTO (ej. "Juego1, Juego2") EN UNA LISTA
    final List<String> juegosList = _juegosController.text
        .split(',') // Separa por comas
        .map((juego) => juego.trim()) // Limpia espacios
        .where((juego) => juego.isNotEmpty) // Elimina vacíos
        .toList();

    return Consola(
      idObjeto: widget.item?.idObjeto ?? 0,
      nombre: _nombreController.text,
      modelo: _modeloController.text,
      cantidadTotal: int.parse(_cantidadTotalController.text),
      cantidadDisponible: int.parse(_cantidadDisponibleController.text),
      estado: _estado,
      idArea: int.parse(_idAreaController.text),
      juegosCompatibles: juegosList, // 4. AÑADIR LA LISTA AL OBJETO
    );
  }

  @override
  Future<void> saveItem(Consola consola) async {
    // (El servicio ya usa toEspecificoJson del modelo, así que esto funciona)
    if (widget.item == null) {
      await _consolaService.createConsola(consola);
    } else {
      await _consolaService.updateConsola(consola);
    }
  }

  @override
  void populateFormFields(Consola consola) {
    _nombreController.text = consola.nombre;
    _modeloController.text = consola.modelo;
    _cantidadTotalController.text = consola.cantidadTotal.toString();
    _cantidadDisponibleController.text = consola.cantidadDisponible.toString();
    _estado = consola.estado;
    _idAreaController.text = consola.idArea.toString();

    // 5. POBLAR EL CAMPO CON LA LISTA (uniéndola con comas)
    _juegosController.text = consola.juegosCompatibles.join(', ');
  }

  @override
  List<Widget> buildFormFields() {
    return [
      TextFormField(
        controller: _nombreController,
        decoration: const InputDecoration(labelText: 'Nombre de la Consola', border: OutlineInputBorder()),
        validator: (value) => requiredValidator(value, 'el nombre'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _modeloController,
        decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()),
        validator: (value) => requiredValidator(value, 'el modelo'),
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

      // 6. AÑADIR EL NUEVO CAMPO AL FORMULARIO
      const SizedBox(height: 16),
      TextFormField(
        controller: _juegosController,
        decoration: const InputDecoration(
            labelText: 'Juegos Compatibles (separados por coma)',
            hintText: 'Ej: FC 24, Halo Infinite, Mario Kart',
            border: OutlineInputBorder()
        ),
        minLines: 2, // Hacerlo un poco más alto
        maxLines: 5,
      ),
    ];
  }
}