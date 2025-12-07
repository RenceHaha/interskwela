import 'package:flutter/material.dart';
import 'package:interskwela/widgets/login/login_form_section.dart';
import 'package:interskwela/widgets/login/login_image_section.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white
          ),
          width: 900,
          height: 600,
          child: const Row(
            children: <Widget>[
              LoginFormSection(),
              ImageSection(),
            ],
          ),
        )
        
      ),
    );
  }
}

