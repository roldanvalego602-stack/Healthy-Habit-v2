import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_servicios.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // 1. Método de Registro con correo y contraseña
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
        await user.updateDisplayName(name);
        await user.reload();

        // Guardar su perfil inicial en Firestore
        await _firebaseService.saveUserData(
          uid: user.uid,
          name: name,
          username: username,
          email: email,
        );
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Método de Inicio de Sesión con correo y contraseña
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

  // 3. Método de Inicio de Sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      // Disparar el flujo de selección de cuenta de Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null; // El usuario canceló la selección de cuenta
      }

      // Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear credencial para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial de Google
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      // Guardar o actualizar datos del usuario en Firestore
      if (user != null) {
        await _firebaseService.saveUserData(
          uid: user.uid,
          name: user.displayName ?? 'Usuario de Google',
          username: '@${user.email?.split('@')[0] ?? 'user'}',
          email: user.email ?? '',
        );
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // 4. Método para Cerrar Sesión
  Future<void> signOut() async {
    await GoogleSignIn().signOut(); // Cierra sesión de Google
    await _auth.signOut(); // Cierra sesión en Firebase
  }
}
