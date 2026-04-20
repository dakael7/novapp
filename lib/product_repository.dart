import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:novapp/supabase_provider.dart';
import 'package:novapp/product.dart';

class ProductRepository {
  final SupabaseClient _client;
  ProductRepository(this._client);

  Future<double> getExchangeRate() async {
    try {
      final response = await _client
          .from('ma_monedas_mirror')
          .select('n_factor')
          .eq('c_codmoneda', 'USD')
          .limit(1)
          .maybeSingle();

      final factor = response?['n_factor'] ?? 1.0;
      return (factor is num) ? factor.toDouble() : 1.0;
    } catch (e) {
      return 1.0; // Fallback a 1.0 si hay error
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final double rate = await getExchangeRate();
      final response = await _client
          .from('ma_productos_mirror')
          .select()
          .eq('n_Activo', 1)
          .limit(12);

      return (response as List)
          .map((json) => Product.fromJson(json, rate))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar productos destacados: $e');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final double rate = await getExchangeRate();
      final response = await _client
          .from('ma_productos_mirror')
          .select()
          .ilike('c_Descri', '%$query%')
          .eq('n_Activo', 1)
          .limit(50);

      return (response as List)
          .map((json) => Product.fromJson(json, rate))
          .toList();
    } catch (e) {
      throw Exception('Error en la búsqueda: $e');
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final double rate = await getExchangeRate();
      final response = await _client
          .from('ma_productos_mirror')
          .select()
          .eq('c_Departamento', category)
          .eq('n_Activo', 1)
          .limit(50);

      return (response as List)
          .map((json) => Product.fromJson(json, rate))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar categoría: $e');
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseClientProvider));
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getFeaturedProducts();
});
