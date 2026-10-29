import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_servicios.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  User? get currentUser => _auth.currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    try {
      await user.updateDisplayName(name.trim());

      await _firebaseService.saveUserData(
        uid: user.uid,
        name: name.trim(),
        username: username.trim(),
        email: email.trim(),
      );

      await user.sendEmailVerification();
    } catch (_) {
      // La cuenta ya se ha creado. No se elimina automáticamente
      // si falla el envío del correo o el guardado del perfil.
      rethrow;
    } finally {
      // El registro no debe dejar una sesión activa sin verificar.
      await _auth.signOut();
    }

    return user;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) return null;

    if (!refreshedUser.emailVerified) {
      try {
        await refreshedUser.sendEmailVerification();
      } finally {
        await _auth.signOut();
      }

      throw EmailNotVerifiedException(
        'Tu correo electrónico todavía no está verificado. '
        'Te hemos enviado un nuevo enlace. Revisa tu bandeja de entrada '
        'y la carpeta de spam antes de volver a iniciar sesión.',
      );
    }

    return refreshedUser;
  }

  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('No se pudo identificar la cuenta.');
    }

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        throw Exception('No se pudo recuperar la cuenta.');
      }

      if (refreshedUser.emailVerified) {
        throw Exception('Tu correo ya está verificado. Puedes iniciar sesión.');
      }

      await refreshedUser.sendEmailVerification();
    } finally {
      await _auth.signOut();
    }
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await _firebaseService.saveUserData(
        uid: user.uid,
        name: user.displayName ?? 'Usuario de Google',
        username: '@${user.email?.split('@')[0] ?? 'user'}',
        email: user.email ?? '',
      );
    }

    return user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } finally {
      await _auth.signOut();
    }
  }
}

class EmailNotVerifiedException implements Exception {
  final String message;

  const EmailNotVerifiedException(this.message);

  @override
  String toString() => message;
}
