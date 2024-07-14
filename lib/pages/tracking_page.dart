import 'dart:async';
import 'dart:convert';
import 'dart:ffi';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/global/global_var.dart';
import 'package:user_app/methods/common_methods.dart';
import 'dart:ui' as ui;


import '../widgets/loading_dialog.dart';


class TrackingPage extends StatefulWidget
{
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage>

{
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  DatabaseReference? tripRequestRef;
  String tripStatus = "";
  String buttonTitleText = "Cancel Delivery";
  Color buttonColor = Colors.black;
  String trackedTripIdFromFirebase = "";
  String trackedUserIdFromFirebase = "";
  Set<Polyline> polylineSet = {};
  Set<Marker> markersSet = {};
  Set<Circle> circleSet = {};
  Set<Polyline> polylinesSet = Set<Polyline>();
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> coordinatesPolylineLatLngList = [];
  late LatLngBounds boundsLatLang;
  double halfFareAmount = 0;

  String tripsStatus = "";
  String userFareAmount = "";
  String deliveryRecipientName = "";
  String deliveryRecipientPhone = "";
  String pickupAddress = "";
  String dropOffAddress = "";
  String driverName ="";
  String driverPhone ="";
  String deliveryFeePaidBy = "";
  String carDetails ="";
  String deliveryInstructions ="";
  String driverPhoto = "";
  String requestTime = '';
  BitmapDescriptor? packageOnTransitMarker;
  BitmapDescriptor? dropoffLocationIcon;



  TextEditingController mpesaNumberTextEditingController = TextEditingController();


  final completedTripRequestsOfCurrentUser = FirebaseDatabase.instance.ref().child("tripRequests");



  makePackageOnTransitMarkerVisible() {
    if (packageOnTransitMarker == null) {
      ImageConfiguration configuration =
      createLocalImageConfiguration(context, size:  ui.Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
          configuration, "assets/images/packageLiveLocation.png")
          .then((iconImage) {
        packageOnTransitMarker = iconImage;
      });
    }
  }

  dropOffLocationMarker() {
    if (dropoffLocationIcon == null) {
      ImageConfiguration configuration =
      createLocalImageConfiguration(context, size:  ui.Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
          configuration, "assets/images/finaldropofficon.png")
          .then((iconImage) {
        dropoffLocationIcon = iconImage;
      });
    }
  }


  void updateMapTheme(GoogleMapController controller)
  {
    getJsonFileFromThemes("themes/grey_map.json").then((value)=> setGoogleMapStyle(value, controller));
  }

  Future< String > getJsonFileFromThemes(String mapStylePath) async
  {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);

  }

  setGoogleMapStyle( String googleMapStyle, GoogleMapController controller)
  {
    controller.setMapStyle(googleMapStyle);

  }

  getCurrentLiveLocationOfUser() async
  {
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng  positionOfUserInLatLang= LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: positionOfUserInLatLang ,zoom: 14.5);
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

  }

  retrieveTrackedTripIdFromFirebase()
  {
    // Query to retrieve drop-off pinned location
    DatabaseReference trackedTripIdRef = FirebaseDatabase.instance.ref().child("trackedTripIds");

    trackedTripIdRef.child(FirebaseAuth.instance.currentUser!.uid).onValue.listen((snap) {
      var value = snap.snapshot.value;

      if (value != null && value is Map)
       {
        var trackedTripID = value["tripId"];
        var trackedTripUserID = value["userID"];

        if (trackedTripID != null) {
          if (mounted) {
            setState(() {

              trackedTripIdFromFirebase = trackedTripID;
              trackedUserIdFromFirebase = trackedTripUserID;

            });
          }
        } else {
          return;
        }
      }
    });
  }

  readAllTrips() {
    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");

     tripRequestsRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        // Data exists
        Map<dynamic, dynamic>? tripsData = event.snapshot.value as Map<dynamic, dynamic>?;



        if (tripsData != null) {
          // Iterate through all trips
          tripsData.forEach((key, value) {
            if (key == trackedTripIdFromFirebase) //compare the tracked key from firebase
                {

              // Access specific values inside the specified key
              //Not sure:setState has a specific number of values it can set not all
              if(mounted)
              {
                setState(() {
                  tripsStatus = value['status'];
                  deliveryFeePaidBy = value['deliveryPaidby'];
                  userFareAmount = value['userFareAmount'];
                  deliveryRecipientName = value['deliveryRecipientName'];
                  deliveryRecipientPhone = value['deliveryRecipientPhone'];
                  driverPhoto = value['driverPhoto'];
                  driverName = value['driverName'];
                  driverPhone = value['driverPhone'];
                  carDetails = value['carDetails'];

                  // requested time
                  String requestedTimeString = value['requestedTime'];
                  DateTime requestedTime = DateTime.parse(requestedTimeString);
                  requestTime = "Requested at:  ${DateFormat('h:mm a').format(requestedTime)}\nDate:  ${DateFormat('d - MMMM -yyyy').format(requestedTime)}";

                  // Pickup location
                  pickupAddress = value['pickUpAddress'];
                  var pickUpLat = double.parse(value["pickUpLatLng"]["latitude"].toString());
                  var pickUpLng = double.parse(value["pickUpLatLng"]["longitude"].toString());
                  var pickupLatLng = LatLng(pickUpLat, pickUpLng);


                  // DropOff location
                  dropOffAddress = value['dropOffAddress'];
                  var dropOffLat = double.parse(value["dropOffLatLng"]["latitude"].toString());
                  var dropOffLng = double.parse(value["dropOffLatLng"]["longitude"].toString());
                  var dropOffLatLng = LatLng(dropOffLat, dropOffLng);


                  //driver live location
                  var driverLocationLat = double.parse(value["driverLocation"]["latitude"].toString());
                  var driverLocationLng = double.parse(value["driverLocation"]["longitude"].toString());
                  var driverLocationLatLng = LatLng(driverLocationLat, driverLocationLng);

                  //plot on the map
                  plotMarkersOnMap(driverLocationLatLng, dropOffLatLng);

                  tripStatusAndButtonUpdater();

                });
              }

            }
          });
        }
      } else {
        // No data exists
        print("No trips found.");
      }
    });
  }

  updateStatusToCancelled() {
    // Reference to the "tripRequests" node
    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");

    // Listen for changes in the "tripRequests" node
    tripRequestsRef.onValue.listen((event) {
      // Get the snapshot of the data
      DataSnapshot snapshot = event.snapshot;

      // Check if the snapshot value is not null and is a Map
      if (snapshot.value != null && snapshot.value is Map) {
        // Iterate over the child nodes
        (snapshot.value as Map).forEach((key, value) {
          if (value["userID"] ==
              FirebaseAuth.instance.currentUser!
                  .uid) //check if trip belongs to current user
          {
            if (value["tripID"] == trackedTripIdFromFirebase) {

              // Update the status to "trip aborted"
              tripRequestsRef.child(key).child("status").set("trip aborted");

              //delete the trip request from firebase
              FirebaseDatabase.instance
                  .ref()
                  .child("tripRequests")
                  .child(trackedTripIdFromFirebase)
                  .remove();


              Restart.restartApp(); //this removes error
            } else {
              return;
            }
          }
        });
      }
    });
  }


  plotMarkersOnMap(LatLng sourceLocationLatLng, LatLng destinationLocationLatLng) async {
    // Fit the polyline on the Google Map
    LatLngBounds boundsLatLang;

    if (sourceLocationLatLng.latitude > destinationLocationLatLng.latitude &&
        sourceLocationLatLng.longitude > destinationLocationLatLng.longitude)
    {
      boundsLatLang = LatLngBounds(
        southwest: destinationLocationLatLng,
        northeast: sourceLocationLatLng,
      );
    }
    else if (sourceLocationLatLng.longitude > destinationLocationLatLng.longitude) {
      boundsLatLang = LatLngBounds(
        southwest: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
        northeast: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
      );
    }
    else if (sourceLocationLatLng.latitude > destinationLocationLatLng.latitude) {
      boundsLatLang = LatLngBounds(
        southwest: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
        northeast: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
      );
    } else {
      boundsLatLang = LatLngBounds(
        southwest: sourceLocationLatLng,
        northeast: destinationLocationLatLng,
      );
    }

    // Start camera animation
    controllerGoogleMap!.animateCamera(
      CameraUpdate.newLatLngBounds(boundsLatLang, 72),
    );


    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLang, 60),);

// Add markers
    Marker sourceMarker = Marker(
      markerId: const MarkerId("sourceID"),
      position: sourceLocationLatLng,
      icon: packageOnTransitMarker!, // Always use custom icon
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLocationLatLng,
      icon: dropoffLocationIcon!,
    );

    markersSet.add(sourceMarker);
    markersSet.add(destinationMarker);

    // Add circles
    Circle sourceCircle = Circle(
      circleId: const CircleId("sourceCircleID"),
      strokeColor: Colors.blue.withOpacity(0.6),
      strokeWidth: 2,
      radius: 8,
      center: sourceLocationLatLng,
      fillColor: Colors.blue.withOpacity(0.3)
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationCircleID"),
      strokeColor: Colors.blue.withOpacity(0.6),
      strokeWidth: 2,
      radius: 8,
      center: destinationLocationLatLng,
      fillColor: Colors.blue.withOpacity(0.3)
    );

    circleSet.add(sourceCircle);
    circleSet.add(destinationCircle);
  }



  tripStatusAndButtonUpdater()
  {
    if ( tripsStatus =="accepted") {

        tripsStatus = "Rider is coming";
        //update button when rider is coming to pick up
        buttonTitleText = "Cancel request";
        buttonColor = Colors.indigo;

    }
    else if (tripsStatus == "updated") {
      tripsStatus = "Rider is coming";
      //update button when rider is coming to pick up
      buttonTitleText = "Cancel request";
      buttonColor = Colors.indigo;

    }

    else if (tripsStatus == "arrived") {
      tripsStatus = "Rider is here";
      //update button when rider has arrived
      buttonTitleText = "Cancel Delivery";
      buttonColor = Colors.black;
    }
    else if (tripsStatus == "onTrip") {
      tripsStatus = "Delivery in progress";
     buttonTitleText = "Cancel Delivery";
     buttonColor = Colors.pink;
    }

    else if (tripsStatus == "trip aborted") {
      tripsStatus = "Trip Cancelled";
      buttonTitleText = "Trip Cancelled";
      buttonColor = Colors.brown[800]!;
    }

    else if (tripsStatus == "ended"
        && deliveryFeePaidBy == "Recipient Pays")
    {
      tripsStatus = "Delivery completed";
      //update cancel Delivery button to pay
      buttonTitleText = "Pay for your Recipient";
      buttonColor = Colors.green;

    }
    else if (tripsStatus == "ended"
        && deliveryFeePaidBy == "Sender Pays" )
    {
      tripsStatus = "Delivery completed";
      //update cancel Delivery button to pay
      buttonTitleText = "Pay";
      buttonColor = Colors.green;

    }



  }


  updateButtonsFunctionalityAccordingToTripsStatus()
  {


    if(tripsStatus == "Rider is coming")
    {
      //pop up dialog box to ask user to be sure
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {

          ///cancel request
          return  AlertDialog(
            title: const Text("CANCEL REQUEST",style: TextStyle(color: Colors.white70),),


            content: const Text('Dear customer, \n\nkindly note that cancelling requests at this point may incur penalties on future requests.Do you wish to proceed ?',
              style: TextStyle(color: Colors.white,fontSize: 14),),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  //yes button
                  GestureDetector(
                    onTap:()
                    {
                      //cancel the trip request and set status to cancelled

                      updateStatusToCancelled();

                      //apply penalties
                      cancelledTripPenalties();


                    },
                    child:Container(
                      width:80,
                      decoration:BoxDecoration(color: Colors.grey[700],borderRadius: BorderRadius.circular(4)),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('YES', style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                  ),


                  //No button
                  GestureDetector(
                    onTap:()
                    {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width:80,
                      decoration:BoxDecoration(color: Colors.grey[700],borderRadius: BorderRadius.circular(4)),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('NO', style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    else if(tripsStatus == "Rider is here")
    {
      //pop up dialog box to ask user to be sure
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {

          ///cancel delivery
          return  AlertDialog(
            title: const Text("CANCEL DELIVERY",style: TextStyle(color: Colors.white70),),


            content: const Text('Dear customer, \n\nkindly note that cancelling requests at this point may incur penalties on future requests.Do you wish to proceed ?',
              style: TextStyle(color: Colors.white,fontSize: 14),),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  //yes button
                  GestureDetector(
                    onTap:()
                    {
                      //cancel the trip request and set status to cancelled

                      updateStatusToCancelled();

                      //apply penalties
                      cancelledTripPenalties();

                    },
                    child:Container(
                      width:80,
                      decoration:BoxDecoration(color: Colors.grey[700],borderRadius: BorderRadius.circular(4)),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('YES', style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                  ),


                  //No button
                  GestureDetector(
                    onTap:()
                    {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width:80,
                      decoration:BoxDecoration(color: Colors.grey[700],borderRadius: BorderRadius.circular(4)),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('NO', style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    //half-payment
    else if(tripsStatus == "Delivery in progress" )
    {

      //update trip status
      FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(trackedTripIdFromFirebase)
          .child("status")
          .set("tripAbortedHalfWay");


      //update end time stamp
      FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(trackedTripIdFromFirebase)
          .child("completedTime")
          .set(DateTime.now().toString());


      //pay half amount dialog box
      halfFareAmount = double.parse(userFareAmount) * 0.5;


      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {

          ///payment button
          return  AlertDialog(

            actions: <Widget>[
              Column(
                children: [

                  const SizedBox(height: 8,),

                  //close button
                  GestureDetector(
                    onTap:()
                    {
                      //update trip status
                      FirebaseDatabase.instance
                          .ref()
                          .child("tripRequests")
                          .child(trackedTripIdFromFirebase)
                          .child("status")
                          .set("onTrip");


                      Navigator.pop(context);

                      mpesaNumberTextEditingController.clear();

                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.close_rounded,color: Colors.white,size: 20,)
                      ],),
                  ),

                  const Center(child: Text("TOTAL",style: TextStyle(fontSize: 30),)),

                  const SizedBox(height: 15,),

                  const Divider(height: 1, color: Colors.white70, thickness: 1,),

                  const SizedBox(height: 10,),

                  //payment amount
                  Row( mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("KES  "),

                      Text(halfFareAmount.toStringAsFixed(0),style: const TextStyle(fontSize: 40,color: Colors.yellowAccent),),
                    ],
                  ),

                  const SizedBox(height: 10,),

                  const SizedBox(height: 10,),

                  //enter mpesa number
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: mpesaNumberTextEditingController,
                      keyboardType: TextInputType.phone,

                      decoration: const InputDecoration(

                        enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue,width: 2),),
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Enter M-Pesa number ",
                        hintStyle:  TextStyle(color: Colors.black45),

                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,

                      ),
                    ),
                  ),

                  const SizedBox(height: 20,),

                  //Lipa na Mpesa button
                  GestureDetector(
                    onTap:()
                    {


                      ///half payment
                      if (mpesaNumberTextEditingController.text.trim().length != 10)
                      {
                        cMethods.displaySnackBar("Enter a valid M-Pesa number",context);
                      }

                      else
                      {

                        String mpesaPhoneNumber = mpesaNumberTextEditingController.text.trim();// Get the text from the text editing controller

                        //pay half amount dialog box
                        halfFareAmount = double.parse(userFareAmount) * 0.5;


                        ///M-PESA API HERE

                        //saving the mpesaPaymentNumber
                         FirebaseDatabase.instance
                            .ref()
                            .child("tripRequests")
                            .child(trackedTripIdFromFirebase)
                            .child("mpesaNumber")
                            .set(mpesaPhoneNumber);



                        //saving the halfFareAmount to firebase records
                         FirebaseDatabase.instance
                            .ref()
                            .child("tripRequests")
                            .child(trackedTripIdFromFirebase)
                            .child("userFareAmount")
                            .set(halfFareAmount);

                        ///saving the halfFareAmount to fareAmount in firebase records.Driver account needs this
                        FirebaseDatabase.instance
                            .ref()
                            .child("tripRequests")
                            .child(trackedTripIdFromFirebase)
                            .child("fareAmount")
                            .set(halfFareAmount);

                        //make tripRequest to be paid
                         FirebaseDatabase.instance
                            .ref()
                            .child("tripRequests")
                            .child(trackedTripIdFromFirebase)
                            .child("status")
                            .set("senderPaidHalfAmount");


                        //remove the penalties and set to 0
                         FirebaseDatabase.instance
                            .ref()
                            .child("users")
                            .child(FirebaseAuth.instance.currentUser!.uid)
                            .child("cancelledTripsPenalties")
                            .set("0");


                        Navigator.pop(context); //close payment dialog
                        Navigator.pop(context); //close tracking page


                      }

                    },

                    child: Container(
                        height: 35,
                        width:250,
                        decoration:BoxDecoration(color: Colors.green,
                            borderRadius: BorderRadius.circular(5.0)

                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Text("LIPA NA M-PESA",style: TextStyle(fontSize:18 ),)),
                        )),
                  ),
                ],
              ),
            ],
          );
        },
      );

    }

    //full payment
    else if(tripsStatus == "Delivery completed")
    {
      //pop up dialog box to ask user to be sure
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {

          ///payment button
          return  AlertDialog(

            actions: <Widget>[
              Column(
                children: [

                  const SizedBox(height: 8,),

                  //close button
                  GestureDetector(
                    onTap:()
                    {
                      Navigator.pop(context);
                      mpesaNumberTextEditingController.clear();

                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.close_rounded,color: Colors.white,size: 20,)
                      ],),
                  ),

                  const Center(child: Text("TOTAL",style: TextStyle(fontSize: 30),)),

                  const SizedBox(height: 15,),

                  const Divider(height: 1, color: Colors.white70, thickness: 1,),

                  const SizedBox(height: 10,),

                  //payment amount
                  Row( mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("KES  "),

                      Text(userFareAmount,style: const TextStyle(fontSize: 40,color: Colors.yellowAccent),),
                    ],
                  ),

                  const SizedBox(height: 10,),

                  const SizedBox(height: 10,),

                  //enter mpesa number
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: mpesaNumberTextEditingController,
                      keyboardType: TextInputType.phone,

                      decoration: const InputDecoration(

                        enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue,width: 2),),
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Enter M-Pesa number ",
                        hintStyle:  TextStyle(color: Colors.black45),

                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,

                      ),
                    ),
                  ),

                  const SizedBox(height: 20,),

                  //Lipa na Mpesa button
                  GestureDetector(
                    onTap:()
                    {
                      paymentNumberValidation();
                    },

                    child: Container(
                        height: 35,
                        width:250,
                        decoration:BoxDecoration(color: Colors.green,
                            borderRadius: BorderRadius.circular(5.0)

                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Text("LIPA NA M-PESA",style: TextStyle(fontSize:18 ),)),
                        )),
                  ),
                ],
              ),
            ],
          );
        },
      );

    }


  }


  cancelledTripPenalties() async
  {
    double penaltyAmount = 0;
    double fareAmount = double.parse(userFareAmount);
    double penalty = penaltyAmount * fareAmount ;


    //when rider is coming and trip is cancelled .apply 5% of userFareAmount as penalty to be paid on next trip
    if(tripsStatus == "Rider is coming")
    {

       penaltyAmount = 0.03;
       fareAmount = double.parse(userFareAmount);
       penalty = double.parse((penaltyAmount * fareAmount).toStringAsFixed(0));



       //saving penalty
      await FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child("cancelledTripsPenalties")
          .set(penalty);

       //delete the trip request from firebase
       FirebaseDatabase.instance
           .ref()
           .child("tripRequests")
           .child(trackedTripIdFromFirebase)
           .remove();

    }


    //when rider is here and trip is cancelled .apply 10% of userFareAmount as penalty to be paid on next trip
    else if(tripsStatus == "Rider is here" ) {
      penaltyAmount = 0.06;
      fareAmount = double.parse(userFareAmount);
      penalty = penaltyAmount * fareAmount;

      //saving penalty
      await FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child("cancelledTripsPenalties")
          .set(penalty);


      //delete the trip request from firebase
      FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(trackedTripIdFromFirebase)
          .remove();
    }


  }

  paymentNumberValidation()
  async {
    if (mpesaNumberTextEditingController.text.trim().length != 10)
    {
      cMethods.displaySnackBar("Enter a valid M-Pesa number",context);
    }
    else
    {

      String mpesaPhoneNumber = mpesaNumberTextEditingController.text.trim();// Get the text from the text editing controller

      String fareAmount = userFareAmount;//get the fare amount

      ///M-PESA API HERE

      //saving the mpesaPaymentNumber
      await FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(trackedTripIdFromFirebase)
          .child("mpesaNumber")
          .set(mpesaPhoneNumber);

      //saving the fareAmount to firebase records
      await FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(trackedTripIdFromFirebase)
          .child("fareAmount")
          .set(fareAmount);

      //make tripRequest to be paid
      await FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(trackedTripIdFromFirebase)
          .child("status")
          .set("senderPaid");


      //remove the penalties and set to 0
      await FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child("cancelledTripsPenalties")
          .set("0");

      //make tripRequest to be paid
      await FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(trackedTripIdFromFirebase)
          .child("status")
          .set("paid");


      Navigator.pop(context); //close payment dialog
      Navigator.pop(context); //close tracking page


    }
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    retrieveTrackedTripIdFromFirebase();

  }

  @override
  Widget build(BuildContext context) {


    makePackageOnTransitMarkerVisible();
    dropOffLocationMarker();




    return Scaffold(
      backgroundColor: Colors.white,

      key: sKey,


      body: Stack(
        children: [

          //Google Map
        GoogleMap(
          padding: const EdgeInsets.only(top: 26, bottom: 365),
          mapType: MapType.normal,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          markers: markersSet,
          circles: circleSet,
          initialCameraPosition: googlePlexInitialPosition,
          onMapCreated: (GoogleMapController mapController) {
            controllerGoogleMap = mapController;

            updateMapTheme(controllerGoogleMap!);

            googleMapCompleterController.complete(controllerGoogleMap);

            ///live location of user brings errors in animating camera
           // getCurrentLiveLocationOfUser();
            readAllTrips(); //this enables user to zoom in swiftly
            retrieveTrackedTripIdFromFirebase();

          },
        ),





          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 8.0, spreadRadius: 0.3, offset: Offset(0.7, 0.7),)]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Center(
                      child: Container(
                          width: 200,
                          decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.circular(3.0)),
                          child:   Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Center(child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:

                                  [
                               const Text('status : ',
                                 style: TextStyle(color: Colors.white70),),
                                Text(tripsStatus ,style: const TextStyle(color: Colors.yellowAccent),),
                              ],
                            )),
                          )),
                    ),

                    const SizedBox(height: 8,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        //request time and date
                        Row(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [

                            //requested time and Date
                            Text(
                              requestTime,
                             style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.normal,
                            ),),
                          ],
                        ),


                        // Fare Amount
                        Row(
                          mainAxisAlignment:MainAxisAlignment.end,

                          children: [
                            Text(" $deliveryFeePaidBy - KES ", style: const TextStyle(fontSize: 13,color: Colors.black54,),),

                            Text(userFareAmount,
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                          ],
                        ),

                      ],
                    ),

                    const SizedBox(height: 8,),
                    const Divider(height: 1, color: Colors.black12, thickness: 1,),
                    const SizedBox(height: 8,),

                    //recipient details heading
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("RECIPIENT DETAILS",style: TextStyle(color: Colors.black,fontSize: 13,fontWeight: FontWeight.bold),),
                      ],
                    ),

                    const SizedBox(height: 8,),


                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        // Recipient Name and phone
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const SizedBox(width: 8,),

                            const Icon(Icons.person,color: Colors.black54,size: 18,),

                            const SizedBox(width: 5,),

                            const Text("Name : ",
                              style: TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 15,
                                color: Colors.black54,
                                letterSpacing: 0,
                                wordSpacing: 2,
                              ),),

                            //recipient name
                            Text( deliveryRecipientName,
                              style: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 15,
                                color: Colors.black,
                                letterSpacing: 0,
                                wordSpacing: 2,
                              ),
                            ),




                          ],
                        ),

                        //call recipient phone
                        GestureDetector(
                          onTap: ()
                          {
                            launchUrl(
                              Uri.parse(
                                  "tel://$deliveryRecipientPhone"
                              ),
                            );

                          },
                          child: Container(
                            height: 20,
                            width: 40,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.grey)),
                            child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Center(child: Text("Call",style: TextStyle(color: Colors.black),))
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13,),
                    // Pickup
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(width: 8,),
                        //heading
                        Image.asset(
                          'assets/images/initial.png',
                          height: 16,
                          width: 16,
                        ),

                        const SizedBox(width: 5,),

                        //pickup  address
                        Expanded(
                          child: Text(pickupAddress,
                            style: const TextStyle(
                              overflow: TextOverflow.ellipsis,
                              fontSize: 15,
                              color: Colors.black,
                              letterSpacing: 0,
                              wordSpacing: 2,
                            ),
                          ),
                        ),


                      ],
                    ),

                    const SizedBox(height: 13,),

                    // drop-off location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(width: 8,),

                        Image.asset(
                          'assets/images/final.png',
                          height: 16,
                          width: 16,
                        ),

                        const SizedBox(width: 5,),

                        //drop-off  address
                        Expanded(
                          child: Text(dropOffAddress,
                            style: const TextStyle(
                              overflow: TextOverflow.ellipsis,
                              fontSize: 15,
                              color: Colors.black,
                              letterSpacing: 0,
                              wordSpacing: 2,
                            ),
                          ),
                        ),


                      ],
                    ),

                    const SizedBox(height: 10,),
                    const Divider(height: 1, color: Colors.black12, thickness: 1,),
                    const SizedBox(height: 8,),

                    //Image - driverName - driver carDetails
                    Column(

                      children: [

                        //delivery personnel heading
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text("DELIVERY PERSON",style: TextStyle(color: Colors.black,fontSize: 13,fontWeight: FontWeight.bold),),
                          ],
                        ),

                        const SizedBox(height: 8,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [


                            //driver image
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.grey)),


                              child: ClipOval(
                                child: Image.network(
                                  driverPhoto == '' //if the image is empty,display the avatar from the link
                                      ? 'https://firebasestorage.googleapis.com/v0/b/idil-deliveries-app-with-admin.appspot.com/o/avatarman.png?alt=media&token=32535a78-83ab-4645-9afc-b05821918aca'
                                      : driverPhoto, //else display actual image
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),

                              ),
                            ),


                            const SizedBox(width: 10,),


                            //driver details
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [


                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [


                                    //rider name
                                    Row(
                                      children: [
                                        const Text("  Name   :  ",style: TextStyle(color: Colors.black54,fontSize: 13),),

                                        //riders Name
                                        Text(
                                          driverName,
                                          style: const TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                            fontSize: 15,
                                            color: Colors.black,
                                            letterSpacing: 0,
                                            wordSpacing: 2,
                                          ),
                                        ),

                                      ],
                                    ),

                                    const SizedBox(height: 5,),

                                    //car details
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("  Vehicle :  \n  Reg  ",style: TextStyle(color: Colors.black54,fontSize: 13),),

                                        //riders Name
                                        Text(
                                          carDetails,
                                          style: const TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                            fontSize: 15,
                                            color: Colors.black,
                                            letterSpacing: 0,
                                            wordSpacing: 2,
                                          ),
                                        ),

                                      ],
                                    ),
                                  ],
                                ),


                                const SizedBox(width: 20,),
                                //rider phone
                                GestureDetector(
                                  onTap: ()
                                  {
                                    launchUrl(
                                      Uri.parse(
                                          "tel://$driverPhone"
                                      ),
                                    );

                                  },
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey)),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.phone_enabled_rounded,color: Colors.black,),
                                    ),
                                  ),
                                ),


                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 13,),
                    const Divider(height: 1, color: Colors.black12, thickness: 1,),
                    const SizedBox(height: 10,),



                    ///cancel request + cancel delivery + pay button
                    GestureDetector(
                      onTap:()
                      {

                        updateButtonsFunctionalityAccordingToTripsStatus();

                      },

                      child: Center(
                        child: Container(
                            width: 200,
                            decoration: BoxDecoration(color: buttonColor,borderRadius: BorderRadius.circular(5.0)),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Center(child: Text(buttonTitleText,style: const TextStyle(color: Colors.white),)),
                            )),
                      ),
                    )

                  ],
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }
}
