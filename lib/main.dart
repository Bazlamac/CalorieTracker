import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Screens/MainLayout.dart';
import 'theme.dart';

void main() => runApp(const CalorieTrackerApp());

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kalori Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}
