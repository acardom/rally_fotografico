/**
 * Botón personalizado reutilizable para la app Rally Fotográfico.
 * Permite personalizar el texto, el callback y el estilo.
 * @author Alberto Cárdeno
 */

import 'package:flutter/material.dart';

// Widget de botón personalizado que puede ser reutilizado en distintas pantallas.
class CustomButton extends StatelessWidget { 
  final String text; // Texto que se mostrará en el botón
  final VoidCallback onPressed; // Función que se ejecuta al pulsar el botón 
  final Color? color; // Color de fondo del botón
  final Color? textColor; // Color del texto del botón

  /// Constructor del botón personalizado
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
  }) : super(key: key);

  /// Construye el widget visual del botón
  @override
  Widget build(BuildContext context) {
    // Comentario: build construye el botón visual con el texto y estilos dados.
    return ElevatedButton(
      onPressed: onPressed, // Ejecuta la función proporcionada al pulsar
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor, // Color de fondo
        foregroundColor: textColor ?? Colors.white, // Color del texto
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text, // Muestra el texto recibido
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Comentario: CustomButton es un widget reutilizable para botones personalizados.
