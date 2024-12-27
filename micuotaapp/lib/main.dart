import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:micuotaapp/screens/home_screen.dart';
import 'package:micuotaapp/screens/login_screen.dart';
import 'package:micuotaapp/screens/profile_screen.dart';
import 'package:micuotaapp/screens/register_screen.dart';
import 'package:micuotaapp/screens/add_debt_screen.dart'; // Importa AddDebtScreen
import 'package:micuotaapp/screens/debtors_screen.dart' as debtors; // Usa alias para evitar conflicto
import 'package:micuotaapp/screens/add_debtor_screen.dart' as add_debtor; // Usa alias para evitar conflicto


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiCuota App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthChecker(), // Nueva clase para gestionar autenticación
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(
          userId: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/profile': (context) => ProfileScreen(
          userId: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/add_debt': (context) => AddDebtScreen(
          userId: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/debtors': (context) => debtors.DebtorsScreen(
          userId: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/add_debtor': (context) => add_debtor.AddDebtorScreen(
          userId: ModalRoute.of(context)?.settings.arguments as String,
        ),
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // Si hay un usuario autenticado, redirige a HomeScreen
          return HomeScreen(userId: snapshot.data!.uid);
        } else {
          // Si no hay usuario autenticado, redirige a LoginScreen
          return const LoginScreen();
        }
      },
    );
  }
}
