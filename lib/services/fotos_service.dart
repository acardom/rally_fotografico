/**
 * Servicio para gestión de fotos en Firestore.
 * Incluye funciones para guardar, consultar y validar datos de fotos.
 * @author Alberto Cárdeno
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class FotosService {
  static final _db = FirebaseFirestore.instance;

  /**
   * Guarda la información de una foto en la base de datos.
   * @param rid El ID del rally.
   * @param uid El ID del usuario que sube la foto.
   * @param estado Estado de la foto (denegado, aprobado, revisando).
   * @param foto URL de la foto.
   * @param username Nombre de usuario que sube la foto.
   * @return El ID generado del documento.
   */
  static Future<String> saveFotoData({
    required String rid,
    required String uid,
    required String estado,
    required String foto,
    required String username,
  }) async {
    final docRef = await _db.collection('Fotos').add({
      'rid': rid,
      'uid': uid,
      'estado': estado,
      'foto': foto,
      'username': username,
    });
    return docRef.id;
  }

  /**
   * Obtiene la información de una foto por su ID.
   * @param fotoId El ID de la foto.
   * @return Un mapa con los datos de la foto, o null si no existe.
   */
  static Future<Map<String, dynamic>?> getFotoData(String fotoId) async {
    final doc = await _db.collection('Fotos').doc(fotoId).get();
    return doc.exists ? doc.data() : null;
  }

  /**
   * Verifica si un usuario ya subió una foto en un rally.
   * @param rid El ID del rally.
   * @param uid El ID del usuario.
   * @return true si ya existe una foto, false en caso contrario.
   */
  static Future<bool> userHasFotoInRally(String rid, String uid) async {
    final query = await _db.collection('Fotos')
      .where('rid', isEqualTo: rid)
      .where('uid', isEqualTo: uid)
      .limit(1)
      .get();
    return query.docs.isNotEmpty;
  }

  /**
   * Obtiene todas las fotos de un rally.
   * @param rid El ID del rally.
   * @return Una lista de mapas con los datos de cada foto.
   */
  static Future<List<Map<String, dynamic>>> getFotosByRally(String rid) async {
    final querySnapshot = await _db.collection('Fotos')
      .where('rid', isEqualTo: rid)
      .get();
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

    /**
   * Obtiene todas las fotos subidas por un usuario.
   * @param uid El ID del usuario.
   * @return Una lista de mapas con los datos de cada foto.
   */
  static Future<List<Map<String, dynamic>>> getFotosByUser(String uid) async {
    final querySnapshot = await _db.collection('Fotos')
      .where('uid', isEqualTo: uid)
      .get();
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  /**
   * Verifica si faltan datos obligatorios en la foto.
   * @param data Un mapa con los datos de la foto.
   * @return true si faltan datos, false si toda la información necesaria está presente.
   */
  static bool needsExtraInfo(Map<String, dynamic>? data) {
    if (data == null) return true;
    return
      (data['rid'] == null || data['rid'].toString().isEmpty) ||
      (data['uid'] == null || data['uid'].toString().isEmpty) ||
      (data['estado'] == null || data['estado'].toString().isEmpty) ||
      (data['foto'] == null || data['foto'].toString().isEmpty) ||
      (data['username'] == null || data['username'].toString().isEmpty);
  }
}