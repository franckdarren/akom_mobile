import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Retour sonore + haptique joué à chaque code-barres détecté par le scanner.
class ScanFeedback {
  ScanFeedback._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setPlayerMode(PlayerMode.lowLatency);

  static Future<void> beep() async {
    unawaited(HapticFeedback.mediumImpact());
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.wav'), volume: 1.0);
    } catch (_) {
      // Le son ne doit jamais bloquer le flux de scan.
    }
  }
}
