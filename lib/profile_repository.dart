import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repositorio encargado de la gestión de perfiles de usuario en Firebase Firestore.
///
/// Este repositorio se utiliza para guardar y recuperar información adicional
/// del usuario (como nombre, cédula, teléfono) que no es manejada directamente
/// por Firebase Authentication.
class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda los datos del perfil de un nuevo usuario en Firestore.
  ///
  /// Se asume que el `userId` es el UID proporcionado por Firebase Authentication
  /// y se utiliza como ID del documento para facilitar búsquedas directas.
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String idNumber, // Cédula o ID
    required String phoneNumber,
    required String municipio,
    required String sector,
  }) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).set({
        'user_id': userId,
        'name': name,
        'id_number': idNumber,
        'phone_number': phoneNumber,
        'municipio': municipio,
        'sector': sector,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(
        'Error al guardar el perfil del usuario en Firestore: $e',
      );
    }
  }

  /// Actualiza únicamente la dirección del usuario.
  Future<void> updateProfileAddress({
    required String userId,
    required String municipio,
    required String sector,
  }) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'municipio': municipio,
        'sector': sector,
      });
    } catch (e) {
      throw Exception('Error al actualizar la dirección en Firestore: $e');
    }
  }

  /// Recupera los datos del perfil de un usuario específico.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_profiles')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      // En caso de error, retornamos null para manejar la redirección al perfil si falta data
      return null;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
