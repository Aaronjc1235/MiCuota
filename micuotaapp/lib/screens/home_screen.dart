import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  String? _userEmail;
  List<Map<String, dynamic>> _debts = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchDebts();
  }

  Future<void> _getCurrentUser() async {
    setState(() {
      _currentUser = _auth.currentUser;
      _userEmail = _currentUser?.email ?? "Usuario desconocido";
    });
  }

  Future<void> _fetchDebts() async {
    if (_currentUser != null) {
      final debtsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('debts');

      final querySnapshot = await debtsCollection.get();
      setState(() {
        _debts = querySnapshot.docs
            .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bienvenido"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDebts, // Refrescar datos
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, $_userEmail",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Deudas:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _debts.isEmpty
                ? const Text("No tienes deudas registradas.")
                : Expanded(
              child: ListView.builder(
                itemCount: _debts.length,
                itemBuilder: (context, index) {
                  final debt = _debts[index];
                  return Card(
                    child: ListTile(
                      title: Text(debt['name'] ?? "Sin nombre"),
                      subtitle: Text(
                          "Cuotas restantes: ${(debt['totalInstallments'] ?? 0) - (debt['paidInstallments'] ?? 0)}\nPróxima fecha: ${debt['nextPaymentDate'] ?? 'No registrada'}"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: const Text("Cerrar Sesión"),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_debt').then((_) => _fetchDebts());
        },
        child: const Icon(Icons.add),
        tooltip: "Agregar Deuda",
      ),
    );
  }
}
