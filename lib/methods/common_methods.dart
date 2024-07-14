import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:user_app/appInfo/app_info.dart';
import 'package:user_app/global/global_var.dart';
import 'package:user_app/models/address_model.dart';

import '../models/directions_details.dart';



class CommonMethods

{
  double cancelledTripsPenalties = 0;


  checkConnectivity( BuildContext context) async
  {
    var connectionResult = await Connectivity().checkConnectivity();

    if(connectionResult != ConnectivityResult.mobile && connectionResult != ConnectivityResult.wifi)
    {
      if(!context.mounted ) return;
      displaySnackBar("Your internet is not available. Check connection and try again", context);

    }

  }


  displaySnackBar(String messageText ,BuildContext context)
  {
    var snackBar = SnackBar(
      content: Text(messageText,style: TextStyle(color: Colors.white),),
      backgroundColor: Colors.black, // Set the background color

    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static sendRequestToApi(String apiUrl) async {
    http.Response responseFromApi = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromApi.statusCode == 200) {
        String dataFromApi = responseFromApi.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      return "error";
    }
  }

  ///Reverse GeoCoding

  static Future<String> convertGeographiccoOrdinatesIntoHumanReadableAddress(Position position, BuildContext context) async {
    String humanReadableAddress = "";
    String hereMapsApiKey = hereMapsKey;
    String apiGeoCodingUrl = 'https://revgeocode.search.hereapi.com/v1/revgeocode?at=${position.latitude},${position.longitude}&lang=en-US&apiKey=$hereMapsApiKey';



    try {
      var response = await http.get(Uri.parse(apiGeoCodingUrl));

      if (response.statusCode == 200) {

        var decodedResponse = json.decode(response.body);

        humanReadableAddress = decodedResponse["items"][0]['address']['label'];

        ///print the results on the terminal to check for errors
        // print("humanReadableAddress >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> " + humanReadableAddress);
        // print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Latitude: ${position.latitude}, Longitude: ${position.longitude}");


        ///for sharing the address to another page
        AddressModel model = AddressModel();
        model.humanReadableAddress = humanReadableAddress;
        model.systemGeneratedPickUp_longitudePosition = position.longitude;
        model.systemGeneratedPickUp_latitudePosition = position.latitude;


        ///the sharing part
        Provider.of<AppInfo>(context,listen: false).updatePickUpAddress(model);

      }

      else {
        print("Failed to get human readable address >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>: ${response.statusCode}");
        print("Latitude: >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  ${position.latitude}, Longitude: ${position.longitude}");
      }
    } catch (e) {
      print("Error: $e");
    }

    return humanReadableAddress;
  }



  ///Directions API (HERE MAPS)
  static Future<DirectionDetails?> getDirectionDetailsFromAPI (LatLng source,LatLng destination) async //source => pickup Address, destination => Drop Off address
      {
    String urlDirectionsApi = 'https://router.hereapi.com/v8/routes?transportMode=bicycle&origin=${source.latitude},${source.longitude}&destination=${destination.latitude},${destination.longitude}&return=polyline,summary&apikey=$hereMapsKey';
    //test api with this:https://router.hereapi.com/v8/routes?transportMode=car&origin=-1.286389,36.817223&destination=-1.3192,36.9273&return=polyline,summary&apikey=ct3hJ5znWFCHYzzph8H6L_aEmPns8j6DP94aby5IQf0

    var responseFromDirectionsAPI = await sendRequestToApi(urlDirectionsApi);

    if(responseFromDirectionsAPI == [])//if response is not available
        {
      return null; //don't execute further if the response is null

    }
    else //check the json for...
        {
      DirectionDetails detailsModel = DirectionDetails();

      detailsModel.distanceTextString = responseFromDirectionsAPI["routes"][0]["sections"][0]["summary"]["length"].toString(); // in meters
      detailsModel.distanceValueDigits = responseFromDirectionsAPI["routes"][0]["sections"][0]["summary"]["length"];

      detailsModel.durationTextString = responseFromDirectionsAPI["routes"][0]["sections"][0]["summary"]["duration"].toString(); // in seconds
      detailsModel.durationValueDigits = responseFromDirectionsAPI["routes"][0]["sections"][0]["summary"]["duration"];

      detailsModel.encodedPoints = responseFromDirectionsAPI["routes"][0]["sections"][0]["polyline"]; // in Latitudes and longitudes









      return detailsModel; //now return the whole data



    }


  }



  saveFareAmountToDriversTotalEarnings(String fareAmount) async
  {

    DatabaseReference driverEarningsRef = FirebaseDatabase.instance.ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("cancelledTripsPenalties");

    //retrieve previous earnings from the data base of the driver
    await driverEarningsRef.once().then((snap)
    {
      //if earnings are available inside the database meaning driver did old trips;
      if(snap.snapshot.value !=null )
      {
        //retrieve the previous earnings from the database
        double cancelledTripsPenalties = double.parse(snap.snapshot.value.toString());//converted to double
        double fareAmountForTrip = double.parse(fareAmount);


        double newTotalEarnings = cancelledTripsPenalties + fareAmountForTrip;

        //now update the total to the earnings in the database
        driverEarningsRef.set(newTotalEarnings);

      }
      else //if the driver is new with no previous earnings records
          {
        //update the fareAmount directly to the earnings
        driverEarningsRef.set(fareAmount);
      }



    });
  }


  ///calculating the delivery cost
  calculateFareAmount(DirectionDetails directionDetails)
  {







    //company fare rates

    double distancePerKmAmount = 30;
    double durationPerMinuteAmount = 10;
    double baseFareAmount = 10;


    double totalDistanceTravelledFareAmount = (directionDetails.distanceValueDigits!/1000) * distancePerKmAmount; // distance amount per km
    double totalDurationSpendFareAmount = (directionDetails.durationValueDigits!/60) * durationPerMinuteAmount;

    //final fare price
    double overAllTotalFareAmount = baseFareAmount + totalDistanceTravelledFareAmount + totalDurationSpendFareAmount + cancelledTripsPenalties;

    //CONDITIONS
    if(overAllTotalFareAmount < 100)
    {
      overAllTotalFareAmount = 100 + cancelledTripsPenalties;
    }
    else if(overAllTotalFareAmount > 2000 )
    {
      return "Distance is too fur";

    }
    else if(overAllTotalFareAmount > 1000)//distances above 100km
        {
      overAllTotalFareAmount = 1000 + cancelledTripsPenalties;

    }

    // //final fare price
    return overAllTotalFareAmount.toStringAsFixed(0);//rounding off the amount to remove decimal numbers
  }
}