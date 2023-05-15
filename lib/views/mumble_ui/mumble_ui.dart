import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';
import 'package:pttoc_test/views/mumble_ui/mumble_ui_view_model.dart';

import '../../gui_utils.dart';
import '../../providers/mumble_provider.dart';

class MumbleUiView extends StatelessWidget with UiLoggy {
  const MumbleUiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MumbleUiViewModel>(
        create: (_) => MumbleUiViewModel(
            Provider.of<MumbleProvider>(context, listen: false)),
        builder: (context, child) {
          return Consumer<MumbleUiViewModel>(
              builder: (context, mumbleUiVM, child) {
            loggy.debug("Building MumbleUiView");
            if (mumbleUiVM.connected) {
              mumbleUiVM.transmitButtonFocus.requestFocus();
            }
            return Scaffold(
              appBar: AppBar(
                // Here we take the value from the MyHomePage object that was created by
                // the App.build method, and use it to set our appbar title.
                title: Text("RG Nets PTToC Demo"),
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (!mumbleUiVM.connected)
                      Card(
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                    controller: mumbleUiVM.hostTextController,
                                    decoration: const InputDecoration(
                                        icon: Icon(Icons.storage),
                                        label: Text("Host")),
                                    onEditingComplete: () =>
                                        FocusScope.of(context).nextFocus()),
                                TextField(
                                    controller: mumbleUiVM.portTextController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                        icon: Icon(Icons.lan),
                                        label: Text("Port")),
                                    onEditingComplete: () =>
                                        FocusScope.of(context).nextFocus()),
                                TextField(
                                    controller: mumbleUiVM.nameTextController,
                                    decoration: const InputDecoration(
                                        icon: Icon(Icons.person),
                                        label: Text("Name")),
                                    onEditingComplete: () =>
                                        FocusScope.of(context).nextFocus()),
                                TextField(
                                    controller:
                                        mumbleUiVM.passwordTextController,
                                    decoration: const InputDecoration(
                                        icon: Icon(Icons.key),
                                        label: Text("Password")),
                                    obscureText: true,
                                    obscuringCharacter: '*',
                                    onEditingComplete: () =>
                                        FocusScope.of(context).nextFocus()),
                              ],
                            )),
                      ),
                    if (!mumbleUiVM.connected)
                      TextButton(
                          onPressed: () {
                            mumbleUiVM
                                .connect()
                                .then((value) => GuiUtils()
                                    .showTextSnackbar(context, 'Connected!'))
                                .onError((error, stackTrace) {
                              GuiUtils().showTextSnackbar(
                                  context, "Failed to connect!",
                                  isError: true);
                              print(error);
                              print(stackTrace);
                            });
                          },
                          child: Text("Connect")),
                    if (mumbleUiVM.connected)
                      TextButton(
                          onPressed: () {
                            mumbleUiVM
                                .disconnect()
                                .then((value) => GuiUtils()
                                    .showTextSnackbar(context, 'Disconnected!'))
                                .onError((error, stackTrace) {
                              GuiUtils().showTextSnackbar(
                                  context, "Failed to disconnect!",
                                  isError: true);
                              print(error);
                              print(stackTrace);
                            });
                          },
                          child: Text("Disconnect")),
                    if (mumbleUiVM.connected)
                      // Focus(
                      //     autofocus: true,
                      //     focusNode: mumbleUiVM.transmitButtonFocus,
                      //     canRequestFocus: true,
                      //
                      //     child:
                      InkWell(
                        onTapDown: (_) {
                          print("Start!");
                          mumbleUiVM.startTransmit();
                        },
                        onTapUp: (_) {
                          mumbleUiVM.stopTransmit();
                        },
                        child: Icon(
                          Icons.mic,
                          size: 200,
                          color: mumbleUiVM.transmitting
                              ? Colors.green
                              : Colors.red,
                        ),
                        // )
                      ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            );
          });
        });
  }
}
