import 'package:flutter/material.dart';
import 'package:user_app/pages/home_page.dart';
import 'package:user_app/pages/menu_page.dart';
import 'package:user_app/pages/account_page.dart';


class Dashboard extends StatefulWidget
{
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}



class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin
{

  TabController? controller;
  int indexSelected = 0;

  onBarItemClicked( int i)
  {
    setState(() {

      indexSelected = i;
      controller!.index = indexSelected;
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)

  {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: const [


          HomePage(
            recipientName: '',
            recipientPhone: '',
            instructions: '',
            pickUpAddress: '',
            dropOffAddress: '',
            pickUpAddressLong: '',
            pickUpAddressLat: '',
            pickUpAddressPlaceId: '',
            dropOffAddressLong: '',
            dropOffAddressLat: '',
            dropOffAddressPlaceId: '',
            deliveryPaidBy: '',

          ),


          //MenuPage() ,
          //NotificationsPage(),
          AccountPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar (
        items: const
        [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home"
          ),


          /*  BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Activity"

          ),


          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_rounded),
              label: "Notifications"
          ),
          */

          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile"
          ),

        ],
        currentIndex: indexSelected,
        backgroundColor: Colors.white.withOpacity(1),
        unselectedItemColor: Colors.black54,
        selectedItemColor: Colors.black,
        showSelectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 15,fontWeight: FontWeight.normal,letterSpacing: 0),
        unselectedFontSize: 13,

        selectedIconTheme: const IconThemeData(size: 25),
        unselectedIconTheme: const IconThemeData(size: 15),
        type: BottomNavigationBarType.fixed,
        onTap: onBarItemClicked,

      ),
    );
  }
}
