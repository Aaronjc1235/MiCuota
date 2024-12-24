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
    String currentText = _amountController.text.replaceAll('.', '');
    if (currentText.isNotEmpty) {
      _amountController.value = TextEditingValue(
        text: _numberFormat.format(int.parse(currentText)),
        selection: TextSelection.collapsed(offset: _numberFormat.format(int.parse(currentText)).length),
      );
    }
  }

  Future<void> _addDebtor() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(amountText) ?? 0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ingresa datos válidos.")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debtors')
        .add({
      'nombre': name,
      'monto': amount,
      'fecha': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deudor agregado exitosamente.")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Deudor"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre del Deudor",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monto de la Deuda",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _formatAmount(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addDebtor,
              child: const Text("Agregar"),
            ),
          ],
        ),
      ),
    );
  }
}
