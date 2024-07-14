
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

import '../methods/common_methods.dart';

class PaymentDialog extends StatefulWidget
{

 //this dialog wil receive the fare amount as a parameter
  String fareAmount;


  PaymentDialog({super.key , required this.fareAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}


class _PaymentDialogState extends State<PaymentDialog>

{

  CommonMethods cMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white24,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 21,),

            const Text("TOTAL DELIVERY COST",
            style: TextStyle(
              color: Colors.black54,

            ),),

            const SizedBox(height: 21,),

            const Divider(
              height: 1.5,
              color: Colors.black54,
              thickness: 1.0,
            ),

            const SizedBox(height: 16,),

            Text("KES ${widget.fareAmount}",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16,),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    "Pay this amount to the Rider via",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54
                        ),

                  ),
                  SizedBox(height: 12,),
                  Text(
                    "TILL : 71945000 \n IDIL DELIVERIES",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                      fontSize: 16
                    ),

                  ),
                ],
              ),
            ),

            const SizedBox(height: 31,),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, 'paid');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text(
                "LIPA NA M-PESA",
                style: TextStyle(
                  color: Colors.greenAccent,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 41,),

          ],
        ),
      ),
    );
  }
}
