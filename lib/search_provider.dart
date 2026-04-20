import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novapp/product_repository.dart';
import 'package:novapp/product.dart';

/// Notificador para gestionar el historial de búsqueda real en memoria.
/// En una fase posterior, esto puede integrarse con SharedPreferences para persistencia local.
class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Agrega una nueva búsqueda al historial, manteniendo solo las 4 más recientes y únicas.
  void addSearch(String query) {
    if (query.trim().isEmpty) return;

    final currentState = state;
    // Movemos el término al principio si ya existe, o lo agregamos si es nuevo.
    final newState = [
      query,
      ...currentState.where(
        (item) => item.toLowerCase() != query.toLowerCase(),
      ),
    ];

    // Limitamos a los 4 elementos solicitados
    state = newState.take(4).toList();
  }
}

/// Provider global para el historial de búsqueda.
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(() {
      return SearchHistoryNotifier();
    });

/// Provider para resultados de búsqueda en tiempo real desde Supabase.
final searchProductsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  query,
) async {
  // La búsqueda ahora es independiente de la categoría seleccionada en el catálogo.
  // Esto permite buscar "Arroz" globalmente aunque se esté en la pestaña "Licores".
  final repository = ref.watch(productRepositoryProvider);
  return repository.searchProducts(query);
});
