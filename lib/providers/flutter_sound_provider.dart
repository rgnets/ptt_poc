import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

const int tSampleRate = 44000;

class FlutterSoundProvider extends ChangeNotifier {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer(logLevel: Level.debug);
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;

  bool get isInitialized => _mPlayerIsInited && _mRecorderIsInited;

  Future<void> initialize() async {
    await _mPlayer!.openPlayer().then((value) {
      _mPlayerIsInited = true;
      notifyListeners();
    });
    await _openRecorder();
  }

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder!.openRecorder();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _mRecorderIsInited = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _mPlayer!.stopPlayer();
    _mPlayer!.closePlayer();
    _mPlayer = null;

    _mRecorder!.stopRecorder();
    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  get startRecorder => _mRecorder!.startRecorder;
  get stopRecorder => _mRecorder!.stopRecorder;

  get startPlayer => _mPlayer!.startPlayer;
  get stopPlayer => _mPlayer!.stopPlayer;

  FlutterSoundPlayer? get mPlayer => _mPlayer;
}
