
import 'package:flutter/material.dart';
import 'package:user_app/methods/common_methods.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendPackagePage extends StatefulWidget {
  const SendPackagePage({Key? key}) : super(key: key);

  @override
  State<SendPackagePage> createState() => _SendPackagePageState();
}


class _SendPackagePageState extends State<SendPackagePage> {
  List<Widget> generatedContainers = [];


  /// SHARED Text editing controllers
  TextEditingController recipientNameTextEditingController = TextEditingController();
  TextEditingController recipientPhoneTextEditingController = TextEditingController();
  TextEditingController instructionsTextEditingController = TextEditingController();
  TextEditingController pickUpAddressTextEditingController = TextEditingController();
  TextEditingController dropOffAddressTextEditingController = TextEditingController();



  ///initializing common methods
  CommonMethods cMethods = CommonMethods();

  ///searching for drop off location list
  List<String> search_suggestions = [];
  String _selectedResult = '';
  String _latitude = ''; // Store latitude
  String _longitude = ''; // Store longitude




  @override
  void initState() {
    super.initState();
    // Add the initial red container
    generatedContainers.add(generateNewContainer(0));
  }


  /// Function to build a red container with a remove button

  Widget generateNewContainer(int index) {
    final originalIndex = index + 1; // Original index starting from 1

    TextEditingController recipientNameController = TextEditingController();
    TextEditingController recipientPhoneTextEditingController = TextEditingController();
    TextEditingController instructionsTextEditingController = TextEditingController();
    //TextEditingController pickUpAddressTextEditingController = TextEditingController();
    TextEditingController dropOffAddress_TextEditingController = TextEditingController();







    return Container(
      margin: const EdgeInsets.only(right: 8.0),///space between generated containers

      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),

      ///contents of the generated containers
      child: Column(

        children: [
          ///container number , close icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ///container number
              Padding(
                padding: const EdgeInsets.only(top: 8.0,left: 8),
                child: Text('$originalIndex', // Display original index,number of container
                  style: const TextStyle(color: Colors.black,fontSize: 16),
                ),
              ),

              const Text('SEND PACKAGE TO?',
                style:  TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),

              ///delete container icon
              IconButton(
                onPressed: () {
                  setState(() {
                    /// Ensure there's more than one container before attempting to delete
                    if (generatedContainers.length > 1 ) {

                      // Remove the container at the given index
                      generatedContainers.removeAt(index);





                      // No need to rebuild all containers in this case
                      // Just update the state to reflect the removal
                    } else {
                      /// Prevent the user from deleting the last remaining container
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Cannot Delete Container'),
                            content: const Text('At least one container must remain.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  });
                },
                icon: Icon(Icons.close_rounded, color: Colors.black),
              ),



            ],
          ),

          ///Recipient name and phone
          Row(
            children: [
              ///recipient Name
              Expanded(flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6,right: 2,top: 6),
                  child: TextField(


                    controller: recipientNameController,
                    keyboardType: TextInputType.text,
                    decoration:const InputDecoration(

                      enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue),),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 1, horizontal: 6), // Adjust height of text field area
                      prefixIcon: Icon(Icons.person,color: Colors.black,),


                      hintText: "Recipient Name ",
                      hintStyle:  TextStyle(color: Colors.black45,fontWeight: FontWeight.normal),

                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,

                    ),


                  ),
                ),
              ),
              const SizedBox(width: 3,),
              ///recipient phone
              Expanded(flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6,left: 2,top: 6),
                  child: TextField(


                    controller: recipientPhoneTextEditingController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(

                      enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue),),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Adjust height of text field area
                      prefixIcon: Icon(Icons.phone,color: Colors.black,),


                      hintText: "Phone  ",
                      hintStyle:  TextStyle(color: Colors.black45,fontWeight: FontWeight.normal),

                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,

                    ),
                  ),
                ),
              ),

            ],
          ),

          ///Instructions
          Container(
            child: Padding(
              padding: const EdgeInsets.only(left: 6,right: 6,top: 6),
              child: TextField(


                controller: instructionsTextEditingController,
                keyboardType: TextInputType.text,
                decoration:const InputDecoration(

                  enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue),),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 1, horizontal: 6), // Adjust height of text field area
                  prefixIcon: Icon(Icons.message_outlined,color: Colors.black,),


                  hintText: "Delivery instructions ( Optional ) ",
                  hintStyle:  TextStyle(color: Colors.black45,fontWeight: FontWeight.normal),

                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,

                ),
              ),
            ),
          ),

          ///Pick up Address
          Row(
            children: [
              ///Main Address
              Expanded(flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6,right: 2,top: 6),
                  child: TextField(


                    controller: pickUpAddressTextEditingController,
                    keyboardType: TextInputType.text,
                    decoration:const InputDecoration(

                      enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue),),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Adjust height of text field area
                      prefixIcon: Icon(Icons.search_rounded,color: Colors.black,),


                      hintText: "Pick Up Address",
                      hintStyle:  TextStyle(color: Colors.black45,fontWeight: FontWeight.normal),

                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,

                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3,),
              ///pin
              Expanded(flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6,left: 2,top: 6),
                    child: Container(


                      decoration: BoxDecoration(
                        color: Colors.white,borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.black12, // Set the border color here
                          width: 1, // Set the border width here
                        ),),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset("assets/images/pin.png",height: 30,width: 30,),
                          )
                        ],
                      ),
                    ),
                  )
              ),
            ],
          ),

          ///Drop off address
          Row(
            children: [
              ///Main Address
              Expanded(flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6,right: 2,top: 6),
                  child: TextField(


                    controller: dropOffAddress_TextEditingController,
                    onChanged: _onSearchTextChanged,


                    keyboardType: TextInputType.text,
                    decoration:const InputDecoration(

                      enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue),),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Adjust height of text field area
                      prefixIcon: Icon(Icons.search_rounded,color: Colors.black,),


                      hintText: "Drop off Address",
                      hintStyle:  TextStyle(color: Colors.black45,fontWeight: FontWeight.normal),

                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,

                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3,),
              ///pin
              Expanded(flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6,left: 2,top: 6),
                    child: Container(


                      decoration: BoxDecoration(
                        color: Colors.white,borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.black12, // Set the border color here
                          width: 1, // Set the border width here
                        ),),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset("assets/images/pin.png",height: 30,width: 30,),
                          )
                        ],
                      ),
                    ),
                  )
              ),

            ],
          ),

          Row(
            children: [
              ///latitude results
              Text(
                'Latitude: $_latitude',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(width: 10.0),

              ///longitude result
              Text(
                'Longitude: $_longitude',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 16.0),
            ],
          )
        ],
      ),
    );
  }





  /// Function to show a popup dialog

  Future<void> showPopupDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Maximum Containers Reached'),
          content: const Text('You cannot add more than 5 containers.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.blueGrey[50],

        ///main container
        body: Column(
          children: [
            Container(
              height: 350,
              decoration: BoxDecoration(color: Colors.grey[300]),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Column(

                    children: [


                      ///this is the container in which the generated containers are placed
                      Container(
                        height: 300,
                        decoration: BoxDecoration(color: Colors.transparent),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ...generatedContainers,
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ///send button
                          GestureDetector(
                            onTap: ()
                            {


                            },
                            child: Container(


                              color: Colors.transparent,
                              child: const Row(
                                children: [
                                  Icon(Icons.send_rounded,color: Colors.black,),
                                  SizedBox(width: 10,),
                                  Text('Send', style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),


                          ///more packages button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (generatedContainers.length < 5) {
                                  generatedContainers.add(generateNewContainer(generatedContainers.length));

                                } else {
                                  // Show the popup dialog when trying to add more than 5 containers
                                  showPopupDialog();
                                }
                              });
                            },
                            child: Container(


                              color: Colors.transparent,
                              child: const Row(
                                children: [
                                  Icon(Icons.add_circle_outline_rounded,color: Colors.black,),
                                  SizedBox(width: 10,),
                                  Text('More Packages   >>', style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),






                    ],
                  ),
                ),
              ),
            ),

            ///suggested location results
            Expanded(
              child: ListView.builder(
                itemCount: search_suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.fromLTRB(10,0,10,0),
                    title: Container(
                        padding: EdgeInsets.all(10),

                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.2), // shadow color
                              spreadRadius: 3, // spread radius
                              blurRadius: 5, // blur radius
                              offset: Offset(0, 3), // changes position of shadow
                            ),]),
                        child: Text(search_suggestions[index],style: TextStyle(color: Colors.black),)),

                    onTap: () {
                      setState(() {
                        _selectedResult = search_suggestions[index];
                        dropOffAddressTextEditingController.text = _selectedResult;
                        _performPlacesSearch(_selectedResult); // Fetch coordinates
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }




  /// Method to fetch suggestions based on the search query

  void _onSearchTextChanged(String query) async {
    final String apiKey = 'ct3hJ5znWFCHYzzph8H6L_aEmPns8j6DP94aby5IQf0'; // Replace with your HERE Maps API key
    final String apiUrl =
        'https://autosuggest.search.hereapi.com/v1/autosuggest?at=-1.2921,36.8219&limit=5&q=$query&apiKey=$apiKey';

    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        var suggestions = data['items'];

        setState(() {
          search_suggestions = List<String>.from(suggestions.map((item) => item['address']['label']));// from jSon data of here maps
        });
      } else {
        setState(() {
          search_suggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        search_suggestions = [];
      });
    }
  }


  /// Method to perform a place search based on the selected result

  void _performPlacesSearch(String query) async {
    final String apiKey = 'ct3hJ5znWFCHYzzph8H6L_aEmPns8j6DP94aby5IQf0'; // Replace with your HERE Maps API key
    final String apiUrl =
        'https://discover.search.hereapi.com/v1/discover?q=$query&apiKey=$apiKey&at=-1.2921,36.8219&limit=1';

    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        var items = data['items'];
        if (items.isNotEmpty) {
          var position = items[0]['position'];
          setState(() {
            _latitude = '${position['lat']}';
            _longitude = '${position['lng']}';
          });
        } else {
          setState(() {
            _latitude = 'No coordinates found';
            _longitude = 'No coordinates found';
          });
        }
      } else {
        setState(() {
          _latitude = 'Failed to get coordinates';
          _longitude = 'Failed to get coordinates';
        });
      }
    } catch (e) {
      setState(() {
        _latitude = 'Error: $e';
        _longitude = 'Error: $e';
      });
    }
  }


}

void main() {
  runApp(MaterialApp(home: SendPackagePage()));
}