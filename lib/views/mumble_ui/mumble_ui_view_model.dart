import 'package:flutter/widgets.dart';
import 'package:pttoc_test/providers/mumble_provider.dart';

class MumbleUiViewModel extends ChangeNotifier {
  MumbleProvider mumbleProvider;

  TextEditingController hostTextController =
      TextEditingController(text: "dr130.ketchel.xyz");
  TextEditingController portTextController =
      TextEditingController(text: "64738");
  TextEditingController nameTextController =
      TextEditingController(text: "Dumble Test");
  TextEditingController passwordTextController = TextEditingController();
  // Controller

  MumbleUiViewModel(this.mumbleProvider);

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

  bool get connected => mumbleProvider.connected;
}
