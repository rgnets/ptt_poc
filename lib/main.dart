import 'package:flutter/material.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';

import '/providers/mumble_provider.dart';
import '/views/mumble_ui/mumble_ui.dart';

void main() {
  Loggy.initLoggy(
      filters: [
        // BlacklistFilter([NetworkLoggy])
      ],
      logPrinter: const PrettyDeveloperPrinter(),
      logOptions: const LogOptions(
        LogLevel.debug,
        stackTraceLevel: LogLevel.error,
      ));

  // runApp(const MyApp());

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<MumbleProvider>(create: (_) => MumbleProvider())
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
      ),
      home: const MumbleUiView(),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
