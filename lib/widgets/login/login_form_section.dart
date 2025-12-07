import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import for storage
import 'package:jwt_decoder/jwt_decoder.dart'; // Import for decoding token

class LoginFormSection extends StatefulWidget {
  const LoginFormSection({super.key});

  @override
  State<LoginFormSection> createState() => _LoginFormSectionState();
}

class _LoginFormSectionState extends State<LoginFormSection> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';

  Future<void> _handleLogin() async {
    const String url = 'http://localhost:3000/api/accounts/login';
    String email = _emailController.text;
    String password = _passwordController.text;

    setState(() {
      _message = 'Logging in...';
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json'
        },
        body: jsonEncode(<String, String>{
          'email' : email,
          'password' : password
        }) 
      );

      if(response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String token = responseData['token'];
        String role = responseData['role'];
        print('Login Successfully. Token ${responseData['token']}');

        final prefs = await SharedPreferences.getInstance();

        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        int userId = decodedToken['user_id'];

        await prefs.setString('token', token);
        await prefs.setInt('userId', userId);
        await prefs.setString('role', role);

        String route = '';
        switch(responseData['role']){
          case 'admin' : route = '/admin/home'; break;
          case 'teacher' : route = '/teacher/home'; break;
          case 'student' : route = '/student/home'; break;
        }

        if(mounted){
          Navigator.of(context).pushReplacementNamed(route, arguments: {'userId': userId});
        }

      }else if(response.statusCode == 401){
        final responseData = jsonDecode(response.body);
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          _message = responseData['error'];
        });
      }

    } catch (e) {
      setState(() {
        _message = 'An error occured: Could not connect to the server.';
      });

      log('Error during api call $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 6, // Gives it 6 parts out of 10 (60%)
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "Login" Text
                Text('Login', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Subtitle
                Text('Enter your credentials to get in', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 30),
              ],
            ),
            // Email Fields
            Text('Email'),
            SizedBox(height: 5),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFF0F0F0), // Light background for the input
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none, // Remove the border line
                ),
                hintText: 'aimerpaix@gmail.com',
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
            SizedBox(height: 20),

            // Password Fields
            Text('Password'),
            SizedBox(height: 5),
            TextField(
              controller: _passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFF0F0F0), // Light background for the input
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none, // Remove the border line
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
            Text(_message),
            SizedBox(height: 20),
            

            // Remember Me and Login Button
            Row(
              children: [
                Checkbox(value: true, onChanged: (bool? val) {}),
                Text('Remember me'),
              ],
            ),
            SizedBox(height: 20),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Dark background
                  foregroundColor: Colors.white, // White text
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Login'),
              ),
            ),
            SizedBox(height: 20),

            // "Create an account" link
            Center(
              child: RichText(
                text: TextSpan(
                  text: 'Not a member? ',
                  style: TextStyle(color: Colors.grey[600]),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Create an account',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      // Add onTap for navigation here
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}