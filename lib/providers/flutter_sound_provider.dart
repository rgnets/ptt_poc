import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

const int tSampleRate = 44000;
typedef _Fn = void Function();

class FlutterSoundProvider extends ChangeNotifier {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;
  String? _mPath;
  StreamSubscription? _mRecordingDataSubscription;

  bool get isInitialized => _mPlayerIsInited && _mRecorderIsInited;

  FlutterSoundProvider() {
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    // _mPlayer!.openPlayer().then((value) {
    //   _mPlayerIsInited = true;
    //   notifyListeners();
    // });
    // _openRecorder();
  }

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
    // stopPlayer();
    _mPlayer!.closePlayer();
    _mPlayer = null;

    // stopRecorder();
    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }
  //
  // Future<void> stopRecorder() async {
  //   await _mRecorder!.stopRecorder();
  //   if (_mRecordingDataSubscription != null) {
  //     await _mRecordingDataSubscription!.cancel();
  //     _mRecordingDataSubscription = null;
  //   }
  //   _mplaybackReady = true;
  // }

  get startRecorder => _mRecorder!.startRecorder;
  get stopRecorder => _mRecorder!.stopRecorder;
  // ----------------------  Here is the code to record to a Stream ------------

  // Future<void> record() async {
  //   assert(_mRecorderIsInited && _mPlayer!.isStopped);
  //   var sink = await createFile();
  //   var recordingDataController = StreamController<Food>();
  //   _mRecordingDataSubscription =
  //       recordingDataController.stream.listen((buffer) {
  //         if (buffer is FoodData) {
  //           sink.add(buffer.data!);
  //         }
  //       });
  //   await _mRecorder!.startRecorder(
  //     toStream: recordingDataController.sink,
  //     codec: Codec.pcm16,
  //     numChannels: 1,
  //     sampleRate: tSampleRate,
  //   );
  //   setState(() {});
  // }

  // _Fn? getRecorderFn() {
  //   if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
  //     return null;
  //   }
  //   return _mRecorder!.isStopped
  //       ? record
  //       : () {
  //           stopRecorder().then((value) => notifyListeners());
  //         };
  // }

  void play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    await _mPlayer!.startPlayer(
        fromURI: _mPath,
        sampleRate: tSampleRate,
        codec: Codec.pcm16,
        numChannels: 1,
        whenFinished: () {
          notifyListeners();
        }); // The readability of Dart is very special :-(
    notifyListeners();
  }

  Future<void> stopPlayer() async {
    await _mPlayer!.stopPlayer();
  }

  // _Fn? getPlaybackFn() {
  //   if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
  //     return null;
  //   }
  //   return _mPlayer!.isStopped
  //       ? play
  //       : () {
  //           stopPlayer().then((value) => notifyListeners());
  //         };
  // }
}
