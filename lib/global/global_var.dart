import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String userPhone = "";
String userID = FirebaseAuth.instance.currentUser!.uid; //get it from firebase
String serverKeyFCM = "key=AAAAoBM7gkg:APA91bFQMblfpDf3hZa2DceHtHilFVmVaCc059vefYSYMR8jF5gV37GFkKRcgqvsEAvTCA_m5hQWhOJzb8w92OPyz44rxcK0HofYphgavskBL1_brQbUcONSgFvjaUPNqdEyGoERVnVR";



String googleMapKey = "AIzaSyDt4xK9MQC2dJYBi_Xvl3mIwD-fhoRXLQc";
String hereMapsKey = "3mIqRE6Uq7nIFjr1kk-vcIvk_7OlmCVZ4jqu9iQgBqE";

const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(-1.2921, 36.8219),
  zoom: 10,
);
