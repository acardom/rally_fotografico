/**
 * Pantalla mostrada cuando el usuario está bloqueado.
 * Permite cerrar sesión o eliminar la cuenta completamente (de Auth y Firestore).
 * Incluye fondo personalizado y botones de acción.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import '../services/user_service.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Contenido centrado
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
                    // Icono de bloqueo
                    Icon(Icons.block, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    // Título indicando el estado de bloqueo
                    const Text(
                      'Fuiste bloqueado',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mensaje explicativo
                    const Text(
                      'No puedes acceder a la aplicación.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botón para cerrar sesión
                        ElevatedButton.icon(
                          icon: const Icon(Icons.exit_to_app, color: Colors.white),
                          label: const Text('Salir', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          onPressed: () => UserService.signOut(context),
                        ),
                        const SizedBox(width: 14),
                        // Botón para eliminar la cuenta
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text('Eliminar cuenta', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => UserService.deleteAccountAndSignOut(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Comentario: BlockedScreen se muestra cuando un usuario está bloqueado.
// - Presenta un mensaje claro indicando que el acceso está restringido.
// - Incluye un fondo decorativo y una tarjeta centrada con un icono de bloqueo.
// - Ofrece dos opciones: cerrar sesión (usando UserService.signOut) o eliminar la cuenta completamente (usando UserService.deleteAccountAndSignOut).
// - No permite otras acciones, limitando la interacción del usuario bloqueado.