import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_debtor_screen.dart';
import 'paid_debtors_screen.dart';

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
        Navigator.pushNamed(context, '/home', arguments: widget.userId);
        break;
      case 1:
        Navigator.pushNamed(context, '/profile', arguments: widget.userId);
        break;
      case 2:
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

  Future<void> _abonarDeuda(String debtorId, double montoActual, String nombreDeudor, BuildContext context) async {
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
                try {
                  double abono = double.tryParse(_abonoController.text.replaceAll('.', '')) ?? 0;

                  if (abono > 0 && abono <= montoActual) {
                    double nuevoMonto = montoActual - abono;
                    final batch = FirebaseFirestore.instance.batch();
                    final debtorRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('debtors')
                        .doc(debtorId);

                    // Agregar nuevo abono
                    final newAbonoRef = debtorRef.collection('abonos').doc();
                    batch.set(newAbonoRef, {
                      'monto': abono,
                      'fecha': Timestamp.now(),
                    });

                    // Obtener monto total pagado y actualizar
                    double montoTotalPagado = abono;

                    final abonosSnapshot = await debtorRef.collection('abonos').get();
                    abonosSnapshot.docs.forEach((abonoDoc) {
                      montoTotalPagado += (abonoDoc['monto'] as num).toDouble();
                    });

                    // Actualizar el monto total pagado
                    batch.update(debtorRef, {'monto': nuevoMonto, 'montoTotalPagado': montoTotalPagado});

                    await batch.commit();

                    // Verificar si la deuda está completamente pagada
                    if (nuevoMonto == 0) {
                      await _moverDeudaAPaid(debtorId, montoTotalPagado);
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
                } catch (e) {
                  print("Error al abonar: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al procesar el abono.")),
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

  Future<void> _moverDeudaAPaid(String debtorId, double montoTotalPagado) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Obtener datos del deudor
      final debtorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('debtors')
          .doc(debtorId)
          .get();

      if (!debtorDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deudor no encontrado.")),
        );
        return;
      }

      final debtorData = debtorDoc.data() as Map<String, dynamic>;

      // Crear documento en paid_debtors con el mismo ID
      final paidDebtorRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('paid_debtors')
          .doc(debtorId);

      batch.set(paidDebtorRef, {
        'nombre': debtorData['nombre'],
        'montoTotalPagado': montoTotalPagado,
        'fecha': Timestamp.now(),
      });

      // Transferir abonos
      final abonosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('debtors')
          .doc(debtorId)
          .collection('abonos')
          .get();

      for (var abonoDoc in abonosSnapshot.docs) {
        final abonoRef = paidDebtorRef.collection('abonos').doc(abonoDoc.id);
        batch.set(abonoRef, abonoDoc.data());

        // Eliminar abono original
        final originalAbonoRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('debtors')
            .doc(debtorId)
            .collection('abonos')
            .doc(abonoDoc.id);
        batch.delete(originalAbonoRef);
      }

      // Eliminar deudor original
      batch.delete(debtorDoc.reference);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deuda pagada en su totalidad.")),
      );
    } catch (e) {
      print("Error al pagar deuda: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al procesar el pago.")),
      );
    }
  }

  Future<void> _mostrarHistorialAbonos(String debtorId, String nombreDeudor) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Historial de Abonos - $nombreDeudor",
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('debtors')
                        .doc(debtorId)
                        .collection('abonos')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text("No hay abonos registrados."));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final abono = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(
                                "\$${NumberFormat("#,##0", "es_CL").format(abono['monto'])}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Fecha: ${_formatFecha(abono['fecha'])}",
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deudores"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('debtors')
            .orderBy('nombre') // Orden alfabético por nombre
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No hay deudores registrados."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final deudor = docs[index].data() as Map<String, dynamic>;
              final debtorId = docs[index].id;
              final double monto = double.tryParse(deudor['monto'].toString()) ?? 0.0;
              final double montoTotalPagado = deudor['montoTotalPagado'] ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  onTap: () => _mostrarHistorialAbonos(debtorId, deudor['nombre'] ?? "Sin nombre"),
                  title: Text(
                    deudor['nombre'] ?? "Sin nombre",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Monto a deber: \$${NumberFormat("#,##0", "es_CL").format(monto)}",
                      ),
                      const SizedBox(height: 8), // Espacio entre los textos
                      Text(
                        "Total Pagado: \$${NumberFormat("#,##0", "es_CL").format(montoTotalPagado)}",
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_money, color: Colors.green),
                        onPressed: () => _abonarDeuda(debtorId, monto, deudor['nombre'], context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDebtorScreen(userId: widget.userId),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaidDebtorsScreen(userId: widget.userId),
                ),
              );
            },
            child: const Icon(Icons.history),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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
