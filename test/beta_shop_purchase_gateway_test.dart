import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/tienda/beta_shop_purchase_gateway.dart';

void main() {
  test('las claves de compra separan artículos y usuarios', () {
    final first = BetaShopPurchaseGateway.pendingKey(
      'usuarioA', 'crown',
    );
    final second = BetaShopPurchaseGateway.pendingKey(
      'usuarioA', 'cape',
    );
    final third = BetaShopPurchaseGateway.pendingKey(
      'usuarioB', 'crown',
    );
    expect(first, 'hh_beta_shop_pending_v1_usuarioA_crown');
    expect(first, isNot(second));
    expect(first, isNot(third));
  });

  test('bloquea artículos con rutas o identificadores inválidos', () {
    expect(
      () => BetaShopPurchaseGateway.pendingKey('usuarioA', '../system'),
      throwsArgumentError,
    );
    expect(
      () => BetaShopPurchaseGateway.pendingKey('usuarioA', 'crown/other'),
      throwsArgumentError,
    );
    expect(
      () => BetaShopPurchaseGateway.pendingKey('', 'crown'),
      throwsArgumentError,
    );
  });

  test('no envía compras con la beta apagada', () async {
    await expectLater(
      const BetaShopPurchaseGateway().comprar('crown'),
      throwsA(isA<StateError>()),
    );
  });

  test('no enumera compras con la beta apagada', () async {
    await expectLater(
      const BetaShopPurchaseGateway().listarPendientes(),
      throwsA(isA<StateError>()),
    );
  });
}
