import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final completedTripRequestsOfCurrentUser = FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,

        title: const Padding(
          padding: EdgeInsets.fromLTRB(15.0,8,8,8),
          child: Text(
            'Notifications',style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              ),

          ),
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
        //stream is basically the query to the record in the database.it updates the changes in realtime
        stream: completedTripRequestsOfCurrentUser.onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {
            return const Center(
              child: Text(
                'Something went wrong...',
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          if (!(snapshotData.hasData)) {
            return  const Center(child: CircularProgressIndicator(color: Colors.black,));
          }


          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips.forEach((key, value) => tripsList.add({"key": key, ...value}));

          /// Sorting tripsList based on publishedDateTime
          tripsList.sort((b, a) {
            DateTime dateTimeA = DateTime.parse(a["requestedTime"]);
            DateTime dateTimeB = DateTime.parse(b["requestedTime"]);
            return dateTimeA.compareTo(dateTimeB);
          });

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length, //total number of trips
            itemBuilder: ((context, index) {
              if (tripsList[index]["status"] != null) {
                if (tripsList[index]["status"] != "paid") {
                  if (tripsList[index]["status"] != "systemArchive") {
                    if (tripsList[index]["status"] != "userArchive") {
                      if (tripsList[index]["status"] != "riderArchive") {
                        if (tripsList[index]["userID"] ==
                            FirebaseAuth.instance.currentUser!.uid) {

                          DateTime parsedDateTime = DateTime.parse(tripsList[index]["requestedTime"]);

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
                                    //pickup - fareAmount
                                    Row(
                                      children: [


                                        Image.asset(
                                          'assets/images/initial.png',
                                          height: 16,
                                          width: 16,
                                        ),


                                        const SizedBox(width: 18,),

                                        //pickup Address
                                        Expanded(
                                          child: Text(
                                            tripsList[index]["pickUpAddress"].toString(),
                                            style: const TextStyle(
                                              overflow: TextOverflow.ellipsis,
                                              fontSize: 15,
                                              color: Colors.black,
                                              letterSpacing: 0,
                                              wordSpacing: 2,
                                            ),
                                          ),
                                        ),


                                        const SizedBox(width: 5,),

                                        //fare Amount
                                        Text(
                                          "KES ${tripsList[index]["userFareAmount"].toString()}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10,),

                                    //dropOff- fareAmount
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/final.png',
                                          height: 16,
                                          width: 16,
                                        ),


                                        const SizedBox(width: 18,),


                                        //pickup Address
                                        Expanded(
                                          child: Text(
                                            tripsList[index]["dropOffAddress"]
                                                .toString(),
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



                                    const SizedBox(height: 8,),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        //time stamp
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            //rider name
                                            Text(
                                              "Rider: ${tripsList[index]["driverName"].toString()}",
                                              style: const TextStyle(
                                                overflow: TextOverflow.ellipsis,
                                                fontSize: 12,
                                                color: Colors.black54,
                                                letterSpacing: 0,
                                                wordSpacing: 2,
                                              ),
                                            ),

                                            //rider phone
                                            Text(
                                              "Phone : ${tripsList[index]["driverPhone"].toString()}",
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

                                        //status
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Delivery status : ',
                                              style: TextStyle(
                                                overflow: TextOverflow.ellipsis,
                                                fontSize: 12,
                                                color: Colors.black54,
                                                letterSpacing: 0,
                                                wordSpacing: 2,
                                              ),
                                            ),
                                            Text(
                                              tripsList[index]["status"]
                                                  .toString(),
                                              style: const TextStyle(
                                                overflow: TextOverflow.ellipsis,
                                                fontSize: 14,
                                                color: Colors.indigo,
                                                fontWeight: FontWeight.normal,
                                                letterSpacing: 0,
                                                wordSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    //delete button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white70),
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
                                                              if (tripsList[
                                                                          index]
                                                                      [
                                                                      "status"] ==
                                                                  "tripAbortedHalfWay") {
                                                                //update trip status
                                                                FirebaseDatabase
                                                                    .instance
                                                                    .ref()
                                                                    .child(
                                                                        "tripRequests")
                                                                    .child(tripsList[
                                                                            index]
                                                                        [
                                                                        "tripID"])
                                                                    .child(
                                                                        "status")
                                                                    .set(
                                                                        "archive");
                                                              }

                                                              Navigator.pop(
                                                                  context); //close dialog
                                                            },
                                                            child: const Text(
                                                              'YES',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white),
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
                                                                  color: Colors
                                                                      .white),
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
                  }
                }
              } else {
                return Container();
              }
            }),
          );
        },
      ),
    );
  }
}
