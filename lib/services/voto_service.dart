/**
 * Servicio para gestión de votos en Firestore.
 * Incluye funciones para guardar, consultar y eliminar votos de fotos.
 * Permite votar, obtener el voto de un usuario, la media de votos y borrar votos de una foto.
 * @author Alberto Cárdeno
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VotosService {
  static final _db = FirebaseFirestore.instance;

  /**
   * Guarda o actualiza el voto de un usuario para una foto.
   * Si ya existe, actualiza la puntuación; si no, crea el voto.
   * @param fid ID de la foto.
   * @param uid ID del usuario.
   * @param puntuacion Valor de la puntuación.
   */
  static Future<void> saveOrUpdateVoto({
    required String fid,
    required String uid,
    required int puntuacion,
  }) async {
    final query = await _db.collection('Votos')
      .where('Fid', isEqualTo: fid)
      .where('Uid', isEqualTo: uid)
      .limit(1)
      .get();

    if (query.docs.isNotEmpty) {
      // Si ya existe, actualiza la puntuación
      await _db.collection('Votos').doc(query.docs.first.id).update({
        'Puntuacion': puntuacion,
      });
    } else {
      // Si no existe, crea el voto
      await _db.collection('Votos').add({
        'Fid': fid,
        'Uid': uid,
        'Puntuacion': puntuacion,
      });
    }
  }

  /**
   * Vota una foto con estrellas, muestra error en SnackBar si ocurre.
   * Utiliza el usuario autenticado actual.
   * @param context Contexto.
   * @param fotoId ID de la foto.
   * @param stars Número de estrellas.
   */
  static Future<void> votePhoto({
    required BuildContext context,
    required String fotoId,
    required int stars,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await saveOrUpdateVoto(
        fid: fotoId,
        uid: user.uid,
        puntuacion: stars,
      );
    } catch (e) {
      if (!e.toString().toLowerCase().contains('permission-denied')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al votar: $e')),
        );
      }
    }
  }

  /**
   * Obtiene el voto de un usuario para una foto (si existe), devuelve 0 si error.
   * @param fid ID de la foto.
   * @param uid ID del usuario.
   * @return Puntuación o 0.
   */
  static Future<int> getUserVoto(String fid, String uid) async {
    try {
      final query = await _db.collection('Votos')
        .where('Fid', isEqualTo: fid)
        .where('Uid', isEqualTo: uid)
        .limit(1)
        .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first['Puntuacion'] as int;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /**
   * Obtiene la puntuación promedio de una foto, devuelve 0.0 si error.
   * @param fid ID de la foto.
   * @return Media de puntuación.
   */
  static Future<double> getAveragePuntuacion(String fid) async {
    try {
      final query = await _db.collection('Votos')
        .where('Fid', isEqualTo: fid)
        .get();

      if (query.docs.isEmpty) return 0.0;

      final total = query.docs.fold<int>(0, (sum, doc) => sum + (doc['Puntuacion'] as int));
      return total / query.docs.length;
    } catch (e) {
      return 0.0;
    }
  }

  /**
   * Borra todos los votos asociados a una foto por su Fid.
   * @param fid ID de la foto.
   */
  static Future<void> deleteVotosByFotoId(String fid) async {
    final query = await _db.collection('Votos').where('Fid', isEqualTo: fid).get();
    for (final doc in query.docs) {
      await _db.collection('Votos').doc(doc.id).delete();
    }
  }
}

// Comentario: VotosService centraliza la gestión de votos en Firestore.
// - Permite votar, consultar el voto de un usuario y la media de votos de una foto.
// - Permite borrar todos los votos asociados a una foto.
// - Gestiona errores y feedback visual en la app.