import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:user_app/appInfo/app_info.dart';
import 'package:user_app/global/global_var.dart';
import 'package:http/http.dart' as http;

class PushNotificationService
{ // Define a variable to hold the dropOffAddress value



  static sendNotificationToSelectedDriver(String deviceToken, BuildContext context,String tripID) async
  {

    //String dropOffDestinationAddress = Provider.of<AppInfo>(context, listen:false).dropOffAddress.toString();


    Map<String, String> headerNotificationMap =
    {
      "Content-Type": "application/json",
      "Authorization": serverKeyFCM,
    };

    Map titleBodyNotificationMap =
    {
      "title": "NEW DELIVERY REQUEST",
      "body": "FROM: $userName $userPhone"
       //"title": "NEW DELIVERY REQUEST from $userName",
      //"body": "Drop Off Location:$dropOffDestinationAddress"
    };

    Map dataMapNotification =
    {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status":"done",
      "tripID": tripID,

    };

    Map bodyNotificationMap =
    {
      "notification": titleBodyNotificationMap,
      "data": dataMapNotification,
      "priority": "high",
      "to": deviceToken,
    };

    await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotificationMap,
      body: jsonEncode(bodyNotificationMap),
    );
  }
}