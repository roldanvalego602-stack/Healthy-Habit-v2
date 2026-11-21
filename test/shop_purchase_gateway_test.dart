import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/tienda/shop_purchase_gateway.dart';

void main() {
  test('por defecto la compra experimental permanece deshabilitada', () {
    expect(DemoShopPurchaseGateway.requested, isFalse);
  });

  test('un proyecto real nunca puede habilitar compras del piloto', () {
    expect(
      () => DemoShopPurchaseGateway.requireDemoProject(
        true, 'cloud-firestore-d8c61'),
      throwsStateError,
    );
    expect(
      () => DemoShopPurchaseGateway.requireDemoProject(
        false, 'demo-healthy-habit'),
      throwsStateError,
    );
    expect(
      () => DemoShopPurchaseGateway.requireDemoProject(
        true, 'demo-healthy-habit'),
      returnsNormally,
    );
  });

  test('el payload contiene identificadores sin datos de economía', () {
    final request = DemoShopPurchaseGateway.purchasePayload(
      'crown', 'shop_operation_00001');
    expect(request, {
      'itemId': 'crown',
      'operationId': 'shop_operation_00001',
    });
    expect(request.containsKey('price'), isFalse);
    expect(request.containsKey('habitCoins'), isFalse);
    expect(request.containsKey('shopInventory'), isFalse);
  });

  test('rechaza IDs de rutas y operaciones inválidas', () {
    expect(
      () => DemoShopPurchaseGateway.purchasePayload(
        '../users', 'shop_operation_00001'),
      throwsArgumentError,
    );
    expect(
      () => DemoShopPurchaseGateway.purchasePayload(
        'crown', '../operation'),
      throwsArgumentError,
    );
    expect(
      () => DemoShopPurchaseGateway.purchasePayload('crown', 'short'),
      throwsArgumentError,
    );
  });
}
