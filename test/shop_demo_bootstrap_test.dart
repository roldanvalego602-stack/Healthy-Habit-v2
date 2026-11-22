import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/shop_demo_bootstrap.dart';

void main() {
  test('la versión normal conserva ambos flags apagados', () {
    expect(ShopDemoBootstrap.enabled, isFalse);
    expect(ShopDemoBootstrap.purchaseEnabled, isFalse);
    expect(() => ShopDemoBootstrap.validateMode(false, false),
        returnsNormally);
  });

  test('no se permite mezclar compra demo con conexión normal', () {
    expect(() => ShopDemoBootstrap.validateMode(false, true),
        throwsStateError);
    expect(() => ShopDemoBootstrap.validateMode(true, false),
        throwsStateError);
    expect(() => ShopDemoBootstrap.validateMode(true, true),
        returnsNormally);
  });

  test('la configuración de prueba usa un proyecto sintético', () {
    final options = ShopDemoBootstrap.demoOptions;
    expect(options.projectId, 'demo-healthy-habit');
    expect(options.projectId, isNot('cloud-firestore-d8c61'));
    expect(options.apiKey, 'demo-api-key');
    expect(() => ShopDemoBootstrap.validateInitializedProject(
      'cloud-firestore-d8c61'), throwsStateError);
    expect(() => ShopDemoBootstrap.validateInitializedProject(
      'demo-healthy-habit'), returnsNormally);
  });

  test('solo se aceptan hosts loopback o del emulador Android', () {
    for (final host in ['127.0.0.1', 'localhost', '10.0.2.2']) {
      expect(() => ShopDemoBootstrap.validateHost(host), returnsNormally);
    }
    for (final host in [
      '192.168.1.55', 'example.com', '', '0.0.0.0',
    ]) {
      expect(() => ShopDemoBootstrap.validateHost(host), throwsStateError);
    }
  });
}
