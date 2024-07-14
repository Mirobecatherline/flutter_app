import 'dart:ui';

import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}



class _AboutPageState extends State<AboutPage>
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Developed by',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: ()
          {
            Navigator.pop(context);

          },
          icon: const Icon(Icons.arrow_back_rounded,
          color: Colors.black54,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const SizedBox(height: 100,),
            
            Image.asset(
              'assets/images/splashScreenLogo.png',
              height: 300,
              width: 300,
            ),

            const SizedBox(height: 20,),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copyright_rounded,color: Colors.black54,),

                Text(
                    '2024 Idil Technologies ltd',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,


                  ),
                ),
              ],
            ),


            const SizedBox(height: 20,),

            const Text(
              'In case of any misuse or any report ,please contact us \nvia email : idildeliveries@gmail.com ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                letterSpacing: 0,
                wordSpacing: 1,


              ),
            ),

          ],
        ),
      ),
    );
  }
}
