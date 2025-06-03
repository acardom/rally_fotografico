/**
 * Widget para mostrar la galería propia de cada usuario con el estado de sus fotos.
 * Muestra fotos subidas por el usuario, su estado, y permite votar si están aprobadas.
 * Consulta fotos y votos desde Firestore.
 * @author Alberto Cárdeno Domínguez
 */

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
  // URL de la foto seleccionada para mostrar en grande
  String? _selectedFotoUrl;
  // ID de la foto seleccionada
  String? _selectedFotoId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Verifica si el usuario está autenticado
    if (user == null) {
      return const Center(child: Text('No has iniciado sesión.'));
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
          // Lista de fotos del usuario
          FutureBuilder<List<Map<String, dynamic>>>(
            future: FotosService.getFotosByUser(user.uid),
            builder: (context, snapshot) {
              // Muestra un indicador de carga mientras se obtienen las fotos
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final fotos = snapshot.data ?? [];
              // Muestra un mensaje si no hay fotos
              if (fotos.isEmpty) {
                return Center(
                  child: Text(
                    'No has subido fotos aún.',
                    style: TextStyle(fontSize: 18, color: Colors.deepPurple.shade700),
                  ),
                );
              }
              // Muestra las fotos en una cuadrícula
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
                    // Asigna colores según el estado de la foto
                    if (estado == 'revisando') estadoColor = Colors.amber;
                    if (estado == 'denegado') estadoColor = Colors.red;
                    return GestureDetector(
                      onTap: () {
                        // Selecciona la foto para mostrarla en grande
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
                          // Indicador de estado (círculo de color)
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
          // Vista ampliada de la foto seleccionada
          if (_selectedFotoUrl != null && _selectedFotoId != null)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: FotosService.getFotosByUser(FirebaseAuth.instance.currentUser!.uid),
              builder: (context, snapshot) {
                // Mientras carga, muestra solo la imagen ampliada
                if (snapshot.connectionState != ConnectionState.done) {
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
                // Encuentra los datos de la foto seleccionada
                final fotoData = fotos.firstWhere(
                  (f) => f['id'] == _selectedFotoId,
                  orElse: () => {},
                );
                final estado = fotoData['estado'] ?? '';
                final rallyId = fotoData['rid'] ?? '';
                // Obtiene el nombre del rally asociado
                return FutureBuilder<Map<String, dynamic>?>(
                  future: rallyId.isNotEmpty
                      ? FirebaseFirestore.instance.collection('Rally').doc(rallyId).get().then((doc) => doc.data())
                      : Future.value(null),
                  builder: (context, rallySnap) {
                    final rallyNombre = rallySnap.data?['nombre'] ?? '';
                    return GestureDetector(
                      onTap: () => setState(() {
                        // Cierra la vista ampliada al tocar fuera
                        _selectedFotoUrl = null;
                        _selectedFotoId = null;
                      }),
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            // Cierra la vista ampliada al tocar la imagen
                            _selectedFotoUrl = null;
                            _selectedFotoId = null;
                          }),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Imagen ampliada con altura máxima limitada y bordes redondeados
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                                  ),
                                  child: Image.network(
                                    _selectedFotoUrl!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Nombre del rally asociado
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
                              // Información según el estado de la foto
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
                                // Sistema de votación para fotos aprobadas
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
                                            // Estrellas para votar
                                            GestureDetector(
                                              onTapDown: (details) async {
                                                // Calcula la puntuación según la posición del toque
                                                final box = details.localPosition.dx;
                                                int star = (box / (28 + 4)).floor() + 1;
                                                if (star < 1) star = 1;
                                                if (star > 5) star = 5;
                                                // Guarda o actualiza el voto
                                                await VotosService.saveOrUpdateVoto(
                                                  fid: _selectedFotoId!,
                                                  uid: FirebaseAuth.instance.currentUser!.uid,
                                                  puntuacion: star,
                                                );
                                                // Refresca la interfaz
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
                                            // Puntuación promedio
                                            Text(
                                              avg.toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
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

// Comentario: GaleriaScreen muestra las fotos subidas por el usuario actual.
// - Obtiene las fotos usando FotosService.getFotosByUser.
// - Las muestra en una cuadrícula con un indicador de estado (revisando: ámbar, denegado: rojo).
// - Al tocar una foto, se muestra ampliada con el nombre del rally asociado y su estado.
// - Para fotos aprobadas, permite votar (1-5 estrellas) y muestra la puntuación promedio.
// - Usa VotosService para gestionar votos y puntuaciones.
// - La interfaz se refresca tras votar para actualizar la puntuación mostrada.