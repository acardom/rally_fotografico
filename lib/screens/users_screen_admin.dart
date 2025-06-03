/**
 * Pantalla de administración de usuarios.
 * Permite buscar, bloquear y desbloquear usuarios.
 * Los administradores no aparecen en el listado.
 * Incluye buscador con lupa y fondo personalizado.
 * 
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

/// Widget principal de la pestaña de administración de usuarios.
/// Ahora es Stateful para soportar el buscador.
class UsersAdminTab extends StatefulWidget {
  const UsersAdminTab({super.key});

  @override
  State<UsersAdminTab> createState() => _UsersAdminTabState();
}

class _UsersAdminTabState extends State<UsersAdminTab> {
  // Texto de búsqueda
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // Imagen de fondo decorativa.
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Columna principal: buscador + listado de usuarios.
          Column(
            children: [
              // Buscador con icono de lupa.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar usuario...',
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
              // Listado de usuarios (filtrado y actualizado en tiempo real).
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No hay usuarios registrados.'));
                    }
                    // Filtra usuarios: excluye admins y aplica búsqueda.
                    final users = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      // Oculta todos los usuarios con esAdmin == true
                      if (data['esAdmin'] == true) return false;
                      // Filtro de búsqueda (nombre, username o email)
                      if (_search.isEmpty) return true;
                      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                      final username = (data['username'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return nombre.contains(_search) ||
                          username.contains(_search) ||
                          email.contains(_search);
                    }).toList();
                    if (users.isEmpty) {
                      return const Center(child: Text('No hay usuarios para mostrar.'));
                    }
                    // ListView de usuarios
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index].data() as Map<String, dynamic>;
                        final foto = user['foto'] as String? ?? '';
                        final nombre = user['nombre'] ?? '';
                        final username = user['username'] ?? '';
                        final email = user['email'] ?? '';
                        final uid = user['uid'] ?? '';
                        final areBaned = user['areBaned'] == true;
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Row(
                              children: [
                                // Avatar del usuario (foto o icono por defecto)
                                Stack(
                                  children: [
                                    foto.isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(foto),
                                            radius: 28,
                                          )
                                        : const CircleAvatar(
                                            child: Icon(Icons.person, size: 28),
                                            radius: 28,
                                          ),
                                    // Icono visual si el usuario está bloqueado
                                    if (areBaned)
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Icon(Icons.block, color: Colors.red, size: 24),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Información del usuario
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          // Distintivo visual si está bloqueado
                                          if (areBaned)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8.0),
                                              child: Text(
                                                '(Bloqueado)',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '($username)',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Botón de bloquear/desbloquear
                                IconButton(
                                  icon: Icon(
                                    areBaned ? Icons.lock_open : Icons.block,
                                    color: areBaned ? Colors.green : Colors.red,
                                    size: 28,
                                  ),
                                  tooltip: areBaned ? 'Desbloquear usuario' : 'Bloquear usuario',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(areBaned ? 'Desbloquear usuario' : 'Bloquear usuario'),
                                        content: Text(
                                          areBaned
                                              ? '¿Seguro que quieres desbloquear a $nombre?'
                                              : '¿Seguro que quieres bloquear a $nombre?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text(
                                              areBaned ? 'Desbloquear' : 'Bloquear',
                                              style: TextStyle(color: areBaned ? Colors.green : Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await UserService.setBanStatus(email, !areBaned);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            areBaned ? 'Usuario desbloqueado' : 'Usuario bloqueado',
                                          ),
                                        ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Comentario: UsersAdminTab permite a los administradores gestionar usuarios.
// - Muestra todos los usuarios no administradores en una lista con buscador.
// - Permite buscar por nombre, usuario o email en tiempo real.
// - Permite bloquear o desbloquear usuarios con confirmación y feedback visual.
// - Muestra un icono y texto si el usuario está bloqueado.
// - Incluye fondo decorativo y diseño responsive.