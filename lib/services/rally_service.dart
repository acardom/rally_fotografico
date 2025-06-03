/**
 * Servicio para gestión de rallies en Firestore.
 * Incluye funciones para guardar, consultar y validar datos de rally.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'fotos_service.dart';

class RallyService {
  static final _db = FirebaseFirestore.instance;

  /**
   * Guarda la información de un rally en la base de datos.
   * @param nombre El nombre del rally.
   * @param uid El ID del usuario que lo crea.
   * @param fechaFin La fecha de finalización del rally.
   * @param foto La URL de la foto del rally (opcional).
   * @return El ID generado del documento.
   */
  static Future<String> saveRallyData({
    required String nombre,
    required String uid,
    required DateTime fechaFin,
    String? foto,
  }) async {
    final docRef = await _db.collection('Rally').add({
      'nombre': nombre,
      'uid': uid,
      'fechaFin': fechaFin,
      'foto': foto ?? '',
    });
    return docRef.id;
  }

  /**
   * Obtiene la información de un rally por su ID.
   * @param rallyId El ID del rally.
   * @return Un mapa con los datos del rally, o null si no existe.
   */
  static Future<Map<String, dynamic>?> getRallyData(String rallyId) async {
    final doc = await _db.collection('Rally').doc(rallyId).get();
    return doc.exists ? doc.data() : null;
  }

  /**
   * Verifica si faltan datos obligatorios en el rally.
   * @param data Un mapa con los datos del rally.
   * @return true si faltan datos, false si toda la información necesaria está presente.
   */
  static bool needsExtraInfo(Map<String, dynamic>? data) {
    if (data == null) return true;
    return 
      (data['nombre'] == null || data['nombre'].toString().isEmpty) ||
      (data['uid'] == null || data['uid'].toString().isEmpty) ||
      (data['fechaFin'] == null);
  }

  /**
   * Obtiene la lista de todos los rallies.
   * @return Una lista de mapas con los datos de cada rally.
   */
  static Future<List<Map<String, dynamic>>> getAllRallies() async {
    final querySnapshot = await _db.collection('Rally').get();
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  /**
   * Borra un rally por su ID y su foto en Storage si existe.
   * También borra todas las fotos asociadas y sus votos.
   * @param rallyId El ID del rally.
   */
  static Future<void> deleteRally(String rallyId) async {
    final doc = await _db.collection('Rally').doc(rallyId).get();
    final data = doc.data();
    // 1. Borra la foto del rally si existe
    if (data != null && data['foto'] != null && data['foto'].toString().isNotEmpty) {
      final fotoUrl = data['foto'] as String;
      try {
        final ref = FirebaseStorage.instance.refFromURL(fotoUrl);
        await ref.delete();
      } catch (e) {
        // Si la foto no existe o no es una URL válida, ignora el error.
      }
    }
    // 2. Borra todas las fotos asociadas a este rally usando FotosService (que ya borra los votos)
    final fotosQuery = await _db.collection('Fotos').where('rid', isEqualTo: rallyId).get();
    for (final fotoDoc in fotosQuery.docs) {
      await FotosService.deleteFoto(fotoDoc.id);
    }
    // 3. Borra el rally
    await _db.collection('Rally').doc(rallyId).delete();
  }

  /**
   * Abre la galería para seleccionar una imagen y la devuelve como File.
   * @param context Contexto de la app.
   * @return File seleccionado o null.
   */
  static Future<File?> pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        return File(picked.path);
      }
      return null;
    } catch (e) {
      // Si ocurre un error con los plugins, muestra un mensaje.
      String msg = e.toString().contains('MissingPluginException')
          ? '' : 'No se pudo seleccionar la imagen: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return null;
    }
  }

  /**
   * Sube la imagen seleccionada a Firebase Storage y devuelve la URL.
   * @param context Contexto de la app.
   * @param image Archivo de imagen.
   * @return URL de la imagen subida o null.
   */
  static Future<String?> uploadImage(BuildContext context, File? image) async {
    if (image == null) return null;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('rallies/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}');
      final uploadTask = await storageRef.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo la imagen: $e')),
      );
      return null;
    }
  }

  /**
   * Guarda el rally en Firestore. Si no hay fecha, pone por defecto un día después de hoy.
   * @param context Contexto de la app.
   * @param formKey Clave del formulario.
   * @param nombreController Controlador del nombre.
   * @param fechaFin Fecha de finalización.
   * @param fotoFile Archivo de la foto.
   */
  static Future<void> saveRally(BuildContext context, GlobalKey<FormState> formKey, TextEditingController nombreController, DateTime? fechaFin, File? fotoFile) async {
    // Valida el formulario, si no es válido no continúa
    if (!formKey.currentState!.validate()) return;
    try {
      // Obtiene el UID del usuario actual
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      String? fotoUrl;
      // Si hay foto seleccionada, la sube a Storage y obtiene la URL
      if (fotoFile != null) {
        fotoUrl = await uploadImage(context, fotoFile);
      }
      // Guarda los datos del rally en Firestore usando el servicio
      await saveRallyData(
        nombre: nombreController.text.trim(),
        uid: uid,
        fechaFin: fechaFin ?? DateTime.now().add(Duration(days: 1)),
        foto: fotoUrl,
      );
      // Vuelve atrás y muestra mensaje de éxito
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rally creado correctamente')),
      );
    } catch (e) {
      // Si hay error de permisos o cualquier otro, muestra mensaje adecuado
      String msg = e.toString().contains('PERMISSION_DENIED')
          ? 'No tienes permisos para crear rallies.'
          : 'Error al crear rally: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  /**
   * Devuelve true si el rally ha finalizado (fechaFin < ahora).
   * @param rally Mapa con los datos del rally.
   * @return true si la fecha de fin es anterior a ahora.
   */
  static bool rallyFinished(Map<String, dynamic> rally) {
    final rallyFin = rally['fechaFin'];
    DateTime? fechaFin;
    if (rallyFin is Timestamp) {
      fechaFin = rallyFin.toDate();
    } else if (rallyFin is DateTime) {
      fechaFin = rallyFin;
    }
    return fechaFin != null && fechaFin.isBefore(DateTime.now());
  }
}

// Comentario: RallyService centraliza la gestión de rallies en Firestore y Storage.
// - Permite crear, consultar, listar y borrar rallies.
// - Gestiona la subida de imágenes y la eliminación de fotos asociadas.
// - Incluye utilidades para validar datos y comprobar si un rally ha finalizado.