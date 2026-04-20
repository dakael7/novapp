import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novapp/cart_provider.dart';
import 'package:novapp/product_details_screen.dart';
import 'package:novapp/search_provider.dart';
import 'package:novapp/product.dart';

/// Pantalla que muestra los resultados de búsqueda filtrados.
/// Diseñada para mantener la consistencia visual con el catálogo principal.
class SearchResultsScreen extends ConsumerWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Consumo del provider asíncrono que busca productos reales en Supabase
    final searchResults = ref.watch(searchProductsProvider(query));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF27A1A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Resultados para',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              '"$query"',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: searchResults.when(
        data: (products) => products.isEmpty
            ? _buildNoResults()
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 25,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.62,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return _buildProductCard(
                    context: context,
                    ref: ref,
                    product: p,
                    headerColor: const Color(0xFFF27A1A),
                    buttonColor: const Color(0xFF00823B),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 100,
            color: Colors.black.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 16),
          const Text(
            'No encontramos coincidencias',
            style: TextStyle(
              color: Colors.black38,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required WidgetRef ref,
    required Product product,
    required Color headerColor,
    required Color buttonColor,
  }) {
    final id = product.id;
    final name = product.name;
    final price = product.priceBs;
    final refPrice = product.priceUsd;
    final brand = product.brand;

    final bool isHeaderGreen = headerColor == const Color(0xFF00823B);
    final bool isButtonGreen = buttonColor == const Color(0xFF00823B);

    final Gradient headerGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isHeaderGreen
          ? [const Color(0xFF00823B), const Color(0xFF009142)]
          : [const Color(0xFFF27A1A), const Color(0xFFF58D38)],
    );

    final Gradient buttonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isButtonGreen
          ? [const Color(0xFF00823B), const Color(0xFF009142)]
          : [const Color(0xFFF27A1A), const Color(0xFFF58D38)],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: headerGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    brand ?? 'MercaNova',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white),
                      children: [
                        const TextSpan(
                          text: 'BS. ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: price.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'ref. ${refPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailsScreen(product: product),
                    ),
                  ),
                  child: Center(
                    child: Hero(
                      tag: id,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(cartProvider.notifier).addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name añadido'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF00823B),
                        ),
                      );
                    },
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        gradient: buttonGradient,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
