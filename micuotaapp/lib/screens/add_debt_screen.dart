import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importa la librería intl

class AddDebtScreen extends StatefulWidget {
  final String userId;

  const AddDebtScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AddDebtScreenState createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  final _totalCuotasController = TextEditingController();
  final _totalPagadasController = TextEditingController();
  DateTime? _fechaDePago;

  final _numberFormat = NumberFormat("#,##0", "es_CL"); // Formato para CLP

  void _guardarDeuda() async {
    final nombre = _nombreController.text.trim();
    final monto = _montoController.text.trim().replaceAll('.', ''); // Elimina puntos antes de convertir
    final totalCuotas = _totalCuotasController.text.trim();
    final totalPagadas = _totalPagadasController.text.trim();

    if (nombre.isEmpty || monto.isEmpty || totalCuotas.isEmpty || totalPagadas.isEmpty || _fechaDePago == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('debts')
          .add({
        'nombre': nombre,
        'monto': double.parse(monto),
        'totalCuotas': int.parse(totalCuotas),
        'totalPagadas': int.parse(totalPagadas),
        'fechaDePago': _fechaDePago?.toIso8601String(),
        'fechaCreacion': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deuda guardada exitosamente.")),
      );

      Navigator.pop(context); // Vuelve a la pantalla anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar deuda: $e")),
      );
    }
  }

  void _seleccionarFecha(BuildContext context) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaDePago = fechaSeleccionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Deuda")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: "Nombre de la deuda"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monto"),
              onChanged: (value) {
                // Formatea el monto mientras se escribe
                final newText = value.replaceAll('.', ''); // Elimina puntos existentes
                if (newText.isNotEmpty) {
                  setState(() {
                    _montoController.value = TextEditingValue(
                      text: _numberFormat.format(int.parse(newText)),
                      selection: TextSelection.collapsed(offset: _numberFormat.format(int.parse(newText)).length),
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _totalCuotasController,
              decoration: const InputDecoration(labelText: "Número total de cuotas"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _totalPagadasController,
              decoration: const InputDecoration(labelText: "Número de cuotas pagadas"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fechaDePago == null
                        ? "Selecciona la fecha de pago"
                        : "Fecha de pago: ${_fechaDePago!.toLocal()}".split(' ')[0],
                  ),
                ),
                TextButton(
                  onPressed: () => _seleccionarFecha(context),
                  child: const Text("Seleccionar Fecha"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarDeuda,
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}
