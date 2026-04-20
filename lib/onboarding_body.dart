import 'package:flutter/material.dart';

/// Widget que define el contenido visual de cada página del carrusel.
/// Implementa el contenedor redondeado gris como placeholder para futuras ilustraciones.
class OnboardingBody extends StatelessWidget {
  final String imagePath;

  const OnboardingBody({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stack para superponer elementos decorativos y la imagen principal
          Stack(
            clipBehavior:
                Clip.none, // Permite que los elementos decorativos sobresalgan
            alignment: Alignment.center,
            children: [
              // Círculo Amarillo (Branding) en la parte superior derecha
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.2,
                    ), // Sintaxis moderna para opacidad
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Elemento Verde (Frescura) en la parte inferior izquierda
              Positioned(
                left: -30,
                bottom: 40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00823B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      30,
                    ), // Forma cuadrada redondeada
                  ),
                ),
              ),
              // Contenedor principal con elevación (sombras) y bordes definidos
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE9F1),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
