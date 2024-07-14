import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({Key? key}) : super(key: key);

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentUser = FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Complete Deliveries',
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


              if (tripsList[index]["status"] != null
                  &&
                  tripsList[index]["userID"] == FirebaseAuth.instance.currentUser!.uid)

              {
                ///mod : don't combine the two conditions,it will ignore user id and not filter properly
                if (tripsList[index]["status"] == "paid")
                {
                  {
                    // requested Time
                    DateTime parsedDateTime = DateTime.parse(tripsList[index]["requestedTime"]);

                    // completed Time
                    DateTime completedTime = DateTime.parse(tripsList[index]["completedTime"]);

                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, top: 5.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 3.0,
                                spreadRadius: 0.3,
                                offset: Offset(0.7, 0.7),
                              )
                            ]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // delivery Recipient Name
                              Row(
                                children: [
                                  //icon
                                  const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.black45,
                                  ),

                                  const SizedBox(
                                    width: 18,
                                  ),

                                  // delivery Recipient Name
                                  Expanded(
                                    child: Text(
                                      tripsList[index]["deliveryRecipientName"]
                                          .toString(),
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

                                  //fareAmount
                                  Text(
                                    "KES ${tripsList[index]["fareAmount"].toString()}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),
                              // Pickup - fareAmount
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/initial.png',
                                    height: 16,
                                    width: 16,
                                  ),
                                  const SizedBox(
                                    width: 18,
                                  ),
                                  // Pickup Address
                                  Expanded(
                                    child: Text(
                                      tripsList[index]["pickUpAddress"]
                                          .toString(),
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  // Fare Amount
                                ],
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              // DropOff - fareAmount
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/final.png',
                                    height: 16,
                                    width: 16,
                                  ),
                                  const SizedBox(
                                    width: 18,
                                  ),
                                  // DropOff Address
                                  Expanded(
                                    child: Text(
                                      tripsList[index]["dropOffAddress"]
                                          .toString(),
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 8,
                              ),

                              //time
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  //requested time
                                  Expanded(
                                    child: Text(
                                      "               Requested at : ${DateFormat('h:mm a').format(parsedDateTime)}",
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 12,
                                        color: Colors.black54,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),
                                  ),

                                  //delivered time
                                  Text(
                                    "              Delivered at : ${DateFormat('h:mm a').format(completedTime)}",
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 12,
                                      color: Colors.black54,
                                      letterSpacing: 0,
                                      wordSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              //date
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  //date
                                  Container(
                                    child: Text(
                                      "              Date: ${DateFormat('d /MM /yyyy ').format(parsedDateTime)}",
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 12,
                                        color: Colors.black54,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),
                                  ),

                                  //riders Name
                                  Text(
                                    "By : ${tripsList[index]["driverName"].toString()}",
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 12,
                                      color: Colors.black54,
                                      letterSpacing: 0,
                                      wordSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              //delete button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                              content: const Text(
                                                'Do you wish to delete this record ?',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              actions: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    //yes
                                                    TextButton(
                                                      onPressed: () {
                                                        if (tripsList[index]
                                                                ["status"] ==
                                                            "riderArchive") //means rider has archived
                                                        {
                                                          //update trip status
                                                          FirebaseDatabase
                                                              .instance
                                                              .ref()
                                                              .child(
                                                                  "tripRequests")
                                                              .child(tripsList[
                                                                      index]
                                                                  ["tripID"])
                                                              .child("status")
                                                              .set(
                                                                  "systemArchive"); //prevent everyone from seeing it
                                                        } else //means rider has not archived.its still visible to them
                                                        {
                                                          //update trip status
                                                          FirebaseDatabase
                                                              .instance
                                                              .ref()
                                                              .child(
                                                                  "tripRequests")
                                                              .child(tripsList[
                                                                      index]
                                                                  ["tripID"])
                                                              .child("status")
                                                              .set(
                                                                  "userArchive");
                                                        }

                                                        Navigator.pop(
                                                            context); //close dialog
                                                      },
                                                      child: const Text(
                                                        'YES',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),

                                                    //No
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context); //close dialog
                                                      },
                                                      child: const Text(
                                                        'NO',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.black54,
                                        size: 18,
                                      ))
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                }

                else if (tripsList[index]["status"] == "riderArchive")//these arent visible in riders app
                {
                  {
                    // requested Time
                    DateTime parsedDateTime = DateTime.parse(tripsList[index]["requestedTime"]);

                    // completed Time
                    DateTime completedTime = DateTime.parse(tripsList[index]["completedTime"]);

                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, top: 5.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 3.0,
                                spreadRadius: 0.3,
                                offset: Offset(0.7, 0.7),
                              )
                            ]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // delivery Recipient Name
                              Row(
                                children: [
                                  //icon
                                  const Icon(
                                    Icons.person, size: 18, color: Colors.black45,
                                  ),

                                  const SizedBox(
                                    width: 18,
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

                                  //fareAmount
                                  Text(
                                    "KES ${tripsList[index]["fareAmount"].toString()}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),
                              // Pickup - fareAmount
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/initial.png',
                                    height: 16,
                                    width: 16,
                                  ),
                                  const SizedBox(
                                    width: 18,
                                  ),
                                  // Pickup Address
                                  Expanded(
                                    child: Text(
                                      tripsList[index]["pickUpAddress"]
                                          .toString(),
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  // Fare Amount
                                ],
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              // DropOff - fareAmount
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/final.png',
                                    height: 16,
                                    width: 16,
                                  ),
                                  const SizedBox(
                                    width: 18,
                                  ),
                                  // DropOff Address
                                  Expanded(
                                    child: Text(
                                      tripsList[index]["dropOffAddress"]
                                          .toString(),
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 8,
                              ),

                              //time
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  //requested time
                                  Text(
                                    "              Requested at : ${DateFormat('h:mm a').format(parsedDateTime)}",
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 12,
                                      color: Colors.black54,
                                      letterSpacing: 0,
                                      wordSpacing: 2,
                                    ),
                                  ),

                                  //delivered time
                                  Text(
                                    "Delivered at : ${DateFormat('h:mm a').format(completedTime)}",
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 12,
                                      color: Colors.black54,
                                      letterSpacing: 0,
                                      wordSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              //date
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  //date
                                  Container(
                                    child: Text(
                                      "              Date: ${DateFormat('dd /MM /yyyy ').format(parsedDateTime)}",
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 12,
                                        color: Colors.black54,
                                        letterSpacing: 0,
                                        wordSpacing: 2,
                                      ),
                                    ),
                                  ),

                                  //riders Name
                                  Text(
                                    "By : ${tripsList[index]["driverName"].toString()}",
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 12,
                                      color: Colors.black54,
                                      letterSpacing: 0,
                                      wordSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              //delete button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                              content: const Text(
                                                'Do you wish to delete this record ?',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              actions: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    //yes
                                                    TextButton(
                                                      onPressed: () {
                                                        if (tripsList[index]
                                                                ["status"] ==
                                                            "riderArchive") //means rider has archived
                                                        {
                                                          //update trip status
                                                          FirebaseDatabase.instance.ref().child("tripRequests")
                                                              .child(tripsList[index]["tripID"])
                                                              .child("status")
                                                              .set("systemArchive"); //prevent everyone from seeing it


                                                        } else //means rider has not archived.its still visible to them
                                                        {
                                                          //update trip status
                                                          FirebaseDatabase.instance.ref().child("tripRequests")
                                                              .child(tripsList[index]["tripID"])
                                                              .child("status")
                                                              .set("userArchive");
                                                        }

                                                        Navigator.pop(context); //close dialog
                                                      },
                                                      child: const Text('YES', style: TextStyle(color: Colors.white),),
                                                    ),

                                                    //No
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context); //close dialog
                                                      },
                                                      child: const Text('NO', style: TextStyle(color: Colors.white),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.black54,
                                        size: 18,
                                      ))
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }
              }

              else {
                return Container(); // Placeholder if the condition doesn't meet
              }
            }),
          );
        },
      ),
    );
  }
}
