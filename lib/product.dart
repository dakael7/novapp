import 'package:flutter/foundation.dart';
import 'package:novapp/price_calculator.dart';

/// Modelo de datos inmutable para un Producto de MercaNova.
/// Mapeado directamente desde la tabla MA_PRODUCTOS_MIRROR.
@immutable
class Product {
  final String id;
  final String code;
  final String name;
  final String? brand;
  final String? description;
  final double priceBs; // Precio_Tarjeta (Bolívares)
  final double priceUsd; // Precio REF (Total USD con Impuesto)
  final String? imageUrl;
  final String category;
  final bool isFeatured;

  const Product({
    required this.id,
    required this.code,
    required this.name,
    this.brand,
    this.description,
    required this.priceBs,
    required this.priceUsd,
    this.imageUrl,
    required this.category,
    this.isFeatured = false,
  });

  factory Product.fromJson(Map<String, dynamic> json, double exchangeRate) {
    // Función auxiliar para manejar el case-sensitivity de PostgreSQL/Supabase
    T? getValue<T>(String key) => (json[key] ?? json[key.toLowerCase()]) as T?;

    // 1. Obtención de valores base (n_Precio1 es la base imponible en USD)
    final double basePrice = (getValue<num>('n_Precio1') ?? 0).toDouble();
    final double taxPercent = (getValue<num>('n_Impuesto1') ?? 0).toDouble();

    // Se delega el cálculo a la clase modular PriceCalculator para facilitar cambios futuros.
    final double precioTarjeta = PriceCalculator.calculatePriceBs(
      basePrice: basePrice,
      taxPercent: taxPercent,
      exchangeRate: exchangeRate,
    );

    final double priceUsdRef = PriceCalculator.calculatePriceRef(
      basePrice: basePrice,
      taxPercent: taxPercent,
    );

    return Product(
      id: (json['ID'] ?? json['id']).toString(),
      code: getValue<String>('c_Codigo') ?? '',
      name: getValue<String>('c_Descri') ?? '',
      brand: getValue<String>('c_Marca'),
      description: getValue<String>('c_Observacio'),
      priceBs: precioTarjeta,
      priceUsd: priceUsdRef,
      imageUrl: getValue<String>('c_FileImagen'),
      category: 'General',
      isFeatured: (json['n_Activo'] ?? 0) == 1,
    );
  }
}
