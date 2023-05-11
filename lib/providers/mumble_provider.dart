import 'dart:async';
import 'dart:io';

import 'package:dumble/dumble.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:loggy/loggy.dart';
import 'package:pttoc_test/providers/connection_options.dart';
import 'package:pttoc_test/providers/lib/mumble_log.dart';

class MumbleProvider extends ChangeNotifier with NetworkLoggy {
  MumbleClient? client;

  MumbleLog mumbleLog = MumbleLog();
  final pttChannel = MethodChannel('com.rgnets.pttoc/ptt');
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

      client!.add(clientCallback);
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
    // // await new Future.delayed(
    // //     const Duration(seconds: 5)); // Wait a few seconds before we start talking
    // StreamOpusEncoder<int> encoder = StreamOpusEncoder.bytes(
    //     frameTime: frameTime,
    //     floatInput: false,
    //     sampleRate: inputSampleRate,
    //     channels: channels,
    //     application: Application.voip);
    // AudioFrameSink audioOutput = client.audio.sendAudio(codec: AudioCodec.opus);
    //
    // await simulateAudioRecording() // This simulates recording by reading from a file
    //     .asyncMap((List<int> bytes) async {
    //       // We need to wait a bit since reading from a file is "faster than realtime".
    //       // Usually we would wait frameTimeMs, but since encoding with opus takes about abit
    //       // (we assume 17ms here), we wait less.
    //       // In an actual live recording, you dont need this artificial waiting.
    //       await new Future.delayed(
    //           const Duration(milliseconds: frameTimeMs - 17));
    //       return bytes;
    //     })
    //     .transform(encoder)
    //     .map((Uint8List audioBytes) => AudioFrame.outgoing(frame: audioBytes))
    //     .pipe(audioOutput);
  }

  void stopTransmit() {
    mumbleLog.internal("Stopping transmit");
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
//
// class MumbleExampleCallback with MumbleClientListener, UserListener {
//   final MumbleClient client;
//
//   const MumbleExampleCallback(this.client);
//
//   @override
//   void onBanListReceived(List<BanEntry> bans) {}
//
//   @override
//   void onChannelAdded(Channel channel) {
//     if (channel.name == 'Dumble Test Channel') {
//       // This is our channel
//       // join it
//       client.self.moveToChannel(channel: channel);
//     }
//   }
//
//   @override
//   void onCryptStateChanged() {}
//
//   @override
//   void onDone() {
//     print('onDone');
//   }
//
//   @override
//   void onDropAllChannelPermissions() {}
//
//   @override
//   void onError(error, [StackTrace? stackTrace]) {
//     print('An error occured!');
//     print(error);
//     if (stackTrace != null) {
//       print(stackTrace);
//     }
//   }
//
//   @override
//   void onQueryUsersResult(Map<int, String> idToName) {}
//
//   @override
//   void onTextMessage(IncomingTextMessage message) {
//     print('[${new DateTime.now()}] ${message.actor?.name}: ${message.message}');
//   }
//
//   @override
//   void onUserAdded(User user) {
//     //Keep an eye on the user
//     user.add(this);
//   }
//
//   @override
//   void onUserListReceived(List<RegisteredUser> users) {}
//
//   @override
//   void onUserChanged(User? user, User? actor, UserChanges changes) {
//     print('User $user changed $changes');
//     // The user changed
//     if (changes.channel) {
//       // ...his channel
//       if (user?.channel == client.self.channel) {
//         // ... to our channel
//         // So greet him
//         client.self.channel
//             .sendMessageToChannel(message: 'Hello ${user?.name}!');
//       }
//     }
//   }
//
//   @override
//   void onUserRemoved(User user, User? actor, String? reason, bool? ban) {
//     // If the removed user is the actor that is responsible for this, the
//     // user simply left the server. Same is ture if the actor is null.
//     if (actor == null || user == actor) {
//       print('${user.name} left the server');
//     } else if (ban ?? false) {
//       // The user was baned from the server
//       print('${user.name} was banned by ${actor.name}, reason $reason.');
//     } else {
//       // The user was kicked from the server
//       print('${user.name} was kicked by ${actor.name}, reason $reason.');
//     }
//   }
//
//   @override
//   void onUserStats(User user, UserStats stats) {}
//
//   @override
//   void onPermissionDenied(PermissionDeniedException e) {
//     print('Permission denied!');
//     print(
//         'This will occur if this example is run a second time, since it will try to create a channel that already exists!');
//     print('The concrete exception was: $e');
//   }
// }
