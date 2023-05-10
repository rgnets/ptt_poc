import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pttoc_test/views/mumble_ui/mumble_ui_view_model.dart';
import 'package:rg_widgets/gui_utils.dart';

import '../../providers/mumble_provider.dart';

class MumbleUiView extends StatelessWidget {
  const MumbleUiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MumbleUiViewModel>(
        create: (_) => MumbleUiViewModel(
            Provider.of<MumbleProvider>(context, listen: false)),
        builder: (context, child) {
          return Consumer<MumbleUiViewModel>(
              builder: (context, mumbleUiVM, child) {
            return Scaffold(
              appBar: AppBar(
                // Here we take the value from the MyHomePage object that was created by
                // the App.build method, and use it to set our appbar title.
                title: Text("Mumble Test"),
              ),
              body: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: mumbleUiVM.hostTextController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.storage), label: Text("Host")),
                    ),
                    TextField(
                        controller: mumbleUiVM.portTextController,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            icon: Icon(Icons.lan), label: Text("Port"))),
                    TextField(
                      controller: mumbleUiVM.nameTextController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.person), label: Text("Name")),
                    ),
                    TextField(
                      controller: mumbleUiVM.passwordTextController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.key), label: Text("Password")),
                      obscureText: true,
                      obscuringCharacter: '*',
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
                          child: Text("Disconnect"))
                    // Text(
                    //   '$_counter',
                    //   style: Theme.of(context).textTheme.headlineMedium,
                    // ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ), // This trailing comma makes auto-formatting nicer for build methods.
            );
          });
        });
  }
}
