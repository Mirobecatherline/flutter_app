import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:user_app/authentication/login_screen.dart';
import 'package:user_app/methods/common_methods.dart';
import 'package:user_app/pages/dashboard.dart';
import 'package:user_app/pages/home_page.dart';
import 'package:user_app/widgets/loading_dialog.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}



class _SignUpScreenState extends State<SignUpScreen>
{
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  CommonMethods cMethods = CommonMethods();

  checkIfNetworkIsAvailable()
  {
    cMethods.checkConnectivity(context);

    signUpFormValidation();

  }
  signUpFormValidation()
  {
    if(userNameTextEditingController.text.trim().length <3 )
    {
      cMethods.displaySnackBar("Your name must be at least 4 or more characters", context);
    }
    else if(userPhoneTextEditingController.text.trim().length <7 )
    {
      cMethods.displaySnackBar("Your phone number must be at least 8 or more characters", context);
    }
    else if(!emailTextEditingController.text.contains("@") )
    {
      cMethods.displaySnackBar("Please write a valid email", context);
    }
    else if(passwordTextEditingController.text.trim().length <5  )
    {
      cMethods.displaySnackBar("Your password should be at least 6 or more characters", context);
    }
    else
    {
      registerNewUser();//register the user

    }
  }

  registerNewUser() async
  {
    showDialog(

      context: context,
      barrierDismissible: false,
      builder: (BuildContext context)  => LoadingDialog(messageText: "Registering your Account..."),
    );

    final User? userFirebase = (
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((errorMsg)
        {
          Navigator.pop(context);
          cMethods.displaySnackBar(errorMsg.toString(), context);

        })

    ).user;

    if(!context.mounted) return;
    Navigator.pop(context);

    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase!.uid);
    Map userDataMap =
    {
      "name": userNameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": userPhoneTextEditingController.text.trim(),
      "id": userFirebase.uid,
      "blockStatus": "no",
      "cancelledTripsPenalties": "0",
      "userStatus": "offline",

    };

    usersRef.set(userDataMap);
    Navigator.push(context, MaterialPageRoute(builder: (c)=> const Dashboard())); // sends user to home page



  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50,),// space above logo image
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.8), // Shadow color and opacity
                        spreadRadius:5, // Spread of the shadow
                        blurRadius: 40, // Blur amount
                        offset: const Offset(0, 15), // Offset of the shadow (x, y)
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/images/companyLogo.png",
                    height: 100,
                    width: 100,
                  ),
                ),//company logo
                const SizedBox(height: 20,),

               const Text(
                  "Create a User\'s Account",
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
            
                        controller: userNameTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
            
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.white)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue)),
                          fillColor: Colors.white,
                          filled: true,
            
                          hintText: "User Name ",
                          hintStyle:  TextStyle(color: Colors.black45),
            
            
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                        ),
            
                      const SizedBox(height: 10,),
            
                      TextField(
            
                        controller: userPhoneTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
            
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.white)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue)),
                          fillColor: Colors.white,
                          filled: true,
            
                          hintText: "User Phone ",
                          hintStyle:  TextStyle(color: Colors.black45),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
            
            
                      ),
            
                      const SizedBox(height: 10,),
            
                      TextField(
            
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
            
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.white)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue)),
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
                        obscureText: true,
                        decoration: const InputDecoration(
            
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.white)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide( color: Colors.blue)),
                          fillColor: Colors.white,
                          filled: true,
            
                          hintText: "User Password ",
                          hintStyle:  TextStyle(color: Colors.black45),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
            
            
                      ),
            
                      const SizedBox(height: 20,),



                      ElevatedButton(
                        onPressed: ()
                        {
                          checkIfNetworkIsAvailable();

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 20,
                          shadowColor: Colors.black,
                           padding: const EdgeInsets.symmetric( horizontal: 100,vertical: 10,
                           )

                        ),
                        child: const Text("Sign Up",style: TextStyle(color: Colors.black54)),

                      ),

                    ],
                  ),
                ),
            
            
            
                
                //Text button
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an Account? ",
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: "Login here",
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
    );
  }
}
