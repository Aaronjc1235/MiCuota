import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final String userEmail;

  const HomeScreen({Key? key, required this.userEmail}) : super(key: key);

  void _navigateToDebtList(BuildContext context) {
    Navigator.pushNamed(context, '/debt_list');
  }

  void _navigateToAddDebt(BuildContext context) {
    Navigator.pushNamed(context, '/add_debt');
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile'); // Ruta para la pantalla de perfil
  }

  void _logout(BuildContext context) async {
    await AuthService().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Bienvenido, $userEmail",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Número de deudas simuladas
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.monetization_on),
                      title: Text("Deuda ${index + 1}"),
                      subtitle: Text("Monto: \$${(index + 1) * 100}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Acción al tocar una deuda (puedes personalizar)
                        _navigateToDebtList(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddDebt(context),
              icon: const Icon(Icons.add),
              label: const Text("Agregar Nueva Deuda"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        onTap: (index) {
          switch (index) {
            case 0:
            // Ya estás en la pantalla de inicio, no hagas nada
              break;
            case 1:
              _navigateToProfile(context);
              break;
            case 2:
              _logout(context);
              break;
          }
        },
      ),
    );
  }
}
