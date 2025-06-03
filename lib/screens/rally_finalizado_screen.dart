/**
 * Pantalla que muestra los detalles de un rally finalizado.
 * Muestra la foto ganadora con la mayor puntuación promedio, el nombre del usuario ganador y el rally.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fotos_service.dart';
import '../services/voto_service.dart';

class RallyFinalizadoScreen extends StatelessWidget {
  // Datos del rally
  final Map<String, dynamic> rally;
  const RallyFinalizadoScreen({Key? key, required this.rally}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rallyId = rally['id'];
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
      // Botón retroceso fijo arriba a la izquierda, dentro de SafeArea
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 15),
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.deepPurple, size: 40),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      // Contenido centrado (card) en toda la pantalla sin que el botón afecte
      FutureBuilder<List<Map<String, dynamic>>>(
        future: FotosService.getFotosByRally(rallyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final fotos = snapshot.data?.where((foto) => foto['estado'] == 'aprobado').toList() ?? [];
          if (fotos.isEmpty) {
            return Center(
              child: Text(
                'No se registraron fotos en este rally.',
                style: TextStyle(fontSize: 20, color: Colors.deepPurple),
              ),
            );
          }

          Future<Map<String, dynamic>?> getGanadora() async {
            if (fotos.isEmpty) return null;
            Map<String, dynamic>? ganadora = fotos.first;
            double maxAvg = -1;
            for (final foto in fotos) {
              final avg = await VotosService.getAveragePuntuacion(foto['id']);
              if (avg > maxAvg) {
                maxAvg = avg;
                ganadora = foto;
                ganadora['avg'] = avg;
              }
            }
            // Si ninguna tiene votos, pon avg 0 a la primera
            if (ganadora != null && ganadora['avg'] == null) {
              ganadora['avg'] = 0.0;
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
                return Center(
                  child: Text(
                    'No se registraron fotos en este rally.',
                    style: TextStyle(fontSize: 20, color: Colors.deepPurple),
                  ),
                );
              }

              final fotoUrl = ganadora['foto'] ?? '';
              final username = ganadora['username'] ?? '';
              final avg = ganadora['avg'] ?? 0.0;

              // Aquí centramos el card en toda la pantalla (sin botón)
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Información del usuario ganador
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

// Comentario: RallyFinalizadoScreen muestra los resultados de un rally finalizado.
// - Obtiene las fotos aprobadas del rally usando FotosService.getFotosByRally.
// - Determina la foto ganadora calculando la mayor puntuación promedio con VotosService.getAveragePuntuacion.
// - Muestra la foto ganadora, el nombre del usuario, su foto de perfil, la puntuación promedio y el nombre del rally.
// - Incluye un botón para regresar a la pantalla anterior y un fondo decorativo.
// - Si no hay fotos aprobadas o votos, muestra un mensaje indicando que no se registraron fotos.