/**
 * Pantalla de detalle de un rally seleccionado.
 * Muestra todas las fotos del rally en cards estilo Instagram.
 * Permite votar con estrellas y subir una foto si no has participado.
 * @author Alberto Cárdeno
 */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fotos_service.dart';
import '../services/user_service.dart';
import '../services/voto_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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

  @override
  void initState() {
    super.initState();
    rallyId = widget.rally['id'];
    currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _checkUserFoto();
  }

  Future<void> _checkUserFoto() async {
    final hasFoto = await FotosService.userHasFotoInRally(rallyId, currentUid);
    setState(() {
      _hasFoto = hasFoto;
    });
  }

  Future<void> _votePhoto(String fotoId, int stars) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await VotosService.saveOrUpdateVoto(
        fid: fotoId,
        uid: user.uid,
        puntuacion: stars,
      );
      setState(() {});
    } catch (e) {
      // Solo muestra el mensaje si NO es un error de permisos
      if (!e.toString().toLowerCase().contains('permission-denied')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al votar: $e')),
        );
      }
      // Si es error de permisos, no mostrar nada
    }
  }

  Future<int> _getUserVote(String fotoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    try {
      final voto = await VotosService.getUserVoto(fotoId, user.uid);
      return voto ?? 0;
    } catch (e) {
      // Si no tienes permisos, muestra un mensaje solo una vez
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para ver/votar.')),
        );
      }
      return 0;
    }
  }

  Future<double> _getAverageVote(String fotoId) async {
    try {
      return await VotosService.getAveragePuntuacion(fotoId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para ver/votar.')),
        );
      }
      return 0.0;
    }
  }

  Future<Map<String, dynamic>?> _getUserDataByUid(String uid) async {
    return await UserService.getUserDataByUid(uid);
  }

  void _onAddPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // No permitir subir si el rally ha finalizado
    final rallyFin = widget.rally['fechaFin'];
    DateTime? fechaFin;
    if (rallyFin is Timestamp) {
      fechaFin = rallyFin.toDate();
    } else if (rallyFin is DateTime) {
      fechaFin = rallyFin;
    }
    if (fechaFin != null && fechaFin.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes subir fotos a un rally finalizado.')),
      );
      return;
    }
    // Selecciona imagen
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    // Sube imagen a Firebase Storage
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

    // Guarda en Firestore
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
  Widget build(BuildContext context) {
    final nombreRally = widget.rally['nombre'] ?? '';
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Barra superior: flecha atrás y buscador por username
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 36, 14, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 28),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: FotosService.getFotosByRally(rallyId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final fotos = snapshot.data ?? [];
                      // Filtrar por username y solo fotos aprobadas
                      final filteredFotos = fotos.where((foto) =>
                        (foto['estado'] == 'aprobado') &&
                        (_search.isEmpty ||
                        (foto['username'] ?? '').toString().toLowerCase().contains(_search))
                      ).toList();
                      if (filteredFotos.isEmpty) {
                        return Center(
                          child: Text(
                            'No hay fotos para mostrar.',
                            style: TextStyle(fontSize: 18, color: Colors.deepPurple.shade700),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        itemCount: filteredFotos.length,
                        itemBuilder: (context, index) {
                          final foto = filteredFotos[index];
                          final fotoUrl = foto['foto'] as String? ?? '';
                          final uid = foto['uid'] ?? '';
                          final username = foto['username'] ?? '';
                          final fotoId = foto['id'];
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _getUserDataByUid(uid),
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
                                      // Arriba derecha: foto perfil y username
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
                                      FutureBuilder<int>(
                                        future: _getUserVote(fotoId),
                                        builder: (context, userVoteSnap) {
                                          final userVote = userVoteSnap.data ?? 0;
                                          return FutureBuilder<double>(
                                            future: _getAverageVote(fotoId),
                                            builder: (context, avgSnap) {
                                              final avg = avgSnap.data ?? 0.0;
                                              return Row(
                                                children: [
                                                  GestureDetector(
                                                    onTapDown: (details) async {
                                                      final box = details.localPosition.dx;
                                                      // El ancho total de las estrellas (5*28 + 4*4 = 148)
                                                      // Calcula la estrella clicada
                                                      int star = (box / (28 + 4)).floor() + 1;
                                                      if (star < 1) star = 1;
                                                      if (star > 5) star = 5;
                                                      await _votePhoto(fotoId, star);
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
          if (!_hasFoto &&
              !(widget.rally['fechaFin'] is DateTime
                  ? widget.rally['fechaFin'].isBefore(DateTime.now())
                  : widget.rally['fechaFin'] is Timestamp
                      ? (widget.rally['fechaFin'] as Timestamp).toDate().isBefore(DateTime.now())
                      : false))
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
