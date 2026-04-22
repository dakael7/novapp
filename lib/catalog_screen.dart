import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercanova_go/cart_provider.dart';
import 'package:mercanova_go/auth_repository.dart';
import 'package:mercanova_go/auth_screen.dart';
import 'package:mercanova_go/cart_screen.dart';
import 'package:mercanova_go/search_provider.dart';
import 'package:mercanova_go/search_results_screen.dart';
import 'package:mercanova_go/product_details_screen.dart';
import 'package:mercanova_go/product.dart';
import 'package:mercanova_go/product_repository.dart';
import 'package:mercanova_go/profile_screen.dart';
import 'package:mercanova_go/product_list_screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  final String branchName;

  const CatalogScreen({super.key, required this.branchName});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  // Lista inicial de sugerencias (Esto vendrá de tu base de datos mediante la API)
  final List<String> _searchSuggestions = [
    'Harina PAN 1KG',
    'Pepsi 2 Litros',
    'Gatorade Surtido',
    'Nestea Durazno',
    'Leche Completa',
    'Arroz Primor',
    'Aceite Vegetal',
    'Pasta Primor',
    'Café Fama de América',
  ];

  @override
  Widget build(BuildContext context) {
    // Observamos el estado del carrito para que el conteo sea reactivo
    final cartItems = ref.watch(cartProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final featuredProducts = ref.watch(featuredProductsProvider);
    final mercanovaOffers = ref.watch(mercanovaOffersProvider);
    final promociones = ref.watch(promocionesProvider);

    final double totalItems = cartItems.values.fold(
      0.0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      // Floating Action Button para el carrito (Neuromarketing: Zona de acción del pulgar)
      floatingActionButton: Badge(
        label: Text(
          totalItems % 1 == 0
              ? totalItems.toInt().toString()
              : totalItems.toStringAsFixed(1),
        ),
        isLabelVisible: totalItems > 0,
        alignment:
            Alignment.topLeft, // Posición superior izquierda como se solicitó
        backgroundColor: const Color(0xFF00823B), // Verde frescura
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const CartScreen()));
          },
          backgroundColor: const Color(0xFFF27A1A),
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F6F8),
      // Sidebar (Cajón lateral) con identidad de marca
      drawer: _buildSidebar(context),
      body: Stack(
        children: [
          // Efecto de iluminación amarilla sutil (Inspirado en instagram.png)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFC700).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Decoraciones de fondo (Inspiradas en instagram.png)
          Positioned(
            top: 200,
            right: -30,
            child: Opacity(
              opacity: 0.05,
              child: Transform.rotate(
                angle: 0.2,
                child: const Icon(
                  Icons.eco,
                  size: 180,
                  color: Color(0xFF00823B),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: Opacity(
              opacity: 0.05,
              child: const Icon(
                Icons.circle,
                size: 220,
                color: Color(0xFFFFC700),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Unificado (Inspirado en catalogo.png)
              SliverAppBar(
                toolbarHeight: 75,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFFF27A1A),
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                // Burbuja de conteo minimalista al lado del searchbar
                actions: [
                  if (totalItems > 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CartScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00823B),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              totalItems % 1 == 0
                                  ? totalItems.toInt().toString()
                                  : totalItems.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                // Búsqueda integrada en el título para mejor distribución
                title: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      // Si no hay texto, mostramos historial y destacados
                      if (textEditingValue.text.isEmpty) {
                        return [
                          ...searchHistory,
                          ...?featuredProducts.asData?.value.map((p) => p.name),
                        ];
                      }
                      // Búsqueda con soporte para coincidencias inexactas (Fuzzy Search)
                      final query = textEditingValue.text.toLowerCase();
                      return _searchSuggestions.where((String option) {
                        final target = option.toLowerCase();
                        if (target.contains(query)) return true;

                        final words = target.split(' ');
                        for (final word in words) {
                          // Tolerancia de hasta 2 errores para palabras largas o 1 para cortas
                          if (_levenshteinDistance(word, query) <=
                              (query.length > 5 ? 2 : 1)) {
                            return true;
                          }
                          // Verificación de prefijo similar para búsqueda predictiva fluida
                          if (word.length >= query.length && query.length > 2) {
                            if (_levenshteinDistance(
                                  word.substring(0, query.length),
                                  query,
                                ) <=
                                1) {
                              return true;
                            }
                          }
                        }
                        return false;
                      });
                    },
                    onSelected: (String selection) {
                      // Registramos la búsqueda en el historial real
                      ref
                          .read(searchHistoryProvider.notifier)
                          .addSearch(selection);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              SearchResultsScreen(query: selection),
                        ),
                      );
                    },
                    // Mantiene la estética actual de la barra de búsqueda
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(
                              hintText: 'Buscar productos...',
                              hintStyle: TextStyle(
                                color: Colors.black26,
                                fontSize: 15,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFFF27A1A),
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(bottom: 5),
                            ),
                            onSubmitted: (value) {
                              // Al no llamar a onFieldSubmitted(), evitamos que Autocomplete elija la primera opción automáticamente.
                              if (value.trim().isNotEmpty) {
                                // Procesamos la búsqueda con el texto literal ingresado por el usuario.
                                ref
                                    .read(searchHistoryProvider.notifier)
                                    .addSearch(value);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SearchResultsScreen(query: value),
                                  ),
                                );
                              }
                              focusNode
                                  .unfocus(); // Cerramos el teclado tras la búsqueda
                            },
                          );
                        },
                    // Personalización del menú desplegable de sugerencias
                    optionsViewBuilder: (context, onSelected, options) {
                      final bool isShowingDefault =
                          options.length ==
                          (searchHistory.length +
                              (featuredProducts.value?.length ?? 0));

                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 10,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            constraints: const BoxConstraints(maxHeight: 350),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);

                                // Lógica para insertar encabezados de sección
                                Widget? header;
                                if (isShowingDefault) {
                                  if (index == 0) {
                                    header = _buildSearchHeader('RECIENTES');
                                  } else if (index == searchHistory.length) {
                                    header = _buildSearchHeader('SUGERIDOS');
                                  }
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    header ?? const SizedBox.shrink(),
                                    ListTile(
                                      leading: Icon(
                                        isShowingDefault &&
                                                index < searchHistory.length
                                            ? Icons.history_rounded
                                            : Icons.star_outline_rounded,
                                        color: const Color(
                                          0xFFF27A1A,
                                        ).withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                      title: Text(
                                        option,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () => onSelected(option),
                                    ),
                                    if (index < options.length - 1)
                                      const Divider(
                                        height: 1,
                                        color: Colors.black12,
                                        indent: 50,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF27A1A), Color(0xFFF7941D)],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Banner Publicitario de Partner (Kraft) - Proporción preservada
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/banner_partner.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),

              // 4. Sección: Mercanova Ofertas (Horizontal)
              mercanovaOffers.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      _buildSectionHeader(
                        'Mercanova Ofertas',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              title: 'Mercanova Ofertas',
                              products: products,
                            ),
                          ),
                        ),
                        icon: Icons.local_fire_department_rounded,
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 280,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: products.length > 8
                                ? 8
                                : products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(
                                product: products[index],
                                headerColor: const Color(0xFF00823B),
                                buttonColor: const Color(0xFFF27A1A),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // 5. Sección: Promociones (Grid 4 items)
              promociones.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  final previewList = products.take(4).toList();
                  return SliverMainAxisGroup(
                    slivers: [
                      _buildSectionHeader(
                        'Promociones',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              title: 'Promociones',
                              products: products,
                            ),
                          ),
                        ),
                        icon: Icons.sell_outlined,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 25,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.62,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildProductCard(
                              product: previewList[index],
                              headerColor: const Color(
                                0xFF00823B,
                              ), // Cambio a verde para Promociones
                              buttonColor: const Color(0xFF00823B),
                            ),
                            childCount: previewList.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // 6. Sección: Productos Destacados (Grid 6 items)
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              featuredProducts.when(
                data: (products) {
                  // Filtramos para que productos en oferta no se repitan en destacados
                  final previewList = products
                      .where((p) => p.offerType == null)
                      .take(6)
                      .toList();
                  return SliverMainAxisGroup(
                    slivers: [
                      _buildSectionHeader(
                        'Productos Destacados',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              title: 'Productos Destacados',
                              products: products,
                            ),
                          ),
                        ),
                        icon: Icons.stars_rounded,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 25,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.62,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildProductCard(
                              product: previewList[index],
                              headerColor: const Color(0xFFF27A1A),
                              buttonColor: const Color(0xFFF27A1A),
                            ),
                            childCount: previewList.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el encabezado de cada sección con el botón "Ver más".
  Widget _buildSectionHeader(
    String title,
    VoidCallback onMorePressed, {
    IconData? icon,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFFF27A1A), size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onMorePressed,
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  color: Color(0xFFF27A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un modal para seleccionar el gramaje de productos vendidos por peso.
  void _showWeightPicker(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 10,
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        tempWeight < 1.0
                            ? '${(tempWeight * 1000).toInt()} gr'
                            : '${tempWeight.toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontSize: 36,
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 25),
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
                            content: Text(
                              '${product.name} (${tempWeight < 1.0 ? (tempWeight * 1000).toInt() : tempWeight} ${tempWeight < 1.0 ? 'gr' : 'kg'}) añadido',
                            ),
                            backgroundColor: const Color(0xFF00823B),
                            duration: const Duration(seconds: 2),
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
                          fontSize: 16,
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

  /// Widget de Tarjeta de Producto rediseñado para un look profesional.
  Widget _buildProductCard({
    required Product product,
    required Color headerColor,
    required Color buttonColor,
  }) {
    final String id = product.id;
    final String name = product.name;
    final double price = product.priceBs;
    final double refPrice = product.priceUsd;
    final String? brand = product.brand;

    // Lógica dinámica: Si es oferta o promoción, el cabezal SIEMPRE es verde
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
          ? [
              const Color(0xFF00823B),
              const Color(0xFF009142), // Verde mucho más leve
            ] // Verde profundo a fresco
          : [
              const Color(0xFFF27A1A),
              const Color(0xFFF58D38), // Naranja suave, no amarillo
            ], // Naranja a Amarillo
    );

    final Gradient buttonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isButtonGreen
          ? [const Color(0xFF00823B), const Color(0xFF009142)]
          : [const Color(0xFFF27A1A), const Color(0xFFF58D38)],
    );

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
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
          // Cabecera clicable para ir al detalle
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
                        brand ?? 'Mercanova Go',
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
                        overflow: TextOverflow.ellipsis,
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
          // Cuerpo: Imagen y Botón
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
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Hero(
                        tag: id,
                        child: Icon(
                          // Corregido: withOpacity a withValues
                          Icons.inventory_2_outlined,
                          size: 65,
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ),
                ),
                // Botón de Agregar (Cuadrado con bordes suaves según catalogo.png)
                Positioned(
                  bottom: 0, // Al raz del borde inferior
                  right: 0, // Al raz del borde derecho
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
                    shadowColor: buttonColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el menú lateral (Sidebar/Drawer) con la identidad de Mercanova Go.
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo y Nombre de la App juntos y centrados
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 50),
                    const SizedBox(width: 12),
                    const Text(
                      'Mercanova Go',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF27A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Identificador de sede centrado en el eje X
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00823B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.branchName,
                    style: const TextStyle(
                      color: Color(0xFF00823B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSidebarItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          _buildSidebarItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Mis pedidos',
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.info_outline_rounded,
            label: 'Acerca de',
            onTap: () {},
          ),
          const Divider(indent: 20, endIndent: 20, height: 30),
          _buildSidebarItem(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            onTap: () async {
              // Ejecuta el cierre de sesión en todos los proveedores configurados
              await ref.read(authRepositoryProvider).signOut();

              if (context.mounted) {
                // Navegamos al inicio de sesión eliminando todas las rutas previas
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF27A1A)),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  /// Genera un encabezado sutil para las secciones del buscador
  Widget _buildSearchHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black38,
          fontSize: 10,
          fontFamily: 'Argentum Sans',
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Calcula la distancia de Levenshtein entre dos cadenas para búsqueda difusa.
  /// Permite encontrar coincidencias incluso con errores ortográficos.
  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i].toLowerCase() == t[j].toLowerCase()) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }
}

/// Widget personalizado que encapsula el botón "+" con una animación de "explosión de partículas".
class _AnimatedAddButton extends StatefulWidget {
  final VoidCallback onTap;
  final Gradient gradient;
  final Color shadowColor;

  const _AnimatedAddButton({
    required this.onTap,
    required this.gradient,
    required this.shadowColor,
  });

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
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(-2, -2),
                ),
              ],
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

    const int count = 16; // Más partículas para un efecto más denso
    const double gravity =
        80.0; // Gravedad un poco más marcada para el efecto de caída

    for (int i = 0; i < count; i++) {
      // Distribución uniforme en círculo (fuego artificial)
      double angle = (i * (360 / count)) * (3.14159 / 180);

      // Velocidad aumentada para mayor alcance de dispersión
      double velocity = 40 + (i * 15 % 40);

      // Movimiento radial (explosión)
      double radialDistance = progress * velocity;
      Offset explosionDir = Offset.fromDirection(angle, radialDistance);

      // Efecto de caída parabólica por gravedad (y = 0.5 * g * t^2)
      double drop = 0.5 * gravity * progress * progress;

      // Posición final combinada
      Offset finalPos = Offset(explosionDir.dx, explosionDir.dy + drop);

      canvas.drawCircle(finalPos, 5.0 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
