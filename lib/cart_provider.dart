import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercanova_go/product.dart';

/// Modelo de datos para representar un producto dentro del carrito.
class CartItem {
  final Product product;
  final double quantity;

  CartItem({required this.product, this.quantity = 1.0});

  CartItem copyWith({double? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

/// Notificador de estado para gestionar la lógica del carrito de compras.
class CartNotifier extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() => {};

  /// Agrega un producto al carrito o incrementa su cantidad si ya existe.
  void addItem(Product product, [double? amount]) {
    // Si es por peso, incrementamos de a 100g (0.1), si no, de a 1 unidad.
    final double step = product.isWeighted ? 0.1 : 1.0;
    final double quantityToAdd = amount ?? step;

    if (state.containsKey(product.id)) {
      final double newQuantity = state[product.id]!.quantity + quantityToAdd;
      state = {
        ...state,
        product.id: state[product.id]!.copyWith(
          quantity: double.parse(newQuantity.toStringAsFixed(3)),
        ),
      };
    } else {
      state = {
        ...state,
        product.id: CartItem(product: product, quantity: quantityToAdd),
      };
    }
  }

  /// Elimina un producto por completo del carrito.
  void removeItem(String productId) {
    // Creamos una copia del estado actual y removemos el elemento
    final newState = Map<String, CartItem>.from(state);
    newState.remove(productId);
    state = newState;
  }

  /// Disminuye la cantidad de un producto. Si llega a 0, se elimina del carrito.
  void decreaseQuantity(String productId) {
    if (!state.containsKey(productId)) return;

    final currentItem = state[productId]!;
    final double step = currentItem.product.isWeighted ? 0.1 : 1.0;

    if (currentItem.quantity > step) {
      final double newQuantity = currentItem.quantity - step;
      state = {
        ...state,
        productId: currentItem.copyWith(
          quantity: double.parse(newQuantity.toStringAsFixed(3)),
        ),
      };
    } else {
      removeItem(productId);
    }
  }

  /// Vacía completamente el carrito de compras.
  void clearCart() {
    state = {};
  }

  /// Calcula el número total de unidades en el carrito.
  double get totalItems =>
      state.values.fold(0.0, (sum, item) => sum + item.quantity);

  /// Calcula el monto total a pagar en Dólares (USD).
  double get totalUsd => state.values.fold(
    0,
    (sum, item) => sum + (item.product.priceUsd * item.quantity),
  );

  /// Calcula el monto total a pagar en Bolívares (BS).
  double get totalBs => state.values.fold(
    0,
    (sum, item) => sum + (item.product.priceBs * item.quantity),
  );
}

/// Provider global para acceder al estado del carrito desde cualquier parte de la app.
final cartProvider = NotifierProvider<CartNotifier, Map<String, CartItem>>(
  () => CartNotifier(),
);
