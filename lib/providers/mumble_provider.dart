import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dumble/dumble.dart' hide Permission;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:loggy/loggy.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pttoc_test/providers/connection_options.dart';
import 'package:pttoc_test/providers/lib/mumble_log.dart';

import 'flutter_sound_provider.dart';

const int channels = 1;
const int sampleRate = 48000;

class MumbleProvider extends ChangeNotifier with NetworkLoggy {
  MumbleClient? client;
  late StreamSubscription<Uint8List> audioStream;

  late FlutterSoundProvider flutterSound = FlutterSoundProvider();

  MumbleLog mumbleLog = MumbleLog();
  final pttChannel = const MethodChannel('com.rgnets.pttoc/ptt');
  bool transmitting = false;

  Future<void> connect(
      {required String host,
      int port = 64738,
      required String name,
      String? password}) async {
    mumbleLog.internal("Attempting to connect to $host:$port as $name");
    ConnectionOptions connectionOptions = ConnectionOptions(
        host: host,
        port: port,
        name: name,
        password: password,
        pingTimeout: const Duration(seconds: 20));

    if (!flutterSound.isInitialized) {
      await flutterSound.initialize();
    }

    return MumbleClient.connect(
        options:
            await createConnectionsOptionsWithCertificate(connectionOptions),
        onBadCertificate: (X509Certificate certificate) {
          //Accept every certificate
          // TODO: This is example behavior--we should probably change it.
          return true;
        }).then((newClient) {
      client = newClient;
      mumbleLog.internal("Connected to $host:$port as $name");

      // MumbleExampleCallback callback = MumbleExampleCallback(client!);
      MumbleClientCallback clientCallback = MumbleClientCallback(
          mumbleClient: client!,
          onBanListReceived: onBanListReceived,
          onChannelAdded: onChannelAdded,
          onCryptStateChanged: onCryptStateChanged,
          onDone: onDone,
          onDropAllChannelPermissions: onDropAllChannelPermissions,
          onError: onError,
          onPermissionDenied: onPermissionDenied,
          onQueryUsersResult: onQueryUsersResult,
          onTextMessage: onTextMessage,
          onUserAdded: onUserAdded,
          onUserListReceived: onUserListReceived);

      MumbleAudioListener audioListener = MumbleAudioListener(
          mumbleClient: client!, onAudioReceived: onAudioReceived);

      client!.add(clientCallback);
      client!.audio.add(audioListener);
      // print('Client synced with server!');

      pttChannel.setMethodCallHandler((MethodCall call) async {
        loggy.debug(call);
        if (call.method == 'pttEvent') {
          // Handle the event here
          if (call.arguments == 'ptt_pressed' && connected && !transmitting) {
            startTransmit();
          }
          if (call.arguments == 'ptt_released') {
            stopTransmit();
          }
        }
      });

      notifyListeners();
    });
    // .onError((error, stackTrace) {
    //   print(error);
    //   print(stackTrace);
    // });

//
//     print('Listing channels...');
//     print(client.getChannels());
//     print('Listing users...');
//     print(client.getUsers());
//     // Watch all users that are already on the server
//     // New users will reported to the callback (because of line 14) and we will
//     // watch these new users in onUserAdded below
//     client.getUsers().values.forEach((User element) => element.add(callback));
//     // Also, watch self
//     client.self.add(callback);
//     // Set a comment for us
//     client.self.setComment(comment: 'I\'m a bot!');
// // Create a channel. If the channel is succesfully created, our callback is invoked.
// //     client.createChannel(name: 'Dumble Test Channel');
//     //await new Future.delayed(const Duration(seconds: 30));
//     //await client.close();
//     //print('Bye!');
  }

  @override
  void dispose() {
    flutterSound.mPlayer!.stopPlayer();
    flutterSound.dispose();
    audioStream.cancel();
    super.dispose();
  }

  bool get connected {
    if (client == null) {
      return false;
    } else {
      return client!.closed == false;
    }
  }

  void startTransmit() async {
    mumbleLog.internal("Starting transmit");
    transmitting = true;
    notifyListeners();
    if (await Permission.microphone.request().isGranted && client != null) {
      // Permission is granted, continue with audio recording and transmission

      HapticFeedback.vibrate();
      // const int inputSampleRate = 24000;
      const int inputSampleRate = sampleRate;
      const FrameTime frameTime = FrameTime.ms40;
      const int outputSampleRate = inputSampleRate;
      const int channels = 1;

      StreamOpusEncoder<int> encoder = StreamOpusEncoder.bytes(
          frameTime: frameTime,
          floatInput: false,
          sampleRate: inputSampleRate,
          channels: channels,
          application: Application.voip);

      AudioFrameSink audioOutput =
          client!.audio.sendAudio(codec: AudioCodec.opus);

      var recordingDataController = StreamController<Food>();
      Stream<Uint8List>? audioStream = recordingDataController.stream
          .map((event) => (event as FoodData).data!);

      audioStream
          .asyncMap((List<int> bytes) async {
            return bytes;
          })
          .transform(encoder)
          .map((Uint8List audioBytes) => AudioFrame.outgoing(frame: audioBytes))
          .pipe(audioOutput);

      flutterSound.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: channels,
        sampleRate: outputSampleRate,
      );

      notifyListeners();
    } else {
      // Permission is not granted, show an error message or request again
      transmitting = false;
      notifyListeners();
    }
  }

  Uint8List generate440HzTone() {
    final sampleRate = 48000;
    final duration = 1; // seconds
    final frequency = 440; // Hz

    final numSamples = (sampleRate * duration).toInt();
    final samples = List<int>.filled(numSamples, 0);

    for (var i = 0; i < numSamples; ++i) {
      final sampleValue = 32767.0 * sin(2 * pi * frequency * i / sampleRate);
      samples[i] = sampleValue.toInt();
    }

    final byteData = ByteData(numSamples * 2); // 2 bytes per sample
    for (var i = 0; i < numSamples; ++i) {
      byteData.setInt16(i * 2, samples[i], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> feedHim(FlutterSoundPlayer player, Uint8List buffer) async {
    const blockSize = 4096;
    int lnData = 0;
    var totalLength = buffer.length;
    while (totalLength > 0 && !player.isStopped) {
      int bsize = totalLength > blockSize ? blockSize : totalLength;
      await player
          .feedFromStream(buffer.sublist(lnData, lnData + bsize)); // await !!!!
      lnData += bsize;
      totalLength -= bsize;
    }
  }

  Future<void> onAudioReceived(Stream<AudioFrame> voiceData, AudioCodec codec,
      User? speaker, TalkMode talkMode) async {
    String target = talkMode == TalkMode.normal
        ? 'talking to ${speaker?.channel.channelId}'
        : ' whispering';
    mumbleLog.internal('${speaker?.name} started $target.');

    if (codec == AudioCodec.opus && flutterSound.mPlayer != null) {
      StreamOpusDecoder opusDecoder = StreamOpusDecoder.bytes(
          floatOutput: false, sampleRate: sampleRate, channels: channels);

      FlutterSoundPlayer player = FlutterSoundPlayer();
      await player.openPlayer(enableVoiceProcessing: true);

      await player.startPlayerFromStream(
          codec: Codec.pcm16, numChannels: channels, sampleRate: sampleRate);
      player.setVolume(1);
      voiceData
          .map<Uint8List>((AudioFrame frame) =>
              frame.frame) //we are only interested in the bytes
          .cast<Uint8List?>()
          .where((event) => event != null && event.isNotEmpty)
          .transform(opusDecoder)
          .cast<Uint8List>()
          .listen((event) {
        player.foodSink!.add(FoodData(event));
      }).onDone(() {
        mumbleLog.internal('${speaker?.name} stopped $target.');
        player.stopPlayer();
        player.closePlayer();
      });
    } else {
      mumbleLog.error("We don't know how to decode $codec");
    }
  }

  void stopTransmit() {
    mumbleLog.internal("Stopping transmit");
    flutterSound.stopRecorder();
    HapticFeedback.vibrate();
    transmitting = false;
    notifyListeners();
  }

  // Client callback functions

  void onBanListReceived(List<BanEntry> bans) {
    mumbleLog.internal("Ban list received: ${bans.join(',')}");
  }

  void onChannelAdded(Channel channel) {
    // if (channel.name == 'Dumble Test Channel') {
    //   // This is our channel
    //   // join it
    //   client.self.moveToChannel(channel: channel);
    // }
    mumbleLog.internal("Channel added: ${channel.name}");
  }

  void onCryptStateChanged() {}

  void onDone() {
    // print('onDone');
    mumbleLog.internal("Done received.");
  }

  void onDropAllChannelPermissions() {}

  void onError(error, [StackTrace? stackTrace]) {
    mumbleLog.error(error);
    loggy.error('An error occurred!');
    loggy.error(error);
    if (stackTrace != null) {
      loggy.error(stackTrace);
    }
  }

  void onQueryUsersResult(Map<int, String> idToName) {
    mumbleLog.internal("QueryUsersResult: $idToName");
  }

  void onTextMessage(IncomingTextMessage message) {
    mumbleLog.message('${message.actor?.name}: ${message.message}');
    // print('[${new DateTime.now()}] ${message.actor?.name}: ${message.message}');
  }

  void onUserAdded(User user) {
    mumbleLog.user('${user.name} appeared');
    //Keep an eye on the user
    // user.add(this);

    // Todo: Implement user listener, the "this" above.
  }

  void onUserListReceived(List<RegisteredUser> users) {
    mumbleLog.user('User list: ${users.map((e) => e.name)}');
  }

  void onUserChanged(User? user, User? actor, UserChanges changes) {
    mumbleLog.user('User $user changed $changes');
    // The user changed
    // if (changes.channel) {
    //   // ...his channel
    //   if (user?.channel == client.self.channel) {
    //     // ... to our channel
    //     // So greet him
    //     client.self.channel
    //         .sendMessageToChannel(message: 'Hello ${user?.name}!');
    //   }
    // }
  }

  void onUserRemoved(User user, User? actor, String? reason, bool? ban) {
    // If the removed user is the actor that is responsible for this, the
    // user simply left the server. Same is ture if the actor is null.
    if (actor == null || user == actor) {
      // print('${user.name} left the server');
      mumbleLog.user('${user.name} left the server');
    } else if (ban ?? false) {
      // The user was baned from the server
      mumbleLog
          .user('${user.name} was banned by ${actor.name}, reason $reason.');
    } else {
      // The user was kicked from the server
      mumbleLog
          .user('${user.name} was kicked by ${actor.name}, reason $reason.');
    }
  }

  void onUserStats(User user, UserStats stats) {}

  void onPermissionDenied(PermissionDeniedException e) {
    mumbleLog.internal('Permission denied!');
    // print(
    //     'This will occur if this example is run a second time, since it will try to create a channel that already exists!');
    mumbleLog.internal('The concrete exception was: $e');
  }
}

class MumbleAudioListener with AudioListener {
  final MumbleClient mumbleClient;
  final void Function(Stream<AudioFrame> voiceData, AudioCodec codec,
      User? speaker, TalkMode talkMode) _onAudioReceived;
  MumbleAudioListener(
      {required this.mumbleClient,
      required void Function(Stream<AudioFrame> voiceData, AudioCodec codec,
              User? speaker, TalkMode talkMode)
          onAudioReceived})
      : _onAudioReceived = onAudioReceived;

  @override
  void onAudioReceived(Stream<AudioFrame> voiceData, AudioCodec codec,
          User? speaker, TalkMode talkMode) =>
      _onAudioReceived(voiceData, codec, speaker, talkMode);
}

class MumbleClientCallback with MumbleClientListener {
  final MumbleClient mumbleClient;
  final void Function(List<BanEntry> bans) _onBanListReceived;
  final void Function(Channel channel) _onChannelAdded;
  final void Function() _onCryptStateChanged;
  final void Function() _onDone;
  final void Function() _onDropAllChannelPermissions;
  final void Function(Object error, [StackTrace? stackTrace]) _onError;
  final void Function(PermissionDeniedException e) _onPermissionDenied;
  final void Function(Map<int, String> idToName) _onQueryUsersResult;
  final void Function(IncomingTextMessage message) _onTextMessage;
  final void Function(User user) _onUserAdded;
  final void Function(List<RegisteredUser> users) _onUserListReceived;

  MumbleClientCallback({
    required this.mumbleClient,
    required void Function(List<BanEntry> bans) onBanListReceived,
    required void Function(Channel channel) onChannelAdded,
    required void Function() onCryptStateChanged,
    required void Function() onDone,
    required void Function() onDropAllChannelPermissions,
    required void Function(Object error, [StackTrace? stackTrace]) onError,
    required void Function(PermissionDeniedException e) onPermissionDenied,
    required void Function(Map<int, String> idToName) onQueryUsersResult,
    required void Function(IncomingTextMessage message) onTextMessage,
    required void Function(User user) onUserAdded,
    required void Function(List<RegisteredUser> users) onUserListReceived,
  })  : _onBanListReceived = onBanListReceived,
        _onChannelAdded = onChannelAdded,
        _onCryptStateChanged = onCryptStateChanged,
        _onDone = onDone,
        _onDropAllChannelPermissions = onDropAllChannelPermissions,
        _onError = onError,
        _onPermissionDenied = onPermissionDenied,
        _onQueryUsersResult = onQueryUsersResult,
        _onTextMessage = onTextMessage,
        _onUserAdded = onUserAdded,
        _onUserListReceived = onUserListReceived;

  @override
  void onBanListReceived(List<BanEntry> bans) => _onBanListReceived(bans);

  @override
  void onChannelAdded(Channel channel) => _onChannelAdded(channel);

  @override
  void onCryptStateChanged() => _onCryptStateChanged();

  @override
  void onDone() => _onDone();

  @override
  void onDropAllChannelPermissions() => _onDropAllChannelPermissions();

  @override
  void onError(Object error, [StackTrace? stackTrace]) =>
      _onError(error, stackTrace);

  @override
  void onPermissionDenied(PermissionDeniedException e) =>
      _onPermissionDenied(e);

  @override
  void onQueryUsersResult(Map<int, String> idToName) =>
      _onQueryUsersResult(idToName);

  @override
  void onTextMessage(IncomingTextMessage message) => _onTextMessage(message);

  @override
  void onUserAdded(User user) => _onUserAdded(user);

  @override
  void onUserListReceived(List<RegisteredUser> users) =>
      _onUserListReceived(users);
}
