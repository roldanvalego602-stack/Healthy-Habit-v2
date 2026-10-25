import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_servicios.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // 1. Método de Registro
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        // Guardar su perfil inicial en Firestore usando el servicio previo
        await _firebaseService.saveUserData(
          uid: user.uid,
          name: name,
          username: username,
          email: email,
        );
      }

      return user;
    } catch (e) {
      rethrow; // Propaga el error para mostrarlo en la interfaz si es necesario
    }
  }

  // 2. Método de Inicio de Sesión
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // 3. Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
