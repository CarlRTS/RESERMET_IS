import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationFormConsole extends StatefulWidget {
  const ReservationFormConsole({super.key});

  @override
  State<ReservationFormConsole> createState() => _ReservationFormConsoleState();
}

class _ReservationFormConsoleState extends State<ReservationFormConsole> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Consola'),
        backgroundColor: Colors.blue,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Formulario de reserva de consola'),
      ),
    );
  }
}
