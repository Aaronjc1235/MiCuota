import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaidDebtorsScreen extends StatelessWidget {
  final String userId;

  const PaidDebtorsScreen({Key? key, required this.userId}) : super(key: key);

  String _formatFecha(Timestamp fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha.toDate());
  }

  Future<void> _mostrarHistorialAbonos(BuildContext context, String debtorId, String nombreDeudor) async {
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
                        .doc(userId)
                        .collection('paid_debtors')
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

                      double totalAbonos = 0;
                      for (var abono in docs) {
                        totalAbonos += (abono['monto'] as num).toDouble();
                      }

                      return Column(
                        children: [
                          Text(
                            "Monto total pagado: \$${NumberFormat("#,##0", "es_CL").format(totalAbonos)}",
                            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16.0),
                          Expanded(
                            child: ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final abono = docs[index].data() as Map<String, dynamic>;
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      "\$${NumberFormat("#,##0", "es_CL").format(abono['monto'])}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text("Fecha: ${_formatFecha(abono['fecha'])}"),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

  Future<void> _eliminarHistorialAbonos(BuildContext context, String debtorId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Estás seguro de borrar el historial?"),
        content: const Text("No se podrá recuperar."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              try {
                final batch = FirebaseFirestore.instance.batch();
                final debtorRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('paid_debtors')
                    .doc(debtorId);

                final abonosSnapshot = await debtorRef.collection('abonos').get();
                for (var doc in abonosSnapshot.docs) {
                  batch.delete(doc.reference);
                }
                batch.delete(debtorRef);

                await batch.commit();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Historial de abonos eliminado.")),
                );
              } catch (e) {
                print("Error al eliminar historial de abonos: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hubo un error al eliminar el historial.")),
                );
              }
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1919),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1CC0C6),
        title: const Text(
          "Deudores Pagados",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('paid_debtors')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay deudores pagados.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final pagado = docs[index].data() as Map<String, dynamic>;
              final debtorId = docs[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D7377), Color(0xFF1CC0C6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      pagado['nombre'] ?? "Sin nombre",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "Fecha: ${_formatFecha(pagado['fecha'])}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.white),
                          onPressed: () => _mostrarHistorialAbonos(context, debtorId, pagado['nombre']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarHistorialAbonos(context, debtorId),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
