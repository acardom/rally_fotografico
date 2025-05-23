/**
 * Punto de entrada principal de la app Rally Fotográfico.
 * Inicializa Firebase y gestiona la autenticación y navegación principal.
 * @author Alberto Cárdeno
 */

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/home_screen_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';
import 'screens/blocked_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

/**
 * Clase principal de la aplicación.
 * Configura el tema y la pantalla de inicio según el estado de autenticación del usuario.
 */
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rally Fotos',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: AuthGate(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/homeAdmin': (_) => HomeScreenAdmin(),
      },
    );
  }
}

/**
 * Widget que determina qué pantalla mostrar
 * según el estado de autenticación del usuario.
 */
class AuthGate extends StatelessWidget {
  Future<Map<String, dynamic>?> _getUserData(User user) async {
    return await UserService.getUserData(user.email ?? '');
  }

  Future<bool> _isAdmin(Map<String, dynamic>? userData) async {
    return userData != null && userData['esAdmin'] == true;
  }

  Future<bool> _isBanned(Map<String, dynamic>? userData) async {
    return userData != null && userData['areBaned'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(user),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userSnapshot.hasError) {
                return Scaffold(body: Center(child: Text('Error al cargar usuario')));
              }
              final userData = userSnapshot.data;
              // Si está bloqueado, muestra la pantalla de bloqueado
              if (userData != null && userData['areBaned'] == true) {
                return const BlockedScreen();
              }
              // Si es admin, HomeScreenAdmin. Si no, HomeScreen (aunque no exista el campo)
              if (userData != null && userData['esAdmin'] == true) {
                return HomeScreenAdmin();
              } else {
                return HomeScreen();
              }
            },
          );
        }
        return LoginScreen();
      },
    );
  }
}

// Comentario: main() inicializa Firebase y lanza la app principal.
// Comentario: MyApp es el widget raíz de la aplicación.
// Comentario: AuthGate decide si mostrar HomeScreen o LoginScreen según el estado de autenticación.
