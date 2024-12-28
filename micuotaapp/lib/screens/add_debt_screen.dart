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
      backgroundColor: const Color(0xFF1B1919),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1CC0C6),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    child: const Text(
                      "Ingresa tu Deuda",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    child: Image.asset(
                      'lib/assets/images/3dicons-wallet-iso-color.png',
                      height: 400,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nombre de la deuda",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white70),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF0D7377)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Monto",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white70),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF0D7377)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
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
              const SizedBox(height: 20),
              TextField(
                controller: _totalCuotasController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Número total de cuotas",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white70),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF0D7377)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _totalPagadasController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Número de cuotas pagadas",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white70),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF0D7377)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fechaDePago == null
                          ? "Selecciona la fecha de pago"
                          : "Fecha de pago: ${_fechaDePago!.toLocal()}".split(' ')[0],
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF0D7377)),
                    onPressed: () => _seleccionarFecha(context),
                    child: const Text("Seleccionar Fecha"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _guardarDeuda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CC0C6),
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text("Guardar", style: TextStyle(fontSize: 16.0, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
