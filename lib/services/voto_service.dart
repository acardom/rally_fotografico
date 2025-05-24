import 'package:cloud_firestore/cloud_firestore.dart';

class VotosService {
  static final _db = FirebaseFirestore.instance;

  /// Guarda o actualiza el voto de un usuario para una foto
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

  /// Obtiene la puntuación promedio de una foto
  static Future<double> getAveragePuntuacion(String fid) async {
    final query = await _db.collection('Votos')
      .where('Fid', isEqualTo: fid)
      .get();

    if (query.docs.isEmpty) return 0.0;

    final total = query.docs.fold<int>(0, (sum, doc) => sum + (doc['Puntuacion'] as int));
    return total / query.docs.length;
  }

  /// Obtiene el voto de un usuario para una foto (si existe)
  static Future<int?> getUserVoto(String fid, String uid) async {
    final query = await _db.collection('Votos')
      .where('Fid', isEqualTo: fid)
      .where('Uid', isEqualTo: uid)
      .limit(1)
      .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first['Puntuacion'] as int;
    }
    return null;
  }
}