import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercanova_go/auth_repository.dart';
import 'package:mercanova_go/profile_repository.dart';
import 'package:mercanova_go/catalog_screen.dart';

/// Pantalla de perfil de usuario que integra datos de Firebase Auth y Firestore.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
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

  String _getBranch(String municipio) {
    if (municipio == 'Libertador' ||
        municipio == 'Francisco Linares Alcántara') {
      return 'Mercanova 22';
    }
    return 'Mercanova Express';
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario actual de Firebase Authentication
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              child: Text(
                _isEditing ? 'Cancelar' : 'Editar',
                style: const TextStyle(
                  color: Color(0xFFF27A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No hay una sesión activa.'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: ref.read(profileRepositoryProvider).getProfile(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF27A1A)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar perfil: ${snapshot.error}'),
                  );
                }

                // Combinamos información de Auth y Firestore para una vista completa
                final profile = snapshot.data;
                final name = profile?['name'] ?? user.displayName ?? 'Usuario';
                final email = user.email ?? 'N/A';
                final idNumber = profile?['id_number'] ?? 'No registrada';
                final phone = profile?['phone_number'] ?? 'No registrado';
                final municipio = profile?['municipio'] ?? 'N/A';
                final sector = profile?['sector'] ?? 'N/A';

                // Inicializar valores de edición si están vacíos
                _selectedMunicipio ??= municipio;
                _selectedSector ??= sector;

                Future<void> saveChanges() async {
                  final oldBranch = _getBranch(municipio);
                  final newBranch = _getBranch(_selectedMunicipio!);

                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Actualizar dirección?'),
                      content: Text(
                        oldBranch != newBranch
                            ? 'Tu sede cambiará de $oldBranch a $newBranch. La aplicación se reiniciará en la nueva sede.'
                            : '¿Estás seguro de guardar los cambios en tu dirección?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sí, guardar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    setState(() => _isSaving = true);
                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfileAddress(
                          userId: user.uid,
                          municipio: _selectedMunicipio!,
                          sector: _selectedSector!,
                        );

                    if (mounted) {
                      if (!context.mounted) return;
                      if (oldBranch != newBranch) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) =>
                                CatalogScreen(branchName: newBranch),
                          ),
                          (route) => false,
                        );
                      } else {
                        setState(() {
                          _isEditing = false;
                          _isSaving = false;
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dirección actualizada'),
                          ),
                        );
                      }
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Avatar premium con la inicial del usuario
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(
                          0xFFF27A1A,
                        ).withValues(alpha: 0.1),
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF27A1A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Campos de información con diseño de tarjeta suave
                      _buildProfileField('Correo Electrónico', email),
                      _buildProfileField('Cédula / ID de Identidad', idNumber),
                      _buildProfileField('Número de Teléfono', phone),
                      if (!_isEditing)
                        _buildProfileField(
                          'Dirección de Entrega',
                          '$sector, $municipio',
                        )
                      else ...[
                        _buildDropdownField(
                          label: 'Municipio',
                          icon: Icons.location_city_outlined,
                          value: _selectedMunicipio,
                          items: _municipiosSectors.keys.toList(),
                          onChanged: (val) => setState(() {
                            _selectedMunicipio = val;
                            _selectedSector = null;
                          }),
                        ),
                        const SizedBox(height: 15),
                        if (_selectedMunicipio != null)
                          _buildDropdownField(
                            label: 'Sector',
                            icon: Icons.map_outlined,
                            value: _selectedSector,
                            items: _municipiosSectors[_selectedMunicipio!]!,
                            onChanged: (val) =>
                                setState(() => _selectedSector = val),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF27A1A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Guardar Cambios',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Construye un campo de información con estética de tarjeta minimalista.
  Widget _buildProfileField(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

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
                value: items.contains(value) ? value : null,
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
}
