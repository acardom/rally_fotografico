/**
 * Servicio para gestión de usuarios en Firestore.
 * Incluye funciones para guardar, consultar y validar datos de usuario.
 * @author Alberto Cárdeno
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  /**
   * Verifica si un usuario existe en la base de datos.
   * @param email El correo electrónico del usuario a verificar.
   * @return true si el usuario existe, false en caso contrario.
   */
  // Comentario: userExists comprueba si existe un usuario por email.
  static Future<bool> userExists(String email) async {
    final doc = await _db.collection('usuarios').doc(email).get();
    return doc.exists;
  }

  /**
   * Guarda la información del usuario en la base de datos.
   * @param uid El ID único del usuario.
   * @param email El correo electrónico del usuario.
   * @param nombre El nombre del usuario.
   * @param username El nombre de usuario elegido.
   * @param fechaNacimiento La fecha de nacimiento del usuario.
   * @param esAdmin Indica si el usuario tiene rol de administrador.
   * @param foto La URL de la foto de perfil del usuario (opcional).
   */
  // Comentario: saveUserData guarda o actualiza los datos del usuario en Firestore.
  static Future<void> saveUserData({
    required String uid,
    required String email,
    required String nombre,
    required String username,
    required DateTime fechaNacimiento,
    required bool esAdmin,
    String? foto,
  }) async {
    await _db.collection('usuarios').doc(email).set({
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'username': username,
      'fechaNacimiento': fechaNacimiento,
      'esAdmin': esAdmin,
      'foto': foto ?? '',
    });
  }

  /**
   * Obtiene la información del usuario desde la base de datos.
   * @param email El correo electrónico del usuario cuya información se desea obtener.
   * @return Un mapa con los datos del usuario, o null si el usuario no existe.
   */
  // Comentario: getUserData obtiene los datos del usuario desde Firestore.
  static Future<Map<String, dynamic>?> getUserData(String email) async {
    final doc = await _db.collection('usuarios').doc(email).get();
    return doc.exists ? doc.data() : null;
  }

  /**
   * Verifica si faltan datos adicionales del usuario en la base de datos.
   * @param data Un mapa con los datos del usuario.
   * @return true si faltan datos, false si toda la información necesaria está presente.
   */
  //needsExtraInfo valida si faltan datos obligatorios en el usuario.
  static bool needsExtraInfo(Map<String, dynamic>? data) {
    if (data == null) return true;
    return 
      (data['nombre'] == null || 
      data['nombre'].toString().isEmpty) ||
      (data['username'] == null || 
      data['username'].toString().isEmpty) ||
      (data['fechaNacimiento'] == null) ||
      (data['esAdmin'] == null);
  }
}
