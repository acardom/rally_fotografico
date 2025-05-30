/**
 * Pantalla de revisión de fotos para administradores.
 * Permite ver y gestionar las fotos subidas por los usuarios.
 * @author Alberto Cárdeno
 */
import 'package:flutter/material.dart';
import '../services/fotos_service.dart';
import '../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RevisionFotosScreen extends StatefulWidget {
  @override
  State<RevisionFotosScreen> createState() => _RevisionFotosScreenState();
}

class _RevisionFotosScreenState extends State<RevisionFotosScreen> {
  String? _selectedImageUrl;

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
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                itemCount: fotos.length,
                itemBuilder: (context, index) {
                  final foto = fotos[index];
                  final fotoUrl = foto['foto'] ?? '';
                  final username = foto['username'] ?? '';
                  final fotoId = foto['id'];
                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
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
          ),
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

// --- FotosService: añade este método ---
/*
static Future<List<Map<String, dynamic>>> getFotosByEstado(String estado) async {
  final querySnapshot = await _db.collection('Fotos')
    .where('estado', isEqualTo: estado)
    .get();
  return querySnapshot.docs
      .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
      .toList();
}
*/
