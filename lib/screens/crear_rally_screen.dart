/**
 * Pantalla para crear un nuevo rally.
 * Permite seleccionar una foto, introducir nombre y fecha de fin.
 * Sube la foto a Firebase Storage y guarda los datos en Firestore.
 * Si la fecha no se selecciona, se pone por defecto un día después de hoy.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rally_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class CrearRallyScreen extends StatefulWidget {
  @override
  State<CrearRallyScreen> createState() => _CrearRallyScreenState();
}

class _CrearRallyScreenState extends State<CrearRallyScreen> {
  // Clave para el formulario
  final _formKey = GlobalKey<FormState>();
  // Controlador para el campo de nombre
  final _nombreController = TextEditingController();
  // Fecha de fin seleccionada
  DateTime? _fechaFin;
  // Archivo de la foto seleccionada
  File? _fotoFile;
  // Estado de guardado (para mostrar loading)
  bool _saving = false;
  // Controla si hay error en la fecha
  bool _fechaFinError = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  /// Abre la galería para seleccionar una imagen y la guarda en _fotoFile.
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _fotoFile = File(picked.path);
        });
      }
    } catch (e) {
      // Si ocurre un error con los plugins, muestra un mensaje.
      String msg = e.toString().contains('MissingPluginException')
          ? '' : 'No se pudo seleccionar la imagen: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  /// Sube la imagen seleccionada a Firebase Storage y devuelve la URL.
  Future<String?> _uploadImage(File? image) async {
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

  /// Guarda el rally en Firestore. Si no hay fecha, pone por defecto un día después de hoy.
  Future<void> _guardarRally() async {
    // Valida el formulario, si no es válido no continúa
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // Obtiene el UID del usuario actual
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      String? fotoUrl;
      // Si hay foto seleccionada, la sube a Storage y obtiene la URL
      if (_fotoFile != null) {
        fotoUrl = await _uploadImage(_fotoFile);
      }
      // Guarda los datos del rally en Firestore usando el servicio
      await RallyService.saveRallyData(
        nombre: _nombreController.text.trim(),
        uid: uid,
        fechaFin: _fechaFin!,
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
    } finally {
      // Quita el estado de guardando
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Título
                        Text(
                          'Crear nuevo rally',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Selector de foto
                        GestureDetector(
                          onTap: () async {
                            await _pickImage();
                          },
                          child: _fotoFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _fotoFile!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.add_a_photo, size: 48, color: Colors.deepPurple),
                                ),
                        ),
                        const SizedBox(height: 20),
                        // Campo de nombre del rally
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre rally',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Campo nombre no puede estar vacio' : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Selector de fecha de fin
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_fechaFin == null
                              ? 'Selecciona fecha de fin'
                              : 'Fecha de fin: ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: DateTime(now.year + 5),
                            );
                            if (picked != null) setState(() {
                              _fechaFin = picked;
                              _fechaFinError = false;
                            });
                          },
                        ),
                        if (_fechaFinError)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                          ),
                        const SizedBox(height: 32),
                        // Botón guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _saving
                                ? const SizedBox(
                                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save, color: Colors.white),
                            label: const Text('Guardar rally'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _saving ? null : _guardarRally,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Botón cancelar
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.deepPurple),
                            label: const Text('Cancelar', style: TextStyle(color: Colors.deepPurple)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.deepPurple),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
