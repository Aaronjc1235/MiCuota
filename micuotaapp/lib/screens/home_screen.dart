import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/profile', arguments: widget.userId);
        break;
      case 2:
        Navigator.pushNamed(context, '/debtors', arguments: widget.userId);
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  String _formatFecha(dynamic fecha) {
    if (fecha is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(fecha.toDate());
    } else if (fecha is String) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha));
      } catch (e) {
        return "Fecha no válida";
      }
    } else {
      return "Fecha no disponible";
    }
  }

  Future<void> _pagarCuota(String debtId, Map<String, dynamic> deuda) async {
    final currentDate = DateTime.now();

    final DateTime fechaDePago = deuda['fechaDePago'] is Timestamp
        ? (deuda['fechaDePago'] as Timestamp).toDate()
        : DateTime.parse(deuda['fechaDePago']);

    final nextPaymentDate = DateTime(
      currentDate.year,
      currentDate.month + 1,
      fechaDePago.day,
    );

    final DateTime ultimoPago = deuda['ultimoPago'] is Timestamp
        ? (deuda['ultimoPago'] as Timestamp).toDate()
        : DateTime.tryParse(deuda['ultimoPago'] ?? '1970-01-01') ?? DateTime(1970);

    if (DateFormat('yyyy-MM').format(currentDate) ==
        DateFormat('yyyy-MM').format(ultimoPago)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solo se puede pagar una cuota al mes.")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debts')
        .doc(debtId)
        .update({
      'totalPagadas': deuda['totalPagadas'] + 1,
      'fechaDePago': Timestamp.fromDate(nextPaymentDate),
      'ultimoPago': Timestamp.now(),
    });

    if (deuda['totalPagadas'] + 1 >= deuda['totalCuotas']) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('debts')
          .doc(debtId)
          .delete();
    }
  }

  Future<void> _deshacerPago(String debtId, Map<String, dynamic> deuda) async {
    final currentDate = DateTime.now();

    final DateTime lastPaymentDate = deuda['ultimoPago'] is Timestamp
        ? (deuda['ultimoPago'] as Timestamp).toDate()
        : DateTime.tryParse(deuda['ultimoPago'] ?? '1970-01-01') ?? DateTime(1970);

    if (currentDate.difference(lastPaymentDate).inMinutes > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se puede deshacer el pago después de 30 minutos.")),
      );
      return;
    }

    final DateTime fechaDePago = deuda['fechaDePago'] is Timestamp
        ? (deuda['fechaDePago'] as Timestamp).toDate()
        : DateTime.parse(deuda['fechaDePago']);

    final previousPaymentDate = DateTime(
      fechaDePago.year,
      fechaDePago.month - 1,
      fechaDePago.day,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debts')
        .doc(debtId)
        .update({
      'totalPagadas': deuda['totalPagadas'] - 1,
      'fechaDePago': Timestamp.fromDate(previousPaymentDate),
      'ultimoPago': null,
    });
  }

  Future<void> _eliminarDeuda(String debtId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('debts')
          .doc(debtId)
          .delete();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deuda eliminada correctamente.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar la deuda.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("MiCuota"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('debts')
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay deudas registradas."));
          }

          final deudas = snapshot.data!.docs;
          deudas.sort((a, b) {
            final nombreA = (a.data() as Map<String, dynamic>)['nombre']?.toString() ?? '';
            final nombreB = (b.data() as Map<String, dynamic>)['nombre']?.toString() ?? '';
            return nombreA.compareTo(nombreB);
          });

          return ListView.builder(
            itemCount: deudas.length,
            itemBuilder: (context, index) {
              final deuda = deudas[index].data() as Map<String, dynamic>;
              final debtId = deudas[index].id;

              final DateTime lastPaymentDate = deuda['ultimoPago'] is Timestamp
                  ? (deuda['ultimoPago'] as Timestamp).toDate()
                  : DateTime.tryParse(deuda['ultimoPago'] ?? '1970-01-01') ?? DateTime(1970);

              final bool canUndo = DateTime.now().difference(lastPaymentDate).inMinutes <= 30;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            deuda['nombre'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'Eliminar') {
                                _eliminarDeuda(debtId);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'Eliminar',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Monto: ${numberFormat.format(deuda['monto'])}"),
                      Text("Cuotas: ${deuda['totalPagadas']}/${deuda['totalCuotas']}"),
                      Text("Próxima fecha: ${_formatFecha(deuda['fechaDePago'])}"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () => _pagarCuota(debtId, deuda),
                          ),
                          if (canUndo)
                            IconButton(
                              icon: const Icon(Icons.undo, color: Colors.red),
                              onPressed: () => _deshacerPago(debtId, deuda),
                            ),
                        ],
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
          Navigator.pushNamed(context, '/add_debt', arguments: widget.userId);
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
