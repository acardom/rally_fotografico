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
import 'package:firebase_auth/firebase_auth.dart';

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
    );
  }
}

/**
 * Widget que determina qué pantalla mostrar
 * según el estado de autenticación del usuario.
 */
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se determina el estado de conexión, se muestra un indicador de carga.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Si el usuario está autenticado, se muestra la pantalla principal.
        if (snapshot.hasData) {
          return HomeScreen();
        }
        // Si no hay datos de usuario, se muestra la pantalla de inicio de sesión.
        return LoginScreen();
      },
    );
  }
}

// Comentario: main() inicializa Firebase y lanza la app principal.
// Comentario: MyApp es el widget raíz de la aplicación.
// Comentario: AuthGate decide si mostrar HomeScreen o LoginScreen según el estado de autenticación.
