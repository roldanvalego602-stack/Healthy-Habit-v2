import 'dart:math' as math;
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'healthy_titan_skin.dart';
import '../../servicios/healthy_retro_sound_service.dart';
import '../../servicios/shop_demo_bootstrap.dart';
import '../../servicios/beta_habit_gateway.dart';
import 'shop_purchase_gateway.dart';
import 'wardrobe_screen.dart';

/// La cueva es un secreto narrativo, no una recompensa de monedas.
/// La respuesta se envía a Firebase, que determina y persiste el premio.
class HealthyTitanCaveScreen extends StatefulWidget {
  const HealthyTitanCaveScreen({super.key, this.testRequest});

  /// Solo para pruebas de UI: permite simular respuestas sin Firebase.
  /// En la navegación real siempre es null y se valida en el servidor.
  @visibleForTesting
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? testRequest;

  @override
  State<HealthyTitanCaveScreen> createState() => _HealthyTitanCaveScreenState();
}

class _HealthyTitanCaveScreenState extends State<HealthyTitanCaveScreen>
    with SingleTickerProviderStateMixin {
  final _answer = TextEditingController();
  late final AnimationController _ambient;
  bool _busy = false;
  static bool _appCheckPrepared = false;
  bool _unlocked = false;
  bool _opened = false;
  bool _consulted = false;
  int _remaining = 5;
  int _hints = 0;
  String _feedback = 'Algo aguarda detrás de las rejas.';
  static const _green = Color(0xFF83F9BA);
  static const _background = Color(0xFF060F15);
  static const _hintsText = <String>[
    'Primera inscripción: «No nazco de un solo esfuerzo».',
    'Segunda inscripción: «Crezco cada día que regresas».',
    'Tercera inscripción: «No soy fuerza ni velocidad; '
        'soy la virtud de seguir intentando».',
  ];

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this,
      duration: const Duration(seconds: 5))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  @override
  void dispose() {
    _answer.dispose();
    _ambient.dispose();
    super.dispose();
  }

  bool get _demoMode {
    if (!ShopDemoBootstrap.enabled) return false;
    if (!kDebugMode || !DemoShopPurchaseGateway.requested ||
        Firebase.app().options.projectId != ShopDemoBootstrap.demoProjectId) {
      throw StateError('Modo demo de la cueva no autorizado.');
    }
    ShopDemoBootstrap.validateMode(
      ShopDemoBootstrap.enabled, DemoShopPurchaseGateway.requested);
    return true;
  }

  Future<void> _prepareAppCheck() async {
    // Solo el proyecto Firebase de laboratorio permite emulador sin App Check.
    if (_demoMode) return;
    // La beta cerrada ya activa App Check en main.dart: no sustituir su
    // proveedor ni su token de depuración durante la navegación.
    if (BetaHabitGateway.enabled) return;
    if (_appCheckPrepared) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError('El santuario requiere un dispositivo Android autorizado.');
    }
    const debugToken = bool.fromEnvironment('HH_TITAN_APP_CHECK_DEBUG');
    if (debugToken && !kDebugMode) {
      throw StateError('App Check de depuración no se admite en release.');
    }
    await FirebaseAppCheck.instance.activate(
      androidProvider: debugToken
          ? AndroidProvider.debug : AndroidProvider.playIntegrity);
    _appCheckPrepared = true;
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> data) async {
    if (widget.testRequest != null) {
      return widget.testRequest!(data);
    }
    await _prepareAppCheck();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Inicia sesión para entrar a la cueva.');
    final functions = FirebaseFunctions.instanceFor(
      app: Firebase.app(), region: 'us-central1');
    if (_demoMode) {
      final host = DemoShopPurchaseGateway.emulatorHost;
      ShopDemoBootstrap.validateHost(host);
      if (host != ShopDemoBootstrap.host ||
          DemoShopPurchaseGateway.emulatorPort != 5001) {
        throw StateError('El emulador no coincide con el laboratorio.');
      }
      functions.useFunctionsEmulator(host, 5001);
    }
    final callable = functions.httpsCallable('titanSecret',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 15)));
    final result = await callable.call<Map<String, dynamic>>(data);
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('La sesión ha cambiado.');
    }
    return Map<String, dynamic>.from(result.data);
  }

  String _errorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'not-found':
          return 'La función del santuario aún no está desplegada en '
              'este proyecto Firebase. La escena se puede explorar, '
              'pero el acertijo no está habilitado.';
        case 'failed-precondition':
          return 'El premio está restringido mientras se revisan las '
              'reglas de seguridad y App Check. No se ha consumido '
              'ningún intento desde esta pantalla.';
        case 'unauthenticated':
          return 'Debes iniciar sesión para validar el secreto.';
        case 'permission-denied':
          return 'No se pudo validar el acceso. Revisa App Check '
              'y los permisos del proyecto.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'No se pudo contactar con Firebase. Comprueba '
              'tu conexión y vuelve a consultar el estado.';
      }
      return 'Firebase no permitió comprobar el secreto '
          '(código: ${error.code}).';
    }
    if (error is StateError) {
      return error.message.toString();
    }
    return 'No fue posible consultar el santuario. '
        'Tu progreso no se ha modificado.';
  }

  Future<void> _loadStatus() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await _request({'action': 'status'});
      if (!mounted) return;
      setState(() {
        _consulted = true;
        _unlocked = status['status'] == 'unlocked';
        _opened = _unlocked;
        _remaining = (status['remaining'] as num?)?.toInt() ?? 0;
        _feedback = _unlocked
            ? 'La celda está abierta. Titán ya pertenece a tu colección.'
            : 'La inscripción está incompleta. Tienes '
              '$_remaining intentos restantes hoy.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _consulted = false;
        _feedback = _errorMessage(error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _solve() async {
    if (_busy || _unlocked || !_consulted || _remaining <= 0 ||
        _answer.text.trim().isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await _request({
        'action': 'solve', 'answer': _answer.text.trim(),
      });
      if (!mounted) return;
      final opened = result['status'] == 'unlocked';
      setState(() {
        _unlocked = opened;
        _opened = opened;
        _remaining = (result['remaining'] as num?)?.toInt() ?? 0;
        _feedback = opened
            ? result['awarded'] == true
                ? '¡Has liberado a Mr. Healthy Titán! '
                  'La skin legendaria se añadió a tu armario.'
                : 'Titán ya estaba desbloqueado en esta cuenta.'
            : result['status'] == 'locked'
                ? 'La puerta se ha sellado por hoy. '
                  'Regresa mañana para intentarlo.'
                : 'Los barrotes permanecen cerrados. '
                  'Escucha las inscripciones e inténtalo de nuevo.';
      });
      // El audio no retrasa la apertura ni intenta actualizar la vista.
      if (opened && result['awarded'] == true) {
        unawaited(HealthyRetroSoundService.play('achievement'));
      } else if (!opened) {
        unawaited(HealthyRetroSoundService.play('error'));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _feedback = '${_errorMessage(error)} '
          'El premio no se ha confirmado. Consulta el estado antes '
          'de volver a enviar la respuesta.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final view = MediaQuery.sizeOf(context);
    final narrow = view.width < 350;
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: _green,
          surface: Color(0xFF111D23)),
      ),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(backgroundColor: _background,
          title: const Text('EL SANTUARIO OLVIDADO',
            style: TextStyle(fontSize: 14, letterSpacing: 2,
              fontWeight: FontWeight.w900)),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Consultar estado del secreto',
              onPressed: _busy ? null : _loadStatus),
          ]),
        body: SafeArea(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(narrow ? 14 : 22, 10, narrow ? 14 : 22, 35),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 530),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text('ARCHIVO 001 · EL PRISIONERO DEL UMBRAL',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, letterSpacing: 2,
                  color: _green.withValues(alpha: .8),
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _caveArtwork(reduceMotion),
              const SizedBox(height: 20),
              Text(_unlocked ? 'EL TITÁN HA DESPERTADO'
                  : 'ALGO RESPIRA AL OTRO LADO',
                textAlign: TextAlign.center,
                style: TextStyle(color: _green,
                  letterSpacing: 1.3,
                  fontSize: narrow ? 20 : 25,
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text('Una criatura de fuerza descomunal fue encerrada '
                'porque nadie comprendía de dónde provenía su poder. '
                'Tres inscripciones conservan la palabra que abre su prisión.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: Color(0xFFCAD8D3))),
              const SizedBox(height: 18),
              _inscriptions(),
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(_feedback,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFE7D7A5),
                  fontSize: 13, height: 1.5))),
              const SizedBox(height: 14),
              if (!_unlocked && !_consulted) ...[
                OutlinedButton.icon(
                  key: const Key('titan-reintentar-conexion'),
                  onPressed: _busy ? null : _loadStatus,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Volver a comprobar el santuario'),
                ),
                const SizedBox(height: 8),
              ],
              if (!_unlocked) ...[
                TextField(
                  key: const Key('titan-respuesta'),
                  controller: _answer,
                  maxLength: 70,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _solve(),
                  decoration: InputDecoration(
                    labelText: '¿Qué palabra libera a la criatura?',
                    hintText: 'Escribe una sola palabra',
                    prefixIcon: const Icon(Icons.key_rounded),
                    filled: true, fillColor: const Color(0xFF16262A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  )),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('titan-validar'),
                  onPressed: _busy || !_consulted ||
                      _remaining <= 0 ? null : _solve,
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(_busy ? 'Comprobando...'
                      : 'Pronunciar la palabra'),
                ),
                Text('Intentos disponibles hoy: $_remaining de 5 · '
                  'No cuesta Habit Coins.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11,
                    color: Color(0xFF9CB4AD))),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WardrobeScreen(initialSlot: 'skin'),
                    ),
                  ),
                  icon: const Icon(Icons.checkroom_rounded),
                  label: const Text('Equipar Titán en el Armario')),
                const SizedBox(height: 7),
                const Text('Skin legendaria exclusiva · '
                  'Un desbloqueo por cuenta · Sin monedas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB4E4C5), fontSize: 12)),
              ],
            ]),
          )),
        )),
      ),
    );
  }

  Widget _inscriptions() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFF121E23),
      border: Border.all(color: const Color(0xFF385950)),
      borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('INSCRIPCIONES DE PIEDRA',
          style: TextStyle(fontSize: 11, letterSpacing: 1.5,
            fontWeight: FontWeight.w800, color: _green)),
        const SizedBox(height: 10),
        for (var i = 0; i < _hints; i++)
          Padding(padding: const EdgeInsets.only(bottom: 9),
            child: Text(_hintsText[i],
              style: const TextStyle(color: Color(0xFFDEE9DC),
                height: 1.45))),
        if (_hints < _hintsText.length)
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _hints++);
              HealthyRetroSoundService.play('tap');
            },
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: Text(_hints == 0 ? 'Descifrar primera pista'
                : 'Descifrar otra pista')),
        if (_hints == _hintsText.length)
          const Text('Las tres runas han sido reveladas.',
            style: TextStyle(color: Color(0xFF91BEAC), fontSize: 11)),
      ]),
  );

  Widget _caveArtwork(bool reduceMotion) => AspectRatio(
    aspectRatio: 1.07,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (context, _) {
          final wave = reduceMotion ? .5 : _ambient.value;
          return CustomPaint(
            painter: _CavePainter(wave: wave, released: _unlocked),
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                bottom: 4, height: 225, width: 212,
                child: AnimatedScale(
                  duration: reduceMotion
                      ? Duration.zero : const Duration(milliseconds: 750),
                  curve: Curves.easeOutBack,
                  scale: _unlocked ? 1.13 : .8 + wave * .025,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 450),
                    opacity: _unlocked ? 1 : .3,
                    child: const HealthyTitanSkin(size: 200)),
                ),
              ),
              Positioned.fill(child: IgnorePointer(child: Row(
                children: [
                  Expanded(child: AnimatedSlide(
                    duration: reduceMotion ? Duration.zero
                        : const Duration(milliseconds: 1200),
                    curve: Curves.easeInOutCubic,
                    offset: _opened ? const Offset(-1.1, 0) : Offset.zero,
                    child: const SizedBox.expand(child:
                      CustomPaint(painter: _CagePainter(left: true))))),
                  Expanded(child: AnimatedSlide(
                    duration: reduceMotion ? Duration.zero
                        : const Duration(milliseconds: 1200),
                    curve: Curves.easeInOutCubic,
                    offset: _opened ? const Offset(1.1, 0) : Offset.zero,
                    child: const SizedBox.expand(child:
                      CustomPaint(painter: _CagePainter(left: false))))),
                ],
              ))),
              if (!_unlocked)
                const Positioned(bottom: 10,
                  child: Icon(Icons.lock_rounded,
                    color: Color(0xFFC8B078), size: 34)),
              if (_unlocked)
                Positioned(top: 12,
                  child: Text('LIBERADO',
                    style: TextStyle(color: _green,
                      fontWeight: FontWeight.w900, letterSpacing: 4,
                      shadows: const [Shadow(
                        blurRadius: 16, color: Color(0xFF4AEDAD))]))),
            ]),
          );
        },
      ),
    ),
  );
}

class _CavePainter extends CustomPainter {
  const _CavePainter({required this.wave, required this.released});
  final double wave;
  final bool released;
  @override
  void paint(Canvas c, Size s) {
    final bounds = Offset.zero & s;
    c.drawRect(bounds, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF050B13),Color(0xFF172A2F),
        Color(0xFF071015)]).createShader(bounds));
    c.drawOval(Rect.fromCenter(center: Offset(s.width*.5,s.height*.62),
      width:s.width*.71,height:s.height*.92),
      Paint()..shader=RadialGradient(colors: [
        (released ? const Color(0xFF4EEE9A):const Color(0xFF357B68))
          .withValues(alpha:.2+wave*.12),
        const Color(0x00000000),
      ]).createShader(bounds));
    final rock = Paint()..color=const Color(0xFF23353A);
    final shade = Paint()..color=const Color(0xFF101C21);
    for (var i=0;i<10;i++) {
      final j=i.toDouble();
      final x=s.width*(j/9);
      final height=s.height*(.1+(math.sin(j*2.4)+1)*.075);
      final p=Path()..moveTo(x-37,0)..lineTo(x,height)
        ..lineTo(x+35,0)..close();
      c.drawPath(p,i.isEven?rock:shade);
    }
    for(var i=0;i<8;i++){
      final x=s.width*(i/7);
      final p=Path()..moveTo(x-29,s.height)
        ..lineTo(x+8,s.height*(.86+math.cos(i*1.8)*.055))
        ..lineTo(x+46,s.height)..close();
      c.drawPath(p,rock);
    }
    final sparks=Paint()..color=const Color(0xFF75E5AB)
      .withValues(alpha:.25+wave*.3);
    for(var i=0;i<13;i++){
      final x=(math.sin(i*22.7)*.45+.5)*s.width;
      final y=(math.cos(i*11.3)*.35+.5)*s.height;
      c.drawCircle(Offset(x,y),1.5+(i%3)*.7,sparks);
    }
  }
  @override
  bool shouldRepaint(covariant _CavePainter old) =>
      old.wave!=wave || old.released!=released;
}

class _CagePainter extends CustomPainter {
  const _CagePainter({required this.left});
  final bool left;
  @override
  void paint(Canvas c, Size s) {
    final iron=Paint()..shader=const LinearGradient(colors: [
      Color(0xFF2D3C47), Color(0xFF8A9B9C), Color(0xFF1F3036),
    ]).createShader(Offset.zero & s)..strokeWidth=9
      ..strokeCap=StrokeCap.round;
    final near=Paint()..color=const Color(0xFF162127)..strokeWidth=2;
    for(var i=0;i<4;i++){
      final x=s.width*(i+.2)/3.5;
      c.drawLine(Offset(x,0),Offset(x,s.height),iron);
      c.drawLine(Offset(x+5,0),Offset(x+5,s.height),near);
    }
    for (final y in [s.height*.17,s.height*.79]) {
      c.drawLine(Offset(0,y),Offset(s.width,y),iron);
    }
    final hinge=Paint()..color=const Color(0xFFBDA77A);
    final cx=left?s.width-8.0:8.0;
    c.drawCircle(Offset(cx,s.height*.49),10,hinge);
    c.drawCircle(Offset(cx,s.height*.49),4,
      Paint()..color=const Color(0xFF263235));
  }
  @override
  bool shouldRepaint(covariant _CagePainter oldDelegate) => false;
}
