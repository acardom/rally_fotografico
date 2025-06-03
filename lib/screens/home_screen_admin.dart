/**
 * Pantalla principal para administradores.
 * Muestra un buscador, botón para crear rallies, lista de rallies, gestión de fotos y usuarios, y perfil.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_tab.dart';
import 'users_screen_admin.dart';
import '../services/rally_service.dart';
import '../services/fotos_service.dart';
import 'crear_rally_screen.dart';
import 'revision_fotos_screen.dart';

class HomeScreenAdmin extends StatefulWidget {
  @override
  State<HomeScreenAdmin> createState() => _HomeScreenAdminState();
}

class _HomeScreenAdminState extends State<HomeScreenAdmin> {
  // Índice de la pestaña seleccionada en la barra de navegación inferior
  int _selectedIndex = 0;
  // Término de búsqueda para filtrar rallies
  String _search = '';

  /**
   * Refresca la lista de rallies actualizando el estado del widget.
   */
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Lista de pantallas para cada pestaña
    final List<Widget> screens = [
      // Pantalla principal: buscador, botón para crear rally y lista de rallies
      Stack(
        children: [
          // Fondo decorativo
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Buscador de rallies
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
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
                    setState(() {
                      _search = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              // Botón para crear un nuevo rally
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Crear nuevo rally'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CrearRallyScreen()),
                      );
                      if (result == true) _refresh();
                    },
                  ),
                ),
              ),
              // Lista de rallies
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: RallyService.getAllRallies(),
                  builder: (context, snapshot) {
                    // Muestra un indicador de carga mientras se obtienen los datos
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Muestra un mensaje si no hay rallies
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay rallies creados.'));
                    }
                    // Filtra rallies según el término de búsqueda
                    final rallies = snapshot.data!
                        .where((rally) =>
                            _search.isEmpty ||
                            (rally['nombre'] ?? '').toString().toLowerCase().contains(_search))
                        .toList();
                    // Muestra un mensaje si no hay coincidencias
                    if (rallies.isEmpty) {
                      return const Center(child: Text('No hay rallies para mostrar.'));
                    }
                    // Construye la lista de rallies
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: rallies.length,
                      itemBuilder: (context, index) {
                        final rally = rallies[index];
                        final foto = rally['foto'] as String? ?? '';
                        final nombre = rally['nombre'] ?? '';
                        final creadorUid = rally['uid'] ?? '';
                        final fechaFin = rally['fechaFin'] is Timestamp
                            ? (rally['fechaFin'] as Timestamp).toDate()
                            : rally['fechaFin'] is DateTime
                                ? rally['fechaFin'] as DateTime
                                : null;
                        final abierto = fechaFin == null ? false : fechaFin.isAfter(DateTime.now());
                        // Obtiene el nombre del creador
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .where('uid', isEqualTo: creadorUid)
                              .limit(1)
                              .get()
                              .then((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() as Map<String, dynamic> : null),
                          builder: (context, userSnap) {
                            final creadorUsername = userSnap.data?['username'] ?? creadorUid;
                            // Obtiene el número de fotos aprobadas
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: FotosService.getFotosByRally(rally['id']),
                              builder: (context, fotosSnap) {
                                final fotosAprobadas = fotosSnap.hasData
                                    ? fotosSnap.data!.where((f) => f['estado'] == 'aprobado').length
                                    : 0;
                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    child: Row(
                                      children: [
                                        // Muestra la foto del rally o un icono por defecto
                                        foto.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  foto,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  color: Colors.deepPurple.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(Icons.camera_alt, size: 36, color: Colors.deepPurple),
                                              ),
                                        const SizedBox(width: 16),
                                        // Información del rally
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nombre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Creador: $creadorUsername',
                                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                abierto ? 'Estado: Abierto' : 'Estado: Cerrado',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: abierto ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Fotos aprobadas: $fotosAprobadas',
                                                style: const TextStyle(fontSize: 13, color: Colors.black38),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Botón para borrar el rally
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                          tooltip: 'Borrar rally',
                                          onPressed: () async {
                                            // Muestra un diálogo de confirmación antes de borrar
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Borrar rally'),
                                                content: Text('¿Seguro que quieres borrar "$nombre"? Esta acción no se puede deshacer.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('Borrar', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              // Borra el rally y refresca la lista
                                              await RallyService.deleteRally(rally['id']);
                                              _refresh();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Rally "$nombre" borrado')),
                                              );
                                            }
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
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      // Pantalla de gestión de fotos
      RevisionFotosScreen(),
      // Pestaña de gestión de usuarios
      const UsersAdminTab(),
      // Pestaña de perfil del administrador
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: screens[_selectedIndex],
      // Barra de navegación inferior para cambiar entre pestañas
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Gestión'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// Comentario: HomeScreenAdmin es la pantalla principal para administradores.
// - Muestra un buscador para filtrar rallies por nombre.
// - Incluye un botón para crear un nuevo rally, que navega a CrearRallyScreen.
// - Lista todos los rallies con su foto, nombre, creador, estado (abierto/cerrado) y número de fotos aprobadas.
// - Permite borrar un rally tras confirmar mediante un diálogo.
// - Incluye pestañas para gestión de fotos (RevisionFotosScreen), usuarios (UsersAdminTab) y perfil (ProfileTab).
// - Usa RallyService para obtener y borrar rallies, y FotosService para contar fotos aprobadas.