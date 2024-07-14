import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({Key? key}) : super(key: key);

  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  final completedTripRequestsOfCurrentUser = FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Receipts',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black,
          ),
        ),
      ),


      body: StreamBuilder(
        // Stream is the query to the record in the database. It updates the changes in real-time.
        stream: completedTripRequestsOfCurrentUser.onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {return const Center(
              child: Text(
                'Something went wrong...',
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          if (!(snapshotData.hasData)) {
            return  const Center(child: CircularProgressIndicator(color: Colors.black,));
          }



          // Extracting data from the snapshot and converting to a list
          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips.forEach((key, value) => tripsList.add({"key": key, ...value}));

          // Sorting tripsList based on publishedDateTime
          tripsList.sort((b, a) {
            DateTime dateTimeA = DateTime.parse(a["requestedTime"]);
            DateTime dateTimeB = DateTime.parse(b["requestedTime"]);
            return dateTimeA.compareTo(dateTimeB);
          });

          // Building ListView with sorted tripsList
          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length, // Total number of trips
            itemBuilder: ((context, index) {
              if (tripsList[index]["status"] != null &&
                  tripsList[index]["status"] == "paid" &&
                  tripsList[index]["userID"] == FirebaseAuth.instance.currentUser!.uid)
              {
                // requested Time
                DateTime parsedDateTime = DateTime.parse(tripsList[index]["requestedTime"]);

                // completed Time
                DateTime completedTime = DateTime.parse(tripsList[index]["completedTime"]);

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 5.0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 3.0, spreadRadius: 0.3, offset: Offset(0.7, 0.7),)]),

                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // company logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/splashScreenLogo.png",
                                height: 140,
                                width: 140,
                              ),


                            ],
                          ),

                          // sender Name
                          Row(
                            children: [
                              const Text(
                                '                   Sender :   ',
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),


                             // sender Name
                              Expanded(
                                child: Text(
                                  tripsList[index]["userName"].toString(),
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    wordSpacing: 2,
                                  ),
                                ),
                              ),

                            ],
                          ),

                          const SizedBox(height: 8,),

                          // delivery Recipient Name
                          Row(
                            children: [
                              const Text(
                                '               Recipient :   ',
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),



                              // delivery Recipient Name
                              Expanded(
                                child: Text(
                                  tripsList[index]["deliveryRecipientName"].toString(),
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    wordSpacing: 2,
                                  ),
                                ),
                              ),


                            ],
                          ),


                          const SizedBox(height: 8,),
                          // Pickup
                          Row(
                            children: [
                              const Text(
                                '   Pickup Address :   ',
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),

                              // Pickup Address
                              Expanded(
                                child: Text(
                                  tripsList[index]["pickUpAddress"].toString(),
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    wordSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5,),
                              // Fare Amount

                            ],
                          ),
                          const SizedBox(height: 8,),
                          // DropOff
                          Row(
                            children: [
                              const Text(
                                'Drop-off Address :   ',
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),

                              // DropOff Address
                              Expanded(
                                child: Text(
                                  tripsList[index]["dropOffAddress"].toString(),
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    wordSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8,),

                          //Request time
                          Row(
                            children: [
                              //total
                              const Text(
                                "    Request time :  ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),

                              Text(
                                DateFormat('hh:mm a').format(parsedDateTime),
                                style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8,),

                          //delivered time
                          Row(
                            children: [

                              const Text(
                                "     Delivery time :  ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),


                              Text(
                                DateFormat('hh:mm a').format(completedTime),
                                style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8,),


                          //date
                          Row(
                            children: [

                              const Text(
                                "                   Date :  ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),

                              Container(
                                child: Text(
                                  DateFormat('d - MMMM - yyyy ').format(parsedDateTime),
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    letterSpacing: 0,
                                    wordSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8,),
                          //riders Name
                          Row(
                            children: [

                              const Text(
                                '          Delivered by :  ',
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),
                              Text(
                                tripsList[index]["driverName"].toString(),
                                style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0,
                                  wordSpacing: 2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8,),

                          const Divider(height: 1, color: Colors.black, thickness: 1,),

                          const SizedBox(height: 10,),

                          //fareAmount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [


                              //total
                              const Text(
                                "TOTAL :  ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),

                              Text(
                                "KES ${tripsList[index]["fareAmount"].toString()}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10,),

                          const Center(
                              child: Text(
                            'Thank you for choosing IDIL deliveries',
                            style: TextStyle(
                              overflow: TextOverflow.ellipsis,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: Colors.black54,
                              letterSpacing: 0,
                              wordSpacing: 2,
                            ),
                          )
                          ),

                          const SizedBox(height: 25,),
                          //social media
                          Row(
                            children: [
                              Container(
                                height: 20,
                                width: 344,
                                color: Colors.black,
                                child: const Row(
                                  children: [
                                    Text(
                                      '    For all communications : ',
                                      style: TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),

                                    SizedBox(width: 16,),
                                    Icon(Icons.email_rounded,size: 16,),

                                    Text(
                                      ' Idildeliveries@gmail.com',
                                      style: TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),

                                  ],
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 5,),
                        ],
                      ),
                    ),
                  ),
                );
              }
              else
              {
                return Container(); // Placeholder if the condition doesn't meet
              }
            }),
          );
        },
      ),
    );
  }
}
