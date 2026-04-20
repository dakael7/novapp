import 'package:flutter/material.dart';
import 'package:novapp/catalog_screen.dart';

/// Pantalla de selección de sucursal con estética de Onboarding.
/// Permite segmentar el inventario entre Maracay y Palo Negro.
class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  // Definición de las sucursales de MercaNova
  final List<Map<String, String>> _branches = [
    {
      'name': 'Mercanova Express',
      'location': 'Maracay',
      'address': 'Av. Bolívar, N87 Entre C.C Parque Aragua y C.C Global',
      'icon': '🚚',
    },
    {
      'name': 'Mercanova 22',
      'location': 'Palo Negro',
      'address': 'Sector La Pica, Calle Paramaconi',
      'icon': '🏠',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo con Degradado Vibrante (Consistencia con Onboarding)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFD966), Color(0xFFF27A1A)],
              ),
            ),
          ),
          // 2. Haz de luz superior
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
          // 3. Contenido
          SafeArea(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centrado vertical en el eje Y
              children: [
                const Text(
                  'Selecciona tu sede',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  '',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(
                  height: 40,
                ), // Espaciado controlado entre texto y botones
                // Selección vertical de sucursales
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildBranchButton(_branches[0]),
                      const SizedBox(height: 24),
                      _buildBranchButton(_branches[1]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta/botón de gran tamaño para cada sucursal.
  Widget _buildBranchButton(Map<String, String> branch) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CatalogScreen(branchName: branch['name']!),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: const Color(
                  0xFFFFC700,
                ).withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF27A1A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      branch['icon']!,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch['name']!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF27A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          branch['location']!,
                          style: const TextStyle(
                            color: Color(0xFF00823B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          branch['address']!,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
