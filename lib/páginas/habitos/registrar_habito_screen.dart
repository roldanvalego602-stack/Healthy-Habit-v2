import '../niveles/levels_system.dart';
import '../estadisticas/daily_streak_screen.dart';
import '../estadisticas/daily_streak_reward_dialog.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_celebration.dart';
import 'temporary_evidence_service.dart';
import 'healthy_vision_preview_panel.dart';
import '../../servicios/healthy_vision_debug_service.dart';
import '../../servicios/official_habit_emulator_service.dart';
import '../../servicios/beta_habit_gateway.dart';
import '../../servicios/habit_evidence_image_preparer.dart';
import '../../servicios/operaciones_habitos_pendientes.dart';
import '../../servicios/healthy_reminders_service.dart';
import 'habit_interaction_card.dart';

class RegistrarHabitoScreen extends StatefulWidget {
  final String? habitId;
  final String? attemptId;
  final String? habitTitle;
  final String? category;
  final int? currentProgress;
  final int? goal;
  const RegistrarHabitoScreen({
    super.key,
    this.habitId,
    this.attemptId,
    this.habitTitle,
    this.category,
    this.currentProgress,
    this.goal,
  });
  @override
  State<RegistrarHabitoScreen> createState() => _RegistrarHabitoScreenState();
}

class _RegistrarHabitoScreenState extends State<RegistrarHabitoScreen> {
  late final FirebaseFirestore _db;
  final TextEditingController _notaController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _imagenSeleccionada;
  Uint8List? _bytesImagen;
  bool _guardando = false;
  bool _modoPasos = false;
  int _pasoRegistro = 0;
  bool _cargando = true;
  final bool _subiendoImagen = false;
  String _interactionType = 'manual';
  int _interactionTarget = 1;
  String _interactionUnit = 'vez';
  bool _interactionComplete = true;
  int _interactionValue = 0;
  String? _error;
  String _nombreHabito = 'Tomar 6 vasos de agua';
  String _categoria = 'Hidratación';
  int _progreso = 0;
  int _meta = 6;
  DocumentReference<Map<String, dynamic>>? _habitoRef;
  DocumentReference<Map<String, dynamic>>? _attemptRef;
  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get _habitos {
    return _userDoc.collection('user_habits');
  }

  bool get _metaCompletada => _meta > 0 && _progreso >= _meta;
  bool get _puedeGuardar =>
      !_guardando && !_cargando && !_metaCompletada && _interactionComplete;
  @override
  void initState() {
    super.initState();
    _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    _nombreHabito = widget.habitTitle ?? _nombreHabito;
    _categoria = widget.category ?? _categoria;
    _progreso = widget.currentProgress ?? 0;
    _meta = widget.goal ?? 6;
    _cargarHabito();
    TemporaryEvidenceService.cleanExpiredForCurrentUser().then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('No se pudieron limpiar evidencias vencidas: $error');
      },
    );
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  int _leerEntero(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _cargarHabito() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Inicia sesión para registrar un hábito.';
        });
      }
      return;
    }
    try {
      if (widget.habitId == null ||
          widget.habitId!.isEmpty ||
          widget.attemptId == null ||
          widget.attemptId!.isEmpty) {
        throw Exception(
          'No se recibió el identificador del hábito y su intento.',
        );
      }
      final habitoRef = _habitos.doc(widget.habitId);
      final attemptRef = habitoRef.collection('attempts').doc(widget.attemptId);
      final resultados = await Future.wait([habitoRef.get(), attemptRef.get()]);
      final habitoSnapshot =
          resultados[0];
      final attemptSnapshot =
          resultados[1];
      if (!habitoSnapshot.exists) {
        throw Exception('No se encontró el hábito seleccionado.');
      }
      if (!attemptSnapshot.exists) {
        throw Exception('No se encontró el intento del hábito.');
      }
      final datosHabito = habitoSnapshot.data()!;
      final datosAttempt = attemptSnapshot.data()!;
      final estado = (datosAttempt['status'] ?? '').toString();
      if (estado != 'inProgress') {
        throw Exception(
          'Este intento ya no está activo y no admite registros.',
        );
      }
      _habitoRef = habitoRef;
      _attemptRef = attemptRef;
      _nombreHabito =
          (datosHabito['title'] ??
                  datosHabito['name'] ??
                  datosHabito['nombre'] ??
                  _nombreHabito)
              .toString();
      _categoria =
          (datosHabito['category'] ?? datosHabito['categoria'] ?? _categoria)
              .toString();
      _progreso = _leerEntero(datosAttempt['progress'], _progreso);
      // El objetivo interactivo es por sesión; no altera la meta del intento.
      final rawInteraction = datosHabito['interaction'];
      final interaction =
          rawInteraction is Map ? rawInteraction : <String, dynamic>{};
      final configuredType = (interaction['type'] ?? '').toString();
      final text = '$_nombreHabito $_categoria'.toLowerCase();
      final fallbackType =
          text.contains('agua') || text.contains('vaso')
              ? 'counter'
              : text.contains('caminar') ||
                  text.contains('correr') ||
                  text.contains('ejercicio')
              ? 'stopwatch'
              : 'manual';
      final type = configuredType.isEmpty ? fallbackType : configuredType;
      _interactionType =
          const {'counter', 'stopwatch', 'timer', 'steps', 'hydration', 'breathing', 'pomodoro'}.contains(type) ? type : 'manual';
      _interactionTarget = _leerEntero(
        interaction['target'],
        _interactionType == 'counter' ? 1 : 60,
      ).clamp(1, 86400);
      _interactionUnit =
          (interaction['unit'] ??
                  (_interactionType == 'counter' ? 'vaso' : 'segundos'))
              .toString();
      _interactionComplete = _interactionType == 'manual';
      _meta = _leerEntero(datosAttempt['target'], widget.goal ?? 6);
      if (_meta < 1) _meta = 1;
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudo cargar el hábito: $e';
        });
      }
    }
  }

  Future<void> _seleccionarImagen(ImageSource origen) async {
    if (_guardando || _cargando) return;
    if (BetaHabitGateway.enabled) {
      _mostrarMensaje('La evidencia fotográfica no está disponible en beta.');
      return;
    }
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: origen,
        imageQuality: 35,
        maxWidth: 640,
        maxHeight: 640,
      );
      if (!mounted || imagen == null) return;
      final bytes = await imagen.readAsBytes();
      if (!mounted) return;
      // En modo oficial, la evidencia se vuelve a codificar como JPEG
      // de máximo 250 KB, sin metadatos EXIF del archivo original.
      final prepared = OfficialHabitEmulatorService.enabled
          ? const HabitEvidenceImagePreparer().prepare(bytes).bytes
          : bytes;
      if (prepared.lengthInBytes > TemporaryEvidenceService.maxImageBytes) {
        _mostrarMensaje(
          'La imagen supera 250 KB. Selecciona otra más pequeña.',
        );
        return;
      }
      setState(() {
        _imagenSeleccionada = imagen;
        _bytesImagen = prepared;
        _error = null;
      });
    } catch (e) {
      _mostrarMensaje(
        'No se pudo seleccionar la imagen. '
        'Comprueba los permisos o la compatibilidad del dispositivo.',
      );
    }
  }

  void _quitarImagen() {
    if (_guardando) return;
    setState(() {
      _imagenSeleccionada = null;
      _bytesImagen = null;
    });
  }

  // Fecha civil local, independiente de los cambios de horario de verano.
  String _fechaLocal(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';

  int? _diasEntreFechas(String anterior, String actual) {
    final a = DateTime.tryParse(anterior);
    final b = DateTime.tryParse(actual);
    if (a == null || b == null) return null;
    final diaA = DateTime.utc(a.year, a.month, a.day);
    final diaB = DateTime.utc(b.year, b.month, b.day);
    return diaB.difference(diaA).inDays;
  }

  Future<void> _guardarRegistro() async {
    if (!_puedeGuardar) return;
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      _mostrarMensaje('Debes iniciar sesión para guardar el registro.');
      return;
    }
    final habitoRef = _habitoRef;
    final attemptRef = _attemptRef;
    if (habitoRef == null || attemptRef == null) {
      _mostrarMensaje('No se pudo identificar el intento del hábito.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      // La foto opcional no concede XP adicional ni verifica el hábito.
      // Solo funciona en el proyecto aislado demo-healthy-habit.
      if (OfficialHabitEmulatorService.enabled || BetaHabitGateway.enabled) {
        if (!const {'manual', 'counter', 'hydration', 'timer', 'stopwatch',
              'breathing', 'pomodoro', 'steps'}
                .contains(_interactionType)) {
          throw StateError('Tipo de interacción no admitido en el piloto.');
        }
        // La sesión guiada o cronometrada es una declaración del cliente;
        // no acredita tiempo físicamente verificado. El backend
        // valida el formato y los periodos, nunca concede XP extra por
        // la cantidad informada.
        final Map<String, dynamic>? interaction =
            _interactionType == 'manual' ? null : {
              'type': _interactionType,
              'value': _interactionValue,
              'target': _interactionTarget,
              'unit': _interactionType == 'steps'
                  ? 'pasos' : _interactionUnit,
            };
        const service = OfficialHabitEmulatorService();
        final photoBytes = _bytesImagen;
        // En beta no existe endpoint de evidencias: rechazar antes de
        // solicitar registro, sin convertir una foto en registro normal.
        if (BetaHabitGateway.enabled && photoBytes != null) {
          throw StateError(
            'Las evidencias aún no están disponibles en la beta cerrada.',
          );
        }
        final response = BetaHabitGateway.enabled
            ? await const PendingBetaHabitOperations().execute(
                action: 'registrar',
                habitId: habitoRef.id,
                attemptId: attemptRef.id,
                note: _notaController.text.trim(),
                interaction: interaction,
              )
            : photoBytes == null
                ? await const PendingOfficialHabitOperations().register(
                    habitoRef.id, attemptRef.id,
                    note: _notaController.text.trim(),
                    interaction: interaction,
                  )
                : await const PendingOfficialHabitOperations()
                    .registerWithEvidence(
                    habitoRef.id, attemptRef.id,
                    imageBytes: photoBytes,
                    note: _notaController.text.trim(),
                    interaction: interaction,
                  );
        if (!mounted) return;
        final xp = _leerEntero(response['xpAwarded'], 0);
        final coins = _leerEntero(response['coinsAwarded'], 0);
        final progress = _leerEntero(response['progress'], 0);
        final target = _leerEntero(response['target'], _meta);
        final completed = response['completed'] == true;
        if (OfficialHabitEmulatorService.enabled &&
            response['dailyStreakNew'] == true) {
          final dayCount = _leerEntero(response['dailyStreakCount'], 1);
          final bonus = _leerEntero(response['dailyStreakReward'], 2);
          final day = response['dailyStreakDay']?.toString() ?? '';
          final action = await showDialog<StreakRewardAction>(
            context: context,
            barrierDismissible: false,
            builder: (_) => DailyStreakRewardDialog(
              streak: dayCount,
              coins: bonus,
              xp: xp,
              onClaim: () => service.claimDailyStreakReward(day: day),
            ),
          );
          if (!mounted) return;
          if (action == StreakRewardAction.showHistory) {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const DailyStreakScreen(),
              ),
            );
            if (!mounted) return;
          } else if (action == StreakRewardAction.claimed ||
              action == StreakRewardAction.alreadyClaimed) {
            HealthyCelebration.show(
              context,
              title: action == StreakRewardAction.claimed
                  ? '¡Premio diario recogido!'
                  : 'Este premio ya se había recogido',
              subtitle: action == StreakRewardAction.claimed
                  ? '+$bonus Habit Coins por tu racha.'
                  : 'Puedes consultar tu historial de racha.',
              icon: Icons.redeem_rounded,
            );
          }
        } else {
          HealthyCelebration.show(
            context,
            title: completed ? '¡Hábito completado!' : '¡Registro guardado!',
            subtitle: '+$xp XP'
                '${coins > 0 ? ' · +$coins Habit Coins' : ''}'
                ' · $progress/$target registros',
            icon: completed
                ? Icons.emoji_events_rounded : Icons.check_circle_rounded,
          );
        }
        // Registro oficial confirmado: cancelar avisos obsoletos.
        await HealthyRemindersService.instance.refreshForCurrentUser();
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
      final usuarioRef = _userDoc;
      // Los registros pertenecen al intento, no directamente
      // al documento principal del hábito.
      final registroRef = attemptRef.collection('logs').doc();
      final nota = _notaController.text.trim();
      if (!_interactionComplete) {
        throw Exception('Completa la actividad interactiva.');
      }
      final interactionType = _interactionType;
      final interactionValue = _interactionValue;
      final interactionUnit = _interactionUnit;
      final uid = usuario.uid;
      final bytesEvidencia = _bytesImagen;
      final tieneEvidenciaReal =
          _imagenSeleccionada != null && bytesEvidencia != null;
      if (tieneEvidenciaReal &&
          bytesEvidencia.lengthInBytes >
              TemporaryEvidenceService.maxImageBytes) {
        throw Exception('La fotografía supera el límite de 250 KB.');
      }
      final xpGanado = tieneEvidenciaReal ? 15 : 10;
      final evidenciaRef = _userDoc
          .collection('temporary_habit_evidence')
          .doc(registroRef.id);
      final ahora = DateTime.now().toUtc();
      final expira = ahora.add(const Duration(hours: 24));
      final extension =
          (_imagenSeleccionada?.name.split('.').last ?? 'jpg').toLowerCase();
      final imagenTipo =
          extension == 'png'
              ? 'image/png'
              : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final resultado = await _db.runTransaction((transaction) async {
        final attemptSnapshot = await transaction.get(attemptRef);
        final usuarioSnapshot = await transaction.get(usuarioRef);
        if (!attemptSnapshot.exists) {
          throw Exception('El intento ya no existe.');
        }
        final datosAttempt = attemptSnapshot.data()!;
        final datosUsuario = usuarioSnapshot.data() ?? <String, dynamic>{};
        // Comprobar el estado dentro de la transacción
        // evita guardar registros en intentos cancelados
        // o completados.
        final estado = (datosAttempt['status'] ?? '').toString();
        if (estado != 'inProgress') {
          throw Exception('El intento ya no está activo.');
        }
        final progresoActual = _leerEntero(datosAttempt['progress'], 0);
        final metaActual = _leerEntero(datosAttempt['target'], _meta);
        final metaSegura = metaActual < 1 ? 1 : metaActual;
        if (progresoActual >= metaSegura) {
          throw Exception('La meta de este hábito ya fue completada.');
        }
        // La racha se actualiza una sola vez por fecha local, dentro
        // de la misma transacción que crea el registro.
        final fechaHoy = _fechaLocal(DateTime.now().toLocal());
        final ultimaFecha = (datosUsuario['lastStreakDate'] ?? '').toString();
        final diferencia = _diasEntreFechas(ultimaFecha, fechaHoy);
        final rachaAnterior = _leerEntero(datosUsuario['currentStreak'], 0);
        final recordAnterior = _leerEntero(datosUsuario['longestStreak'], 0);
        final nuevaRacha =
            diferencia == 0
                ? (rachaAnterior > 0 ? rachaAnterior : 1)
                : diferencia == 1
                ? rachaAnterior + 1
                : 1;
        final nuevoRecord =
            nuevaRacha > recordAnterior ? nuevaRacha : recordAnterior;

        // HEALTHY_HABIT_LEVEL_REWARDS_V2
        final xpActual =
            _leerEntero(
              datosUsuario['xp'] ?? datosUsuario['currentXp'],
              0,
            ).clamp(0, 1000000000).toInt();

        final xpNuevo = xpActual + xpGanado;
        final nivelAnterior = LevelSystem.fromXp(xpActual).number;
        final nivelNuevo = LevelSystem.fromXp(xpNuevo).number;

        const recompensas = <int, int>{
          2: 25,
          3: 25,
          4: 25,
          5: 50,
          6: 50,
          7: 50,
          8: 50,
          9: 75,
          10: 75,
          11: 75,
          12: 75,
          13: 100,
          14: 100,
          15: 100,
          16: 100,
          17: 150,
          18: 150,
          19: 150,
          20: 300,
        };

        final reclamados = <int>{
          for (final valor
              in (datosUsuario['claimedLevelRewards'] is List
                  ? datosUsuario['claimedLevelRewards'] as List
                  : <dynamic>[]))
            if (_leerEntero(valor, 0) >= 2) _leerEntero(valor, 0),
        };

        var monedasGanadas = 0;

        for (var numero = nivelAnterior + 1; numero <= nivelNuevo; numero++) {
          if (reclamados.add(numero)) {
            monedasGanadas += recompensas[numero] ?? 0;
          }
        }

        final monedasActuales = _leerEntero(datosUsuario['habitCoins'], 0);

        final monedasNuevas = monedasActuales + monedasGanadas;

        final xpHabito = _leerEntero(datosAttempt['xpEarned'], 0);
        final nuevoProgreso = progresoActual + 1;
        final completado = nuevoProgreso >= metaSegura;
        final datosActualizacion = <String, dynamic>{
          'progress': nuevoProgreso,
          'target': metaSegura,
          'xpEarned': xpHabito + xpGanado,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (completado) {
          datosActualizacion['status'] = 'completed';
          datosActualizacion['completedAt'] = FieldValue.serverTimestamp();
        }
        transaction.update(attemptRef, datosActualizacion);
        transaction.set(habitoRef, {
          'latestAttemptId': attemptRef.id,
          'latestProgress': nuevoProgreso,
          'latestTarget': metaSegura,
          'latestStatus': completado ? 'completed' : 'inProgress',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(usuarioRef, {
          'xp': xpNuevo,
          'currentXp': xpNuevo,
          'level': nivelNuevo,
          'habitCoins': monedasNuevas,
          'claimedLevelRewards': reclamados.toList()..sort(),
          'currentStreak': nuevaRacha,
          'streakDays': nuevaRacha,
          'longestStreak': nuevoRecord,
          'lastStreakDate': fechaHoy,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (tieneEvidenciaReal) {
          transaction.set(evidenciaRef, {
            'userId': uid,
            'habitId': habitoRef.id,
            'attemptId': attemptRef.id,
            'logId': registroRef.id,
            'imageBase64': base64Encode(bytesEvidencia),
            'contentType': imagenTipo,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expira),
          });
        }

        transaction.set(registroRef, {
          'habitId': habitoRef.id,
          'attemptId': attemptRef.id,
          'habitTitle': _nombreHabito,
          'category': _categoria,
          'note': nota,
          'interactionType': interactionType,
          'interactionValue': interactionValue,
          'interactionUnit': interactionUnit,
          'hasEvidence': tieneEvidenciaReal,
          'imageUrl': null,
          'evidenceId': tieneEvidenciaReal ? registroRef.id : null,
          'evidenceExpiresAt':
              tieneEvidenciaReal ? Timestamp.fromDate(expira) : null,
          'xpEarned': xpGanado,
          'progressAfter': nuevoProgreso,
          'goal': metaSegura,
          'completed': completado,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': uid,
        });
        // Solo devolvemos el resultado cuando Firestore confirma la transacción.
        // No conceder recompensas desde la interfaz ni dentro de callbacks visuales.
        return (
          completado: completado,
          rachaAnterior: rachaAnterior,
          nuevaRacha: nuevaRacha,
          nivelAnterior: nivelAnterior,
          nivelNuevo: nivelNuevo,
          xpGanado: xpGanado,
          monedasGanadas: monedasGanadas,
          progresoNuevo: nuevoProgreso,
          meta: metaSegura,
        );
      });
      if (!mounted) return;
      // Estas cifras provienen exclusivamente de una transacción confirmada.
      // El banner es informativo: nunca concede XP ni Habit Coins.
      final resumenRecompensa = [
        '+${resultado.xpGanado} XP',
        if (resultado.monedasGanadas > 0)
          '+${resultado.monedasGanadas} Habit Coins',
        '${resultado.progresoNuevo}/${resultado.meta} registros',
      ].join(' · ');
      if (resultado.nivelNuevo > resultado.nivelAnterior) {
        HealthyCelebration.show(
          context,
          title: '¡Subiste al nivel ${resultado.nivelNuevo}!',
          subtitle: resumenRecompensa,
          icon: Icons.workspace_premium_rounded,
        );
      } else if (resultado.completado) {
        HealthyCelebration.show(
          context,
          title: '¡Hábito completado!',
          subtitle: resumenRecompensa,
          icon: Icons.emoji_events_rounded,
        );
      } else if (resultado.nuevaRacha > resultado.rachaAnterior) {
        HealthyCelebration.show(
          context,
          title: '¡${resultado.nuevaRacha} días de racha!',
          subtitle: resumenRecompensa,
          icon: Icons.local_fire_department_rounded,
        );
      } else {
        HealthyCelebration.show(
          context,
          title: '¡Registro guardado!',
          subtitle: resumenRecompensa,
          icon: Icons.check_circle_rounded,
        );
      }
      // Registro habitual confirmado en Firestore: reconstruir la agenda.
      await HealthyRemindersService.instance.refreshForCurrentUser();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'No se pudo guardar el registro. Verifica tu conexión, '
              'Firestore y las reglas de seguridad.';
        });
        _mostrarMensaje('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: HealthyAdaptive.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: HealthyAdaptive.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: HealthyAdaptive.text),
          onPressed: _guardando ? null : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Hábito',
              style: TextStyle(
                color: HealthyAdaptive.text,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            Text(
              'Añade algo que acompañe tu registro.',
              style: TextStyle(
                color: HealthyAdaptive.muted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTarjetaHabito(),
            const SizedBox(height: 18),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false,
                    icon: Icon(Icons.view_agenda_outlined),
                    label: Text('Todo junto')),
                ButtonSegment(value: true,
                    icon: Icon(Icons.route_outlined),
                    label: Text('Por pasos')),
              ],
              selected: {_modoPasos},
              onSelectionChanged: _guardando ? null : (values) => setState(() {
                _modoPasos = values.first;
                _pasoRegistro = 0;
              }),
            ),
            const SizedBox(height: 14),
            if (_modoPasos) ...[
              Text('Paso ${_pasoRegistro + 1} de 3: '
                '${['Actividad y evidencia', 'Nota personal', 'Confirmación'][_pasoRegistro]}',
                style: TextStyle(fontWeight: FontWeight.w800,
                    color: HealthyAdaptive.text)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (_pasoRegistro + 1) / 3),
              const SizedBox(height: 16),
            ],
            if (!_modoPasos || _pasoRegistro == 0) ...[
            if (_interactionType != 'manual') ...[
              HabitInteractionCard(
                type: _interactionType,
                target: _interactionTarget,
                unit: _interactionUnit,
                enabled: !_guardando && !_metaCompletada,
                initialValue: _interactionValue,
                onChanged: (complete, value) {
                  if (!mounted) return;
                  setState(() {
                    _interactionComplete = complete;
                    _interactionValue = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            _buildTituloSeccion('Fotografía', 'Opcional'),
            const SizedBox(height: 12),
            _buildFotografia(),
            const SizedBox(height: 8),
            Text(
              'Puedes adjuntar una fotografía para respaldar el registro. '
              'Adjuntarla NO verifica automáticamente que se realizó '
              'la actividad. La imagen se elimina tras 24 horas al '
              'ejecutar la limpieza.',
              style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
            ),
            const SizedBox(height: 24),
            ],
            if (!_modoPasos || _pasoRegistro == 1) ...[
            _buildTituloSeccion('Añadir una nota', 'Opcional'),
            const SizedBox(height: 12),
            TextField(
              controller: _notaController,
              enabled: !_guardando,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej. Terminé mi botella durante el almuerzo.',
                hintStyle: TextStyle(
                  color: HealthyAdaptive.muted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: HealthyAdaptive.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: HealthyAdaptive.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: HealthyAdaptive.border),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ],
            if (_modoPasos) ...[
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _guardando || _pasoRegistro == 0
                      ? null : () => setState(() => _pasoRegistro--),
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Anterior'),
                ),
                const Spacer(),
                if (_pasoRegistro < 2)
                  FilledButton.icon(
                    onPressed: _guardando ? null :
                        () => setState(() => _pasoRegistro++),
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Siguiente'),
                  ),
              ]),
              const SizedBox(height: 16),
            ],
            if (!_modoPasos || _pasoRegistro == 2) ...[
            if (_modoPasos && !_interactionComplete) ...[
              Card(
                color: HealthyAdaptive.surface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Falta completar la actividad',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Regresa al primer paso para finalizar '
                        'el contador o temporizador. Lo que ya registraste '
                        'se conserva.'),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey('registro-volver-actividad'),
                        onPressed: () => setState(() => _pasoRegistro = 0),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Volver a la actividad'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Tu registro suma',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: HealthyAdaptive.text,
              ),
            ),
            const SizedBox(height: 12),
            _buildTarjetasXP(),
            const SizedBox(height: 24),
            _buildPrivacidad(),
            const SizedBox(height: 16),
            _buildMrHealthy(),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_metaCompletada) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HealthyAdaptive.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '¡Meta completada! Este intento ya no admite '
                  'más registros.',
                  style: TextStyle(
                    color: HealthyAdaptive.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _puedeGuardar ? _guardarRegistro : null,
                icon:
                    _guardando
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _guardando
                      ? (_subiendoImagen
                          ? 'Preparando imagen...'
                          : 'Guardando...')
                      : _metaCompletada
                      ? 'Meta completada'
                      : 'Guardar registro',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HealthyAdaptive.accent,
                  foregroundColor: const Color(0xFF10392F),
                  disabledBackgroundColor: HealthyAdaptive.accent
                      .withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: _guardando ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HealthyAdaptive.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaHabito() {
    final progresoVisual =
        _meta > 0 ? (_progreso / _meta).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HealthyAdaptive.water,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _nombreHabito.toLowerCase().contains('agua')
                      ? Icons.water_drop_outlined
                      : Icons.check_circle_outline,
                  color: HealthyAdaptive.waterInk,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombreHabito,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: HealthyAdaptive.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_categoria · Misión diaria',
                      style: TextStyle(
                        fontSize: 13,
                        color: HealthyAdaptive.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progresoVisual,
                    minHeight: 6,
                    backgroundColor: HealthyAdaptive.border,
                    valueColor: AlwaysStoppedAnimation(
                      HealthyAdaptive.waterInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_progreso / $_meta',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: HealthyAdaptive.waterInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Al guardar, el progreso avanzará una unidad.',
              style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloSeccion(String titulo, String subtitulo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: HealthyAdaptive.text,
          ),
        ),
        Text(
          subtitulo,
          style: TextStyle(fontSize: 13, color: HealthyAdaptive.muted),
        ),
      ],
    );
  }

  Widget _buildFotografia() {
    final tieneImagen = _bytesImagen != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HealthyAdaptive.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (tieneImagen) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _bytesImagen!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: HealthyAdaptive.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Imagen seleccionada',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: HealthyAdaptive.text,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _guardando ? null : _quitarImagen,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HealthyAdaptive.mint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                color: HealthyAdaptive.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Añadir fotografía',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: HealthyAdaptive.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Adjunta una imagen para respaldar tu registro.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: HealthyAdaptive.muted),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _guardando
                          ? null
                          : () => _seleccionarImagen(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text(
                    'Tomar fotografía',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HealthyAdaptive.accent,
                    backgroundColor: HealthyAdaptive.mint,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _guardando
                          ? null
                          : () => _seleccionarImagen(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text(
                    'Elegir de galería',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HealthyAdaptive.text,
                    side: BorderSide(color: HealthyAdaptive.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (tieneImagen && HealthyVisionDebugService.enabled) ...[
            HealthyVisionPreviewPanel(
              image: _bytesImagen!,
              category: _categoria,
              habitTitle: _nombreHabito,
              saving: _guardando,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Registrar con evidencia',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              tieneImagen
                  ? OfficialHabitEmulatorService.enabled
                      ? 'Imagen privada y no verificada; caduca en 60 minutos.'
                      : 'La imagen se guardará temporalmente durante 24 horas.'
                  : 'Selecciona una imagen para activar la evidencia.',
              style: const TextStyle(fontSize: 11),
            ),
            value: tieneImagen,
            activeColor: HealthyAdaptive.accent,
            onChanged:
                (_guardando || BetaHabitGateway.enabled)
                    ? null
                    : (value) {
                      if (!value) {
                        _quitarImagen();
                      } else {
                        _seleccionarImagen(ImageSource.gallery);
                      }
                    },
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetasXP() {
    final conEvidencia = _bytesImagen != null;
    final normalColor = conEvidencia
        ? HealthyAdaptive.surface
        : HealthyAdaptive.mint;
    final evidenceColor = conEvidencia
        ? HealthyAdaptive.mint
        : HealthyAdaptive.surface;
    final normalInk = conEvidencia
        ? HealthyAdaptive.text
        : HealthyAdaptive.accent;
    final evidenceInk = conEvidencia
        ? HealthyAdaptive.accent
        : HealthyAdaptive.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            (OfficialHabitEmulatorService.enabled || BetaHabitGateway.enabled)
                ? 'La recompensa se calcula en el servidor, sin bonus por foto.'
                : conEvidencia
                    ? 'Recompensa prevista: 15 XP con fotografía'
                    : 'Recompensa prevista: 10 XP sin fotografía',
            key: const ValueKey('habit-xp-preview'),
            style: TextStyle(
              color: HealthyAdaptive.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _tarjetaXP(
                titulo: 'Registro normal',
                xp: (OfficialHabitEmulatorService.enabled || BetaHabitGateway.enabled)
                    ? 'Según hábito' : '+10 XP',
                descripcion: conEvidencia ? 'Opción alternativa' : 'Seleccionado',
                color: normalColor,
                colorTexto: normalInk,
                borde: conEvidencia
                    ? HealthyAdaptive.border
                    : HealthyAdaptive.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tarjetaXP(
                titulo: 'Con evidencia',
                xp: (OfficialHabitEmulatorService.enabled || BetaHabitGateway.enabled)
                    ? 'Sin bonus' : '+15 XP',
                descripcion: conEvidencia ? 'Seleccionado' : 'Añade una fotografía',
                color: evidenceColor,
                colorTexto: evidenceInk,
                borde: conEvidencia
                    ? HealthyAdaptive.accent
                    : HealthyAdaptive.border,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tarjetaXP({
    required String titulo,
    required String xp,
    required String descripcion,
    required Color color,
    required Color colorTexto,
    required Color borde,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bolt, color: colorTexto, size: 20),
              Flexible(
                child: Text(
                  xp,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorTexto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: TextStyle(fontSize: 11, color: HealthyAdaptive.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacidad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: HealthyAdaptive.text),
              SizedBox(width: 8),
              Text(
                'Tu privacidad importa',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'La evidencia se utiliza para respaldar este registro y '
            'se manejará según tus preferencias de privacidad.',
            style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMrHealthy() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/mascot/healthy.png',
          width: 40,
          height: 40,
          errorBuilder:
              (context, error, stackTrace) => const Icon(Icons.eco, size: 40),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mr. Healthy',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: HealthyAdaptive.accent,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'La evidencia es opcional. Obtienes XP al registrar '
                'tu hábito; los Healthy Coins se obtienen al completar '
                'una misión, no por cada registro.',
                style: TextStyle(fontSize: 12, color: HealthyAdaptive.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
