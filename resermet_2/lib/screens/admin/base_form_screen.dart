// Pantalla base para formularios con funcionalidades comunes
import 'package:flutter/material.dart';

abstract class BaseFormScreen<T> extends StatefulWidget {
  final T? item;
  final VoidCallback onItemSaved;
  final String screenTitle;
  final Color appBarColor;

  const BaseFormScreen({
    super.key,
    this.item,
    required this.onItemSaved,
    required this.screenTitle,
    required this.appBarColor,
  });
}

abstract class BaseFormScreenState<T, W extends BaseFormScreen<T>> extends State<W> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Métodos abstractos que deben implementarse
  T createItem();
  Future<void> saveItem(T item);
  List<Widget> buildFormFields();
  void populateFormFields(T item);

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      populateFormFields(widget.item!);
    }
  }

  // Guardar item con validación
  Future<void> saveForm() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final item = createItem();
      await saveItem(item);
      
      widget.onItemSaved();
      Navigator.of(context).pop();
      
      showSuccessSnackbar(widget.item == null ? 'Creado exitosamente' : 'Actualizado exitosamente');
    } catch (e) {
      showErrorSnackbar('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Mostrar snackbar de error
  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Mostrar snackbar de éxito
  void showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Validador para campos requeridos
  String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    return null;
  }

  // Validador para números
  String? numberValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    if (int.tryParse(value) == null) {
      return 'Por favor ingresa un número válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screenTitle),
        backgroundColor: widget.appBarColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    ...buildFormFields(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // Botón guardar
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: saveForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.appBarColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(widget.item == null ? 'Crear' : 'Actualizar'),
    );
  }
}