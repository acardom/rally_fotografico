/**
 * Pantalla principal del Rally Fotográfico.
 * Muestra un listado de rallies y permite ver detalles de cada uno.
 * @author Alberto Cárdeno
 */
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rally_service.dart';
import 'rally_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_tab.dart';
import 'galeria_screen.dart'; // <-- Añade esta línea
import 'rally_finalizado_screen.dart'; // <-- Añade esta línea


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // Listado de rallies
      Column(
        children: [
          // Buscador igual que en home_screen_admin
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
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: RallyService.getAllRallies(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay rallies disponibles.'));
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
                    final fechaFin = rally['fechaFin'] is Timestamp
                        ? (rally['fechaFin'] as Timestamp).toDate()
                        : rally['fechaFin'] is DateTime
                            ? rally['fechaFin'] as DateTime
                            : null;
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
      // Pantalla de perfil
      const GaleriaScreen(), 
      const ProfileTab(),
    ];

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
          screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Galería'), 
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
