import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice inicial para la pestaña "Inicio"

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Evitar recargar la misma pestaña

    switch (index) {
      case 0: // Mantenerse en la pantalla de inicio
        break;
      case 1: // Redirigir al perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: widget.userId),
          ),
        );
        break;
      case 2: // Lógica para cerrar sesión
        FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
        break;
    }

    setState(() {
      _selectedIndex = index; // Actualizar índice seleccionado
    });
  }

  Future<void> _pagarCuota(String debtId, Map<String, dynamic> deuda) async {
    final currentDate = DateTime.now();
    final nextPaymentDate = DateTime(
      currentDate.year,
      currentDate.month + 1,
      DateTime.parse(deuda['fechaDePago']).day,
    );

    if (DateFormat('yyyy-MM').format(currentDate) ==
        DateFormat('yyyy-MM').format(DateTime.parse(deuda['ultimoPago'] ?? '1970-01-01'))) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debts')
        .doc(debtId)
        .update({
      'totalPagadas': deuda['totalPagadas'] + 1,
      'fechaDePago': nextPaymentDate.toIso8601String(),
      'ultimoPago': currentDate.toIso8601String(),
    });
  }

  Future<void> _deshacerPago(String debtId, Map<String, dynamic> deuda) async {
    final currentDate = DateTime.now();
    final lastPaymentDate = DateTime.parse(deuda['ultimoPago'] ?? '1970-01-01');

    if (currentDate.difference(lastPaymentDate).inMinutes > 30) {
      return;
    }

    final previousPaymentDate = DateTime(
      lastPaymentDate.year,
      lastPaymentDate.month - 1,
      DateTime.parse(deuda['fechaDePago']).day,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('debts')
        .doc(debtId)
        .update({
      'totalPagadas': deuda['totalPagadas'] - 1,
      'fechaDePago': previousPaymentDate.toIso8601String(),
      'ultimoPago': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('debts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay deudas registradas."));
          }

          final deudas = snapshot.data!.docs;
          return ListView.builder(
            itemCount: deudas.length,
            itemBuilder: (context, index) {
              final deuda = deudas[index].data() as Map<String, dynamic>;
              final debtId = deudas[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.monetization_on, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deuda['nombre'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Monto: ${numberFormat.format(deuda['monto'])}",
                            ),
                            Text(
                              "Cuotas: ${deuda['totalPagadas']}/${deuda['totalCuotas']}",
                            ),
                            Text(
                              "Próxima fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(deuda['fechaDePago']))}",
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () => _pagarCuota(debtId, deuda),
                          ),
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
            icon: Icon(Icons.logout),
            label: 'Cerrar Sesión',
          ),
        ],
      ),
    );
  }
}
