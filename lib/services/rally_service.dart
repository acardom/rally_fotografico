/**
 * Servicio para gestión de rallies en Firestore.
 * Incluye funciones para guardar, consultar y validar datos de rally.
 * @author Alberto Cárdeno
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'fotos_service.dart ';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/crear_rally_screen.dart';


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

  /// Borra un rally por su ID y su foto en Storage si existe.
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
}