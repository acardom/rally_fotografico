import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fotos_service.dart';
import '../services/voto_service.dart';

class RallyFinalizadoScreen extends StatelessWidget {
  final Map<String, dynamic> rally;
  const RallyFinalizadoScreen({Key? key, required this.rally}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rallyId = rally['id'];
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
            future: FotosService.getFotosByRally(rallyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final fotos = snapshot.data?.where((foto) => foto['estado'] == 'aprobado').toList() ?? [];
              if (fotos.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 36, 14, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No se registraron fotos en este rally.',
                          style: TextStyle(fontSize: 20, color: Colors.deepPurple),
                        ),
                      ),
                    ),
                  ],
                );
              }
              // Buscar la foto ganadora (mayor media de votos)
              Future<Map<String, dynamic>?> getGanadora() async {
                double maxAvg = -1;
                Map<String, dynamic>? ganadora;
                for (final foto in fotos) {
                  final avg = await VotosService.getAveragePuntuacion(foto['id']);
                  if (avg > maxAvg) {
                    maxAvg = avg;
                    ganadora = foto;
                    ganadora!['avg'] = avg;
                  }
                }
                return ganadora;
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: getGanadora(),
                builder: (context, winnerSnap) {
                  if (winnerSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final ganadora = winnerSnap.data;
                  if (ganadora == null) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 36, 14, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 28),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No se registraron fotos en este rally.',
                              style: TextStyle(fontSize: 20, color: Colors.deepPurple),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  final fotoUrl = ganadora['foto'] ?? '';
                  final username = ganadora['username'] ?? '';
                  final avg = ganadora['avg'] ?? 0.0;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 36, 14, 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 28),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Ajuste: usar Spacer para centrar verticalmente el Card
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Fila: foto de perfil redonda y username a la derecha
                                FutureBuilder<Map<String, dynamic>?>(
                                  future: FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .where('username', isEqualTo: username)
                                      .limit(1)
                                      .get()
                                      .then((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() : null),
                                  builder: (context, userSnap) {
                                    final userData = userSnap.data;
                                    final userFoto = userData?['foto'] as String? ?? '';
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.start, // <-- alineación a la izquierda
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
                                        const SizedBox(width: 10),
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                // Foto ganadora (tamaño grande, no tocar)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    fotoUrl,
                                    width: 320,
                                    height: 320,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Nota media
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 28),
                                    const SizedBox(width: 6),
                                    Text(
                                      avg.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                // Ganador del rally y nombre del rally
                                Text(
                                  'Ganador del rally',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rally['nombre'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
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
