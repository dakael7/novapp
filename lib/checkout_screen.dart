import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:novapp/order_repository.dart';
import 'package:novapp/product_repository.dart';
import 'package:novapp/auth_repository.dart';
import 'package:novapp/profile_repository.dart';
import 'package:novapp/cart_provider.dart';
import 'package:novapp/catalog_screen.dart'; // Importar CatalogScreen para la navegación

/// Pantalla de Checkout para selección de ubicación y envío a WhatsApp.
class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double subtotalUsd;
  final double subtotalBs;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotalUsd,
    required this.subtotalBs,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with WidgetsBindingObserver {
  String? selectedSector;
  bool _isLoading = false;
  final Map<String, double> deliveryPrices = {
    'LA PICA': 2.0,
    'SANTA RITA': 2.0,
    'PALO NEGRO': 2.0,
    'PARAPARAL': 4.0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Detecta cambios en el ciclo de vida de la aplicación.
  /// Se usa para saber cuándo la app vuelve a primer plano desde WhatsApp.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLoading) {
      // Si la app se reanuda y estábamos en proceso de envío, mostramos el modal.
      _showOrderConfirmationDialog();
    }
  }

  /// Procesa el pedido: guarda en DB, arma mensaje y envía a WhatsApp.
  Future<void> _finalizarPedido() async {
    if (selectedSector == null || _isLoading) return;

    setState(() => _isLoading = true);

    // 0. Obtener datos del usuario logueado
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(user.uid);
    if (profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se encontró tu perfil.')),
        );
      }
      return;
    }

    final appId =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final deliveryUsd = deliveryPrices[selectedSector]!;

    // Obtenemos tasa para convertir delivery a Bs
    final rate = await ref.read(productRepositoryProvider).getExchangeRate();
    final deliveryBs = deliveryUsd * rate;

    final totalUsd = widget.subtotalUsd + deliveryUsd;
    final totalBs = widget.subtotalBs + deliveryBs;

    try {
      // 1. Guardar en Base de Datos
      await ref
          .read(orderRepositoryProvider)
          .saveOrder(
            sector: selectedSector!,
            appId: appId,
            userId: user.uid,
            ciCliente: profile['id_number'] ?? 'N/A',
          );

      // 2. Armar plantilla de WhatsApp
      final String fecha = DateFormat('hh:mm a').format(DateTime.now());

      StringBuffer buffer = StringBuffer();
      buffer.writeln('*DATOS DEL CLIENTE*');
      buffer.writeln('Nombre: ${profile['name']}');
      buffer.writeln('Cédula: ${profile['id_number']}');
      buffer.writeln('Teléfono: ${profile['phone_number']}');
      buffer.writeln('Sector (Ubicación): $selectedSector');
      buffer.writeln('Hora del pedido: $fecha');
      buffer.writeln('ID de Pedido: #$appId');
      buffer.writeln('\n---------------- PRODUCTOS -------------');

      for (final item in widget.cartItems) {
        final p = item.product;
        final cant = item.quantity;
        buffer.writeln('Cod: ${p.code} | Desc: ${p.name}'); // Se usa p.name
        buffer.writeln(
          'Subtotal: ${(p.priceBs * cant).toStringAsFixed(2)} Bs. / \$${(p.priceUsd * cant).toStringAsFixed(2)}',
        );
        buffer.writeln('---');
      }

      buffer.writeln('\n*TOTAL A PAGAR:*');
      buffer.writeln('Bolívares (BS): ${totalBs.toStringAsFixed(2)}');
      buffer.writeln('Dólares (USD): ${totalUsd.toStringAsFixed(2)}');

      // 3. Enviar a WhatsApp
      final phone = "+584123907028";
      final url =
          "https://wa.me/$phone?text=${Uri.encodeComponent(buffer.toString())}";

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // El estado de carga se desactiva después de que el modal se ha mostrado y resuelto.
      // No lo desactivamos aquí directamente para que didChangeAppLifecycleState pueda actuar.
    }
  }

  /// Muestra un modal de confirmación al regresar de WhatsApp.
  Future<void> _showOrderConfirmationDialog() async {
    // Aseguramos que el modal solo se muestre una vez y que el widget esté montado.
    if (!mounted) return;
    if (!Navigator.of(context).canPop()) {
      return;
    }

    // Desactivamos el estado de carga antes de mostrar el modal.
    if (mounted) setState(() => _isLoading = false);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Tu pedido ha finalizado?'),
          content: const Text(
            'Confirma si ya enviaste el mensaje por WhatsApp.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Sí'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ref.read(cartProvider.notifier).clearCart(); // Vaciar el carrito

      if (!mounted) return;
      // Navegar a la pantalla principal del catálogo, eliminando todas las rutas anteriores.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const CatalogScreen(branchName: 'Palo Negro'),
        ), // Asume un branchName por defecto o pásalo
        (Route<dynamic> route) => false,
      );
    } else {
      // Si el usuario pulsa 'No', se queda en la pantalla de checkout.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryUsd = selectedSector != null
        ? deliveryPrices[selectedSector]!
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Pago')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona tu ubicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text('Seleccionar sector'),
              initialValue: selectedSector,
              items: deliveryPrices.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('$value (\$${deliveryPrices[value]})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedSector = val),
            ),
            const Spacer(),
            if (selectedSector != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery:', style: TextStyle(fontSize: 16)),
                        Text(
                          '\$${deliveryUsd.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'TOTAL A PAGAR:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    FutureBuilder<double>(
                      future: ref
                          .read(productRepositoryProvider)
                          .getExchangeRate(),
                      builder: (context, snapshot) {
                        final rate = snapshot.data ?? 1.0;
                        final totalUsd = widget.subtotalUsd + deliveryUsd;
                        final totalBs =
                            widget.subtotalBs + (deliveryUsd * rate);

                        return Column(
                          children: [
                            Text(
                              '${totalBs.toStringAsFixed(2)} Bs.',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF27A1A),
                              ),
                            ),
                            Text(
                              '${totalUsd.toStringAsFixed(2)} \$',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _finalizarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF27A1A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CONTINUAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
