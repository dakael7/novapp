/// Clase encargada de centralizar las fórmulas financieras del catálogo.
/// Permite editar los cálculos de precios de forma modular.
class PriceCalculator {
  /// Calcula el precio de venta final en Bolívares (Precio_Tarjeta).
  /// Sigue el orden: (Base + Impuesto) * Factor, con redondeo a 2 decimales.
  static double calculatePriceBs({
    required double basePrice,
    required double taxPercent,
    required double exchangeRate,
  }) {
    // 1. Cálculo del monto del impuesto
    final double taxAmount = basePrice * (taxPercent / 100);

    // 2. Suma del total en moneda extranjera (USD)
    final double totalUsd = basePrice + taxAmount;

    // 3. Conversión a moneda local (BS) y ajuste contable (Redondeo a 2 decimales)
    return (totalUsd * exchangeRate * 100).roundToDouble() / 100;
  }

  /// Calcula el precio de Referencia (REF) en USD.
  /// Sigue el orden: Base + Impuesto (Ej: 1.0 + 0.16 = 1.16).
  static double calculatePriceRef({
    required double basePrice,
    required double taxPercent,
  }) {
    final double taxAmount = basePrice * (taxPercent / 100);
    return basePrice + taxAmount;
  }
}
