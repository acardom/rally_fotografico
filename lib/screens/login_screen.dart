/**
 * Pantalla de inicio de sesión y registro.
 * Permite autenticación por email/contraseña y Google.
 * @author Alberto Cárdeno
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'extra_info_flow.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLogin = true;
  String? _registerError;

  /**
   * Maneja la autenticación del usuario, ya sea por email/contraseña o Google.
   * @param authMethod Método de autenticación a ejecutar.
   * @param isGoogle Indica si la autenticación es por Google.
   */
  Future<void> _handleAuth(Function authMethod, {bool isGoogle = false}) async {
    try {
      await authMethod();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final email = user.email;
      if (email == null) return;
      final userData = await UserService.getUserData(email);
      final needsExtra = UserService.needsExtraInfo(userData);
      if (needsExtra) {
        final googlePhoto = isGoogle ? user.photoURL : null;
        final googleName = isGoogle ? user.displayName : null;
        final completed = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExtraInfoFlow(user: user, googlePhotoUrl: googlePhoto, googleDisplayName: googleName),
          ),
        );
        if (completed != true) {
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quita backgroundColor para usar imagen de fondo
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Contenido principal centrado
          Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.deepPurple),
                      const SizedBox(height: 16),
                      Text(
                        isLogin ? 'Inicia sesión en Rally Fotográfico' : 'Crea tu cuenta',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                        obscureText: true,
                      ),
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          decoration: InputDecoration(labelText: 'Repite la contraseña', border: OutlineInputBorder()),
                          obscureText: true,
                        ),
                      ],
                      if (_registerError != null) ...[
                        const SizedBox(height: 12),
                        Text(_registerError!, style: TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white, // Fuerza el texto blanco
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          if (isLogin) {
                            await _handleAuth(() => AuthService.login(emailController.text, passwordController.text));
                          } else {
                            if (passwordController.text != confirmPasswordController.text) {
                              setState(() => _registerError = 'Las contraseñas no coinciden');
                              return;
                            }
                            setState(() => _registerError = null);
                            await _handleAuth(() => AuthService.register(emailController.text, passwordController.text));
                          }
                        },
                        child: Text(isLogin ? 'Entrar' : 'Registrarse', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
                      ),
                      const Divider(height: 40),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _handleAuth(() => AuthService.signInWithGoogle(), isGoogle: true);
                        },
                        icon: Icon(
                          Icons.account_circle, // Icono redondo para simular Google
                          color: Colors.white,
                          size: 28,
                        ),
                        label: Text('Entrar con Google', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Comentario: LoginScreen permite al usuario iniciar sesión o registrarse.
// Comentario: _handleAuth gestiona el flujo tras login/registro, mostrando el flujo extra si es necesario.
// Comentario: Botón para login/registro y Google Sign-In.
