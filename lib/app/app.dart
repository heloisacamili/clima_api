import 'package:flutter/material.dart';
import 'package:http_example/view/weather_app.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WeatherApp(),
    );
  }
}