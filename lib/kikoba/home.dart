import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vicoba/tabshome.dart';
import 'package:vicoba/appColor.dart';
import 'package:vicoba/typography.dart';

List<CameraDescription> cameras = List.empty();

Future<Null> mainx() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Vikundi",
     theme: ThemeData(
  primaryColor: AppColors.primary,
  hintColor: AppColors.secondary,
  scaffoldBackgroundColor: AppColors.background,
  cardColor: AppColors.secondary,
  textTheme: AppTypography.textTheme,
),


      debugShowCheckedModeBanner: false,
      home: tabshome(),
    );
  }
}
