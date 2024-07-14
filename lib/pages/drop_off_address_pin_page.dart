import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import '../widgets/loading_dialog.dart';

class DropOffAddressMapPin extends StatefulWidget {
  const DropOffAddressMapPin({Key? key}) : super(key: key);

  @override
  State<DropOffAddressMapPin> createState() => _DropOffAddressMapPinState();
}

class _DropOffAddressMapPinState extends State<DropOffAddressMapPin> {
  final Completer<GoogleMapController> googleMapCompleterController =
  Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double bottomMapPadding = 0;
  LatLng? dropOffPinPosition;
  double pinVerticalOffset = 0;

  @override
  void initState() {
    super.initState();
    getCurrentLiveLocationOfUser();
  }

  void updateMapTheme(GoogleMapController controller) async {
    String mapStyle = await getJsonFileFromThemes("themes/grey_map.json");
    setGoogleMapStyle(mapStyle, controller);
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    String style = await rootBundle.loadString(mapStylePath);
    return style;
  }

  void setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  void getCurrentLiveLocationOfUser() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation,);



    setState(() {
      currentPositionOfUser = positionOfUser;
      dropOffPinPosition = LatLng(positionOfUser.latitude, positionOfUser.longitude,
      );
    });
  }

  void _onCameraMoveStarted() {
    // When camera movement starts, raise the pin slightly
    setState(() {
      pinVerticalOffset = 10;
    });
  }

  void _onCameraIdle() async {
    // When camera movement stops, update pin position and drop it back
    final GoogleMapController controller =
    await googleMapCompleterController.future;

    LatLngBounds visibleRegion = await controller.getVisibleRegion();
    double lat = (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2;
    double lng = (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2;
    LatLng centerLocation = LatLng(lat, lng);


    setState(() {
      dropOffPinPosition = centerLocation;
      pinVerticalOffset = 0;
    });
  }

  void sendCoordinatesToFirebase() {
    if (dropOffPinPosition != null) {
      String userID = FirebaseAuth.instance.currentUser!.uid;
      String pinnedDropOffName = "pinned drop-0ff Location";

      Map<String, dynamic> pinnedDropOffAddress = {
        "userId": userID,
        "AddressName": pinnedDropOffName,
        "latitude": dropOffPinPosition!.latitude,
        "longitude": dropOffPinPosition!.longitude,
      };

      DatabaseReference databaseReference = FirebaseDatabase.instance
          .ref()
          .child("dropOffPinnedPosition")
          .child(userID);

      databaseReference.set(pinnedDropOffAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: sKey,

      body: Stack(
        children: [

          //map
          if (dropOffPinPosition != null)
            GoogleMap(
              padding: EdgeInsets.only(top: 40, bottom: bottomMapPadding),
              mapType: MapType.normal,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: dropOffPinPosition!,
                zoom: 17,
              ),
              onMapCreated: (GoogleMapController mapController) {
                controllerGoogleMap = mapController;
                googleMapCompleterController.complete(controllerGoogleMap);
                setState(() {
                  bottomMapPadding = 0;
                });
                updateMapTheme(controllerGoogleMap!);
              },
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraIdle: _onCameraIdle,
            ),



          //pin
          if (dropOffPinPosition != null)
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 48 - pinVerticalOffset,
              left: MediaQuery.of(context).size.width / 2 - 24,
              child: Image.asset(
                'assets/images/dropoffPin.png',
                width: 55,
                height: 55,
              ),
            ),


          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                decoration:  BoxDecoration(color: Colors.grey,borderRadius: BorderRadius.circular(3)),
                child: const Text(" Drag Map to Pin your Drop-off Location ",style: TextStyle(color: Colors.white),),
              ),
            ),
          ),


          //coordinates
          Positioned(
            bottom: 50,
            left: 16,
            right: 16,
            child: Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),color: Colors.grey),

                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        dropOffPinPosition != null
                            ? 'Latitude: ${dropOffPinPosition!.latitude.toStringAsFixed(8)},    Longitude: ${dropOffPinPosition!.longitude.toStringAsFixed(8)}'
                            : '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12,),


                  //select pickup button
                  GestureDetector(
                    onTap: () {

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) => LoadingDialog(
                          messageText: "   Loading...",
                        ),
                      );

                      //send coordinates to firebase
                      sendCoordinatesToFirebase();

                      Navigator.pop(context);

                      // Show a pop-up dialog indicating successful location sent to firebase
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Drop-off Location', style: TextStyle(color: Colors.white70),),

                            content: const Text('Selected Successfully.', style: TextStyle(color: Colors.white),),
                            actions: <Widget>[

                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); //close dialog
                                  Navigator.pop(context); //close map page.go back to send_package page
                                },

                                child: const Text('OK', style: TextStyle(color: Colors.white),),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.black,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Select drop-off Location",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
