import 'dart:async'; // Import the async library for handling asynchronous operations

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Import the Firebase Core library for Firebase initialization
import 'package:flutter/material.dart'; // Import the Flutter Material library for building UI components
import 'package:permission_handler/permission_handler.dart'; // Import the permission_handler library for handling permissions
import '../authentication/login_screen.dart';
import 'dashboard.dart'; // Import the LoginScreen widget from another file

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that Flutter bindings are initialized
  await Firebase.initializeApp(); // Initialize Firebase services

  // Request location permission if it is denied
  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });

  runApp(splash_screen()); // Run the Flutter application
}

class splash_screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Build the MaterialApp widget
    return MaterialApp(
      title: 'Flutter Demo', // Set the title of the app
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black), // Set the dark theme
      home: SplashScreen(), // Set the SplashScreen widget as the home screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  splashScreenState createState() => splashScreenState(); // Create state for the SplashScreen widget
}

class splashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Set a timer to trigger a setState after 700 milliseconds
    Timer(const Duration(milliseconds: 700), () {
      setState(() {});
    });

    // Set a timer to navigate to the LoginScreen after 3 seconds
    Timer(const Duration(seconds: 5), () {

      Navigator.pushReplacement(
        context,

        //if user is not logged into the App,navigate to loginScreen. if they are logged in go to dashboard
        MaterialPageRoute(
          builder: (context) => FirebaseAuth.instance.currentUser == null ? const LoginScreen() : const Dashboard(),


        ),
      );
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height; // Get the height of the screen
    double width = MediaQuery.of(context).size.width; // Get the width of the screen

    // Build the SplashScreen UI
    return Scaffold(
      backgroundColor: Colors.yellow, // Set background color to yellow
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 3000), // Set duration for the animation
            curve: Curves.fastLinearToSlowEaseIn, // Set animation curve
            width: width, // Set width of the container
            height: height, // Set height of the container
            color: Colors.white, // Change background color to white (This will animate due to the AnimatedContainer)
          ),


          Center(
            child: Image.asset(
              'assets/images/splashScreenLogo.png', // Set the image asset path
              width: 300, // Set width of the image
              height: 300, // Set height of the image
            ),
          ),
        ],
      ),
    );
  }
}
