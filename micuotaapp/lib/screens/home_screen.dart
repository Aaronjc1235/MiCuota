import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pantalla Principal")),
      body: const Center(
        child: Text(
          "¡Bienvenido a MiCuota App!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
