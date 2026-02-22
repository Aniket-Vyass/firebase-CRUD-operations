import 'package:firebase_auth_crud/home.dart';
import 'package:firebase_auth_crud/login.dart';
import 'package:firebase_auth_crud/login2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // if Waiting for connection due to slow internet etc. could be anything
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        //User Logged in Successfully
        if (snapshot.hasData) {
          return Home();
          //if user not logged in, sending the user to login screen to login again
        } else {
          return PhoneLoginScreen();
        }
      },
    );
  }
}
