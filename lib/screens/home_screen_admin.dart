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
  int _selectedIndex = 0;
  String _search = '';

  // Refresca la lista tras borrar
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List<Widget> screens = [
      // Nueva pantalla principal de admin: buscador, botón crear y lista de rallies
      Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Buscador
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
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
              // Botón crear nuevo rally
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay rallies creados.'));
                    }
                    // Filtrar por búsqueda
                    final rallies = snapshot.data!
                        .where((rally) =>
                          _search.isEmpty ||
                          (rally['nombre'] ?? '').toString().toLowerCase().contains(_search)
                        )
                        .toList();
                    if (rallies.isEmpty) {
                      return const Center(child: Text('No hay rallies para mostrar.'));
                    }
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
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .where('uid', isEqualTo: creadorUid)
                              .limit(1)
                              .get()
                              .then((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() as Map<String, dynamic> : null),
                          builder: (context, userSnap) {
                            final creadorUsername = userSnap.data?['username'] ?? creadorUid;
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
                                        // Foto rally
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
                                        // Info rally
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
                                        // Botón borrar
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                          tooltip: 'Borrar rally',
                                          onPressed: () async {
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
      // Pantalla de gestión de fotos (nuevo apartado)
      RevisionFotosScreen(),
      // Pestaña de usuarios
      const UsersAdminTab(),
      // Pantalla de perfil
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // <-- Asegura que todos los botones se muestren y la animación sea normal
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