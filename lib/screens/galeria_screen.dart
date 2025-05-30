import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fotos_service.dart';
import '../services/voto_service.dart';

class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({Key? key}) : super(key: key);

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  String? _selectedFotoUrl;
  String? _selectedFotoId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No has iniciado sesión.'));
    }

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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: FotosService.getFotosByUser(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final fotos = snapshot.data ?? [];
              if (fotos.isEmpty) {
                return Center(
                  child: Text(
                    'No has subido fotos aún.',
                    style: TextStyle(fontSize: 18, color: Colors.deepPurple.shade700),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 fotos por fila
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: fotos.length,
                  itemBuilder: (context, index) {
                    final foto = fotos[index];
                    final fotoUrl = foto['foto'] ?? '';
                    final estado = foto['estado'] ?? '';
                    final fotoId = foto['id'];
                    Color? estadoColor;
                    if (estado == 'revisando') estadoColor = Colors.amber;
                    if (estado == 'denegado') estadoColor = Colors.red;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFotoUrl = fotoUrl;
                          _selectedFotoId = fotoId;
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 3), // Borde blanco
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fotoUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          if (estadoColor != null)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: estadoColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (_selectedFotoUrl != null && _selectedFotoId != null)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: FotosService.getFotosByUser(FirebaseAuth.instance.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  // Mientras carga, solo muestra la imagen grande (sin valoración ni texto)
                  return Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _selectedFotoUrl!,
                        width: MediaQuery.of(context).size.width * 0.85,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }
                final fotos = snapshot.data ?? [];
                final fotoData = fotos.firstWhere(
                  (f) => f['id'] == _selectedFotoId,
                  orElse: () => {},
                );
                final estado = fotoData['estado'] ?? '';
                final rallyId = fotoData['rid'] ?? '';
                return FutureBuilder<Map<String, dynamic>?>(
                  future: rallyId.isNotEmpty
                      ? FirebaseFirestore.instance.collection('Rally').doc(rallyId).get().then((doc) => doc.data())
                      : Future.value(null),
                  builder: (context, rallySnap) {
                    final rallyNombre = rallySnap.data?['nombre'] ?? '';
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedFotoUrl = null;
                        _selectedFotoId = null;
                      }),
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedFotoUrl = null;
                            _selectedFotoId = null;
                          }),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _selectedFotoUrl!,
                                  width: MediaQuery.of(context).size.width * 0.85,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (rallyNombre.isNotEmpty)
                                Text(
                                  'Rally: $rallyNombre',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (estado == 'revisando' || estado == 'denegado')
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    estado == 'revisando'
                                        ? 'Tu foto está en revisión'
                                        : 'Tu foto ha sido denegada',
                                    style: TextStyle(
                                      color: estado == 'revisando' ? Colors.amber : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                )
                              else
                                FutureBuilder<int>(
                                  future: VotosService.getUserVoto(_selectedFotoId!, FirebaseAuth.instance.currentUser!.uid).then((v) => v ?? 0),
                                  builder: (context, userVoteSnap) {
                                    final userVote = userVoteSnap.data ?? 0;
                                    return FutureBuilder<double>(
                                      future: VotosService.getAveragePuntuacion(_selectedFotoId!),
                                      builder: (context, avgSnap) {
                                        final avg = avgSnap.data ?? 0.0;
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTapDown: (details) async {
                                                final box = details.localPosition.dx;
                                                int star = (box / (28 + 4)).floor() + 1;
                                                if (star < 1) star = 1;
                                                if (star > 5) star = 5;
                                                await VotosService.saveOrUpdateVoto(
                                                  fid: _selectedFotoId!,
                                                  uid: FirebaseAuth.instance.currentUser!.uid,
                                                  puntuacion: star,
                                                );
                                                setState(() {});
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
                                                color: Colors.white, // Nota media en blanco
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
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
