import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repositorio encargado de la comunicación directa con Firebase Auth.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Instancia estática para evitar múltiples inicializaciones del SDK de Google en la web.
  static final GoogleSignIn _googleSignInInstance = GoogleSignIn(
    clientId: kIsWeb
        ? '507734879692-b7fe6p4cn6bhjrq1u6l2tabegvni2sd9.apps.googleusercontent.com'
        : null,
  );

  /// Getter para acceder a la instancia única.
  GoogleSignIn get _googleSignIn => _googleSignInInstance;

  /// Stream que notifica cambios en el estado de la sesión.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obtiene el usuario actual si existe.
  User? get currentUser => _auth.currentUser;

  /// Verifica si un correo electrónico ya está registrado en Firebase.
  /// Retorna true si el correo tiene algún método de inicio de sesión (password, google, etc).
  Future<bool> isEmailRegistered(String email) async {
    // ignore: deprecated_member_use
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  /// Autenticación con Correo y Contraseña (Login).
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Creación de cuenta nueva.
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Autenticación Social con Google.
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Cierra la sesión de todos los proveedores.
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
