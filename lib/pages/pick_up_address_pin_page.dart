import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import '../widgets/loading_dialog.dart';

class PickUpAddressMapPin extends StatefulWidget {
  const PickUpAddressMapPin({Key? key}) : super(key: key);

  @override
  State<PickUpAddressMapPin> createState() => _PickUpAddressMapPinState();
}

class _PickUpAddressMapPinState extends State<PickUpAddressMapPin> {
  final Completer<GoogleMapController> googleMapCompleterController =
  Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double bottomMapPadding = 0;
  LatLng? pickUpPinPosition;
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
      pickUpPinPosition = LatLng(positionOfUser.latitude, positionOfUser.longitude,
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
      pickUpPinPosition = centerLocation;
      pinVerticalOffset = 0;
    });
  }

  void sendCoordinatesToFirebase() {
    if (pickUpPinPosition != null) {
      String userID = FirebaseAuth.instance.currentUser!.uid;
      String pinnedPickupName = "pinned pick-Up Location";

      Map<String, dynamic> pinnedPickUpAddress = {
        "userId": userID,
        "AddressName": pinnedPickupName,
        "latitude": pickUpPinPosition!.latitude,
        "longitude": pickUpPinPosition!.longitude,
      };

      DatabaseReference databaseReference = FirebaseDatabase.instance
          .ref()
          .child("pickUpPinnedPosition")
          .child(userID);

      databaseReference.set(pinnedPickUpAddress);
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
          if (pickUpPinPosition != null)
            GoogleMap(
              padding: EdgeInsets.only(top: 40, bottom: bottomMapPadding),
              mapType: MapType.normal,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: pickUpPinPosition!,
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
          if (pickUpPinPosition != null)
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 48 - pinVerticalOffset,
              left: MediaQuery.of(context).size.width / 2 - 24,
              child: Image.asset(
                'assets/images/pickupPin.png',
                width: 55,
                height: 55,
              ),
            ),


          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                decoration:  BoxDecoration(color: Colors.grey,borderRadius: BorderRadius.circular(3)),
                child: const Text(" Drag Map to Pin your Pickup Location ",style: TextStyle(color: Colors.white),),
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
                        pickUpPinPosition != null
                            ? 'Latitude: ${pickUpPinPosition!.latitude.toStringAsFixed(8)},    Longitude: ${pickUpPinPosition!.longitude.toStringAsFixed(8)}'
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
                            title: const Text('Pick-up Location', style: TextStyle(color: Colors.white70),),

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
                            "Select pickup Location",
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
