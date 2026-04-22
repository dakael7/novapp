import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mercanova_go/firebase_options.dart'; // Importa las opciones generadas
import 'package:mercanova_go/splash_screen.dart';

/// Punto de entrada principal de la aplicación Mercanova Go.
/// Se utiliza [ProviderScope] para habilitar el manejo de estado con Riverpod
/// según la arquitectura definida en el contexto del proyecto.
Future<void> main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de servicios asíncronos.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase para acceso a tablas de inventario y pedidos.
  await Supabase.initialize(
    url: 'https://jyuiezfqjgegaenxlhim.supabase.co',
    anonKey: 'sb_publishable_ZsuZM1AnQ8s_tjGmQC1RMg_Ommlw_pF',
  );

  // Inicialización de Firebase (Lógica de autenticación secundaria).
  // NOTA: Debes descomentar firebase_options una vez ejecutes 'flutterfire configure'.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercanova Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Se establece la fuente oficial definida en pubspec.yaml
        fontFamily: 'Argentum Sans',
        // Configuración de la paleta de colores oficial definida en context.txt
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF27A1A), // Naranja Principal
          primary: const Color(0xFFF27A1A),
          secondary: const Color(0xFFFFC700), // Amarillo Secundario
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      ),
      // La aplicación inicia con la pantalla de carga (Splash Screen).
      home: const SplashScreen(),
    );
  }
}
