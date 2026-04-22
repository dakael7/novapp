import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mercanova_go/supabase_provider.dart';
import 'package:mercanova_go/product.dart';
import 'package:mercanova_go/price_calculator.dart';

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
          .limit(16);

      final products = (response as List)
          .map((json) => Product.fromJson(json, rate))
          .toList();

      return _applyActiveOffers(products, rate);
    } catch (e) {
      throw Exception('Error al cargar productos destacados: $e');
    }
  }

  /// Obtiene productos en oferta basados en vigencia y observación.
  Future<List<Product>> getOfferProducts({
    List<String>? targetObservations,
    bool invert = false,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // 1. Buscar documentos de oferta vigentes
      var query = _client
          .from('ma_ofertas_mirror')
          .select('c_documento, c_observacion');
      query = query.lte('f_desde', today).gte('f_hasta', today);

      final List docsResponse = await query;

      // 2. Filtrar por observación (01/02 o el resto)
      final Map<String, String> docTags = {}; // c_documento -> tag
      final List<String> validDocs = []; // lista de c_documento vigentes

      for (var doc in docsResponse) {
        final obs = (doc['c_observacion'] ?? '').toString();
        final isOffer = obs == '01' || obs == '02';
        final isMatch = targetObservations?.contains(obs) ?? false;

        if (invert ? !isMatch : isMatch) {
          final String docId = doc['c_documento'].toString();
          validDocs.add(docId);
          docTags[docId] = isOffer ? 'oferta' : 'promocion';
        }
      }

      if (validDocs.isEmpty) return [];

      // 3. Obtener códigos de artículos, su precio de oferta y mapear su tag
      final List itemsResponse = await _client
          .from('tr_ofertas_mirror')
          .select('c_codarticulo, c_documento, n_oferta')
          .inFilter('c_documento', validDocs);

      // Mapeo: c_codarticulo -> { tag, n_oferta }
      final Map<String, Map<String, dynamic>> articleToOfferData = {
        for (var item in itemsResponse)
          item['c_codarticulo'].toString(): {
            'tag': docTags[item['c_documento'].toString()] ?? 'promocion',
            'price': (item['n_oferta'] as num?)?.toDouble() ?? 0.0,
          },
      };

      final productCodes = articleToOfferData.keys.toList();
      if (productCodes.isEmpty) return [];

      // 4. Obtener los productos reales
      final double rate = await getExchangeRate();
      final List productsResponse = await _client
          .from('ma_productos_mirror') // Corregido: 'in_' a 'inFilter' o 'in'
          .select()
          .inFilter('c_Codigo', productCodes)
          .eq('n_Activo', 1);

      return productsResponse.map((json) {
        final String code = (json['c_Codigo'] ?? json['c_codigo'] ?? '')
            .toString();
        final offerData = articleToOfferData[code];
        final double? offerPrice = offerData?['price'];

        // Re-creamos el producto. Si hay precio de oferta, se pasa a fromJson
        // para que PriceCalculator haga el cálculo de Bs y REF correctamente.
        final p = Product.fromJson(
          json,
          rate,
          overrideBasePrice: (offerPrice != null && offerPrice > 0)
              ? offerPrice
              : null,
        );

        return p.copyWith(offerType: offerData?['tag']);
      }).toList();
    } catch (e) {
      return [];
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

      final products = (response as List)
          .map((json) => Product.fromJson(json, rate))
          .toList();

      return _applyActiveOffers(products, rate);
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

      final products = (response as List)
          .map((json) => Product.fromJson(json, rate))
          .toList();

      return _applyActiveOffers(products, rate);
    } catch (e) {
      throw Exception('Error al cargar categoría: $e');
    }
  }

  /// Método privado para adjuntar ofertas vigentes a una lista de productos.
  /// Asegura que los precios se actualicen según n_oferta si hay vigencia.
  Future<List<Product>> _applyActiveOffers(
    List<Product> products,
    double rate,
  ) async {
    if (products.isEmpty) return products;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final codes = products.map((p) => p.code).toList();

      // 1. Obtener documentos de oferta vigentes
      final List docsResponse = await _client
          .from('ma_ofertas_mirror')
          .select('c_documento, c_observacion')
          .lte('f_desde', today)
          .gte('f_hasta', today);

      if (docsResponse.isEmpty) return products;

      final Map<String, String> docTags = {
        for (var doc in docsResponse)
          doc['c_documento'].toString():
              (doc['c_observacion'] == '01' || doc['c_observacion'] == '02')
              ? 'oferta'
              : 'promocion',
      };

      final List<String> validDocs = docsResponse
          .map((d) => d['c_documento'].toString())
          .toList();

      // 2. Buscar si estos productos específicos están en esas ofertas
      final List itemsResponse = await _client
          .from('tr_ofertas_mirror')
          .select('c_codarticulo, n_oferta, c_documento')
          .inFilter('c_documento', validDocs)
          .inFilter('c_codarticulo', codes);

      if (itemsResponse.isEmpty) return products;

      final Map<String, Map<String, dynamic>> articleToOffer = {
        for (var item in itemsResponse)
          item['c_codarticulo'].toString(): {
            'price': (item['n_oferta'] as num?)?.toDouble() ?? 0.0,
            'tag': docTags[item['c_documento'].toString()],
          },
      };

      // 3. Aplicar ofertas a los productos mediante recálculo de precios
      return products.map((p) {
        final offer = articleToOffer[p.code];
        if (offer != null && (offer['price'] as double) > 0) {
          final double basePrice = offer['price'];
          return p.copyWith(
            offerType: offer['tag'],
            priceBs: PriceCalculator.calculatePriceBs(
              basePrice: basePrice,
              taxPercent: p.taxPercent,
              exchangeRate: rate,
            ),
            priceUsd: PriceCalculator.calculatePriceRef(
              basePrice: basePrice,
              taxPercent: p.taxPercent,
            ),
          );
        }
        return p;
      }).toList();
    } catch (e) {
      return products; // En caso de error, devolvemos productos sin oferta
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseClientProvider));
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getFeaturedProducts();
});

final mercanovaOffersProvider = FutureProvider<List<Product>>((ref) {
  return ref
      .watch(productRepositoryProvider)
      .getOfferProducts(targetObservations: ['01', '02']);
});

final promocionesProvider = FutureProvider<List<Product>>((ref) {
  return ref
      .watch(productRepositoryProvider)
      .getOfferProducts(targetObservations: ['01', '02'], invert: true);
});
