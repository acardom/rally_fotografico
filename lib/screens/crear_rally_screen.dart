/**
 * Pantalla para crear un nuevo rally.
 * Permite seleccionar una foto, introducir nombre y fecha de fin.
 * Sube la foto a Firebase Storage y guarda los datos en Firestore.
 * Si la fecha no se selecciona, se pone por defecto un día después de hoy.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import '../services/rally_service.dart';
import 'dart:io';

class CrearRallyScreen extends StatefulWidget {
  @override
  State<CrearRallyScreen> createState() => _CrearRallyScreenState();
}

class _CrearRallyScreenState extends State<CrearRallyScreen> {
  // Clave para el formulario de validación
  final _formKey = GlobalKey<FormState>();
  // Controlador para el campo de nombre del rally
  final _nombreController = TextEditingController();
  // Fecha de finalización seleccionada
  DateTime? _fechaFin;
  // Archivo de la foto seleccionada
  File? _fotoFile;
  // Indica si se está guardando (para mostrar el indicador de carga)
  bool _saving = false;
  // Controla si hay un error en la fecha de fin
  bool _fechaFinError = false;

  /**
   * Libera los recursos del controlador al destruir el widget.
   */
  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
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
          // Contenido desplazable centrado
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
                        // Título de la pantalla
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
                            // Abre la galería para seleccionar una imagen
                            final file = await RallyService.pickImage(context);
                            if (file != null) {
                              setState(() {
                                _fotoFile = file;
                              });
                            }
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
                        // Campo para el nombre del rally
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
                            // Abre un selector de fecha
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
                        // Espacio para mensaje de error en la fecha (si aplica)
                        if (_fechaFinError)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                          ),
                        const SizedBox(height: 32),
                        // Botón para guardar el rally
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
                            onPressed: _saving
                                ? null
                                : () async {
                                    // Guarda el rally usando RallyService
                                    setState(() => _saving = true);
                                    await RallyService.saveRally(context, _formKey, _nombreController, _fechaFin, _fotoFile);
                                    setState(() => _saving = false);
                                  },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Botón para cancelar y volver atrás
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

// Comentario: CrearRallyScreen permite a los administradores crear un nuevo rally.
// - Incluye un formulario para ingresar el nombre, seleccionar una foto y elegir una fecha de fin.
// - Usa RallyService para seleccionar la imagen y guardar los datos en Firestore.
// - Valida que el nombre no esté vacío y muestra un indicador de carga durante el guardado.
// - Si no se selecciona una fecha, RallyService asigna un día después de hoy por defecto.
// - Permite cancelar la operación, volviendo a la pantalla anterior sin guardar.