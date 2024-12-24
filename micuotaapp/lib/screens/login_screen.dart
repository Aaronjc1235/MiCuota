import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos.")),
      );
      return;
    }

    try {
      final user = await AuthService().login(email, password);
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/debt_list'); // Navega a la pantalla principal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inicio de sesión fallido: Usuario no autenticado.")),
        );
      }
    } catch (e) {
      print("Error en inicio de sesión: $e"); // Muestra el error en la consola
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inicio de sesión fallido: $e")),
      );
    }
  }

  void _loginAnonymously() async {
    try {
      final user = await AuthService().loginAnonymously();
      if (user != null) {
        print("Usuario anónimo autenticado: ${user.uid}");
        Navigator.pushReplacementNamed(context, '/home'); // Navega a la pantalla principal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inicio de sesión anónimo fallido.")),
        );
      }
    } catch (e) {
      print("Error en inicio de sesión anónimo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inicio de sesión anónimo fallido: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inicio de Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              onPressed: _login,
              child: const Text("Iniciar Sesión"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text("¿No tienes cuenta? Regístrate"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginAnonymously,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
              ),
              child: const Text("Iniciar Sesión Anónimo"),
            ),
          ],
        ),
      ),
    );
  }
}
