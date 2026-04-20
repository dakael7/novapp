import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novapp/cart_provider.dart';
import 'package:novapp/product.dart';

/// Pantalla de detalle de producto con diseño premium y funcional.
class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Galería de Imagen (Hero)
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6F8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                ),
              ),
              child: Hero(
                tag: widget.product.id,
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 150,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            // 2. Información del Producto
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _buildReviewBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Color(0xFFF27A1A)),
                      children: [
                        const TextSpan(
                          text: 'BS. ',
                          style: TextStyle(fontSize: 18),
                        ),
                        TextSpan(
                          text: widget.product.priceBs.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'ref. ${widget.product.priceUsd.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black38, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  _buildQuantitySelector(),
                  const SizedBox(height: 40),
                  const Text(
                    'Puntuaciones y reseñas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildRatingDistribution(),
                  const SizedBox(height: 30),
                  _buildReviewItem(
                    'Ana María',
                    5,
                    'Excelente calidad, la harina siempre fresca.',
                  ),
                  _buildReviewItem(
                    'Juan Pérez',
                    4,
                    'Muy buen producto, aunque el empaque llegó algo arrugado.',
                  ),
                  _buildReviewItem(
                    'Carla Gómez',
                    5,
                    'Mi marca favorita para las arepas, 100% recomendada.',
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mostrar más',
                        style: TextStyle(
                          color: Color(0xFFF27A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120), // Espacio para el botón inferior
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildAddToCartBar(),
    );
  }

  Widget _buildRatingDistribution() {
    return Column(
      children: [
        _ratingRow(5, 0.85),
        _ratingRow(4, 0.10),
        _ratingRow(3, 0.03),
        _ratingRow(2, 0.01),
        _ratingRow(1, 0.01),
      ],
    );
  }

  Widget _ratingRow(int starCount, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$starCount',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.star_rounded, size: 14, color: Colors.black26),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.black12,
                color: const Color(0xFFFFC700),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, double rating, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFF27A1A).withValues(alpha: 0.1),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Color(0xFFF27A1A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: index < rating
                        ? const Color(0xFFFFC700)
                        : Colors.black12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC700).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.star_rounded, color: Color(0xFFFFC700), size: 18),
          SizedBox(width: 4),
          Text(
            '4.8',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cantidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _qtyBtn(Icons.remove, () {
              if (_quantity > 1) setState(() => _quantity--);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$_quantity',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _qtyBtn(Icons.add, () => setState(() => _quantity++)),
          ],
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildAddToCartBar() {
    return Consumer(
      builder: (context, ref, child) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Precio Total',
                      style: TextStyle(color: Colors.black38, fontSize: 12),
                    ),
                    Text(
                      'BS. ${(widget.product.priceBs * _quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        // Lógica para añadir múltiples unidades al carrito
                        for (int i = 0; i < _quantity; i++) {
                          ref
                              .read(cartProvider.notifier)
                              .addItem(widget.product);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$_quantity ${widget.product.name} añadidos',
                            ),
                            backgroundColor: const Color(0xFF00823B),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF27A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_checkout_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Añadir al carrito',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
