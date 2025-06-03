/**
 * Pantalla de detalle de un rally seleccionado.
 * Muestra todas las fotos del rally en cards estilo Instagram.
 * Permite votar con estrellas y subir una foto si no has participado.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fotos_service.dart';
import '../services/user_service.dart';
import '../services/voto_service.dart';
import '../services/rally_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Pantalla principal de detalle de un rally.
class RallyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rally;
  const RallyDetailScreen({Key? key, required this.rally}) : super(key: key);

  @override
  State<RallyDetailScreen> createState() => _RallyDetailScreenState();
}

class _RallyDetailScreenState extends State<RallyDetailScreen> {
  late String rallyId;
  late String currentUid;
  bool _hasFoto = false;
  String _search = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    rallyId = widget.rally['id'];
    currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _checkUserFoto();
  }

  /// Comprueba si el usuario ya ha subido una foto a este rally.
  /// @author Alberto Cárdeno Domínguez
  Future<void> _checkUserFoto() async {
    final hasFoto = await FotosService.userHasFotoInRally(rallyId, currentUid);
    setState(() {
      _hasFoto = hasFoto;
    });
  }

  /// Permite al usuario subir una foto al rally si no ha finalizado.
  /// @author Alberto Cárdeno Domínguez
  void _onAddPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (RallyService.rallyFinished(widget.rally)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes subir fotos a un rally finalizado.')),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    String? fotoUrl;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('fotos_rally/${rallyId}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
      await storageRef.putFile(File(picked.path));
      fotoUrl = await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo la foto: $e')),
      );
      return;
    }

    try {
      final userData = await UserService.getUserData(user.email ?? '');
      final username = userData?['username'] ?? '';
      await FotosService.saveFotoData(
        rid: rallyId,
        uid: user.uid,
        estado: 'revisando',
        foto: fotoUrl,
        username: username,
      );
      setState(() {
        _hasFoto = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida correctamente. Queda pendiente de revisión.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando la foto: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nombreRally = widget.rally['nombre'] ?? '';
    final bool puedeSubirFoto = !_hasFoto && !RallyService.rallyFinished(widget.rally);
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
          // Columna principal: barra superior y listado de fotos
          Column(
            children: [
              // Barra superior: flecha atrás y buscador por username
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 60, 20, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 40),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Buscar por usuario...',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _search = value.trim().toLowerCase();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Listado de fotos del rally
              Expanded(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: FotosService.getFotosByRally(rallyId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final fotos = snapshot.data ?? [];
                      // Filtra solo fotos aprobadas y por búsqueda de usuario
                      final filteredFotos = fotos.where((foto) =>
                        (foto['estado'] == 'aprobado') &&
                        (_search.isEmpty || (foto['username'] ?? '').toString().toLowerCase().contains(_search))
                      ).toList();

                      // Elimina el filtro que ocultaba tus propias fotos
                      final finalFotos = filteredFotos;

                      if (finalFotos.isEmpty) {
                        return Center(
                          child: Text(
                            'No hay fotos para mostrar.',
                            style: TextStyle(fontSize: 18, color: Colors.deepPurple.shade700),
                          ),
                        );
                      }
                      // Lista de fotos estilo Instagram
                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(12, 0, 12, puedeSubirFoto ? 80 : 20),
                        itemCount: finalFotos.length,
                        itemBuilder: (context, index) {
                          final foto = finalFotos[index];
                          final fotoUrl = foto['foto'] as String? ?? '';
                          final uid = foto['uid'] ?? '';
                          final username = foto['username'] ?? '';
                          final fotoId = foto['id'];
                          // Obtiene datos del usuario para mostrar avatar
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: UserService.getUserDataByUid(uid),
                            builder: (context, userSnap) {
                              final userData = userSnap.data;
                              final userFoto = userData?['foto'] as String? ?? '';
                              return Card(
                                elevation: 6,
                                margin: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Arriba: avatar y username
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          if (userFoto.isNotEmpty)
                                            CircleAvatar(
                                              backgroundImage: NetworkImage(userFoto),
                                              radius: 22,
                                            )
                                          else
                                            const CircleAvatar(
                                              radius: 22,
                                              child: Icon(Icons.person, size: 22),
                                            ),
                                          const SizedBox(width: 8),
                                          // Username al lado del avatar
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Foto principal
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final width = constraints.maxWidth;
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              fotoUrl,
                                              width: width,
                                              height: width,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      // Estrellas de votación y media
                                      StatefulBuilder(
                                        builder: (context, setLocalState) {
                                          return FutureBuilder<int>(
                                            future: VotosService.getUserVoto(fotoId, currentUid),
                                            builder: (context, userVoteSnap) {
                                              final userVote = userVoteSnap.data ?? 0;
                                              return FutureBuilder<double>(
                                                future: VotosService.getAveragePuntuacion(fotoId),
                                                builder: (context, avgSnap) {
                                                  final avg = avgSnap.data ?? 0.0;
                                                  return Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTapDown: (details) async {
                                                          final box = details.localPosition.dx;
                                                          int star = (box / (28 + 4)).floor() + 1;
                                                          if (star < 1) star = 1;
                                                          if (star > 5) star = 5;
                                                          await VotosService.votePhoto(
                                                            context: context,
                                                            fotoId: fotoId,
                                                            stars: star,
                                                          );
                                                          setLocalState(() {}); // Solo recarga este widget
                                                        },
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: List.generate(5, (i) {
                                                            return Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 2),
                                                              child: Icon(
                                                                Icons.star,
                                                                color: (i + 1) <= userVote ? Colors.amber : Colors.grey[400],
                                                                size: 28,
                                                              ),
                                                            );
                                                          }),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        avg.toStringAsFixed(2),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.deepPurple,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
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
                ),
              ),
            ],
          ),
          // Botón para subir foto (solo si no tiene ya una foto y el rally no ha finalizado)
          if (puedeSubirFoto)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.deepPurple,
                  onPressed: _onAddPhoto,
                  child: const Icon(Icons.add, size: 36, color: Colors.white),
                  tooltip: 'Subir foto al rally',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Comentario: RallyDetailScreen muestra el detalle de un rally activo o finalizado.
// - Permite ver todas las fotos aprobadas del rally en formato de tarjetas tipo Instagram.
// - Incluye buscador por nombre de usuario en la parte superior.
// - Permite votar cada foto con estrellas y ver la media de votos en tiempo real.
// - Si el usuario no ha subido foto y el rally no ha finalizado, puede subir una nueva foto.
// - Muestra el avatar y username del autor de cada foto.
// - El fondo es decorativo y el diseño es responsive.
