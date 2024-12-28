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
  final _lastNameController = TextEditingController();  // Nuevo controller
  final _nickNameController = TextEditingController();  // Nuevo controller
  bool _obscurePassword = true;

  String? _selectedImage;

  final List<String> _profileImages = [
    'lib/assets/images/avatar1.png',
    'lib/assets/images/avatar2.png',
    'lib/assets/images/avatar3.png',
    'lib/assets/images/avatar4.png',
    'lib/assets/images/avatar5.png',
    'lib/assets/images/avatar6.png',
    'lib/assets/images/avatar7.png',
    'lib/assets/images/avatar8.png',
    'lib/assets/images/avatar9.png',
    'lib/assets/images/avatar10.png',
    'lib/assets/images/avatar11.png',
    'lib/assets/images/avatar12.png',
    'lib/assets/images/avatar13.png',
    'lib/assets/images/avatar14.png',
    'lib/assets/images/avatar15.png',
    'lib/assets/images/avatar16.png',
    'lib/assets/images/avatar18.png',
    'lib/assets/images/avatar19.png',
    'lib/assets/images/avatar20.png',
    'lib/assets/images/avatar21.png',
    'lib/assets/images/avatar22.png',
    'lib/assets/images/avatar23.png',
  ];

  void _showImageSelectionDialog() {
    // [Mantener el código existente del diálogo de selección de imagen]
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Elige una imagen de perfil",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: _profileImages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final imagePath = _profileImages[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = imagePath;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedImage == imagePath
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final lastName = _lastNameController.text.trim();  // Nuevo campo
    final nickName = _nickNameController.text.trim();  // Nuevo campo

    if (email.isEmpty || password.isEmpty || name.isEmpty || lastName.isEmpty || nickName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, ingresa un correo electrónico válido."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La contraseña debe tener al menos 6 caracteres."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = await AuthService().register(email, password);
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'nombre': name,
          'apellido': lastName,  // Nuevo campo
          'nickName': nickName,  // Nuevo campo
          'profileImage': _selectedImage ?? 'lib/assets/images/avatar1.png',
          'fechaRegistro': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registro exitoso. Iniciando sesión..."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home', arguments: user.uid);
      }
    } catch (e) {
      String errorMessage = "Error en el registro";

      if (e.toString().contains('email-already-in-use')) {
        errorMessage = "Este correo electrónico ya está registrado";
      } else if (e.toString().contains('weak-password')) {
        errorMessage = "La contraseña es demasiado débil";
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = "El correo electrónico no es válido";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 320,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1CC0C6),
                      Color(0xFF0D7377),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Row(
                        children: const [
                          Icon(Icons.more_horiz, color: Colors.white, size: 30),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 0.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "Vamos a",
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontFamily: "Monserrat",
                                fontSize: 60,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              "Crear\ntuu\nCuenta",
                              style: TextStyle(
                                fontFamily: "Monserrat",
                                fontSize: 60,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Nombre",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Apellido",
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nickNameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Nickname",
                            prefixIcon: const Icon(Icons.face),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Correo Electrónico",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Contraseña",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Imagen de perfil",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            TextButton.icon(
                              onPressed: _showImageSelectionDialog,
                              icon: const Icon(Icons.image, color: Colors.black),
                              label: const Text(
                                "Elegir imagen",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_selectedImage != null)
                          Center(
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading selected image: $error');
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.person, size: 50, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF0D7377),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            "Registrarse",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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