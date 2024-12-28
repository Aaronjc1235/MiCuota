import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micuotaapp/screens/home_screen.dart';
import 'package:micuotaapp/screens/login_screen.dart';
import 'package:micuotaapp/screens/profile_screen.dart';
import 'package:micuotaapp/screens/register_screen.dart';
import 'package:micuotaapp/screens/add_debt_screen.dart';
import 'package:micuotaapp/screens/debtors_screen.dart' as debtors;
import 'package:micuotaapp/screens/add_debtor_screen.dart' as add_debtor;

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D7377)),
        useMaterial3: true,
      ),
      home: const AuthChecker(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => MainContainer(
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
    return StreamBuilder<User?> (
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return MainContainer(userId: snapshot.data!.uid);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainContainer extends StatefulWidget {
  final String userId;

  const MainContainer({Key? key, required this.userId}) : super(key: key);

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
      debtors.DebtorsScreen(userId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1919),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0D7377),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < 3; i++)
                GestureDetector(
                  onTap: () => _onItemTapped(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: _selectedIndex == i ? 12.0 : 0.0,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedIndex == i
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          i == 0
                              ? (_selectedIndex == 0
                              ? Icons.home
                              : Icons.home_outlined)
                              : i == 1
                              ? (_selectedIndex == 1
                              ? Icons.person
                              : Icons.person_outline)
                              : (_selectedIndex == 2
                              ? Icons.people
                              : Icons.people_outline),
                          color: Colors.white,
                          size: 36,
                        ),
                        if (_selectedIndex == i)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              i == 0
                                  ? 'Inicio'
                                  : i == 1
                                  ? 'Perfil'
                                  : 'Deudores',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
