import 'package:flutter/material.dart';
import 'package:novapp/auth_screen.dart';
import 'package:novapp/onboarding_body.dart';

/// Pantalla de Onboarding que gestiona el carrusel de bienvenida.
/// Implementa un [PageView] con 3 secciones informativas siguiendo el diseño minimalista.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controlador para el flujo de las páginas del carrusel.
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo con Degradado Vibrante (Inspirado en instagram.png)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFD966), // Amarillo cálido superior
                  Color(0xFFF27A1A), // Naranja corporativo inferior
                ],
              ),
            ),
          ),
          // 1.1 Haz de luz superior (Inspirado en el brillo del logo Nova en el flyer)
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 2. Elementos decorativos de fondo para romper la planitud
          Positioned(
            top: -30,
            left: -20,
            child: Opacity(
              opacity: 0.15,
              child: Transform.rotate(
                angle: -0.5,
                child: const Icon(Icons.eco, size: 150, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -40,
            child: Opacity(
              opacity: 0.12,
              child: const Icon(Icons.circle, size: 200, color: Colors.white),
            ),
          ),
          // 3. Contenido Principal
          SafeArea(
            child: Column(
              children: [
                // Área central del carrusel (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: 3,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      // Lista de rutas de imágenes para las 3 páginas del onboarding.
                      final List<String> onboardingImages = [
                        'assets/onboarding_1.png',
                        'assets/onboarding_2.png',
                        'assets/onboarding_3.png',
                      ];
                      return OnboardingBody(imagePath: onboardingImages[index]);
                    },
                  ),
                ),

                // Indicador de posición (Dots) - Ref: car reference.png
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),

                const SizedBox(height: 40),

                // Botón de acción principal: "Siguiente"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Navegación fluida hacia AuthScreen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .white, // Fondo blanco para máximo contraste sobre el naranja
                        foregroundColor: const Color(
                          0xFFF27A1A,
                        ), // Texto en el color de marca
                        elevation:
                            4, // Elevación para dar sensación de profundidad (capas)
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            40,
                          ), // Unificado a 40px
                        ),
                      ),
                      child: const Text(
                        'Siguiente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botón secundario: "Omitir"
                TextButton(
                  onPressed: () {
                    // Salto directo a la autenticación
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Omitir',
                    style: TextStyle(
                      color: Colors
                          .white, // Mejor contraste sobre el fondo naranja
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ), // Cierre de SafeArea
        ],
      ), // Cierre de Stack
    );
  }

  /// Construye un punto indicador individual.
  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 10,
      width: isActive ? 24 : 10, // Efecto "Pill" para la página activa
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF27A1A) : const Color(0xFFFFCC99),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
