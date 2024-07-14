import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:user_app/pages/receipts_page.dart';
import 'package:user_app/pages/trips_history_page.dart';

import '../authentication/login_screen.dart';
import '../global/global_var.dart';
import 'about_page.dart';


class AccountPage extends StatefulWidget
{
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}


class _AccountPageState extends State<AccountPage>
{

  String numberOfActiveTrips = "0";

  getNumberOfActiveTrips() async
  {


    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");

    await tripRequestsRef.once().then((snap)async
    {
      if(snap.snapshot.value !=null ) //check if the tripRequest parent node exists in the database
          {
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map; //get all trips from database and assign to allTripsMap

        int allTripsLength = allTripsMap.length; //get the number of all trips in the database.currently not needed

        ///get the length of trips with status !paid
        ///then filter the trips assigned to the current driver and add them to the tripsCompletedByCurrentDriver list
        List<String> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value)
        {
          if(value["status"] !=null) //checks status inside the tripRequests in firebase if its empty
              {
            if(value["status"] != "paid"
                && value["status"] != "userArchive"
                && value["status"] != "systemArchive"
                && value["status"] != "riderArchive"
            )

                {
              if(value["userID"] == FirebaseAuth.instance.currentUser!.uid)
                  {
                tripsCompletedByCurrentDriver.add(key); //add the key of that trip to the list
              }
            }
          }
        });



        //assign the number of trips to variable currentDriverTotalTripsCompleted
        setState(() {
          numberOfActiveTrips = tripsCompletedByCurrentDriver.length.toString();

        });

      }
    });
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getNumberOfActiveTrips();
  }

  @override
  Widget build(BuildContext context) {

    getNumberOfActiveTrips();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const SizedBox(
            height: 80,
          ),

          //header
          Column(
            children: [
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    border: Border.all(
                      width: 1,
                      color: Colors.grey,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.black,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                userName, // Replace "userName" with the actual variable
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                userPhone,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 50,
          ),

          const SizedBox(
            height: 5,
          ),

          Divider(
            thickness: 2,
            color: Colors.grey[300],
          ),

          //Active trips
          ListTile(
            leading: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.online_prediction,
                color: Colors.green,
              ),
            ),
            title:  Row(
              children: [
                const Text(
                  "Active Deliveries",
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(width: 12,),

                Text(
                  numberOfActiveTrips,
                  style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          //Receipts
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const ReceiptsPage()));
            },
            child: ListTile(
              leading: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.black,
                ),
              ),
              title: const Text(
                "Receipts",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),

          //rent a shelf
          ListTile(
            leading: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.shelves,
                color: Colors.black,
              ),
            ),
            title: const Text(
              "Rent a Shelf",
              style: TextStyle(color: Colors.black54),
            ),
          ),


          //about page
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const AboutPage()));
            },
            child: ListTile(
              leading: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.info,
                  color: Colors.black,
                ),
              ),
              title: const Text(
                "Idil Deliveries",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),



          Divider(
            thickness: 2,
            color: Colors.grey[300],
          ),

          GestureDetector(
            onTap: () {
              //goOfflineNow();//stop sharing users live location updates

              FirebaseAuth.instance.signOut(); // sign out the user

              //send user to login page
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const LoginScreen()));
              Navigator.popUntil(context, (route) => true);
            },
            child: ListTile(
              leading: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.logout,
                  color: Colors.black,
                ),
              ),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

