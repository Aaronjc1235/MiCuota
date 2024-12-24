import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos.")),
      );
      return;
    }

    try {
      final user = await AuthService().register(email, password);
      if (user != null) {
        // Crear el documento del usuario
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'nombre': name,
          'fechaRegistro': Timestamp.now(), // Agregamos fecha de registro como Timestamp
        });

        // Crear la subcolección `debts` con un documento inicial
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debts')
            .add({
          'fechaDePago': Timestamp.now(), // Aseguramos que sea Timestamp
          'monto': 0,
          'nombre': 'Deuda inicial',
          'totalCuotas': 0,
          'totalPagadas': 0,
        });

        // Crear la subcolección `debtors` con un documento inicial
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debtors')
            .add({
          'nombre': 'Juan Pérez',
          'monto': 50000,
          'pagado': 0,
          'fechaDeCreacion': Timestamp.now(), // Aseguramos que sea Timestamp
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso. Iniciando sesión...")),
        );

        // Iniciar sesión automáticamente
        Navigator.pushReplacementNamed(context, '/home', arguments: user.uid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro fallido: Usuario no creado.")),
        );
      }
    } catch (e) {
      print("Error en registro: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registro fallido: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Correo electrónico",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text("Registrarse"),
            ),
          ],
        ),
      ),
    );
  }
}
