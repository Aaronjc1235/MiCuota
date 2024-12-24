import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  final String userId; // Recibe el userId del usuario autenticado

  const DashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiCuota Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('debts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay deudas registradas.'),
            );
          }

          final debts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              return ListTile(
                title: Text(debt['name']),
                subtitle: Text(
                    '${debt['paidInstallments']} de ${debt['totalInstallments']} cuotas pagadas'),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('debts')
                        .doc(debt.id)
                        .update({
                      'paidInstallments': FieldValue.increment(1),
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
