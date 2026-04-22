import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercanova_go/supabase_provider.dart';

/// Repositorio encargado de registrar las transacciones en la tabla ma_pedidos_core.
class OrderRepository {
  final SupabaseClient _client;
  OrderRepository(this._client);

  Future<void> saveOrder({
    required String sector,
    required String appId,
    required String userId,
    required String ciCliente,
  }) async {
    try {
      await _client.from('ma_pedidos_core').insert({
        'user_id': userId,
        'ubicacion': sector,
        'ci_cliente': ciCliente,
        'app_id': appId,
      });
    } catch (e) {
      throw Exception('No se pudo registrar el pedido en Supabase: $e');
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(supabaseClientProvider));
});
