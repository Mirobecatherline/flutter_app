import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/authentication/login_screen.dart';
import 'package:user_app/global/global_var.dart';
import 'package:user_app/global/trip_var.dart';
import 'package:user_app/methods/common_methods.dart';
import 'package:user_app/methods/manage_drivers_methods.dart';
import 'package:user_app/methods/push_notification_service.dart';
import 'package:user_app/models/directions_details.dart';
import 'package:user_app/models/online_nearby_drivers.dart';
import 'package:user_app/pages/track_delivery.dart';
import 'package:user_app/pages/trips_history_page.dart';
import 'package:user_app/widgets/info_dialog.dart';
import 'package:user_app/widgets/loading_dialog.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/payment_dialog.dart';
import 'Send_package_page.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget
{

  ///received info from the send page
  final String recipientName;
  final String recipientPhone;
  final String instructions;
  final String pickUpAddress;
     final String pickUpAddressLong;
     final String pickUpAddressLat;
     final String pickUpAddressPlaceId;

  final String dropOffAddress;
     final String dropOffAddressLong;
     final String dropOffAddressLat;
     final String dropOffAddressPlaceId;

  final String deliveryPaidBy;


  const HomePage({
    Key? key,
    required this.recipientName,
    required this.recipientPhone,
    required this.instructions,

    //pickUp address details
    required this.pickUpAddress,
    required this.pickUpAddressLong,
    required this.pickUpAddressLat,
    required this.pickUpAddressPlaceId,

    //dropOff address details
    required this.dropOffAddress,
    required this.dropOffAddressLong,
    required this.dropOffAddressLat,
    required this.dropOffAddressPlaceId,

    required this.deliveryPaidBy,



  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>

{
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  //GoogleMapController? controllerGoogleMap;
  late GoogleMapController controllerGoogleMap;

  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 170;
  double userDeliveryDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  double advertsContainerHeight = 170;
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoOrdinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  LatLngBounds? get boundsLatLang => null;
  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeyLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;
  Position? currentPositionOfOnlineUser;
  DatabaseReference? currentPositionOfOnlineUserReference; //for checking if driver is engaged to delivery or not
  BitmapDescriptor? dropoffLocationIcon;
  BitmapDescriptor? pickupLocationIcon;
  //double fareAmount = 0;



  makeDriverNearbyCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: const Size(0.5, 0.5));
              BitmapDescriptor.fromAssetImage(
              configuration, "assets/images/onlineRiderMarker.png")
          .then((iconImage) {
        carIconNearbyDriver = iconImage;
      });
    }
  }

  dropOffLocationMarker() {
    if (dropoffLocationIcon == null) {
      ImageConfiguration configuration =
      createLocalImageConfiguration(context, size:const Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
          configuration, "assets/images/finaldropofficon.png")
          .then((iconImage) {
        dropoffLocationIcon = iconImage;
      });
    }
  }

  pickupLocationMarker() {
    if (pickupLocationIcon == null) {
      ImageConfiguration configuration =
      createLocalImageConfiguration(context, size:const Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
          configuration, "assets/images/initialPickupIcon.png")
          .then((iconImage) {
        pickupLocationIcon = iconImage;
      });
    }
  }

  ///
  @override
  void initState() {
    super.initState();

    // Call displayUserDeliveryDetailsContainer asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.recipientName.isNotEmpty) {
        displayUserDeliveryDetailsContainer();

      }
    });
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

  getCurrentLiveLocationOfUser() async {


    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    if (userDeliveryDetailsContainerHeight == 0) //to prevent camera from zooming into your current position once you add makers,circles and poly-lines
    {
     showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              LoadingDialog(messageText: "Getting Your Location..."));

      //current position of user lat-lang
      LatLng positionOfUserInLatLang = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      CameraPosition cameraPosition =
          CameraPosition(target: positionOfUserInLatLang, zoom: 16.5);
      controllerGoogleMap.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      await CommonMethods.convertGeographiccoOrdinatesIntoHumanReadableAddress(currentPositionOfUser!, context);

      await getUserInfoAndCheckBlockStatus();

      await initializeGeoFireListener();

      Navigator.pop(context); //disappear the dialog box

     ///mod to prevent unwanted "online user" problem during app installation
     if(userName.isNotEmpty)
     {
       goOnlineNow();
     }
     else if(userName.isEmpty)
     {
       Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen())); // sends user to home page
     }

    }
  }

  //share users live location updates
  goOnlineNow()
  {
    //all users who are online
    Geofire.initialize("onlineUsers");
    Geofire.setLocation(
        FirebaseAuth.instance.currentUser!.uid, //getting the user id from firebase
        currentPositionOfUser!.latitude, //user latitude
        currentPositionOfUser!.longitude //user longitude
    );
    currentPositionOfOnlineUserReference = FirebaseDatabase.instance.ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("userStatus");

    currentPositionOfOnlineUserReference!.set("online"); //means the user is online

    currentPositionOfOnlineUserReference!.onValue.listen((event) { }); //it will listed for the updates
  }

  //stop sharing users live location updates
  goOfflineNow()
  {
    //stop sharing users live location updates
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);//remove user id

  }


  getUserInfoAndCheckBlockStatus() async {
    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);

    await usersRef.once().then((snap) {
      if (snap.snapshot.value !=
          null) //means if users record is in the "users parent" then the null wont be available
      {
        //checking if user is blocked by admin
        if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
          setState(() {
            userName = (snap.snapshot.value
                as Map)["name"]; // get the value of key name
            userPhone = (snap.snapshot.value as Map)["phone"];
          });
        } else // if user is blocked
        {
          FirebaseAuth.instance.signOut(); // sign out the user
          //send user to login page
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => const LoginScreen()));

          cMethods.displaySnackBar(
              "Account Suspended.Kindly Contact company: 0719 538 833",
              context); // display message
        }
      } else // if user record doesn't exist
      {
        FirebaseAuth.instance.signOut(); // sign out the user
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const LoginScreen()));
      }
    });
  }

  displayUserDeliveryDetailsContainer() async
  //displayUserDeliveryDetailsContainer()
  {
    ///await Directions Api (from HERE MAPS)
    // retrieveDirectionDetails();
    await retrieveDirectionDetails();

    setState(() {
      advertsContainerHeight = 0;
      bottomMapPadding = 390; //raise google maps high
      userDeliveryDetailsContainerHeight = 380; //make the details container visible
      isDrawerOpened = false;
    });
  }

  retrieveDirectionDetails() async
  {
    var userTypedPickUpGeographicCoOrdinates = LatLng(double.parse(widget.pickUpAddressLat),double.parse(widget.pickUpAddressLong));
    var dropOffGeographicCoOrdinates = LatLng(double.parse(widget.dropOffAddressLat),double.parse(widget.dropOffAddressLong));

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting directions..."),
    );

    ///Send request to direction API (HERE MAPS)

    var detailsFromDirectionsApiWithUserTypedPickUpAddress = await CommonMethods.getDirectionDetailsFromAPI(userTypedPickUpGeographicCoOrdinates, dropOffGeographicCoOrdinates);

    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionsApiWithUserTypedPickUpAddress;
      // print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Encoded Polyline Data: ${tripDirectionDetailsInfo!.encodedPoints!}');
    });


    Navigator.pop(context); // close the dialog box

    ///REMOVE POLY LINES FOR NOW
  /*  PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination = pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polylineCoOrdinates.clear();

    if(latLngPointsFromPickUpToDestination.isNotEmpty)
    {
      for (var latLngPoint in latLngPointsFromPickUpToDestination) {
        polylineCoOrdinates.add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
        ///print(polylineCoOrdinates); //confirms polyline coordinates are present

      }
    }

    polylineSet.clear();
    //now add it to the map
    setState(() {

      Polyline polyline =  Polyline(
        polylineId: PolylineId("polylineID"),
        color: Colors.black,
        points:polylineCoOrdinates,
        jointType: JointType.round,
        width: 1,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );


      //polylineSet.add(polyline);


    });*/

    //making the polyline fit on the map
    LatLngBounds boundsLatLang;

    if(userTypedPickUpGeographicCoOrdinates.latitude > dropOffGeographicCoOrdinates.latitude &&
        userTypedPickUpGeographicCoOrdinates.longitude > dropOffGeographicCoOrdinates.longitude)
    {
      boundsLatLang = LatLngBounds(
          southwest: dropOffGeographicCoOrdinates,
          northeast: userTypedPickUpGeographicCoOrdinates
      );
    }

    else if(userTypedPickUpGeographicCoOrdinates.longitude > dropOffGeographicCoOrdinates.longitude)
    {
      boundsLatLang = LatLngBounds(
        southwest: LatLng(userTypedPickUpGeographicCoOrdinates.latitude, dropOffGeographicCoOrdinates.longitude),
        northeast: LatLng(dropOffGeographicCoOrdinates.latitude, userTypedPickUpGeographicCoOrdinates.longitude),
      );
    }
    else if(userTypedPickUpGeographicCoOrdinates.latitude > dropOffGeographicCoOrdinates.latitude)
    {
      boundsLatLang = LatLngBounds(
          southwest: LatLng(dropOffGeographicCoOrdinates.latitude,userTypedPickUpGeographicCoOrdinates.longitude),
          northeast:LatLng(userTypedPickUpGeographicCoOrdinates.latitude,dropOffGeographicCoOrdinates.longitude)
      );

    }
    else
    {
      boundsLatLang = LatLngBounds(
          southwest: userTypedPickUpGeographicCoOrdinates,
          northeast: dropOffGeographicCoOrdinates);
    }


    //animate the camera according to the new boundsLatLang

    controllerGoogleMap.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLang, 72));

    controllerGoogleMap.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLang, 60),);

    //add markers to the initial and end points
    Marker pickUpLocationPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: userTypedPickUpGeographicCoOrdinates,
      icon: pickupLocationIcon!,
      infoWindow: InfoWindow(title: widget.pickUpAddress, snippet: "PickUp Location"),
    );

    Marker dropOffDestinationPointMarker = Marker(
      markerId: const MarkerId("dropOffDestinationPointMarkerID"),
      position: dropOffGeographicCoOrdinates,
      icon: dropoffLocationIcon!,
      infoWindow: InfoWindow(title: widget.dropOffAddress, snippet: "Destination Location"),


    );

    //display the markers on google maps
    setState(() {
      markerSet.add(pickUpLocationPointMarker);
      markerSet.add(dropOffDestinationPointMarker);
    });




    Circle pickUpPointCircle = Circle(
        circleId: const CircleId("pickUpCircleID"),
        strokeColor: Colors.blue.withOpacity(0.6),
        strokeWidth: 2,
        radius: 4,
        center: userTypedPickUpGeographicCoOrdinates,
        fillColor: Colors.blue.withOpacity(0.3)
    );

    Circle dropOffDestinationPointCircle = Circle(
        circleId: const CircleId("dropOffDestinationCircleID"),
        strokeColor: Colors.blue.withOpacity(0.6),
        strokeWidth: 2,
        radius: 4,
        center: dropOffGeographicCoOrdinates,
        fillColor: Colors.blue.withOpacity(0.3)
    );

    //now add it to the map
    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });
  }


  resetAppNow()
  {
    setState(() {
      //polylineCoOrdinates.clear();
      //polylineSet.clear();
      //markerSet.clear();
      //circleSet.clear();
      userDeliveryDetailsContainerHeight = 380;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      advertsContainerHeight = 0;


      searchContainerHeight = 276;
      bottomMapPadding = 400;
      isDrawerOpened = true;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetailsDriver = "";
      tripStatusDisplay = "Driver is arriving";

    });

    //Restart.restartApp();//method to restart our App
  }



  displayRequestContainer()
  {
    setState(() {
      advertsContainerHeight = 0;
      userDeliveryDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 250;
      isDrawerOpened = true;
    });

    //send ride request

    makeTripRequest();

  }
/*
  updateAvailableNearbyOnlineDriversOnMp() {
    if (markerSet.isEmpty) // Check if markerSet is empty
    {
      // Create a temporary set to hold all markers including existing ones
      Set<Marker> updatedMarkerSet = Set<Marker>.from(markerSet);

      // Create a temporary set to hold the new markers
      Set<Marker> markersTempSet = Set<Marker>();

      // Iterate over the list of nearby online drivers
      for (OnlineNearbyDrivers eachOnlineNearbyDriver in ManageDriversMethods.nearbyOnlineDriversList)
      {
        LatLng driverCurrentPosition = LatLng(eachOnlineNearbyDriver.latDriver!,eachOnlineNearbyDriver.longDriver!);

        Marker driverMarker = Marker(
          markerId: MarkerId("driver ID =${eachOnlineNearbyDriver.uidDriver}"),
          position: driverCurrentPosition,
          icon: carIconNearbyDriver!,
        );

        // Add the new marker to the temporary set
        markersTempSet.add(driverMarker);
      }

      // Add existing markers to the updated marker set
      updatedMarkerSet.addAll(markersTempSet);

      // Update the marker set only if the widget is still mounted and there are new markers
      if (mounted && markersTempSet.isNotEmpty) {
        setState(() {
          markerSet = updatedMarkerSet;
        });
      }
    }
  } */

  updateAvailableNearbyOnlineDriversOnMp()
  {
    setState(() {
      markerSet.clear(); //this removes all the markers
    });

    Set<Marker> markersTempSet = Set<Marker>();

    for(OnlineNearbyDrivers eachOnlineNearbyDriver in ManageDriversMethods.nearbyOnlineDriversList)
    {
      LatLng driverCurrentPosition = LatLng(eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.longDriver!);

      Marker driverMarker = Marker(
          markerId: MarkerId("driver ID =${eachOnlineNearbyDriver.uidDriver}"),
          position: driverCurrentPosition,
          icon: carIconNearbyDriver!,

        );

      markersTempSet.add(driverMarker);


    }

    setState(() {
      markerSet = markersTempSet;

    });



  }

  initializeGeoFireListener()
  {
    Geofire.initialize("onlineDrivers"); //go to firebase inside the "online drivers"

    //around the user current location,get all online drivers within a radius of 22 on google maps,
    Geofire.queryAtLocation(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude, 22)!.listen((driverEvent) // and listen continuously to their position updates
    {
      if(driverEvent != null)
      {
        var onlineDriverChild = driverEvent["callBack"];

        switch(onlineDriverChild)
        {
          case Geofire.onKeyEntered: //fired when any driver enters within the radius and displays them

            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];      //gets the drivers Uid
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];    //gets the drivers lat
            onlineNearbyDrivers.longDriver = driverEvent["longitude"];    //gets the drivers long
            ManageDriversMethods.nearbyOnlineDriversList.add(onlineNearbyDrivers);

            if(nearbyOnlineDriversKeyLoaded == true)
            {
              // update drivers on user google maps
              updateAvailableNearbyOnlineDriversOnMp();

            }

            break;

          case Geofire.onKeyExited: //fired when any driver becomes out of radius or goes offline
            ManageDriversMethods.removeDriverFromList(driverEvent["key"]);

            //update remaining drivers location on google maps
            updateAvailableNearbyOnlineDriversOnMp();


            break;

          case Geofire.onKeyMoved: //used to see drivers online movement within the radius
          //display nearest online drivers
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];      //gets the drivers Uid
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];    //gets the drivers lat
            onlineNearbyDrivers.longDriver = driverEvent["longitude"];    //gets the drivers long
            ManageDriversMethods.updateOnlineNearbyDriversLocation(onlineNearbyDrivers);

            // update drivers on user google maps
            updateAvailableNearbyOnlineDriversOnMp();

            break;

          case Geofire.onGeoQueryReady:
          //display nearest online drivers
            nearbyOnlineDriversKeyLoaded = true;

          //update drivers on google map
          updateAvailableNearbyOnlineDriversOnMp();
            break;
        }
      }
    });

  }

  makeTripRequest() {

    tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").push();


    // Accessing Delivery Recipient details from HomePage instance
    var recipientName = widget.recipientName;
    var recipientPhone = widget.recipientPhone;
    var deliveryInstructions = widget.instructions;

    // Accessing pickUp address details from HomePage instance
    var userTypedPickUpAddressLat = widget.pickUpAddressLat;
    var userTypedPickUpAddressLng = widget.pickUpAddressLong;

    // Accessing drop-off address details from HomePage instance
    var dropOffAddressLat = widget.dropOffAddressLat;
    var dropOffAddressLong = widget.dropOffAddressLong;

    //user FareAmount
    var userFareAmount = (cMethods.calculateFareAmount(tripDirectionDetailsInfo!)).toString();

    Map<String, dynamic> pickUpCoOrdinatesMap = {
      "latitude": userTypedPickUpAddressLat,
      "longitude": userTypedPickUpAddressLng,
    };

    Map<String, dynamic> dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffAddressLat,
      "longitude": dropOffAddressLong,
    };

    // User data
    Map<String, dynamic> dataMap = {
      "tripID": tripRequestRef!.key,
      "requestedTime": DateTime.now().toString(),
      "completedTime": "",
      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "deliveryRecipientName": recipientName,
      "deliveryRecipientPhone": recipientPhone,
      "deliveryInstructions": deliveryInstructions,
      "pickUpAddress": widget.pickUpAddress,
      "dropOffAddress": widget.dropOffAddress,
      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": {"latitude": "", "longitude": ""},
      "driverName": "",
      "driverPhone": "",
      "driverPhoto": "",
      "userFareAmount": userFareAmount,
      "fareAmount": "",
      "deliveryPaidby": widget.deliveryPaidBy,
      "mpesaNumber": "",
      "mpesaReceivedAmount": "",
      "status": "new",
    };

    // Upload trip request data to Firebase
    tripRequestRef!.set(dataMap);



    //getting assigned driver details immediately the driver accepts the request
    tripStreamSubscription = tripRequestRef!.onValue.listen((evenSnapshot) async
    {
      ///MOD- To prevent location updates from triggering tracking page to keep opening

      if(evenSnapshot.snapshot.value == null)
      {
        //if that trip request doesn't exist within the database return
        return;

      }

      //else if it exists retrieve the information of the driver
      //driver name
      if((evenSnapshot.snapshot.value as Map)['driverName'] != null)
      {
        nameDriver = (evenSnapshot.snapshot.value as Map)['driverName']; //nameDriver variable is from trip_var

      }
      //driver phone
      if((evenSnapshot.snapshot.value as Map)['driverPhone'] != null)
      {
        phoneNumberDriver = (evenSnapshot.snapshot.value as Map)['driverPhone']; //phoneNumberDriver variable is from trip_var

      }

      //driver photo
      if((evenSnapshot.snapshot.value as Map)['driverPhoto'] != null)
      {
        photoDriver = (evenSnapshot.snapshot.value as Map)['driverPhoto']; //photoDriver variable is from trip_var

      }


      //car details
      if((evenSnapshot.snapshot.value as Map)['carDetails'] != null)
      {
        carDetailsDriver = (evenSnapshot.snapshot.value as Map)['carDetails']; //carDetailsDriver variable is from trip_var

      }

      //status
      if((evenSnapshot.snapshot.value as Map)['status'] != null)
      {
        status = (evenSnapshot.snapshot.value as Map)['status']; //status variable is from trip_var

      }

      //get driver location
      if((evenSnapshot.snapshot.value as Map)['driverLocation'] != null)
      {
        double driverLatitude = double.parse((evenSnapshot.snapshot.value as Map)['driverLocation']['latitude'].toString());
        double driverLongitude = double.parse((evenSnapshot.snapshot.value as Map)['driverLocation']['longitude'].toString());


        //convert it to LatLang
        LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);



      //update trip status to the user on the user interface
      if(status == 'accepted')//status variable is from trip_var
        {
          //update info for pickup to the user UI
        //info will be driver current location to user pickup location
        updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
      }

      else if(status == 'arrived')//status variable is from trip_var
          {
        //update info for arrived- when driver has reached the pickup
        setState(() {
          tripStatusDisplay = "Rider has Arrived";
        });

      }

      else if(status == 'onTrip')//status variable is from trip_var
          {
        //info will be driver current location to user destination location
        updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
        }
      }


      //
      if(status == 'accepted')
      {
        displayTripDetailsContainerToUser();

        Geofire.stopListener();

        //Remove drivers markers.Delete all nearby drivers markers from the user map
        setState(() {
          //if the marker ID contains the word "driver" then remove that marker
          markerSet.removeWhere((element) => element.markerId.value.contains('driver'));
        });
      }



      if(status == 'ended')
      {
        if((evenSnapshot.snapshot.value as Map)['userFareAmount'] != null)
        {
          double fareAmount = double.parse((evenSnapshot.snapshot.value as Map)['userFareAmount'].toString());

          /*var responseFromPaymentDialog = await showDialog(
                                          context: context,
                                          barrierDismissible: false, // Set to false to make the dialog not dismissible
                                          builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount.toString())
          );*/

          if(status == 'paid')
          {
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();

            //restart the App to refresh
            Restart.restartApp();

          }

        }
      }

    });
/////////////////////////////////////////////////////////////////////////////////////////////////////////

    //empty pinnedLocation Data for next trip
     FirebaseDatabase.instance
        .ref()
        .child("pickUpPinnedPosition")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .set('');

    //empty pinnedLocation Data for next trip
    FirebaseDatabase.instance
        .ref()
        .child("dropOffPinnedPosition")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .set('');
  }



  displayTripDetailsContainerToUser()
  {



    setState(() {
      advertsContainerHeight = 0;
      requestContainerHeight = 0; //remove requestContainer

      tripContainerHeight = 291; // make tripContainer visible
      bottomMapPadding = 300;
    });
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo) //means if not true
    {
      requestingDirectionDetailsInfo = true;//set it to true

                   ///MOD get the drop off location from firebase
                  tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").push();
                   // Accessing drop-off address details from HomePage instance
                  double pickUpAddressLat = double.parse(widget.pickUpAddressLat);
                  double pickUpAddressLong = double.parse(widget.pickUpAddressLong) ;

      var userPickUPLocationLatLng = LatLng(pickUpAddressLat,pickUpAddressLong );

      var directionDetailsPickUp = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userPickUPLocationLatLng);

      if(directionDetailsPickUp ==null)
      {
        return;
      }

      //else
      setState(() {
        tripStatusDisplay = 'Rider is Coming in - ${(directionDetailsPickUp.durationValueDigits!/60).toStringAsFixed(0)} min';
        //durationText = "${(directionDetailsInfo.durationValueDigits! / 60).toStringAsFixed(0)} mins";
      });

      //set it to false so that it can execute next time
      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo) //means if not true
        {
      requestingDirectionDetailsInfo = true;//set it to true

              ///get the drop off location from firebase
              tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").push();
              // Accessing drop-off address details from HomePage instance
              double dropOffAddressLat = double.parse(widget.dropOffAddressLat);
              double dropOffAddressLong = double.parse(widget.dropOffAddressLong) ;


     /*var dropOffLocation = Provider.of<AppInfo>(context ,listen: false).dropOffAddress;*/
     var userDropOffLocationLatLng = LatLng(dropOffAddressLat,dropOffAddressLong);

     var directionDetailsPickUp = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if(directionDetailsPickUp ==null)
      {
        return;
      }

      //else
      setState(() {
        tripStatusDisplay = 'Package arrives in - ${(directionDetailsPickUp.durationValueDigits!/60).toStringAsFixed(0)} mins ';
      });

      //set it to false so that it can execute next time
      requestingDirectionDetailsInfo = false;
    }
  }


  cancelRideRequest() {
    //remove ride request from database
    tripRequestRef!.remove(); //delete it from database

    setState(() {
      stateOfApp = "normal";
    });
  }

  noDriverAvailable() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => InfoDialog(
              title: "Oops!! No Rider Available",
              description:
                  "No Rider found in the nearby location,please try again shortly.",
            ));

    cancelRideRequest(); //don't proceed with the request
  }

  searchDriver() {
    if (availableNearbyOnlineDriversList!.isEmpty) {
      cancelRideRequest();
      resetAppNow(); //to reset the App
      noDriverAvailable(); // message from dialog box
      return;
    }

    //else if the drivers are available
    var currentDriver = availableNearbyOnlineDriversList![0];

    //send notification to this current driver
    sendNotificationToDriver(currentDriver);

    //once the notification is sent remove current driver from the availableNearbyOnlineDriversList list

    availableNearbyOnlineDriversList!.removeAt(0);
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    //update drivers new trip status - assign trip Id to current driver(selected driver)
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key); //change the status from waiting to trip Id

    //get current driver device recognition token
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    tokenOfCurrentDriverRef.once().then((dataSnapShot) {
      if (dataSnapShot.snapshot.value != null) {
        String deviceToken = dataSnapShot.snapshot.value.toString();

        //send notification
        PushNotificationService.sendNotificationToSelectedDriver(
          deviceToken,
          context,
          tripRequestRef!.key.toString(),
        );
      } else {
        return;
      }

      const oneTicPerSec = Duration(seconds: 1);

      var timerCountDown = Timer.periodic(oneTicPerSec, (timer) {
        //decrement our timer with speed of 1 sec
        requestTimeoutDriver = requestTimeoutDriver - 1;

        //when delivery request is not requesting meaning delivery request is cancelled - stop timer
        if (stateOfApp != "requesting") {
          timer.cancel();

          currentDriverRef.set("cancelled");

          currentDriverRef.onDisconnect();

          requestTimeoutDriver = 20;
        }

        //when delivery request is accepted by online nearest available driver
        currentDriverRef.onValue.listen((dataSnapshot) {
          if (dataSnapshot.snapshot.value.toString() == "accepted") {
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }
        });

        //if driver lets the request pass the 20 secs,we send the request to the next nearest available online driver
        if (requestTimeoutDriver == 0) // means driver did not respond to requestContainerHeight
        {
          currentDriverRef.set("timeout");
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;

          //send request to next nearest available online driver
          searchDriver();
        }
      });
    });
  }

  /* sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key); //place the trip request key in the newTripStatus

    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    tokenOfCurrentDriverRef.once().then((dataSnapShot) {
      if (dataSnapShot.snapshot.value != null) { //means that the deviceToken is present
        String deviceToken = dataSnapShot.snapshot.value.toString();

        PushNotificationService.sendNotificationToSelectedDriver(
          deviceToken,
          context,
          tripRequestRef!.key.toString(),
        );
      } else
      {
        return;
      }

      const oneTicPerSec = Duration(seconds: 1);
      var timerCountDown = Timer.periodic(oneTicPerSec, (timer) {
        // Add print statements to monitor the timer
        print(
            '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Timer Tick  $requestTimeoutDriver'); // Print a message for each timer tick

        requestTimeoutDriver = requestTimeoutDriver - 1;

        if (requestTimeoutDriver == 0) {
          print(
              '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Timer expired - Request timeout  $requestTimeoutDriver');

          timer.cancel();
          currentDriverRef.onDisconnect();
          currentDriverRef.set("timeout");
          requestTimeoutDriver = 20;
          searchDriver();
        } else {
          if (stateOfApp != "requesting") {
            print(
                '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Timer cancelled - App state changed');
            timer.cancel();
            currentDriverRef.set("cancelled");
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }

          currentDriverRef.onValue.listen((dataSnapshot) {
            if (dataSnapshot.snapshot.value.toString() == "accepted") {
              print(
                  '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Timer cancelled - Request accepted by driver');
              timer.cancel();
              currentDriverRef.onDisconnect();
              requestTimeoutDriver = 20;
            }
          });
        }
      });
    });
  }*/


  void updateStatusToCancelled() {
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


          if (value["userID"] == FirebaseAuth.instance.currentUser!.uid)//check if trip belongs to current user
          {
            // Check if the status is "accepted"
            if (value["status"] == "accepted") //means rider has not yet reached at pickup location
                {

              //remove ride request from database
              //tripRequestsRef.remove(); //delete it from database


              // Update the status to "cancelled"
              tripRequestsRef.child(key).child("status").set("trip aborted");

              Restart.restartApp(); //this removes error
            } else {
              return;
            }
          }
        });
      }
    });
  }





  @override
  Widget build(BuildContext context) {

    makeDriverNearbyCarIcon(); //call the online drivers icon everytime the app starts building
    dropOffLocationMarker();
    pickupLocationMarker();


    return Scaffold(



      body: Stack(
        children: [
          ///Google Map
          GoogleMap(

            padding: EdgeInsets.only(top: 30, bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: false,

            //for drawing routes on the map
            //polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,

            initialCameraPosition: googlePlexInitialPosition,

            onMapCreated: (GoogleMapController mapController) {

              controllerGoogleMap = mapController;

              updateMapTheme(controllerGoogleMap);

              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
               // bottomMapPadding = 300;

              });

              getCurrentLiveLocationOfUser();

            },
          ),





          ///requestContainer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(0),topRight: Radius.circular(0)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.white70,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),

                  )


                ]
              ),
              child:  Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     const SizedBox(height: 12,),

                    //animation
                    SizedBox(
                      width: 200,
                      child: LoadingAnimationWidget.beat(
                          color: Colors.white,
                          size: 80)
                    ),

                    const SizedBox(height: 20,),

                    GestureDetector(
                      onTap: ()
                      {
                        cancelRideRequest();
                        resetAppNow();

                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.0 , color: Colors.black54),

                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.black,
                          size: 20,
                        ),

                      ),
                    ),



                  ],
                ),
              ),
            ),
          ),



          ///ADVERTISE HERE CONTAINER
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: advertsContainerHeight,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 13.0,
                        spreadRadius: 0.3,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),


                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [

                      SizedBox(height: 15,),

                      //logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Image.asset(
                              "assets/images/AppIcon.png",
                              height: 40,
                              width: 40,
                            ),
                          ),

                          Text('DELIVERIES',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,),)
                        ],
                      ),

                      SizedBox(height: 5,),
                      Divider(
                        thickness: 1,
                        color: Colors.grey[300],
                      ),

                      SizedBox(height: 20,),
                      //icons
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0,right: 8.0),
                        child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [


                            //notifications
                            GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (c)=> const NotificationsPage()));
                              },
                              child: Column(
                                children: [
                                  Icon(Icons.notifications_active_outlined,color: Colors.black,size: 25,),

                                  SizedBox(height: 5,),
                                  const Text("Notifications",style: TextStyle(color: Colors.black54,letterSpacing: 0,fontSize: 12),)
                                ],
                              ),
                            ),




                            //track
                            GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (c)=>const TrackDeliveryPage()));
                              },
                              child: Column(
                                children: [
                                  Icon(Icons.track_changes_rounded,color: Colors.black,size: 25,),
                                  SizedBox(height: 5,),
                                  const Text("Track",style: TextStyle(color: Colors.black54,letterSpacing: 0,fontSize: 12),)
                                ],
                              ),
                            ),




                            //send
                            GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (c)=> SendPackagePage()));
                              },
                              child: Column(
                                children: [
                                  Icon(Icons.send_rounded,color: Colors.black,size: 25,),

                                  SizedBox(height: 5,),
                                  const Text("Send",style: TextStyle(color: Colors.black54,letterSpacing: 0,fontSize: 12),)
                                ],
                              ),
                            ),


                            //history
                            GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (c)=>const TripsHistoryPage()));
                              },
                              child: Column(
                                children: [
                                  Icon(Icons.history,color: Colors.black,size: 25,),

                                  SizedBox(height: 5,),
                                  const Text("History",style: TextStyle(color: Colors.black54,letterSpacing: 0,fontSize: 12),)
                                ],
                              ),
                            ),




                            //rent a shelf
                            Column(
                              children: [
                                Icon(Icons.shelves,color: Colors.black,size: 25,),

                                SizedBox(height: 5,),
                                const Text("Shelves",style: TextStyle(color: Colors.black54,letterSpacing: 0,fontSize: 12),)
                              ],
                            ),





                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }
}
