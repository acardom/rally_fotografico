/**
 * Pantalla de revisión de fotos para administradores.
 * Permite ver y gestionar las fotos subidas por los usuarios.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import '../services/fotos_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla principal para que los administradores revisen fotos pendientes.
class RevisionFotosScreen extends StatefulWidget {
  @override
  State<RevisionFotosScreen> createState() => _RevisionFotosScreenState();
}

class _RevisionFotosScreenState extends State<RevisionFotosScreen> {
  // URL de la imagen seleccionada para mostrar en grande
  String? _selectedImageUrl;

  /// Actualiza el estado de una foto ('aprobado' o 'denegado') en Firestore.
  Future<void> _updateEstadoFoto(String fotoId, String estado) async {
    await FirebaseFirestore.instance.collection('Fotos').doc(fotoId).update({'estado': estado});
    setState(() {}); // Refresca la pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // Imagen de fondo decorativa.
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          // FutureBuilder para cargar las fotos en estado 'revisando'.
          FutureBuilder<List<Map<String, dynamic>>>(
            future: FotosService.getFotosByEstado('revisando'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final fotos = snapshot.data ?? [];
              if (fotos.isEmpty) {
                return Center(
                  child: Text(
                    'No hay fotos pendientes de revisión.',
                    style: TextStyle(fontSize: 18, color: Colors.deepPurple.shade700),
                  ),
                );
              }
              // Listado de fotos pendientes
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
                itemCount: fotos.length,
                itemBuilder: (context, index) {
                  final foto = fotos[index];
                  final fotoUrl = foto['foto'] ?? '';
                  final username = foto['username'] ?? '';
                  final fotoId = foto['id'];
                  final rallyId = foto['rid']; // ID del rally
                  // FutureBuilder para obtener el nombre del rally
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Rally').doc(rallyId).get(),
                    builder: (context, rallySnapshot) {
                      String rallyNombre = '';
                      if (rallySnapshot.hasData && rallySnapshot.data != null && rallySnapshot.data!.exists) {
                        rallyNombre = rallySnapshot.data!.get('nombre') ?? '';
                      }
                      return Card(
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Imagen en miniatura, ampliable al pulsar
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImageUrl = fotoUrl;
                                  });
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    fotoUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Información de la foto: nombre del rally y usuario
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Rally nombre: grande, morado, negrita
                                    if (rallyNombre.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2.0),
                                        child: Text(
                                          rallyNombre,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    // Usuario: pequeño, negro
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Botones de aprobar y denegar
                              Column(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _updateEstadoFoto(fotoId, 'aprobado'),
                                    child: const Text('Aceptar'),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _updateEstadoFoto(fotoId, 'denegado'),
                                    child: const Text('Denegar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Si hay una imagen seleccionada, la muestra en grande en un overlay
          if (_selectedImageUrl != null)
            GestureDetector(
              onTap: () => setState(() => _selectedImageUrl = null),
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImageUrl = null),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _selectedImageUrl!,
                      width: MediaQuery.of(context).size.width * 0.85,
                      fit: BoxFit.contain,
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

// Comentario: RevisionFotosScreen permite a los administradores revisar y gestionar fotos pendientes.
// - Muestra una lista de fotos en estado 'revisando', con nombre del rally y usuario.
// - Permite aprobar o denegar cada foto con botones directos.
// - Al pulsar la miniatura, muestra la imagen en grande en un overlay.
// - Incluye fondo decorativo y diseño responsive.


