import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novapp/product.dart';

/// Modelo de datos para representar un producto dentro del carrito.
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

/// Notificador de estado para gestionar la lógica del carrito de compras.
class CartNotifier extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() => {};

  /// Agrega un producto al carrito o incrementa su cantidad si ya existe.
  void addItem(Product product) {
    if (state.containsKey(product.id)) {
      state = {
        ...state,
        product.id: state[product.id]!.copyWith(
          quantity: state[product.id]!.quantity + 1,
        ),
      };
    } else {
      state = {...state, product.id: CartItem(product: product)};
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
    if (currentItem.quantity > 1) {
      state = {
        ...state,
        productId: currentItem.copyWith(quantity: currentItem.quantity - 1),
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
  int get totalItems =>
      state.values.fold(0, (sum, item) => sum + item.quantity);

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
