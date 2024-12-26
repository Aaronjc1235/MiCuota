import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DebtorsScreen extends StatefulWidget {
  final String userId;

  const DebtorsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DebtorsScreenState createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  int _selectedIndex = 2;

  String _formatFecha(Timestamp fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha.toDate());
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home', arguments: widget.userId);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/profile', arguments: widget.userId);
        break;
      case 2:
      // No hacer nada porque ya estamos en esta página
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ruta no válida")),
        );
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _abonarDeuda(String debtorId, double montoActual, BuildContext context) async {
    TextEditingController _abonoController = TextEditingController();
    final _numberFormat = NumberFormat("#,##0", "es_CL");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Abonar a la deuda"),
          content: TextField(
            controller: _abonoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Monto a abonar"),
            onChanged: (value) {
              String formatted = value.replaceAll('.', '');
              if (formatted.isNotEmpty) {
                _abonoController.value = TextEditingValue(
                  text: _numberFormat.format(int.parse(formatted)),
                  selection: TextSelection.collapsed(
                      offset: _numberFormat.format(int.parse(formatted)).length),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                double abono = double.tryParse(_abonoController.text.replaceAll('.', '')) ?? 0;

                if (abono > 0 && abono <= montoActual) {
                  double nuevoMonto = montoActual - abono;

                  if (nuevoMonto == 0) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('debtors')
                        .doc(debtorId)
                        .delete();
                  } else {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('debtors')
                        .doc(debtorId)
                        .update({'monto': nuevoMonto});
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Abono realizado exitosamente.")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Monto inválido para abonar.")),
                  );
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pagarDeudaTotal(String debtorId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debtors')
        .doc(debtorId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deuda pagada en su totalidad.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('debtors')
            .orderBy('nombre')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay deudores registrados."));
          }

          final deudores = snapshot.data!.docs;
          return ListView.builder(
            itemCount: deudores.length,
            itemBuilder: (context, index) {
              final deudor = deudores[index].data() as Map<String, dynamic>;
              final debtorId = deudores[index].id;
              final double monto = double.tryParse(deudor['monto'].toString()) ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(
                    deudor['nombre'] ?? "Sin nombre",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Monto: \$${NumberFormat("#,##0", "es_CL").format(monto)} | Fecha: ${_formatFecha(deudor['fecha'])}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_money, color: Colors.green),
                        onPressed: () => _abonarDeuda(debtorId, monto, context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.done_all, color: Colors.blue),
                        onPressed: () => _pagarDeudaTotal(debtorId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/add_debtor', arguments: widget.userId);
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Deudores',
          ),
        ],
      ),
    );
  }
}
