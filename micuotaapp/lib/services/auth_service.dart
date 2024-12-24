import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constructor para configurar el idioma
  AuthService() {
    _auth.setLanguageCode('es'); // Configura el idioma a español
  }

  // Inicio de sesión anónimo
  Future<User?> loginAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("Error en inicio de sesión anónimo: $e");
      return null;
    }
  }

  // Registro de usuario
  Future<User?> register(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        print("Usuario registrado exitosamente: ${userCredential.user!.uid}");
        return userCredential.user;
      } else {
        print("Error: Usuario no fue registrado correctamente");
        return null;
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            print("Error: El correo ya está en uso.");
            break;
          case 'invalid-email':
            print("Error: El correo electrónico no es válido.");
            break;
          case 'weak-password':
            print("Error: La contraseña es demasiado débil.");
            break;
          default:
            print("Error desconocido: ${e.message}");
            break;
        }
      } else {
        print("Error al registrar usuario: $e");
      }
      return null;
    }
  }

  // Inicio de sesión de usuario
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        print("Inicio de sesión exitoso: ${userCredential.user!.uid}");
        return userCredential.user;
      } else {
        print("Error: Usuario no autenticado");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          print("Error: No se encontró un usuario con ese correo.");
          break;
        case 'wrong-password':
          print("Error: Contraseña incorrecta.");
          break;
        case 'too-many-requests':
          print("Error: Demasiados intentos fallidos. Intenta más tarde.");
          break;
        default:
          print("Error desconocido: ${e.message}");
          break;
      }
      return null;
    } catch (e) {
      print("Error al iniciar sesión: $e");
      return null;
    }
  }



  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Verificar usuario actual
  User? get currentUser => _auth.currentUser;
}
