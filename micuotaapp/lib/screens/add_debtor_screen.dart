import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddDebtorScreen extends StatefulWidget {
  final String userId;

  const AddDebtorScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AddDebtorScreenState createState() => _AddDebtorScreenState();
}

class _AddDebtorScreenState extends State<AddDebtorScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _numberFormat = NumberFormat("#,##0", "es_CL");

  void _formatAmount() {
    try {
      String currentText = _amountController.text.replaceAll('.', '');
      if (currentText.isNotEmpty) {
        _amountController.value = TextEditingValue(
          text: _numberFormat.format(int.parse(currentText)),
          selection: TextSelection.collapsed(offset: _numberFormat.format(int.parse(currentText)).length),
        );
      }
    } catch (e) {
      print("Error al formatear la cantidad: $e");
    }
  }

  Future<void> _addDebtor() async {
    try {
      final name = _nameController.text.trim();
      final amountText = _amountController.text.replaceAll('.', '');
      final amount = double.tryParse(amountText) ?? 0;

      if (name.isEmpty || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, ingresa datos válidos.")),
        );
        return;
      }

      // Agregar deudor a la subcolección "debtors"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('debtors')
          .add({
        'nombre': name,
        'monto': amount,
        'fecha': Timestamp.now(),
      });

      // Incrementar el contador de deudores en el documento principal del usuario
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'debtorsCount': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deudor agregado exitosamente.")),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error al agregar el deudor: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ocurrió un error al agregar el deudor.")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
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
                      "Agregar Deudor",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    child: Image.asset(
                      'lib/assets/images/3dicons-dollar-iso-color.png',
                      height: 400,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nombre del Deudor",
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
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Monto de la Deuda",
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
                onChanged: (value) => _formatAmount(),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _addDebtor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CC0C6),
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text(
                    "Agregar",
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
