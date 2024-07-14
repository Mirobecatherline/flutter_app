import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:user_app/pages/Send_package_page.dart';
import 'package:user_app/pages/receipts_page.dart';
import 'package:user_app/pages/track_delivery.dart';
import 'package:user_app/pages/trips_history_page.dart';

import 'Receive_package_page.dart';
import 'notifications_page.dart';


class MenuPage extends StatefulWidget
{
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
{
  String numberOfNotifications = "";

  numberOfNotificationsAvailable() async
  {


    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");

    await tripRequestsRef.once().then((snap)async
    {
      if(snap.snapshot.value !=null ) //check if the tripRequest parent node exists in the database
          {
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map; //get all trips from database and assign to allTripsMap

        int allTripsLength = allTripsMap.length;//get the number of all trips in the database.currently not needed

        ///get the length of trips with status paid
        ///then filter the trips assigned to the current driver and add them to the tripsCompletedByCurrentDriver list
        List<String> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value)
        {
          if(
          value["status"] != null &&
          value["status"] != "paid" && //paid trips belong in history
          value["status"] != "userArchive" &&
          value["status"] != "systemArchive" &&
          value["status"] != "riderArchive" &&
          value["userID"] == FirebaseAuth.instance.currentUser!.uid  ) //checks status inside the tripRequests in firebase if its empty

            {
            tripsCompletedByCurrentDriver.add(key); //add the key of that trip to the list
            }
        });

        //assign the number of trips to variable currentDriverTotalTripsCompleted
       if(mounted)
       {
         setState(() {

           numberOfNotifications = tripsCompletedByCurrentDriver.length.toString();

         });
       }

      }
    });
  }


  @override
  Widget build(BuildContext context) {

    numberOfNotificationsAvailable();


    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,

              child: Container(
                decoration: BoxDecoration(color: Colors.white),

                child: Padding(
                  padding: EdgeInsets.fromLTRB(15.0,8,8,8),
                  child: Row(
                    children: [

                      SizedBox(width: 15,),
                      Row(

                        children: [

                          Image.asset(
                            "assets/images/companyLogo.png",
                            height: 40,
                            width: 40,
                          ),


                          SizedBox(width: 10,),

                          const Text(
                            "IDIL DELIVERIES",style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                              fontSize: 20),
                          ),



                        ],
                      )
                    ],
                  ),
                ),
              ),
        
            ),
            SizedBox(height: 2,),

            Expanded(
              flex: 8,
              ///parent container

              child: Container(
                decoration: BoxDecoration(color: Colors.blueGrey[50]),

                child: GridView.count(crossAxisCount: 3,
                children: [


 /// Send package
                  GestureDetector(
                    onTap:()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> SendPackagePage()));
                    },


                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.black12)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon(Icons.send_rounded,color: Colors.black,size: 30,),
                                    Image.asset(
                                      "assets/images/fastdelivery.png",
                                      height: 40,
                                      width: 40,
                                    ),

                                    const SizedBox(
                                      width: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10,),
                          const Text("Send Package",style: TextStyle(color: Colors.black,letterSpacing: 0),)
                        ],
                      ),

                    ),
                  ),



/// TRACK package
                  GestureDetector(
                    onTap: ()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c)=>const TrackDeliveryPage()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black12)
                            ),
                            child:  Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/trackIcon.png",
                                  height: 30,
                                  width: 30,
                                ),

                              ],
                            ),
                          ),
                          const SizedBox(height: 10,),
                          const Text("Track",style: TextStyle(color: Colors.black,letterSpacing: 0),)
                        ],
                      ),

                    ),
                  ),

/// Rent A Shelf
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black12)
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shelves,color: Colors.black,size: 30,),

                            ],
                          ),
                        ),
                        const SizedBox(height: 10,),
                        const Text("Rent A Shelf",style: TextStyle(color: Colors.black,letterSpacing: 0),)
                      ],
                    ),

                  ),


/// History
                  GestureDetector(
                    onTap: ()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c)=>const TripsHistoryPage()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black12)
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded,color: Colors.black,size: 30,),

                              ],
                            ),
                          ),
                          const SizedBox(height: 10,),
                          const Text("History",style: TextStyle(color: Colors.black,letterSpacing: 0),)
                        ],
                      ),

                    ),
                  ),


/// NOTIFICATIONS
                  GestureDetector(
                    onTap: ()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c)=> const NotificationsPage()));
                    },

                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black12)
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(height: 10,),
                                //number of notifications
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Text(numberOfNotifications,style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 12),),
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.notifications_active,color: Colors.black,size: 30,),


                                  ],
                                ),
                              ],
                            ),
                          ),


                          const SizedBox(height: 10,),
                          const Text("Notifications",style: TextStyle(color: Colors.black,letterSpacing: 0),)
                        ],
                      ),

                    ),
                  ),






/*
  /// Receipts
                  GestureDetector(
                    onTap: ()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c)=>const ReceiptsPage()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black12)
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,color: Colors.black,size: 30,),

                              ],
                            ),
                          ),
                          const SizedBox(height: 10,),
                          const Text("Receipts",style: TextStyle(color: Colors.black,letterSpacing: 0),)
                        ],
                      ),

                    ),
                  ),*/


                ],
                ),





                ),
              ),
          ],
        ),
      )
    );
  }
}

