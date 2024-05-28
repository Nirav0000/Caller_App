import 'package:caller_app/Screens/Intro/IntroScreen2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

import 'Constent/Colors.dart';
import 'Screens/BottomTabBar.dart';
import 'Screens/HomeScreen.dart';
import 'Screens/Intro/IntroScreemn.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Hive.initFlutter();
  await Hive.openBox('GetContacts');
  runApp(
    GetMaterialApp(

      home: storage.read('gotContact')==true? BottomTabbar():Intro2(),
      debugShowCheckedModeBanner: false,
    )
  );
}