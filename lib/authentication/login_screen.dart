import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:user_app/authentication/signup_screen.dart';
import 'package:user_app/global/global_var.dart';
import 'package:user_app/pages/dashboard.dart';

import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}



class _LoginScreenState extends State<LoginScreen>
{
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  bool obscureText = true;

  checkIfNetworkIsAvailable()
  {
    cMethods.checkConnectivity(context);

    signInFormValidation();

  }
  signInFormValidation()
  {
    if(!emailTextEditingController.text.contains("@") )
    {
      cMethods.displaySnackBar("Please write a valid email", context);
    }
    else if(passwordTextEditingController.text.trim().length <5  )
    {
      cMethods.displaySnackBar("Your password should be at least 6 or more characters", context);
    }
    else
    {
      signInUser();//register the user

    }
  }
  signInUser()async
  {
    showDialog(

      context: context,
      barrierDismissible: false,
      builder: (BuildContext context)  => LoadingDialog(messageText: "Logging in..."),
    );

    final User? userFirebase = (
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((errorMsg)
        {
          Navigator.pop(context);
          cMethods.displaySnackBar(errorMsg.toString(), context);

        })

    ).user;

    //closing dialog box
    if(!context.mounted) return;
    Navigator.pop(context);

    //confirming only user logs in the app and not the driver
    if(userFirebase !=null)
    {
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);
      await usersRef.once().then((snap)
      {
        if(snap.snapshot.value !=null)//means if users record is in the "users parent" then the null wont be available
          {
          //checking if user is blocked by admin
            if((snap.snapshot.value as Map)["blockStatus"] == "no")//user not blocked
              {
                userName = (snap.snapshot.value as Map)["name"]; // get the value of key name
                userPhone = (snap.snapshot.value as Map)["phone"]; // get the value of key name

                //send user to home page
                Navigator.push(context, MaterialPageRoute(builder: (c)=> const Dashboard()));

              }
            else // if user is blocked
            {
              FirebaseAuth.instance.signOut(); // sign out the user
              cMethods.displaySnackBar("Account Suspended.Kindly Contact company: 0719 538 833", context);// display message

            }

          }
        else// if user record doesn't exist
        {
          FirebaseAuth.instance.signOut(); // sign out the user
          cMethods.displaySnackBar("Your record does not exist as a USER.", context);// display message

        }

      }

      );

    }






  }


  @override


  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 100,),// space above logo image

                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(1), // Shadow color and opacity
                        spreadRadius:5, // Spread of the shadow
                        blurRadius: 40, // Blur amount
                        offset: const Offset(0, 20), // Offset of the shadow (x, y)
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/images/companyLogo.png",
                    height: 200,
                    width: 200,
                  ),
                ), //logo image

                const SizedBox(height: 50,),
            
                const Text(
                  "Login as a User",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
            
                //Text fields + button
                Padding(
                  padding:const EdgeInsets.all(15),
                  child: Column(
                    children: [
            
                      TextField(

                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(

                          enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.black54)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue),),
                          fillColor: Colors.white,
                          filled: true,


                          hintText: "User Email ",
                          hintStyle:  TextStyle(color: Colors.black45),
            
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
            
                        ),
                        ),
            
                      const SizedBox(height: 10,),

                      TextField(
                        controller: passwordTextEditingController,
                        keyboardType: TextInputType.text,
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                          fillColor: Colors.white,
                          filled: true,
                          hintText: "User Password",
                          hintStyle: const TextStyle(color: Colors.black45),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),



                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                            child: Icon(
                              obscureText ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),


                      const SizedBox(height: 30,),
            
                      ElevatedButton(
                        onPressed: ()
                        {
                          checkIfNetworkIsAvailable();// check the internet 1st

            
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 20,
                            shadowColor: Colors.black,

                            padding: const EdgeInsets.symmetric( horizontal: 100,vertical: 10,)



            
                        ),
                        child: const Text("Login",style: TextStyle(color: Colors.white)),

            
            
            
                      ),

                    ],
                  ),
                ),
            
                //Text button
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen()));
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an Account? ",
                      style: const TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: "Register here",
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ],
                    ),
                  ),
                ),


              ],
            ),
          ),

        ),
      ),
    );;
  }
}
