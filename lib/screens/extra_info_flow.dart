/**
 * Widget para el flujo de información extra del usuario tras el registro/login.
 * Solicita nombre, usuario, fecha de nacimiento y si es admin.
 * @author Alberto Cárdeno Domínguez
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'home_screen_admin.dart';
import '../main.dart'; // Añade esta importación para usar AuthGate

class ExtraInfoScreen extends StatelessWidget {
  final User user;
  final String? googlePhotoUrl;
  final String? googleDisplayName;
  const ExtraInfoScreen({required this.user, this.googlePhotoUrl, this.googleDisplayName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtraInfoFlow(
      user: user,
      googlePhotoUrl: googlePhotoUrl,
      googleDisplayName: googleDisplayName,
      key: key,
      // Al finalizar, navega a la pantalla principal
    );
  }
}

class ExtraInfoFlow extends StatefulWidget {
  final User user;
  final String? googlePhotoUrl;
  final String? googleDisplayName;
  const ExtraInfoFlow({required this.user, this.googlePhotoUrl, this.googleDisplayName, Key? key}) : super(key: key);

  @override
  State<ExtraInfoFlow> createState() => _ExtraInfoFlowState();
}

class _ExtraInfoFlowState extends State<ExtraInfoFlow> {
  final _usernameController = TextEditingController();
  final _nombreController = TextEditingController();
  DateTime? _fechaNacimiento;
  bool _esAdmin = false;
  bool _areBaned = false;
  int _step = 0;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    if (widget.googleDisplayName != null) {
      _nombreController.text = widget.googleDisplayName!;
    }
  }

  /// Avanza al siguiente paso del flujo
  /// @author Alberto Cárdeno Domínguez
  Future<void> _nextStep() async {
    if (_step == 1) {
      // Validar username antes de pasar al siguiente paso
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        setState(() {
          _usernameError = 'El nombre de usuario es obligatorio.';
        });
        return;
      }
      final exists = await UserService.usernameExists(username);
      if (exists) {
        setState(() {
          _usernameError = 'El nombre de usuario ya está en uso. Elige otro.';
        });
        return;
      }
      setState(() {
        _usernameError = null;
      });
    }
    setState(() {
      _step++;
    });
  }

  /// Retrocede al paso anterior del flujo
  /// @author Alberto Cárdeno Domínguez
  void _prevStep() {
    setState(() {
      _step--;
    });
  }

  /// Guarda la información del usuario y finaliza el flujo
  /// @author Alberto Cárdeno Domínguez
  Future<void> _saveAndFinish() async {
    // Comprobar si el username ya existe en Firestore
    final exists = await UserService.usernameExists(_usernameController.text);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El nombre de usuario ya está en uso. Elige otro.')),
        );
      }
      return;
    }
    await UserService.saveUserData(
      uid: widget.user.uid,
      email: widget.user.email ?? '',
      nombre: _nombreController.text,
      username: _usernameController.text,
      fechaNacimiento: _fechaNacimiento!,
      esAdmin: _esAdmin,
      areBaned: _areBaned,
      foto: widget.googlePhotoUrl,
    );
    // Navega a AuthGate para que decida la pantalla correcta
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'lib/assets/Background.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildStep(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el widget correspondiente al paso actual del flujo
  /// @author Alberto Cárdeno Domínguez
  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text('Introduce tu nombre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            TextField(controller: _nombreController, decoration: InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              onPressed: _nextStep,
              child: Text('Siguiente', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alternate_email, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text('Elige tu nombre de usuario', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Usuario',
                border: OutlineInputBorder(),
                errorText: _usernameError,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _prevStep, child: Text('Atrás')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: () async => await _nextStep(),
                  child: Text('Siguiente', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cake, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text('Selecciona tu fecha de nacimiento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000, 1, 1),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _fechaNacimiento = picked);
              },
              child: Text(_fechaNacimiento == null ? 'Elegir fecha' : _fechaNacimiento!.toLocal().toString().split(' ')[0], style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _prevStep, child: Text('Atrás')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: _fechaNacimiento != null ? _nextStep : null,
                  child: Text('Siguiente', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text('¡Listo! Pulsa finalizar para guardar tus datos.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _prevStep, child: Text('Atrás')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: (_nombreController.text.isNotEmpty && _usernameController.text.isNotEmpty && _fechaNacimiento != null)
                      ? _saveAndFinish
                      : null,
                  child: Text('Finalizar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }
}

// Comentario: ExtraInfoFlow muestra los pasos para completar el perfil del usuario.
// Paso 0: Solicita el nombre del usuario.
// Paso 1: Solicita el nombre de usuario.
// Paso 2: Solicita la fecha de nacimiento.
// Paso 3: Pregunta si el usuario es administrador.
// Al finalizar, guarda la información en Firestore y cierra el flujo.

// Comentario: _saveAndFinish guarda los datos en Firestore y cierra el flujo.
// Se utiliza el servicio UserService para almacenar los datos del usuario.
// Almacena uid, email, nombre, username, fecha de nacimiento, estado de admin y foto de perfil.
// Finalmente, cierra el flujo volviendo a la pantalla anterior.
