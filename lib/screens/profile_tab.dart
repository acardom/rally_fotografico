/**
 * Pantalla de perfil de usuario.
 * Permite ver y editar el perfil, cambiar contraseña, borrar cuenta y cerrar sesión.
 * 
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Variables de estado para los datos del usuario
  String? _fotoUrl;
  String? _username;
  String? _email;
  String? _uid;
  bool _loading = true;
  bool _editingUsername = false;
  final _usernameController = TextEditingController();
  bool _isEmailPasswordUser = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isEmailPasswordUser = user.providerData.any((p) => p.providerId == 'password');
    }
  }

  /// Carga los datos del usuario desde Firestore usando UserService.
  /// @author Alberto Cárdeno Domínguez
  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await UserService.getUserData(user.email ?? '');
    setState(() {
      _fotoUrl = data?['foto'] as String?;
      _username = data?['username'] as String?;
      _email = data?['email'] as String?;
      _uid = data?['uid'] as String?;
      _usernameController.text = _username ?? '';
      _loading = false;
    });
  }

  /// Permite seleccionar y subir una nueva foto de perfil usando UserService.
  /// @author Alberto Cárdeno Domínguez
  Future<void> _pickAndUploadPhoto() async {
    await UserService.pickAndUploadPhoto(context, _fotoUrl, (url) {
      setState(() {
        _fotoUrl = url;
      });
    });
  }

  /// Habilita la edición del nombre de usuario.
  /// @author Alberto Cárdeno Domínguez
  Future<void> _editUsername() async {
    setState(() => _editingUsername = true);
  }

  /// Guarda el nuevo nombre de usuario usando UserService.
  /// @author Alberto Cárdeno Domínguez
  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;
    if (newUsername == _username) {
      setState(() => _editingUsername = false);
      return;
    }
    await UserService.saveUsername(
      context,
      newUsername,
      _username,
      _email,
      (updatedUsername, editing) {
        setState(() {
          _username = updatedUsername;
          _editingUsername = editing;
        });
      },
    );
  }

  // Añade variables para mostrar errores en los campos de contraseña
  String? _passwordError;
  String? _repeatPasswordError;

  /// Muestra un diálogo para cambiar la contraseña del usuario autenticado.
  /// @author Alberto Cárdeno Domínguez
  Future<void> _changePasswordDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newPasswordController = TextEditingController();
    final repeatPasswordController = TextEditingController();
    String? newPasswordError;
    String? repeatPasswordError;
    String? generalError;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      errorText: (newPasswordError != null && newPasswordError!.isNotEmpty) ? newPasswordError : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: repeatPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Repetir contraseña',
                      errorText: (repeatPasswordError != null && repeatPasswordError!.isNotEmpty) ? repeatPasswordError : null,
                    ),
                  ),
                  if (generalError != null && generalError!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, left: 2),
                        child: Text(
                          generalError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    setStateDialog(() {
                      newPasswordError = null;
                      repeatPasswordError = null;
                      generalError = null;
                    });
                    final newPass = newPasswordController.text.trim();
                    final repeatPass = repeatPasswordController.text.trim();

                    if (newPass.isEmpty) {
                      setStateDialog(() => newPasswordError = 'Obligatorio');
                      return;
                    }
                    if (newPass.length < 6) {
                      setStateDialog(() => newPasswordError = 'Debe tener al menos 6 caracteres');
                      return;
                    }
                    if (repeatPass.isEmpty) {
                      setStateDialog(() => repeatPasswordError = 'Obligatorio');
                      return;
                    }
                    if (newPass == _email) {
                      setStateDialog(() => newPasswordError = 'La contraseña no puede ser igual al email');
                      return;
                    }
                    if (newPass != repeatPass) {
                      setStateDialog(() => repeatPasswordError = 'Las contraseñas no coinciden');
                      return;
                    }
                    try {
                      await user.updatePassword(newPass);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contraseña actualizada')),
                      );
                    } catch (e) {
                      setStateDialog(() => generalError = 'Error: $e');
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Elimina la cuenta del usuario y todos sus datos asociados usando UserService.
  /// @author Alberto Cárdeno Domínguez
  Future<void> _deleteAccount() async {
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
      await UserService.deleteAccount(user, _email, _fotoUrl);
      // Cierra sesión y navega fuera
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  // Avatar de usuario con opción de editar
                  Stack(
                    children: [
                      _fotoUrl != null && _fotoUrl!.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(_fotoUrl!),
                              radius: 80, 
                            )
                          : const CircleAvatar(
                              radius: 80,
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.person, size: 108, color: Colors.white),
                            ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.deepPurple, width: 2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.edit, color: Colors.deepPurple, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card con datos y acciones
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Username editable
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _editingUsername
                                  ? SizedBox(
                                      width: 140,
                                      child: TextField(
                                        controller: _usernameController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _username ?? '',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _editingUsername ? _saveUsername : _editUsername,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    _editingUsername ? Icons.check : Icons.edit,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Cambiar contraseña (solo si es usuario email/password)
                          if (_isEmailPasswordUser)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.lock, color: Colors.deepPurple),
                                label: const Text('Cambiar contraseña'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _changePasswordDialog,
                              ),
                            ),
                          if (_isEmailPasswordUser) const SizedBox(height: 12),
                          // Borrar cuenta
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Borrar cuenta', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _deleteAccount,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Cerrar sesión
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout, color: Colors.deepPurple),
                              label: const Text('Cerrar sesión', style: TextStyle(color: Colors.deepPurple)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.deepPurple, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Comentario: ProfileTab permite al usuario gestionar su perfil.
// - Muestra el avatar, username y opciones de edición.
// - Permite cambiar la foto de perfil y el nombre de usuario usando UserService.
// - Permite cambiar la contraseña si es usuario email/password.
// - Permite borrar la cuenta y cerrar sesión.
// - Incluye fondo decorativo y diseño responsive.
