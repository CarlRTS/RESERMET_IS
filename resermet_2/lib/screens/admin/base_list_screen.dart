// Pantalla base para listas con funcionalidades comunes
import 'package:flutter/material.dart';

abstract class BaseListScreen<T> extends StatefulWidget {
  const BaseListScreen({super.key});
}

abstract class BaseListScreenState<T, W extends BaseListScreen<T>> extends State<W> {
  List<T> items = [];
  bool isLoading = true;
  String screenTitle = '';
  Color appBarColor = const Color(0xFF0033A0);

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  // Métodos abstractos que deben implementarse
  Future<List<T>> fetchItems();
  Widget buildItemCard(T item);
  void navigateToAdd();
  void navigateToEdit(T item);
  Future<void> deleteItem(T item);
  String getDeleteMessage(T item);

  // Cargar items
  Future<void> loadItems() async {
    try {
      final fetchedItems = await fetchItems();
      setState(() {
        items = fetchedItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Error al cargar: $e');
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

  // Confirmación para eliminar
  void showDeleteConfirmation(T item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar'),
          content: Text(getDeleteMessage(item)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDelete(item);
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

  // Ejecutar eliminación
  Future<void> _performDelete(T item) async {
    try {
      await deleteItem(item);
      showSuccessSnackbar('Eliminado exitosamente');
      await loadItems();
    } catch (e) {
      showErrorSnackbar('Error al eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: navigateToAdd,
            tooltip: 'Agregar',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text(
                    'No hay registros',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return buildItemCard(item);
                  },
                ),
    );
  }
}