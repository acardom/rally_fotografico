/**
 * Pantalla principal del Rally Fotográfico.
 * Controla el acceso según si el usuario tiene datos completos en Firestore.
 * @author Alberto Cárdeno
 */
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'extra_info_flow.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Indica si se está comprobando el estado del usuario
  bool _checking = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkUserData(); // Al iniciar, comprobamos los datos del usuario
  }

  /// Comprueba si el usuario tiene todos los datos requeridos en Firestore
  Future<void> _checkUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    print('[DEBUG] Usuario autenticado: [32m[1m[4m${user?.email}[0m');
    if (user == null) {
      print('[ERROR] No hay usuario autenticado.');
      setState(() => _checking = false);
      return;
    }
    final email = user.email;
    if (email == null) {
      print('[ERROR] El usuario autenticado no tiene email.');
      setState(() => _checking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: El usuario no tiene email.')),
        );
      }
      await FirebaseAuth.instance.signOut();
      return;
    }
    print('[DEBUG] Buscando documento en Firestore para: $email');
    try {
      final userData = await UserService.getUserData(email);
      print('[DEBUG] Datos obtenidos de Firestore: $userData');
      final needsExtra = UserService.needsExtraInfo(userData);
      print('[DEBUG] ¿Necesita datos extra?: $needsExtra');
      // Si faltan datos, mostramos la pantalla para completarlos
      if (needsExtra) {
        print('[DEBUG] Mostrando pantalla de información extra para $email');
        if (mounted) {
          final completed = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExtraInfoFlow(
                  user: user,
                  googlePhotoUrl: user.photoURL,
                  googleDisplayName: user.displayName),
            ),
          );
          // Si el usuario no completa la info, cerramos sesión
          if (completed != true) {
            print('[DEBUG] El usuario no completó la información extra. Cerrando sesión.');
            await FirebaseAuth.instance.signOut();
          }
        }
      }
    } catch (e, st) {
      print('[ERROR] Error al consultar Firestore: ' + e.toString());
      print(st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al consultar Firestore: $e')),
        );
      }
      await FirebaseAuth.instance.signOut();
    }
    if (mounted) setState(() => _checking = false);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List<Widget> screens = [
      // Pantalla principal
      Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  'Pantalla principal del Rally',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                ),
              ],
            ),
          ),
        ),
      ),
      // Pantalla de perfil
      Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Perfil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
    if (_checking) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PerfilScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Perfil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
