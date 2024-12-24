import 'package:flutter/material.dart';

class DebtListScreen extends StatelessWidget {
  final String userId;

  const DebtListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Deudas'),
      ),
      body: Center(
        child: Text('Mostrando las deudas del usuario con ID: $userId'),
      ),
    );
  }
}
