import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercanova_go/catalog_screen.dart';
import 'package:mercanova_go/auth_repository.dart';
import 'package:mercanova_go/profile_repository.dart'; // Importamos el nuevo repositorio

/// Define los estados lógicos del flujo de autenticación dinámico.
/// completeProfile se utiliza para capturar datos adicionales en registros OAuth.
enum AuthStep { email, login, register, completeProfile }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  AuthStep _currentStep = AuthStep.email;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estados para los prefijos seleccionados
  String _selectedIdPrefix = 'V-';
  String _selectedPhonePrefix = '0412';

  // Controladores adicionales para el registro (Paso 2 del Journey)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // Nuevo controlador para el teléfono
  final TextEditingController _idController = TextEditingController();

  // Estados para la ubicación dinámica (Dirección)
  String? _selectedMunicipio;
  String? _selectedSector;

  final Map<String, List<String>> _municipiosSectors = {
    'Girardot': [
      'El Castaño',
      'La Soledad',
      'Calicanto',
      'San Jacinto',
      'Base Aragua',
      'San Isidro',
      'La Floresta',
      'El Bosque',
      'Las Acacias',
      'Piñonal',
      'San José',
      'La Maracaya',
      'la Coromoto',
      'san Vicente',
      '23 de Enero',
      'Los Olivos',
    ],
    'Libertador': [
      'La Ovallera',
      'Los Hornos',
      'Barrio Libertad',
      'La Pica',
      'Santa Ana',
      'El Cortijo',
      'Urbanización Bael',
      'Residencias El Parque',
      'San José de la Caridad',
      'Las Ánimas',
      'Ocumarito',
      'la Esmeraldita',
      'Palo Negro',
    ],
    'Francisco Linares Alcántara': [
      'Santa Rita',
      'Coropo',
      'Paraparal',
      'La Morita',
      'Francisco de Miranda',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Si el usuario ya está autenticado en Firebase pero llegó aquí,
    // es porque le falta completar el perfil (redirección desde Splash).
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      _currentStep = AuthStep.completeProfile;
    }
  }

  /// Verifica en Firebase si el correo existe para decidir si ir a Login o Registro.
  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Por favor, ingresa un correo electrónico válido.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Consultamos a Firebase si el correo ya está registrado
      final bool exists = await ref
          .read(authRepositoryProvider)
          .isEmailRegistered(email);

      if (mounted) {
        setState(() {
          _currentStep = exists ? AuthStep.login : AuthStep.register;
        });
      }
    } catch (e) {
      _showError('Error al verificar el correo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Prepara la conexión con Firebase para el inicio de sesión.
  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      _navigateToCatalog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Prepara la conexión con Firebase para el registro de nuevos usuarios.
  Future<void> _handleRegister() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final String nameInput = _nameController.text.trim();
    final String idBody = _idController.text.trim();
    final String phoneBody = _phoneController.text.trim();
    final String password = _passwordController.text;

    // Validación de dirección obligatoria
    if (_selectedMunicipio == null || _selectedSector == null) {
      _showError('Por favor, selecciona tu municipio y sector.');
      setState(() => _isLoading = false);
      return;
    }

    // 1. Validar y Formatear Nombre (mínimo 2 palabras)
    final words = nameInput
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length < 2) {
      _showError('Ingresa nombre y apellido (mínimo 2 palabras).');
      setState(() => _isLoading = false);
      return;
    }
    // Formateo automático: Primera Mayúscula, resto minúscula
    final formattedName = words
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');

    // 2. Validar Cédula (7 a 9 dígitos numéricos)
    if (!RegExp(r'^\d{7,9}$').hasMatch(idBody)) {
      _showError('La cédula debe contener entre 7 y 9 números.');
      setState(() => _isLoading = false);
      return;
    }
    final fullId = '$_selectedIdPrefix$idBody';

    // 3. Validar Teléfono (Exactamente 7 dígitos después del prefijo)
    if (!RegExp(r'^\d{7}$').hasMatch(phoneBody)) {
      _showError('El número de teléfono debe tener 7 dígitos.');
      setState(() => _isLoading = false);
      return;
    }
    final fullPhone = '$_selectedPhonePrefix$phoneBody';

    // 4. Validar Contraseña (Min 6, letras y números) solo si es registro nuevo
    if (_currentStep == AuthStep.register) {
      if (password.length < 6 ||
          !password.contains(RegExp(r'[a-zA-Z]')) ||
          !password.contains(RegExp(r'[0-9]'))) {
        _showError(
          'La contraseña debe tener mínimo 6 caracteres, letras y números.',
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      String? uid;

      // Si es un registro nuevo por correo
      if (_currentStep == AuthStep.register) {
        final userCredential = await ref
            .read(authRepositoryProvider)
            .signUpWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            );
        uid = userCredential.user?.uid;
      } else {
        // Si es completar perfil de Google/OAuth
        uid = ref.read(authRepositoryProvider).currentUser?.uid;
      }

      if (uid != null) {
        // Guardar datos adicionales en Firestore (Perfil de usuario)
        await ref
            .read(profileRepositoryProvider)
            .createUserProfile(
              userId: uid,
              name: formattedName,
              idNumber: fullId,
              phoneNumber: fullPhone,
              municipio: _selectedMunicipio!,
              sector: _selectedSector!,
            );
      }

      await _navigateToCatalog();
    } catch (e) {
      _showError('Error al registrarse: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Lógica para el inicio de sesión social con Google.
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();

      if (result != null && result.user != null) {
        // Verificamos si ya tiene perfil en Firestore
        final profile = await ref
            .read(profileRepositoryProvider)
            .getProfile(result.user!.uid);

        if (profile == null) {
          // Obligamos a completar los datos faltantes
          setState(() => _currentStep = AuthStep.completeProfile);
        } else {
          // Si ya existe, entra directo
          await _navigateToCatalog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error con Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navegación centralizada hacia la pantalla de catálogo.
  Future<void> _navigateToCatalog() async {
    if (!mounted) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    // Obtenemos el perfil para determinar la sede automáticamente
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(user.uid);

    if (!mounted) return;

    final municipio = profile?['municipio'] ?? 'Girardot';
    final branch =
        (municipio == 'Libertador' ||
            municipio == 'Francisco Linares Alcántara')
        ? 'Mercanova 22'
        : 'Mercanova Express';

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CatalogScreen(branchName: branch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Elementos decorativos de fondo (Inspirados en instagram.png)
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: const Color(0xFFFFC700).withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(
                Icons.eco,
                size: 120,
                color: const Color(0xFF00823B).withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30.0,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Centrado vertical absoluto
                          children: [
                            // Logo con sombreado leve para mayor presencia
                            Image.asset('assets/logo.png', height: 130),
                            const SizedBox(height: 30),

                            // Texto de bienvenida dinámico y con jerarquía visual
                            Column(
                              children: [
                                const Text(
                                  '¡Bienvenido!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFF27A1A),
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  'Calidad y frescura en la puerta de tu hogar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 45),

                            // Contenedor animado para transiciones suaves entre pasos
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _buildAuthForm(),
                            ),

                            // Divisor y Social Login (Solo en paso Email)
                            if (_currentStep == AuthStep.email) ...[
                              const SizedBox(height: 40),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Text(
                                      'O conéctate con',
                                      style: TextStyle(color: Colors.black38),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              _buildSocialButton(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el formulario dinámicamente según el paso actual.
  Widget _buildAuthForm() {
    switch (_currentStep) {
      case AuthStep.email:
        return Column(
          key: const ValueKey('email_form'),
          children: [
            _buildTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 25),
            _buildPrimaryButton(
              text: 'Continuar',
              onPressed: _isLoading ? () {} : _handleContinue,
            ),
          ],
        );
      case AuthStep.login:
        return Column(
          key: const ValueKey('login_form'),
          children: [
            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildPrimaryButton(
              text: 'Iniciar sesión',
              onPressed: _handleLogin,
            ),
            TextButton(
              onPressed: () => setState(() => _currentStep = AuthStep.email),
              child: const Text(
                'Usar otro correo',
                style: TextStyle(color: Color(0xFFF27A1A)),
              ),
            ),
          ],
        );
      case AuthStep.register:
        return Column(
          key: const ValueKey('register_form'),
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Nombre completo',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 15),
            _buildPrefixField(
              controller: _idController,
              label: 'Cédula / ID',
              icon: Icons.badge_outlined,
              prefixValue: _selectedIdPrefix,
              items: const ['V-', 'E-'],
              onChanged: (val) => setState(() => _selectedIdPrefix = val!),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildPrefixField(
              controller: _phoneController,
              label: 'Número de teléfono',
              icon: Icons.phone_outlined,
              prefixValue: _selectedPhonePrefix,
              items: const ['0412', '0422', '0416', '0426', '0424', '0414'],
              onChanged: (val) => setState(() => _selectedPhonePrefix = val!),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildDropdownField(
              label: 'Municipio',
              icon: Icons.location_city_outlined,
              value: _selectedMunicipio,
              items: _municipiosSectors.keys.toList(),
              onChanged: (val) {
                setState(() {
                  _selectedMunicipio = val;
                  _selectedSector =
                      null; // Reiniciar sector al cambiar municipio
                });
              },
            ),
            if (_selectedMunicipio != null) ...[
              const SizedBox(height: 15),
              _buildDropdownField(
                label: 'Sector',
                icon: Icons.map_outlined,
                value: _selectedSector,
                items: _municipiosSectors[_selectedMunicipio!]!,
                onChanged: (val) => setState(() => _selectedSector = val),
              ),
            ],
            const SizedBox(height: 15),
            _buildTextField(
              controller: _passwordController,
              label: 'Crea tu contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 25),
            _buildPrimaryButton(
              text: 'Registrarse',
              onPressed: _handleRegister,
            ),
            TextButton(
              onPressed: () => setState(() => _currentStep = AuthStep.email),
              child: const Text(
                'Volver atrás',
                style: TextStyle(color: Color(0xFFF27A1A)),
              ),
            ),
          ],
        );
      case AuthStep.completeProfile:
        return Column(
          key: const ValueKey('complete_profile_form'),
          children: [
            const Text(
              'Completa tu información',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Nombre completo',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 15),
            _buildPrefixField(
              controller: _idController,
              label: 'Cédula / ID',
              icon: Icons.badge_outlined,
              prefixValue: _selectedIdPrefix,
              items: const ['V-', 'E-'],
              onChanged: (val) => setState(() => _selectedIdPrefix = val!),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildPrefixField(
              controller: _phoneController,
              label: 'Número de teléfono',
              icon: Icons.phone_outlined,
              prefixValue: _selectedPhonePrefix,
              items: const ['0412', '0422', '0416', '0426', '0424', '0414'],
              onChanged: (val) => setState(() => _selectedPhonePrefix = val!),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildDropdownField(
              label: 'Municipio',
              icon: Icons.location_city_outlined,
              value: _selectedMunicipio,
              items: _municipiosSectors.keys.toList(),
              onChanged: (val) {
                setState(() {
                  _selectedMunicipio = val;
                  _selectedSector = null;
                });
              },
            ),
            if (_selectedMunicipio != null) ...[
              const SizedBox(height: 15),
              _buildDropdownField(
                label: 'Sector',
                icon: Icons.map_outlined,
                value: _selectedSector,
                items: _municipiosSectors[_selectedMunicipio!]!,
                onChanged: (val) => setState(() => _selectedSector = val),
              ),
            ],
            const SizedBox(height: 25),
            _buildPrimaryButton(
              text: 'Finalizar Registro',
              onPressed: _handleRegister,
            ),
          ],
        );
    }
  }

  /// Widget reutilizable para los campos de texto estilizados según login.png.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40), // Unificado con Onboarding
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  /// Campo de selección desplegable (Dropdown) estilizado según el diseño de Mercanova Go.
  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.black38),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text(
                  label,
                  style: const TextStyle(color: Colors.black38, fontSize: 16),
                ),
                onChanged: onChanged,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Campo especial con selector de prefijo para Cédula y Teléfono.
  Widget _buildPrefixField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String prefixValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.black38),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: prefixValue,
              onChanged: onChanged,
              style: const TextStyle(
                color: Color(0xFFF27A1A),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const Text(
            '|',
            style: TextStyle(color: Colors.black12, fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón principal con el color naranja de MercaNova (#F27A1A).
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF27A1A),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              40,
            ), // Estilo "Pill" consistente
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Botón de Google inspirado en login.png.
  Widget _buildSocialButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sustitución del icono genérico por el asset oficial de Google
            Image.asset(
              'assets/google.png',
              height: 24, // Tamaño estándar para botones sociales premium
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuar con Google',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
