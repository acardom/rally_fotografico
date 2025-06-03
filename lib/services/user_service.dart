/**
 * Servicio para gestión de usuarios en Firestore.
 * Incluye funciones para guardar, consultar y validar datos de usuario.
 * @author Alberto Cárdeno
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'fotos_service.dart';
import 'package:rally_fotografico/screens/login_screen.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  /**
   * Comprueba si existe un usuario por email.
   * @param email Email del usuario.
   * @return true si existe, false si no.
   */
  static Future<bool> userExists(String email) async {
    final doc = await _db.collection('usuarios').doc(email).get();
    return doc.exists;
  }

  /**
   * Guarda los datos del usuario en Firestore.
   * @param uid ID de usuario.
   * @param email Email.
   * @param nombre Nombre.
   * @param username Nombre de usuario.
   * @param fechaNacimiento Fecha de nacimiento.
   * @param esAdmin Si es admin.
   * @param areBaned Si está baneado.
   * @param foto URL de la foto.
   */
  static Future<void> saveUserData({
    required String uid,
    required String email,
    required String nombre,
    required String username,
    required DateTime fechaNacimiento,
    required bool esAdmin,
    required bool areBaned,
    String? foto,
  }) async {
    await _db.collection('usuarios').doc(email).set({
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'username': username,
      'fechaNacimiento': fechaNacimiento,
      'esAdmin': esAdmin,
      'areBaned': areBaned,
      'foto': foto ?? '',
    });
  }

  /**
   * Obtiene los datos de un usuario por email.
   * @param email Email del usuario.
   * @return Mapa con los datos o null.
   */
  static Future<Map<String, dynamic>?> getUserData(String email) async {
    final doc = await _db.collection('usuarios').doc(email).get();
    return doc.exists ? doc.data() : null;
  }

  /**
   * Obtiene los datos de un usuario por UID.
   * @param uid UID del usuario.
   * @return Mapa con los datos o null.
   */
  static Future<Map<String, dynamic>?> getUserDataByUid(String uid) async {
    final query = await _db.collection('usuarios').where('uid', isEqualTo: uid).limit(1).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  /**
   * Comprueba si faltan datos obligatorios en el usuario.
   * @param data Mapa de datos.
   * @return true si faltan datos, false si está completo.
   */
  static bool needsExtraInfo(Map<String, dynamic>? data) {
    if (data == null) return true;
    return 
      (data['nombre'] == null || 
      (data['nombre'] as String).isEmpty) ||
      (data['username'] == null || 
      (data['username'] as String).isEmpty) ||
      data['fechaNacimiento'] == null ||
      data['esAdmin'] == null ||
      data['areBaned'] == null;
  }

  /**
   * Comprueba si existe un username en la base de datos.
   * @param username Nombre de usuario.
   * @return true si existe, false si no.
   */
  static Future<bool> usernameExists(String username) async {
    final query = await _db.collection('usuarios')
      .where('username', isEqualTo: username)
      .limit(1)
      .get();
    return query.docs.isNotEmpty;
  }

  /**
   * Cambia el estado de bloqueo de un usuario.
   * @param email Email del usuario.
   * @param ban true para bloquear, false para desbloquear.
   */
  static Future<void> setBanStatus(String email, bool ban) async {
    await _db.collection('usuarios').doc(email).update({'areBaned': ban});
  }

  /**
   * Carga los datos del usuario actual y ejecuta un callback para actualizar el estado.
   * @param context Contexto.
   * @param updateState Callback para actualizar el estado.
   */
  static Future<void> loadUser(BuildContext context, Function(Map<String, dynamic>) updateState) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await getUserData(user.email ?? '');
    updateState({
      'fotoUrl': data?['foto'] as String?,
      'username': data?['username'] as String?,
      'email': data?['email'] as String?,
      'uid': data?['uid'] as String?,
      'loading': false,
    });
  }

  /**
   * Permite seleccionar y subir una nueva foto de perfil.
   * @param context Contexto.
   * @param currentFotoUrl URL actual de la foto.
   * @param updateState Callback para actualizar la foto.
   */
  static Future<void> pickAndUploadPhoto(BuildContext context, String? currentFotoUrl, Function(String?) updateState) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      if (currentFotoUrl != null && currentFotoUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(currentFotoUrl).delete();
        } catch (_) {}
      }
      await FirebaseFirestore.instance.collection('usuarios').doc(user.email).update({'foto': url});
      updateState(url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
    }
  }

  /**
   * Habilita la edición del nombre de usuario.
   * @param enableEditing Callback para habilitar la edición.
   */
  static void editUsername(Function() enableEditing) {
    enableEditing();
  }

  /**
   * Guarda el nuevo nombre de usuario si es válido y no está repetido.
   * @param context Contexto.
   * @param newUsername Nuevo username.
   * @param currentUsername Username actual.
   * @param email Email del usuario.
   * @param updateState Callback para actualizar el estado.
   */
  static Future<void> saveUsername(BuildContext context, String newUsername, String? currentUsername, String? email, Function(String, bool) updateState) async {
    if (newUsername.isEmpty) return;
    if (newUsername == currentUsername) {
      updateState(newUsername, false);
      return;
    }
    final exists = await usernameExists(newUsername);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese nombre de usuario ya existe')),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('usuarios').doc(email).update({'username': newUsername});
    updateState(newUsername, false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre de usuario actualizado')));
  }

  /**
   * Muestra un diálogo de confirmación y elimina la cuenta del usuario.
   * @param context Contexto.
   * @param email Email del usuario.
   * @param fotoUrl URL de la foto.
   */
  static Future<void> confirmAndDeleteAccount(BuildContext context, String? email, String? fotoUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar cuenta'),
        content: const Text('¿Seguro que quieres borrar tu cuenta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await deleteAccount(user, email, fotoUrl);
      await FirebaseAuth.instance.signOut();
    }
  }

  /**
   * Elimina la cuenta del usuario y todos sus datos asociados.
   * @param user Usuario de Firebase.
   * @param email Email.
   * @param fotoUrl URL de la foto.
   */
  static Future<void> deleteAccount(User user, String? email, String? fotoUrl) async {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(fotoUrl).delete();
      } catch (_) {}
    }
    if (user.uid.isNotEmpty) {
      final fotos = await FotosService.getFotosByUser(user.uid);
      for (final foto in fotos) {
        await FotosService.deleteFoto(foto['id']);
      }
    }
    if (email != null && email.isNotEmpty) {
      await FirebaseFirestore.instance.collection('usuarios').doc(email).delete();
    }
    await user.delete();
  }

  /**
   * Elimina la cuenta y cierra sesión.
   * @param context Contexto.
   */
  static Future<void> deleteAccountAndSignOut(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final email = user.email;
    try {
      if (email != null && email.isNotEmpty) {
        await FirebaseFirestore.instance.collection('usuarios').doc(email).delete();
      }
      await user.delete();
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la cuenta: $e')),
      );
    }
  }

  /**
   * Cierra la sesión del usuario.
   * @param context Contexto.
   */
  static Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// Comentario: UserService centraliza la gestión de usuarios en Firestore y Storage.
// - Permite crear, consultar, editar y borrar usuarios.
// - Gestiona la subida y borrado de fotos de perfil y la edición de username.
// - Permite bloquear/desbloquear usuarios y eliminar cuentas completamente.