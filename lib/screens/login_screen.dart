/**
 * Pantalla de inicio de sesión y registro.
 * Permite autenticación por email/contraseña y Google.
 * Incluye imagen de fondo y validación de datos.
 * 
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'extra_info_flow.dart';

/// Widget principal de login y registro.
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto.
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Estado para alternar entre login y registro.
  bool isLogin = true;
  String? _registerError;

  // Estados de error para cada campo y para login general
  String? _loginError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Valida el formato del email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Valida la contraseña (mínimo 6 caracteres)
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  /**
   * Maneja la autenticación del usuario, ya sea por email/contraseña o Google.
   * Si falta información extra, lanza el flujo correspondiente para completarla.
   * Si el usuario no completa la información extra, se cierra el sesión.
   * 
   * @author Alberto Cárdeno Domínguez
   */
  Future<void> _handleAuth(Function authMethod, {bool isGoogle = false}) async {
    try {
      // Ejecuta el método de autenticación (login, registro o Google).
      await authMethod();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final email = user.email;
      if (email == null) return;
      // Obtiene los datos del usuario desde Firestore.
      final userData = await UserService.getUserData(email);
      // Comprueba si necesita completar información extra.
      final needsExtra = UserService.needsExtraInfo(userData);
      if (needsExtra) {
        // Si es Google, pasa foto y nombre de Google.
        final googlePhoto = isGoogle ? user.photoURL : null;
        final googleName = isGoogle ? user.displayName : null;
        // Navega al flujo de información extra.
        final completed = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExtraInfoFlow(user: user, googlePhotoUrl: googlePhoto, googleDisplayName: googleName),
          ),
        );
        // Si no completa la info, cierra sesión.
        if (completed != true) {
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      // Muestra error en un SnackBar si ocurre algún problema.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Imagen de fondo usando Stack.
      body: Stack(
        children: [
          // Imagen de fondo decorativa.
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Card centrada con el formulario de login/registro.
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
                      // Icono de cámara y título.
                      // Icon(Icons.auto_awesome_motion_rounded, size: 48, color: Colors.deepPurple),
                      Image.asset(
                        'lib/assets/Logo.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isLogin ? 'Inicia sesión' : 'Crea tu cuenta',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 24),
                      // Campo de email.
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          errorText: _emailError,
                        ),
                        onChanged: (_) {
                          if (!isLogin) setState(() => _emailError = null);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo de contraseña.
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          // Solo muestra errorText en registro, no en el if de abajo
                          errorText: !isLogin ? _passwordError : null,
                        ),
                        obscureText: true,
                        onChanged: (_) {
                          if (!isLogin) setState(() => _passwordError = null);
                        },
                      ),
                      // Elimina este bloque duplicado para evitar mostrar el error dos veces
                      // if (!isLogin && _passwordError != null) ...[
                      //   const SizedBox(height: 4),
                      //   Align(
                      //     alignment: Alignment.centerLeft,
                      //     child: Text(
                      //       _passwordError!,
                      //       style: const TextStyle(color: Colors.red, fontSize: 13),
                      //     ),
                      //   ),
                      // ],
                      // Campo de repetir contraseña solo en registro.
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Repite la contraseña',
                            border: OutlineInputBorder(),
                            errorText: _confirmPasswordError,
                          ),
                          obscureText: true,
                          onChanged: (_) => setState(() => _confirmPasswordError = null),
                        ),
                        
                      ],
                      // Mensaje de error general en login
                      if (isLogin && _loginError != null) ...[
                        const SizedBox(height: 12),
                        Text(_loginError!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),
                      // Botón principal de login o registro.
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white, // Fuerza el texto blanco
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          setState(() {
                            _loginError = null;
                            _emailError = null;
                            _passwordError = null;
                            _confirmPasswordError = null;
                          });

                          if (isLogin) {
                            // Validación de campos vacíos
                            if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                              setState(() => _loginError = 'Falta información');
                              return;
                            }
                            // Intentar login y mostrar error si no lo hace
                            await _handleAuth(() => AuthService.login(emailController.text, passwordController.text));
                            setState(() => _loginError = 'Datos no válidos');
                            
                          } else {
                            // Validación de email
                            if (!_isValidEmail(emailController.text)) {
                              setState(() => _emailError = 'Formato no válido');
                            }
                            // Validación de contraseña
                            if (!_isValidPassword(passwordController.text)) {
                              setState(() => _passwordError = 'La contraseña debe tener al menos 6 caracteres');
                            }
                            // Validación de confirmación de contraseña
                            if (passwordController.text != confirmPasswordController.text) {
                              setState(() => _confirmPasswordError = 'Las contraseñas no coinciden');
                            }
                            // Si hay errores, no continuar
                            if (_emailError != null || _passwordError != null || _confirmPasswordError != null) {
                              return;
                            }
                            // Intentar registro
                            try {
                              await _handleAuth(() => AuthService.register(emailController.text, passwordController.text));
                            } catch (e) {
                              // Puedes agregar manejo de error de registro aquí si lo deseas
                            }
                          }
                        },
                        child: Text(isLogin ? 'Entrar' : 'Registrarse', style: TextStyle(color: Colors.white)),
                      ),
                      // Botón para alternar entre login y registro.
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            // Limpia los campos y errores al alternar
                            emailController.clear();
                            passwordController.clear();
                            confirmPasswordController.clear();
                            _loginError = null;
                            _emailError = null;
                            _passwordError = null;
                            _confirmPasswordError = null;
                          });
                        },
                        child: Text(isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
                      ),
                      const Divider(height: 40),
                      // Botón de login con Google.
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _handleAuth(() => AuthService.signInWithGoogle(), isGoogle: true);
                        },
                        icon: Icon(
                          Icons.account_circle, 
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
