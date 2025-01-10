import 'package:flutter/material.dart';
import 'package:music_app/models/music_provider.dart';
import 'package:music_app/pages/home_page.dart';
import 'package:music_app/models/settings_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
    ),
    ChangeNotifierProvider(
      create: (context) => MusicProvider(),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: Provider.of<SettingsProvider>(context).themeData,
      home: HomePage(),
    );
  }
}
