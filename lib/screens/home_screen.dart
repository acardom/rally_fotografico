/**
 * Pantalla principal del Rally Fotográfico.
 * Muestra un listado de rallies filtrados por búsqueda, permite navegar a detalles de cada rally y acceder a galería y perfil.
 * Utiliza Firebase para obtener datos de rallies y navega entre pantallas mediante un BottomNavigationBar.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rally_service.dart';
import 'rally_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_tab.dart';
import 'galeria_screen.dart';
import 'rally_finalizado_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Índice de la pestaña seleccionada en el BottomNavigationBar
  int _selectedIndex = 0;
  // Término de búsqueda para filtrar rallies
  String _search = '';

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas para las pestañas de navegación
    final List<Widget> screens = [
      // Listado de rallies
      Column(
        children: [
          // Campo de búsqueda para filtrar rallies por nombre
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar rally...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // Actualiza el término de búsqueda y refresca la pantalla
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
            ),
          ),
          // Lista de rallies obtenida de forma asíncrona
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: RallyService.getAllRallies(),
              builder: (context, snapshot) {
                // Muestra un indicador de carga mientras se obtienen los datos
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Muestra un mensaje si no hay rallies disponibles
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay rallies disponibles.'));
                }
                // Filtra los rallies según el término de búsqueda
                final rallies = snapshot.data!
                    .where((rally) =>
                        _search.isEmpty ||
                        (rally['nombre'] ?? '').toString().toLowerCase().contains(_search))
                    .toList();
                // Muestra un mensaje si no hay coincidencias con la búsqueda
                if (rallies.isEmpty) {
                  return const Center(child: Text('No hay rallies para mostrar.'));
                }
                // Construye la lista de rallies
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: rallies.length,
                  itemBuilder: (context, index) {
                    final rally = rallies[index];
                    // Obtiene los datos del rally (foto, nombre, fecha de fin)
                    final foto = rally['foto'] as String? ?? '';
                    final nombre = rally['nombre'] ?? '';
                    final fechaFin = rally['fechaFin'] is Timestamp
                        ? (rally['fechaFin'] as Timestamp).toDate()
                        : rally['fechaFin'] is DateTime
                            ? rally['fechaFin'] as DateTime
                            : null;
                    // Determina si el rally ha finalizado
                    final finalizado = fechaFin != null && fechaFin.isBefore(DateTime.now());
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: SizedBox(
                        height: 110,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Imagen del rally o ícono por defecto
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: foto.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        foto,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 44, color: Colors.deepPurple),
                                    ),
                            ),
                            // Detalles del rally (nombre y fecha de fin)
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                subtitle: fechaFin != null
                                    ? Row(
                                        children: [
                                          Text('Finaliza: ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}'),
                                          if (finalizado)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                '(finalizado)',
                                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      )
                                    : null,
                                // Navega a la pantalla de detalles o finalizado según el estado del rally
                                onTap: () {
                                  if (finalizado) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RallyFinalizadoScreen(rally: rally),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RallyDetailScreen(rally: rally),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Pantalla de galería
      const GaleriaScreen(),
      // Pantalla de perfil
      const ProfileTab(),
    ];

    return Scaffold(
      // Fondo decorativo de la pantalla
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Muestra la pantalla seleccionada según el índice
          screens[_selectedIndex],
        ],
      ),
      // Barra de navegación inferior para cambiar entre pantallas
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Galería'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        // Actualiza la pantalla seleccionada al cambiar de pestaña
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// Comentario: HomeScreen es la pantalla principal de la aplicación.
// - Muestra un listado de rallies obtenidos de Firestore mediante RallyService.
// - Permite filtrar rallies por nombre usando un campo de búsqueda.
// - Cada rally muestra su nombre, foto y fecha de finalización, indicando si está finalizado.
// - Navega a RallyDetailScreen para rallies activos o RallyFinalizadoScreen para rallies terminados.
// - Incluye un BottomNavigationBar para alternar entre las pantallas de rallies, galería y perfil.