import 'package:flutter/material.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
// import 'package:logger/logger.dart' as LOGGER;
import 'package:loggy/loggy.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:provider/provider.dart';

import '/providers/mumble_provider.dart';
import '/views/mumble_ui/mumble_ui.dart';

void main() async {
  // var logger = LOGGER.Logger(
  //   printer: LOGGER.PrettyPrinter(
  //       methodCount: 2, // number of method calls to be displayed
  //       errorMethodCount: 8, // number of method calls if stacktrace is provided
  //       lineLength: 120, // width of the output
  //       colors: true, // Colorful log messages
  //       printEmojis: true, // Print an emoji for each log message
  //       printTime: false // Should each log print contain a timestamp
  //       ),
  // );
  // Logger.addOutputListener((record) {
  //   print(
  //       '${record.time}: [${record.level.name}] ${record.loggerName}: ${record.message}');
  // });

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

  initOpus(await opus_flutter.load());
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
      title: 'RG Nets PTToC Demo',
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
