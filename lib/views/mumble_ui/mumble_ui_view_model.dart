import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Intent;
import 'package:loggy/loggy.dart';
import 'package:pttoc_test/providers/mumble_provider.dart';

// https://stackoverflow.com/questions/33281286/samsung-galaxy-xcover-active-button

// https://docs.samsungknox.com/dev/knox-sdk/hardware-key-remapping-isv.htm
// https://stackoverflow.com/questions/64052156/how-do-you-use-receiver-broadcastreceiver-in-a-flutter-plugin

class MumbleUiViewModel extends ChangeNotifier with UiLoggy {
  MumbleProvider mumbleProvider;
  late HardwareKeyboard keeb;

  FocusNode transmitButtonFocus = FocusNode();

  TextEditingController hostTextController =
      TextEditingController(text: "dr130.ketchel.xyz");
  TextEditingController portTextController =
      TextEditingController(text: "64738");
  TextEditingController nameTextController =
      TextEditingController(text: "Dumble Test");
  TextEditingController passwordTextController = TextEditingController();
  // Controller

  MumbleUiViewModel(this.mumbleProvider) {
    mumbleProvider.addListener(mumbleProviderListener);
    // ServicesBinding.instance.keyboard.addHandler(pttKeyHandler);
  }

  bool pttKeyHandler(KeyEvent keyEvent) {
    const xcoverKeyId = 0x11000003f7;
    if (connected && keyEvent.logicalKey.keyId == xcoverKeyId) {
      if (keyEvent is KeyDownEvent && !transmitting) {
        startTransmit();
      }
      if (keyEvent is KeyUpEvent) {
        stopTransmit();
      }
      return true;
    }
    return false;
  }

  void mumbleProviderListener() {
    notifyListeners();
  }

  // Future<void> _initReceiveIntent() async {
  //   // ... check initialIntent
  //
  //   // Attach a listener to the stream
  //   _intentSub = ReceiveIntent.receivedIntentStream.listen((Intent? intent) {
  //     // Validate receivedIntent and warn the user, if it is not correct,
  //     print(intent);
  //   }, onError: (err) {
  //     print(err);
  //     // Handle exception
  //   });
  //
  //   // NOTE: Don't forget to call _sub.cancel() in dispose()
  // }

  @override
  void dispose() {
    loggy.debug("Disposing of MumbleUiViewModel.");
    // window.onKeyData = null;
    ServicesBinding.instance.keyboard.removeHandler(pttKeyHandler);
    stopTransmit();
    transmitButtonFocus.dispose();
    // _intentSub.cancel();
    hostTextController.dispose();
    portTextController.dispose();
    nameTextController.dispose();
    passwordTextController.dispose();
    mumbleProvider.removeListener(mumbleProviderListener);
    super.dispose();
  }

  Future<void> connect() async {
    // TODO: Validate form fields
    return mumbleProvider
        .connect(
            host: hostTextController.text,
            name: nameTextController.text,
            port: int.parse(portTextController.text),
            password: passwordTextController.text)
        .whenComplete(() => notifyListeners());
  }

  Future<void> disconnect() async {
    return mumbleProvider.client!.close().whenComplete(() => notifyListeners());
  }

  void startTransmit() {
    mumbleProvider.startTransmit();
    // notifyListeners();
  }

  void stopTransmit() {
    mumbleProvider.stopTransmit();
    // notifyListeners();
  }

  bool get connected => mumbleProvider.connected;
  bool get transmitting => mumbleProvider.transmitting;
}
