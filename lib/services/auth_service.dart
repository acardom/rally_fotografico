/**
 * Servicio de autenticación con Firebase Auth y Google Sign-In.
 * Proporciona funciones para login, registro y autenticación con Google.
 * @author Alberto Cárdeno
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Clase estática para gestionar la autenticación de usuarios
class AuthService {
  /**
   * Inicia sesión con correo y contraseña.
   * Lanza una excepción si el usuario o la contraseña no son válidos.
   * @param email El correo electrónico del usuario.
   * @param password La contraseña del usuario.
   */
  static Future<void> login(String email, String password) async {
    // Llama a Firebase para autenticar con email y password
    // login inicia sesión con email y contraseña usando Firebase Auth.
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  /**
   * Registra un nuevo usuario con correo y contraseña.
   * Lanza una excepción si el correo ya está en uso o la contraseña es débil.
   * @param email El correo electrónico del nuevo usuario.
   * @param password La contraseña del nuevo usuario.
   */
  static Future<void> register(String email, String password) async {
    // Llama a Firebase para crear un nuevo usuario
    // Comentario: register crea un nuevo usuario con email y contraseña.
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  /**
   * Inicia sesión con Google.
   * Si el usuario cancela el login de Google, no hace nada.
   * Si es exitoso, autentica con Firebase usando las credenciales de Google.
   */
  static Future<void> signInWithGoogle() async {
    // Abre el selector de cuentas de Google
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // El usuario canceló

    // Obtiene los tokens de autenticación de Google
    final googleAuth = await googleUser.authentication;

    // Crea las credenciales de Firebase a partir de los tokens de Google
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Inicia sesión en Firebase con las credenciales de Google
    // signInWithGoogle inicia sesión con Google y autentica en Firebase.
    await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
