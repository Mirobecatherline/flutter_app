

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/appInfo/app_info.dart';
import 'package:user_app/methods/common_methods.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:user_app/pages/drop_off_address_pin_page.dart';
import 'package:user_app/pages/home_page.dart';
import 'package:user_app/pages/pick_up_address_pin_page.dart';
import 'package:user_app/pages/request_page.dart';
import 'package:user_app/widgets/loading_dialog.dart';

import '../global/global_var.dart';

class SendPackagePage extends StatefulWidget {
  const SendPackagePage({Key? key}) : super(key: key);

  @override
  State<SendPackagePage> createState() => _SendPackagePageState();
}


class _SendPackagePageState extends State<SendPackagePage> {

  bool isCheckBoxChecked = false;
  String deliveryPaymentDoneBy = "Sender Pays";
  double cancelledTripsPenalties = 0;
  double farePerKmAmount = 0;


  /// SHARED Text editing controllers
  TextEditingController recipientNameTextEditingController = TextEditingController();
  TextEditingController recipientPhoneTextEditingController = TextEditingController();
  TextEditingController instructionsTextEditingController = TextEditingController();
  TextEditingController pickUpAddressTextEditingController = TextEditingController();
  TextEditingController dropOffAddressTextEditingController = TextEditingController();

  FocusNode dropOffAddressFocusNode = FocusNode();
  FocusNode pickUpAddressFocusNode = FocusNode();
  FocusNode recipientNameFocusNode = FocusNode();


  ///initializing common methods
  CommonMethods cMethods = CommonMethods();

  ///searching for drop off location list
  List<String> searchSuggestionsTitle = [];
  List<String> searchSuggestionsRoad = [];
  List<double> searchSuggestionsLatitude =[];
  List<double> searchSuggestionsLongitude =[];

  String _selectedResult = '';

  ///PICK UP ADDRESS
  String pickUpAddressLatitude = ''; // Store latitude
  String pickUpAddressLongitude = ''; // Store longitude
  String pickUpPlaceId = ""; // place id

  ///DROP OFF ADDRESS
  String dropOffAddressLatitude = ''; // Store latitude
  String dropOffAddressLongitude = ''; // Store longitude
  String dropOffPlaceId = "";

  DatabaseReference? pinnedDropOffLocationRef;
  DatabaseReference? pinnedPickUpLocationRef;

  ///pinned pickup locations
  String pinnedPickupLatitude = "";
  String pinnedPickupLongitude = "";
  String pinnedPickupAddressName = "";

  ///pinned drop-off locations
  String pinnedDropOffLatitude = "";
  String pinnedDropOffLongitude = "";
  String pinnedDropOffAddressName = "";

  final FocusNode _recipientNameFocusNode = FocusNode();
  String distance = '';




  readPinnedPickupLocationFromFirebase() async {
    // Query to retrieve pick-up pinned location
    DatabaseReference pinnedPickUpLocationRef = FirebaseDatabase.instance.ref().child("pickUpPinnedPosition");

    pinnedPickUpLocationRef.child(FirebaseAuth.instance.currentUser!.uid).onValue.listen((snap) {
      var value = snap.snapshot.value;

      if (value != null && value is Map) {
        var addressName = value["AddressName"];

        if (addressName != null) {
          if (mounted) {
            setState(() {
              pinnedPickupLatitude = (value["latitude"] as double).toStringAsFixed(8);
              pinnedPickupLongitude = (value["longitude"] as double).toStringAsFixed(8);
              pinnedPickupAddressName = addressName;

              pickUpAddressLatitude = pinnedPickupLatitude;
              pickUpAddressLongitude = pinnedPickupLongitude;
              pickUpAddressTextEditingController.text = addressName;
            });
          }
        } else {
          return;
        }
      }
    });
  }


  readPinnedDropOffLocationFromFirebase() async {
    // Query to retrieve drop-off pinned location
    DatabaseReference pinnedDropOffLocationRef = FirebaseDatabase.instance.ref().child("dropOffPinnedPosition");

    pinnedDropOffLocationRef.child(FirebaseAuth.instance.currentUser!.uid).onValue.listen((snap) {
      var value = snap.snapshot.value;

      if (value != null && value is Map) {
        var addressName = value["AddressName"];

        if (addressName != null) {
          if (mounted) {
            setState(() {
              pinnedDropOffLatitude = (value["latitude"] as double).toStringAsFixed(8);
              pinnedDropOffLongitude = (value["longitude"] as double).toStringAsFixed(8);
              pinnedDropOffAddressName = addressName;

              dropOffAddressLatitude = pinnedDropOffLatitude;
              dropOffAddressLongitude = pinnedDropOffLongitude;
              dropOffAddressTextEditingController.text = addressName;
            });
          }
        } else {
          return;
        }
      }
    });
  }


  deletePinnedPickupLocationFromFirebase() async
  {

    await FirebaseDatabase.instance
        .ref()
        .child("pickUpPinnedPosition")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .set('');
  }

  deletePinnedDropOffLocationFromFirebase() async
  {

    await FirebaseDatabase.instance
        .ref()
        .child("dropOffPinnedPosition")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .set('');
  }


  importedPickupAddressFromHomePage()
  {
    ///imported address from home page
    String pickUpAddress =Provider.of<AppInfo>(context,listen: false).pickUpAddress?.humanReadableAddress ?? "";
    var userTypedPickUpLatitude =Provider.of<AppInfo>(context,listen: false).pickUpAddress?.systemGeneratedPickUp_latitudePosition ?? "";
    var userTypedPickUpAddressLongitude =Provider.of<AppInfo>(context,listen: false).pickUpAddress?.systemGeneratedPickUp_longitudePosition ?? "";


    ///put the imported address and lat, lang only when the text field area is empty
    if(pickUpAddressTextEditingController.text.trim().isEmpty )
    {
      //delay for 0 secs then ,if there is no activity put it.this prevents user from fighting with system to put data in the text-field area
      Future.delayed(const Duration(seconds: 0)).then((_)
      {
        pickUpAddressTextEditingController.text = pickUpAddress;
        pickUpAddressLatitude = userTypedPickUpLatitude.toString();
        pickUpAddressLongitude = userTypedPickUpAddressLongitude.toString();
      });
    }
    else
    {
      return;
    }
   }


  detailsValidation() async {

    if(recipientNameTextEditingController.text.trim().length <3 ) {
      cMethods.displaySnackBar("Recipient name must be at least 4 or more characters", context);

    } else if(recipientPhoneTextEditingController.text.trim().length <10 ) {
      cMethods.displaySnackBar("Invalid phone number", context);

    } else if(pickUpAddressTextEditingController.text.trim().length <2 ) {
      cMethods.displaySnackBar("Enter Pick Up Address", context);

    } else if(dropOffAddressTextEditingController.text.trim().length <2 ) {
      cMethods.displaySnackBar("Enter drop Off Address", context);
    }
    else
    {
      if(dropOffAddressLatitude.isNotEmpty && pickUpAddressLatitude.isNotEmpty)
      {
         //proceed showing the dialog box
        {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => LoadingDialog(messageText: "  Requesting Delivery\n  please wait..."),
          );

          bool dataSentSuccessfully = await sendDataToHomePage(context); // Pass the context here

          if(dataSentSuccessfully)
          {
            Navigator.pop(context); // Close the dialog if sending is successful

          }
          else
          {
            cMethods.displaySnackBar("Request Failed !", context);
          }

        }

      }
      else if(dropOffAddressLatitude.isEmpty)
      {
        // Show a pop-up dialog indicating successful location sent to firebase
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Drop-off Location not Found', style: TextStyle(color: Colors.white70),),

              content: const Text('Pin Location on Map.', style: TextStyle(color: Colors.white),),
              actions: <Widget>[

                TextButton(
                  onPressed: ()
                  {
                    //close that dialog
                    Navigator.pop(context);


                    //navigate to the map to pin location
                    Navigator.push(context, MaterialPageRoute(builder: (c)=>const DropOffAddressMapPin()));

                  },

                  child: const Text('OK', style: TextStyle(color: Colors.white),),
                ),
              ],
            );
          },
        );
      }

      else if(pickUpAddressLatitude.isEmpty)
      {

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Pick-up Location not Found', style: TextStyle(color: Colors.white70),),

              content: const Text('Pin Location on Map.', style: TextStyle(color: Colors.white),),
              actions: <Widget>[

                TextButton(
                  onPressed: ()
                  {
                    //close that dialog
                    Navigator.pop(context);


                    //navigate to the map to pin location
                    Navigator.push(context, MaterialPageRoute(builder: (c)=>const PickUpAddressMapPin()));

                  },

                  child: const Text('OK', style: TextStyle(color: Colors.white),),
                ),
              ],
            );
          },
        );
      }
    }
  }



  getAdditionalDataFromFirebase()
  async {

    ///penalties for cancelled rides
    DatabaseReference driverEarningsRef = await FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("cancelledTripsPenalties");

    driverEarningsRef.once().then((snap) {
      //retrieve the penalties from the database
      cancelledTripsPenalties = double.parse(snap.snapshot.value.toString()); //converted to double
    });


    ///company rates from firebase
    DatabaseReference companyRatesRef = await FirebaseDatabase.instance
        .ref()
        .child("companyRates")
        .child("farePerKm");

    companyRatesRef.once().then((snap) {
      //retrieve the farePerKm from the database
      farePerKmAmount = double.parse(snap.snapshot.value.toString()); //converted to double
    });




    print(">>>>>>>>>>>>>cancelledTripsPenalties $cancelledTripsPenalties");
    print(">>>>>>>>>>>>> farePerKmAmount $farePerKmAmount");

  }


  @override
  void initState() {
    super.initState();
    importedPickupAddressFromHomePage();

  }

  @override
  Widget build(BuildContext context) {

    readPinnedPickupLocationFromFirebase();
    readPinnedDropOffLocationFromFirebase();

    ///mod this ensures that the penalties and fareAmountPerKm  are always present
    getAdditionalDataFromFirebase();



    return Scaffold(
      backgroundColor: Colors.white,


      body: Column(
        children: [

          ///details section
          Container(
            height: 345,
            decoration: BoxDecoration(color: Colors.white,boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.2), // shadow color
              spreadRadius: 2, // spread radius
              blurRadius: 6, // blur radius
              offset: const Offset(0, 3),

            )] ),

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(7),

                child :Column(

                  children: [

                    const Text("SEND TO",
                      style: TextStyle(
                        color: Colors.black,fontSize: 17,fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4,),
                    ///Recipient name and phone
                    Row(
                      children: [
                        ///recipient Name
                        Expanded(flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6,right: 2,top: 6),
                            child: Container(
                              height: 35,
                              child: TextField(



                                controller: recipientNameTextEditingController,
                                keyboardType: TextInputType.text,
                                decoration:InputDecoration(

                                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.blue,width: 2),),
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6), // Adjust height of text field area
                                  prefixIcon: const Icon(Icons.person,color: Colors.black,),
                                  suffixIcon: GestureDetector(
                                      onTap: ()
                                      {
                                        recipientNameTextEditingController.clear();

                                      },
                                      child: const Icon(Icons.cancel,color: Colors.black26,size: 20,)),


                                  hintText: "Recipient Name ",
                                  hintStyle:  const TextStyle(color: Colors.black38,fontWeight: FontWeight.normal,fontSize: 14),

                                ),
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  letterSpacing: 0,

                                ),


                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3,),
                        ///recipient phone
                        Expanded(flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6,left: 2,top: 6),
                            child: Container(
                              height: 35,
                              child: TextField(


                                controller: recipientPhoneTextEditingController,
                                keyboardType: TextInputType.phone,
                                decoration:const InputDecoration(

                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue,width: 2),),
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Adjust height of text field area
                                  prefixIcon: Icon(Icons.phone,color: Colors.black,),




                                  hintText: "Phone  ",
                                  hintStyle:  const TextStyle(color: Colors.black38,fontWeight: FontWeight.normal,fontSize: 14),

                                ),
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 15,

                                ),
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 5),

                    ///Instructions
                    Padding(
                      padding: const EdgeInsets.only(left: 6,right: 6,top: 6),
                      child: Container(
                        height: 35,
                        child: TextField(


                          controller: instructionsTextEditingController,
                          keyboardType: TextInputType.text,

                          decoration:InputDecoration(

                            enabledBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.blue,width: 2),),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6), // Adjust height of text field area
                            prefixIcon: const Icon(Icons.edit_note,color: Colors.black,),

                            suffixIcon: GestureDetector(
                                onTap: ()
                                {
                                  instructionsTextEditingController.clear();

                                },
                                child: const Icon(Icons.cancel,color: Colors.black26,size: 20,)),




                            hintText: "Delivery instructions ( Optional ) e.g Room no",
                            hintStyle:  const TextStyle(color: Colors.black38,fontWeight: FontWeight.normal,fontSize: 14),


                          ),
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0,

                          ),

                          /// setting the max number of characters the user can type in the instructions
                          onChanged: (text) {
                           if (text.length > 80) {
                              instructionsTextEditingController.text = text.substring(0, 80);
                              instructionsTextEditingController.selection = TextSelection.fromPosition(
                                TextPosition(offset: instructionsTextEditingController.text.length),
                              );
                            }
                          },

                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    ///Pick up Address
                    Row(
                      children: [
                        ///Main Address
                        Expanded(flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6,right: 2,top: 6),
                            child: Container(
                              height: 35,
                              child: TextField(


                                controller: pickUpAddressTextEditingController,
                                keyboardType: TextInputType.text,
                                onChanged: _onSearchTextChanged,
                                focusNode: pickUpAddressFocusNode,

                                decoration:InputDecoration(

                                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.blue,width: 2),),
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Adjust height of text field area

                                  prefixIcon: const Icon(Icons.search_rounded,color: Colors.black,),
                                  suffixIcon: GestureDetector(
                                      onTap: ()
                                      {
                                        //clear the text
                                        pickUpAddressTextEditingController.clear();

                                        //also clear the lat and long
                                        pickUpAddressLatitude ="";
                                        pickUpAddressLongitude ="";

                                        //clear the pinned location data
                                        deletePinnedPickupLocationFromFirebase();

                                      },
                                      child: const Icon(Icons.cancel,color: Colors.black26,size: 20,)),



                                  hintText: "Pick Up Address",
                                  hintStyle:  const TextStyle(color: Colors.black38,fontWeight: FontWeight.normal,fontSize: 14),

                                ),
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  letterSpacing: 0,

                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3,),
                        ///pin pick up
                        Expanded(flex: 1,
                            child: GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (c)=>const PickUpAddressMapPin()));
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6,left: 2,top: 6),
                                child: Container(


                                  decoration: BoxDecoration(
                                    color: Colors.black12,borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.black12, // Set the border color here
                                      width: 1, // Set the border width here
                                    ),),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Image.asset("assets/images/pickupPin.png",height: 20,width: 20,),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    ///Drop off address
                    Row(
                      children: [
                        ///Main Address
                        Expanded(flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6,right: 2,top: 6),
                            child: GestureDetector(
                              onTap: ()
                              {
                                //if text field area is empty,clear the suggestions list
                                if(dropOffAddressTextEditingController.text.isEmpty)
                                {
                                  searchSuggestionsTitle.clear();// clear suggestions list
                                  searchSuggestionsRoad.clear();// clear suggestions list

                                }
                              },
                              child: Container(
                                height: 35,
                                child: TextField(


                                  controller: dropOffAddressTextEditingController,
                                  onChanged: _onSearchTextChanged,
                                  focusNode: dropOffAddressFocusNode,


                                  keyboardType: TextInputType.text,
                                  decoration:InputDecoration(

                                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide( color: Colors.blue,width: 2),),
                                    fillColor: Colors.white,
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Adjust height of text field area
                                    prefixIcon: const Icon(Icons.search_rounded,color: Colors.black,),

                                    suffixIcon: GestureDetector(
                                        onTap: ()
                                        {
                                          dropOffAddressTextEditingController.clear();

                                          //also clear lat and long
                                          dropOffAddressLongitude = "";
                                          dropOffAddressLatitude = "";

                                          deletePinnedDropOffLocationFromFirebase();//delete the pinned locations data from firebase too

                                        },
                                        child: const Icon(
                                          Icons.cancel,
                                          color: Colors.black26,
                                          size: 20,
                                        )),
                                    hintText: "Drop off Address",
                                    hintStyle:  const TextStyle(color: Colors.black38,fontWeight: FontWeight.normal,fontSize: 14),

                                  ),
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    letterSpacing: 0,

                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3,),
                        ///pin drop off
                        Expanded(flex: 1,
                            child: GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (c)=>const DropOffAddressMapPin()));
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6,left: 2,top: 6),
                                child: Container(


                                  decoration: BoxDecoration(
                                    color: Colors.black12,borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.black12, // Set the border color here
                                      width: 1, // Set the border width here
                                    ),

                                  ),

                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Image.asset("assets/images/dropoffPin.png",height: 20,width: 20,),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                        ),

                      ],
                    ),

                    const SizedBox(height: 10),

                    ///checkbox + request delivery
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 35,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [

                            Checkbox(
                              value: isCheckBoxChecked,
                              onChanged: (newValue) {
                                setState(() {
                                  isCheckBoxChecked = newValue!;
                                  // Update the payment method based on the checkbox state
                                  deliveryPaymentDoneBy = isCheckBoxChecked ? "Recipient Pays" : "Sender Pays";


                                });
                              },
                              checkColor: Colors.white, // Color of the check icon
                              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.black; // Color when checkbox is checked
                                }
                                return Colors.transparent; // Color when checkbox is not checked
                              }),
                            ),

                            const Text("Recipient pays for delivery",style: TextStyle(color: Colors.black87,fontWeight: FontWeight.normal),),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),




                    ///request delivery
                    Expanded(flex: 3,
                      child: Row(
                        children: [

                          //request delivery
                          Expanded( flex:5,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: GestureDetector(
                                onTap: () async
                                {
                                  detailsValidation(); // Validate the information

                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2), // shadow color
                                        spreadRadius: 2, // spread radius
                                        blurRadius: 6, // blur radius
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        'Request Delivery',
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                  ],
                ),

              ),
            ),
          ),

          ///suggested location results list
          Expanded(
            child: ListView.builder(
              itemCount: searchSuggestionsTitle.length,
              itemBuilder: (context, index) {

               if (index >= 0 && index < searchSuggestionsTitle.length &&
              index < searchSuggestionsRoad.length &&
               index < searchSuggestionsLatitude.length &&
                 index < searchSuggestionsLongitude.length)
               {
                 String title = searchSuggestionsTitle[index];
                 String? road = searchSuggestionsRoad[index]; // Get the road name associated with the title
                 double lat = searchSuggestionsLatitude[index];
                 double long = searchSuggestionsLongitude[index];


                 ///contains titles and roads
                 return ListTile(
                   contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),

                   title: Column(
                     children: [
                       Row(
                         children: [
                           const Expanded(
                             flex: 1,
                             child: Icon(Icons.location_on_outlined),
                           ),
                           Expanded(
                             flex: 9,
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [

                                 ///title
                                 Text(title, style: const TextStyle(
                                     color: Colors.black,
                                     fontSize: 16,
                                     letterSpacing: 0),),


                                 if (road
                                     .isNotEmpty) // Check if road is not empty to avoid null values
                                 ///road
                                   Text(road, style: const TextStyle(
                                       color: Colors.black54,
                                       fontSize: 13,
                                       letterSpacing: 0),)


                               ],
                             ),
                           ),
                           const Expanded(
                             flex: 1,
                             child: Icon(Icons.north_west_rounded),
                           ),
                         ],
                       ),

                       SizedBox(height: 5,),

                       const Divider(height: 1, color: Colors.black12, thickness: 1,),
                     ],
                   ),


                   onTap: () {
                     setState(() {
                       _selectedResult =
                       "$title,$road"; // put text on text field area

                       if (dropOffAddressTextEditingController.text.isEmpty) {
                         searchSuggestionsTitle.clear(); // clear suggestions list
                         searchSuggestionsRoad.clear(); // clear suggestions list

                       }
                       else
                       if (pickUpAddressTextEditingController.text.isEmpty) {
                         searchSuggestionsTitle.clear(); // clear suggestions list
                         searchSuggestionsRoad.clear(); // clear suggestions list
                       }
                       else if (dropOffAddressTextEditingController.text.isNotEmpty && dropOffAddressFocusNode.hasFocus)
                       {
                         dropOffAddressLatitude = lat.toString();
                         dropOffAddressLongitude = long.toString();
                         searchSuggestionsTitle.clear(); // clear suggestions list
                         searchSuggestionsRoad.clear(); // clear suggestions list
                         dropOffAddressTextEditingController.text = _selectedResult;
                       }
                       else if (pickUpAddressTextEditingController.text.isNotEmpty && pickUpAddressFocusNode.hasFocus)
                       {
                         pickUpAddressLatitude = lat.toString();
                         pickUpAddressLongitude = long.toString();
                         searchSuggestionsTitle.clear(); // clear suggestions list
                         searchSuggestionsRoad.clear(); // clear suggestions list
                         pickUpAddressTextEditingController.text = _selectedResult;
                       }

                       searchSuggestionsTitle.clear();
                       searchSuggestionsRoad
                           .clear(); // clear suggestions list
                     });
                   },
                 );
               }
               else {
                 // Display a text message when no location is found
                 return const Padding(
                   padding: EdgeInsets.all(10.0),
                   child: Center(
                     child: CircularProgressIndicator(color: Colors.black,)
                   ),
                 );
               }

               },
            ),
          ),


        ],
      ),
    );
  }



  void _onSearchTextChanged(String query) async {
    bool isLoading = true;

    setState(() {
      bool isLoading = true; // Set loading state to true when starting the search
    });

    String apiKey = hereMapsKey; // Replace with your HERE Maps API key
    final String apiUrl =
        'https://autocomplete.search.hereapi.com/v1/autosuggest?at=-1.2921,36.8219&limit=10&q=$query&apiKey=$apiKey&country=KEN';
    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        var suggestions = data['items'];

        setState(() {
          //put the results on the list
          searchSuggestionsTitle =
          List<String>.from(suggestions.map((item) => item['title'])); // Extract titles

          searchSuggestionsRoad = List<String>.from(suggestions.map((item) {
            String label = item['address']['label']; // Get the label from the address result of the j format
            List<String> addressParts =
            label.split(', '); // Split the label by comma and space

            // Ensure there are at least three parts in the addressParts list
            if (addressParts.length > 2) {
              // Return a concatenated string of the second and third items
              return '${addressParts[1]}, ${addressParts[2]}';
            } else if (addressParts.length > 1) {
              // If there are only two parts, return the second part
              return addressParts[1];
            } else {
              // Otherwise, return an empty string
              return '';
            }
          }));

          searchSuggestionsLatitude =
          List<double>.from(suggestions.map((item) => item['position']['lat']));
          searchSuggestionsLongitude =
          List<double>.from(suggestions.map((item) => item['position']['lng']));
        });
      } else {
        setState(() {
          searchSuggestionsTitle = [""];
          searchSuggestionsRoad = [""];
        });
      }
    } catch (e) {
      setState(() {
        searchSuggestionsTitle = [""];
        searchSuggestionsRoad = [""];
      });
    } finally {
      if(mounted){
      setState(() {
        isLoading = false; // Set loading state to false when search is finished
      });}
    }
  }



  /// function to send data to the home screen
  Future<bool> sendDataToHomePage(BuildContext context,) async {

    String recipientName = recipientNameTextEditingController.text;
    String recipientPhone = recipientPhoneTextEditingController.text;
    String instructions = instructionsTextEditingController.text;

    //pickup address
    String pickUpAddress = pickUpAddressTextEditingController.text;
    String pickUpAddressLong = pickUpAddressLongitude;
    String pickUpAddressLat = pickUpAddressLatitude;
    String pickUpAddressPlaceId = pickUpPlaceId;

    //drop Off address
    String dropOffAddress = dropOffAddressTextEditingController.text;
    String dropOffAddressLong = dropOffAddressLongitude;
    String dropOffAddressLat = dropOffAddressLatitude;
    String dropOffAddressPlaceId = dropOffPlaceId;

    //delivery paid by
    String deliveryPaidBy = deliveryPaymentDoneBy;

    double fareAmountPerKilometer = farePerKmAmount;
    double cancelledTripsPenaltiesFromFirebase = cancelledTripsPenalties;

    try {
      // Call the function to send data to HomePage
      await Navigator.push(context, MaterialPageRoute(builder: (context) => RequestPage(
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            instructions: instructions,

            pickUpAddress: pickUpAddress,
               pickUpAddressLong:pickUpAddressLong,
               pickUpAddressLat:pickUpAddressLat,
               pickUpAddressPlaceId:pickUpAddressPlaceId,

            dropOffAddress: dropOffAddress,
               dropOffAddressLong:dropOffAddressLong,
               dropOffAddressLat:dropOffAddressLat,
               dropOffAddressPlaceId:dropOffAddressPlaceId,

          deliveryPaidBy:deliveryPaidBy,
          fareAmountPerKilometer:fareAmountPerKilometer,
          cancelledTripsPenaltiesFromFirebase:cancelledTripsPenaltiesFromFirebase,




          ),
        ),
      );
      // Data sent successfully
      return true;
    } catch (e) {
      // Handle errors if data sending fails
      print("Error sending data to HomePage: $e");
      return false;
    }
  }


}


void main() {
  runApp(const MaterialApp(home: SendPackagePage()));
}