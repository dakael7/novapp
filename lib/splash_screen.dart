import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercanova_go/auth_repository.dart';
import 'package:mercanova_go/profile_repository.dart';
import 'package:mercanova_go/catalog_screen.dart';
import 'package:mercanova_go/onboarding_screen.dart';

/// Pantalla de carga inicial (Splash Screen) que presenta la identidad de la marca.
/// Ahora valida la persistencia de la sesión de Firebase para dirigir al usuario.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  @override
  void didChangeDependencies() {
    // Precarga la imagen del logo para evitar saltos de frames en el primer renderizado
    precacheImage(const AssetImage('assets/logo.png'), context);
    super.didChangeDependencies();
  }

  /// Maneja el retardo de tiempo y la transición de navegación hacia el Onboarding.
  Future<void> _navigateToNext() async {
    // Retardo de 3 segundos para mostrar el branding correctamente
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 1. Verificamos sesión activa en Firebase
    final user = ref.read(authRepositoryProvider).currentUser;
    Map<String, dynamic>? profile;

    // 2. Si hay usuario, verificamos que tenga su perfil registrado en Supabase
    if (user != null) {
      profile = await ref.read(profileRepositoryProvider).getProfile(user.uid);
    }

    // Verificamos que el widget siga montado después de las llamadas asíncronas antes de navegar.
    if (!mounted) return;

    // 3. Lógica de ruteo:
    // - Si tiene sesión y perfil completo -> Calcula sede y va a Catálogo.
    // - En cualquier otro caso -> Onboarding (que llevará al AuthScreen).
    Widget targetScreen;

    if (user != null && profile != null) {
      final municipio = profile['municipio'] ?? 'Girardot';

      // Lógica de asignación de sede automática
      String branch =
          (municipio == 'Libertador' ||
              municipio == 'Francisco Linares Alcántara')
          ? 'Mercanova 22'
          : 'Mercanova Express';

      targetScreen = CatalogScreen(branchName: branch);
    } else {
      targetScreen = const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Implementación de una curva de animación suave y un efecto de opacidad
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
        transitionDuration: const Duration(
          milliseconds: 800,
        ), // Duración optimizada para suavidad
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio según el manual de estilo
      body: Stack(
        children: [
          // Decoración superior derecha (Amarillo Mercanova Go)
          Positioned(
            top: -40,
            right: -40,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: const Color(0xFFFFC700).withValues(alpha: 0.1),
            ),
          ),
          // Decoración orgánica en la esquina inferior para dar peso visual
          Positioned(
            bottom: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: const Color(0xFFF27A1A).withValues(alpha: 0.05),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo principal de Mercanova Go con un ligero delay de entrada
                Image.asset('assets/logo.png', width: 220, fit: BoxFit.contain),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
