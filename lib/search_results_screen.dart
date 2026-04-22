import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercanova_go/cart_provider.dart';
import 'package:mercanova_go/product_details_screen.dart';
import 'package:mercanova_go/search_provider.dart';
import 'package:mercanova_go/product.dart';

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

  void _showWeightPicker(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        double tempWeight = 0.1;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Cuánto deseas llevar?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tempWeight < 1.0
                            ? '${(tempWeight * 1000).toInt()} gr'
                            : '${tempWeight.toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF27A1A),
                        ),
                      ),
                      if (tempWeight >= 1.0)
                        Text(
                          ' (${(tempWeight * 1000).toInt()} gr)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black26,
                          ),
                        ),
                    ],
                  ),
                  Slider(
                    value: tempWeight,
                    min: 0.1,
                    max: 2.0,
                    divisions: 190,
                    activeColor: const Color(0xFFF27A1A),
                    inactiveColor: const Color(
                      0xFFF27A1A,
                    ).withValues(alpha: 0.1),
                    onChanged: (value) {
                      setModalState(() {
                        tempWeight = double.parse(value.toStringAsFixed(2));
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(product, tempWeight);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} añadido al carrito'),
                            backgroundColor: const Color(0xFF00823B),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00823B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Añadir al carrito',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

    final bool hasOffer = product.offerType != null;
    final Color effectiveHeaderColor = hasOffer
        ? const Color(0xFF00823B)
        : headerColor;

    final bool isHeaderGreen = effectiveHeaderColor == const Color(0xFF00823B);
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (hasOffer)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.percent_rounded,
                          size: 14,
                          color: Color(0xFF00823B),
                        ),
                      ),
                    ),
                  Column(
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
                        size: 60, // Corregido: withOpacity a withValues
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _AnimatedAddButton(
                    onTap: () {
                      if (product.isWeighted) {
                        _showWeightPicker(context, ref, product);
                      } else {
                        ref.read(cartProvider.notifier).addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name añadido'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFF00823B),
                          ),
                        );
                      }
                    },
                    gradient: buttonGradient,
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

/// Widget personalizado que encapsula el botón "+" con una animación de "explosión de partículas".
class _AnimatedAddButton extends StatefulWidget {
  final VoidCallback onTap;
  final Gradient gradient;

  const _AnimatedAddButton({required this.onTap, required this.gradient});

  @override
  State<_AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Capa de partículas (Explosión de gotitas)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  progress: _animation.value,
                  color: const Color(0xFF00823B), // El color verde solicitado
                ),
              );
            },
          ),
          // Botón Base
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

/// Pintor encargado de dibujar las pequeñas gotas volando.
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0, 1))
      ..style = PaintingStyle.fill;

    const int count = 16;
    const double gravity = 80.0;

    for (int i = 0; i < count; i++) {
      // Distribución radial uniforme
      double angle = (i * (360 / count)) * (3.14159 / 180);

      // Velocidad aumentada para mayor alcance
      double velocity = 40 + (i * 15 % 40);

      double radialDistance = progress * velocity;
      Offset explosionDir = Offset.fromDirection(angle, radialDistance);

      // Gravedad aplicada al eje Y
      double drop = 0.5 * gravity * progress * progress;
      Offset finalPos = Offset(explosionDir.dx, explosionDir.dy + drop);

      canvas.drawCircle(finalPos, 5.0 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
