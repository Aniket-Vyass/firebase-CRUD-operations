import 'package:firebase_auth_crud/home.dart';
import 'package:flutter/material.dart';

//OLD PROJECT LOST, THIS IS NEW ONE CONEECTED TO SAME FIRESTORE AND SAME GIT REPO
void main() {
  runApp(const MyApp()); //
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Home(),
    );
  }
}
