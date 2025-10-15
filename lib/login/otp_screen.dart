import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/login/auth_gate.dart';
import 'package:curbshare/login/signup_screen.dart';
import 'package:curbshare/login/success.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpScreen extends StatefulWidget {
  final String countryCode;
  final String phoneNumber;
  final String verificationId;
  const OtpScreen(
      {super.key,
      required this.phoneNumber,
      required this.verificationId,
      required this.countryCode});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final String _verificationId = "";

  // Future<void> signInWithOTP() async {
  //   try {
  //     PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //       verificationId: _verificationId,
  //       smsCode: _otpController.text.trim(),
  //     );

  //     // Sign in the user (or register if new)
  //     UserCredential userCredential =
  //         await FirebaseAuth.instance.signInWithCredential(credential);
  //     User? user = userCredential.user;

  //     if (user != null) {
  //       print("✅ User registered/logged in: ${user.phoneNumber}");
  //     }
  //   } catch (e) {
  //     print("Error signing in with OTP: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context); //navigate back
        },
        icon: Image.asset(
          'icons/back-btn.png',
          scale: 1,
        ),
      ),
      titleSpacing: 0,
      //text enter
      centerTitle: true,
      title: const Text("Enter code",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF004991),
          )),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Align left
              children: [
                SizedBox(height: 40), // Add top spacing if needed
                Text(
                  "We sent you the code with SMS",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                  ),
                ),
                SizedBox(height: 10),
                // Text(
                //   widget.phoneNumber,
                //   style: TextStyle(
                //     fontFamily: 'Inter',
                //     fontWeight: FontWeight.w600,
                //     fontSize: 18,
                //     color: Color.fromRGBO(0, 0, 0, 1),
                //   ),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.countryCode,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color.fromRGBO(0, 0, 0, 1),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color.fromRGBO(0, 0, 0, 1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    keyboardType: TextInputType.number,
                    autoDismissKeyboard: true,
                    onChanged: (value) {
                      print(value);
                    },
                    onCompleted: (value) async {
                      try {
                        PhoneAuthCredential credential =
                            PhoneAuthProvider.credential(
                          verificationId: widget.verificationId,
                          smsCode: value.trim(),
                        );
                        UserCredential userCredential = await FirebaseAuth
                            .instance
                            .signInWithCredential(credential);
                        User? user = userCredential.user;
                        if (user != null) {
                          final userRef = FirebaseFirestore.instance
                              .collection("User")
                              .doc(user.uid);
                          final userDoc = await userRef.get();
                          if (!userDoc.exists) {
                            String fullPhone =
                                '${widget.countryCode}${widget.phoneNumber}';

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupScreen(
                                  initialCountryCode: widget.countryCode,
                                  initialPhone: widget.phoneNumber,
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Wrapper()),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Incorrect code, please try again."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Incorrect code, please try again."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          _retryText(), // This will always be at the bottom
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _retryText() {
    return RichText(
      text: TextSpan(
        text: "Didn't receive the code? ",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w300,
          fontSize: 13,
          color: Color.fromRGBO(0, 0, 0, 0.5),
        ),
        children: [
          TextSpan(
            text: "Resend",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w300,
              fontSize: 13,
              color: Color(0xFF004991),
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Call your resend OTP logic here
                _resendOTP();
              },
          ),
        ],
      ),
    );
  }

  void _resendOTP() async {
    // You need to call verifyPhoneNumber again with the same phone number
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber:
          '${widget.countryCode}${widget.phoneNumber}', // format as needed
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resend failed: ${e.message}")),
        );
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          // Update verificationId for new OTP
          // If you want to show a message:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP resent successfully!")),
          );
        });
      },
      codeAutoRetrievalTimeout: (String verId) {},
    );
  }
}
