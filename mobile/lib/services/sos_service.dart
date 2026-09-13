import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/locale/locale_controller.dart';
import '../core/network/api_exception.dart';
import '../features/home/application/home_controller.dart';
import '../features/home/data/home_repository.dart';
import '../features/home/domain/aidant_models.dart';
import '../features/home/domain/profile_settings_models.dart';
import 'emergency_contact_cache.dart';
import 'network_status.dart';

typedef SosUiCallbacks = ({
  void Function(SosTicket ticket) onCountdownStarted,
  void Function(String message) onCancelled,
  void Function(String message) onEscalatedCall,
  void Function(String message) onAidantAcked,
  void Function(String error) onError,
  void Function() onFlowUiClose,
});

/// Orchestration SOS : countdown natif, confirm/FCM, fallback appel (escalade native).
class SosService {
  SosService(this._ref);

  final Ref _ref;
  static const channelName = 'cm.fidel.assistant/sos';
  static const actionTrigger = 'sos_trigger';
  static const actionCancelCountdown = 'sos_cancel_countdown';
  static const eventCountdownExpired = 'countdown_expired';
  static const eventCountdownExpiredCalled = 'countdown_expired_called';
  static const ackTimeout = Duration(seconds: 45);

  static const _method = MethodChannel(channelName);

  SosUiCallbacks? _ui;
  Timer? _ackPoll;
  bool _bound = false;
  bool _inFlight = false;
  bool _handlingExpire = false;
  SosTicket? _activeTicket;

  HomeRepository get _repo => _ref.read(homeRepositoryProvider);
  EmergencyContactCache get _cache =>
      EmergencyContactCache(_ref.read(sharedPreferencesProvider));
  NetworkStatus get _net => _ref.read(networkStatusProvider);

  SosTicket? get activeTicket => _activeTicket;

  void bindUi(SosUiCallbacks callbacks) {
    _ui = callbacks;
    _ensureBound();
  }

  void unbindUi() {
    _ui = null;
  }

  void _ensureBound() {
    if (_bound || !Platform.isAndroid) return;
    _bound = true;
    _method.setMethodCallHandler((call) async {
      if (call.method == 'onAction' || call.method == 'onNativeEvent') {
        await _handleNativeAction(call.arguments?.toString());
      }
    });
  }

  Future<void> _handleNativeAction(String? action) async {
    if (action == null || action.isEmpty) return;
    if (action == actionTrigger || action == 'sos_trigger') {
      await startSosFlow();
      return;
    }
    if (action == actionCancelCountdown) {
      final ticket = _activeTicket;
      if (ticket != null) {
        await cancelCountdown(ticket);
      } else {
        await _stopCountdown();
        _ui?.onFlowUiClose();
      }
      return;
    }
    if (action == eventCountdownExpired) {
      final ticket = _activeTicket;
      if (ticket != null) {
        await onCountdownExpired(ticket);
      }
      return;
    }
    if (action == eventCountdownExpiredCalled) {
      _activeTicket = null;
      _handlingExpire = false;
      _ui?.onFlowUiClose();
      _ui?.onEscalatedCall('call');
    }
  }

  Future<void> ensurePersistentNotification({
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return;
    _ensureBound();
    await _method.invokeMethod<bool>('showPersistent', {
      'title': title,
      'body': body,
    });
  }

  Future<void> hidePersistentNotification() async {
    if (!Platform.isAndroid) return;
    await _method.invokeMethod<bool>('hidePersistent');
  }

  Future<String?> consumePendingAction() async {
    if (!Platform.isAndroid) return null;
    return _method.invokeMethod<String>('consumePendingAction');
  }

  Future<void> drainPendingAction() async {
    final pending = await consumePendingAction();
    if (pending != null) {
      await _handleNativeAction(pending);
    }
  }

  Future<void> cacheContacts(List<ContactUrgence> contacts) async {
    if (contacts.isEmpty) {
      await _cache.clear();
      return;
    }
    final first = contacts.first;
    await _cache.saveFirst(phone: first.telephone, name: first.nom);
  }

  Future<bool> ensureCallPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  Future<String> placeEmergencyCall() async {
    final phone = _cache.phone;
    if (phone == null || phone.isEmpty) {
      throw ApiException(
        code: 'AUCUN_CONTACT_URGENCE',
        message: 'Ajoute un contact d’urgence pour le SOS.',
      );
    }
    await ensureCallPermission();
    if (!Platform.isAndroid) return 'unsupported';
    final mode = await _method.invokeMethod<String>('placeCall', {
      'phone': phone,
    });
    return mode ?? 'failed';
  }

  /// Point d’entrée unique (Cercle ou notif lock).
  Future<void> startSosFlow() async {
    if (_inFlight || _activeTicket != null) return;
    _inFlight = true;
    _handlingExpire = false;
    try {
      final online = _net.canSync;
      final SosTicket ticket;
      if (!online) {
        ticket = SosTicket(
          id: 'offline',
          annulableJusquA: DateTime.now().add(const Duration(seconds: 30)),
        );
      } else {
        ticket = await _repo.triggerSos();
      }
      _activeTicket = ticket;
      _ui?.onCountdownStarted(ticket);
      await _startNativeCountdown(ticket);
    } catch (e) {
      _activeTicket = null;
      _ui?.onError(e is ApiException ? e.message : e.toString());
      rethrow;
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _startNativeCountdown(SosTicket ticket) async {
    if (!Platform.isAndroid) return;
    final waitMs = math.max(
      1000,
      ticket.annulableJusquA.difference(DateTime.now()).inMilliseconds,
    );
    final mode = ticket.id == 'offline' ? 'offline' : 'online';
    await _method.invokeMethod<bool>('startCountdown', {
      'waitMs': waitMs,
      'phone': _cache.phone ?? '',
      'mode': mode,
      'sosId': ticket.id,
    });
  }

  Future<void> _stopCountdown() async {
    if (!Platform.isAndroid) return;
    try {
      await _method.invokeMethod<bool>('stopCountdown');
    } catch (_) {}
  }

  Future<void> cancelCountdown(SosTicket ticket) async {
    _ackPoll?.cancel();
    await _stopCountdown();
    final wasActive = _activeTicket?.id == ticket.id;
    _activeTicket = null;
    _handlingExpire = false;
    if (ticket.id != 'offline') {
      try {
        final msg = await _repo.cancelSos(ticket.id);
        _ui?.onFlowUiClose();
        _ui?.onCancelled(msg);
      } catch (e) {
        if (wasActive) _activeTicket = ticket;
        _ui?.onError(e is ApiException ? e.message : e.toString());
        rethrow;
      }
    } else {
      _ui?.onFlowUiClose();
      _ui?.onCancelled('');
    }
    await _stopEscalation();
  }

  /// Appelé quand le countdown natif expire (ou miroir UI).
  Future<void> onCountdownExpired(SosTicket ticket) async {
    if (_handlingExpire) return;
    if (_activeTicket != null && _activeTicket!.id != ticket.id) return;
    _handlingExpire = true;
    _ui?.onFlowUiClose();

    final online = _net.canSync && ticket.id != 'offline';
    if (!online) {
      try {
        final mode = await placeEmergencyCall();
        _ui?.onEscalatedCall(mode);
      } catch (e) {
        _ui?.onError(e is ApiException ? e.message : e.toString());
      } finally {
        _activeTicket = null;
        _handlingExpire = false;
      }
      return;
    }
    try {
      final confirm = await _repo.confirmSos(ticket.id);
      if (confirm.fallbackCallRecommended) {
        final mode = await placeEmergencyCall();
        _activeTicket = null;
        _handlingExpire = false;
        _ui?.onEscalatedCall(mode);
        return;
      }
      await _startAckWait(ticket.id);
    } catch (e) {
      debugPrint('SosService confirm failed: $e');
      try {
        final mode = await placeEmergencyCall();
        _ui?.onEscalatedCall(mode);
      } catch (e2) {
        _ui?.onError(e2 is ApiException ? e2.message : e2.toString());
      } finally {
        _activeTicket = null;
        _handlingExpire = false;
      }
    }
  }

  Future<void> _startAckWait(String sosId) async {
    final phone = _cache.phone;
    if (phone != null && Platform.isAndroid) {
      await _method.invokeMethod<bool>('startEscalation', {
        'phone': phone,
        'waitMs': ackTimeout.inMilliseconds,
      });
    }
    _ackPoll?.cancel();
    final deadline = DateTime.now().add(ackTimeout);
    _ackPoll = Timer.periodic(const Duration(seconds: 3), (t) async {
      try {
        final status = await _repo.getSosStatus(sosId);
        if (status.acked) {
          t.cancel();
          await _stopEscalation();
          _activeTicket = null;
          _handlingExpire = false;
          _ui?.onAidantAcked('Un aidant a pris en charge le SOS.');
          return;
        }
      } catch (e) {
        debugPrint('SosService ack poll: $e');
      }
      if (DateTime.now().isAfter(deadline)) {
        t.cancel();
        _activeTicket = null;
        _handlingExpire = false;
        // Appel placé uniquement par SosEscalationService.
        _ui?.onEscalatedCall('timeout');
      }
    });
  }

  Future<void> _stopEscalation() async {
    _ackPoll?.cancel();
    if (Platform.isAndroid) {
      try {
        await _method.invokeMethod<bool>('stopEscalation');
      } catch (_) {}
    }
  }
}

final sosServiceProvider = Provider<SosService>((ref) {
  return SosService(ref);
});
