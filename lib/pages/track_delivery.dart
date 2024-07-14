import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:user_app/pages/tracking_page.dart';
import 'package:user_app/pages/tracking_page.dart';


class TrackDeliveryPage extends StatefulWidget {
  const TrackDeliveryPage({Key? key}) : super(key: key);

  @override
  State<TrackDeliveryPage> createState() => _TrackDeliveryPageState();
}

class _TrackDeliveryPageState extends State<TrackDeliveryPage> {
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
            'Track Package',style: TextStyle(
              color: Colors.black,
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
              if (tripsList[index]["status"] != null
                  &&
                  tripsList[index]["status"] != "new" //start of request

                  &&
                  tripsList[index]["status"] != "paid"

                  &&
                  tripsList[index]["status"] != "userArchive"

                  &&
                  tripsList[index]["status"] != "systemArchive"
                  &&
                  tripsList[index]["status"] != "riderArchive"

                  &&
                  tripsList[index]["userID"] == FirebaseAuth.instance.currentUser!.uid)



              {

                DateTime parsedDateTime = DateTime.parse(tripsList[index]["requestedTime"]);

                ///send tripsID to firebase
                sendTripIdToFirebase() {
                  if ((tripsList[index]["tripID"].toString().isNotEmpty))
                  {
                    String userID = FirebaseAuth.instance.currentUser!.uid;
                    String tripId = tripsList[index]["tripID"].toString(); //node name

                    //create a Map that contains the user Id and the Map id
                    Map<String, dynamic> trackedTripMap = {
                      "userID": userID,
                      "tripId": tripId,

                    };

                    //uploading the map
                    DatabaseReference databaseReference = FirebaseDatabase.instance
                        .ref()
                        .child("trackedTripIds") // firebase node name
                        .child(userID);

                    //use set so that you can only view what has been uploaded.this prevents multiple Ids from being uploaded
                    databaseReference.set(trackedTripMap);
                  }
                }


                return Padding(
                  padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 5.0),
                  child: GestureDetector(
                    onTap: ()
                    {
                      if((tripsList[index]["tripID"].toString().isNotEmpty))
                      {
                        //upload track ID to firebase
                        sendTripIdToFirebase();

                        //navigate to the tracking page to view. Retrieve the tracking id from firebase
                        Navigator.push(context,MaterialPageRoute(builder: (c) => const TrackingPage()));
                      }

                    },
                    child: Container(

                      decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 3.0, spreadRadius: 0.3, offset: Offset(0.7, 0.7),)]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            //view
                            GestureDetector(
                              onTap:()
                              {
                                if((tripsList[index]["tripID"].toString().isNotEmpty))
                                {
                                  //upload track ID to firebase
                                  sendTripIdToFirebase();

                                  //navigate to the tracking page to view. Retrieve the tracking id from firebase
                                  Navigator.push(context,MaterialPageRoute(builder: (c) => const TrackingPage()));
                                }

                              },
                              child: Center(
                                child: Container(
                                  width:80,
                                  decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.circular(5),),
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 5,right: 5),
                                    child: Center(
                                      child: Text(
                                        "View",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10,),


                            //recipient name
                            Row(
                              children: [
                                const Icon(Icons.person,color: Colors.black54,size: 18,),
                                const SizedBox(width: 8,),

                                const Text("Recipient : ",style: TextStyle(color: Colors.black54),),

                                //recipient name
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
                                const SizedBox(width: 5,),


                              ],
                            ),
                            const SizedBox(height: 8,),

                            //dropOff address
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/final.png',
                                  height: 16,
                                  width: 16,
                                ),
                                const SizedBox(width: 8,),

                                const Text("Drop-off location : ",style: TextStyle(color: Colors.black54),),

                                //pickup Address
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

                            //requested at
                            Text("          Requested at : ${DateFormat('h:mm a').format(parsedDateTime)}                   Date: ${DateFormat('dd /MM /yyyy ').format(parsedDateTime)} ",
                              style: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 12,
                                color: Colors.black,
                                letterSpacing: 0,
                                wordSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 2,),


                          ],
                        ),
                      ),
                    ),
                  ),
                );
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
