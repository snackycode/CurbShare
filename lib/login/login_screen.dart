import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:curbshare/login/auth_gate.dart';
import 'package:curbshare/login/otp_screen.dart';
import 'package:curbshare/login/signup_screen.dart';
import 'package:curbshare/main.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  // final TextEditingController _otpController = TextEditingController();
  String _verificationId = "";
  // Default Cambodia (+855)
  String _selectedCode = "+855";

  // Future<void> testBackendConnection() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) throw Exception("No user logged in");

  //   // Get a fresh ID token
  //   final idToken = await user.getIdToken(true);

  //   final dio = Dio();

  //   final url =
  //       'https://us-central1-curbshare-22cs17.cloudfunctions.net/testConnection';

  //   try {
  //     final response = await dio.post(
  //       url,
  //       data: {}, // Send any payload here
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer $idToken',
  //           'Content-Type': 'application/json',
  //         },
  //       ),
  //     );

  //     print('Response status: ${response.statusCode}');
  //     print('Response data: ${response.data}');
  //   } catch (e) {
  //     print('Dio request failed: $e');
  //   }
  // }

  Future<void> verifyPhoneNumber() async {
    String phone =
        _selectedCode + _phoneController.text.replaceAll(RegExp(r'\D'), '');
    print("Sending OTP to: $phone"); // For debugging

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number automatically verified!")),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
        );
      },
      codeSent: (String verId, int? resendToken) {
        _verificationId = verId;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent successfully!")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              countryCode: _selectedCode,
              phoneNumber: _phoneController.text.trim(),
              verificationId: _verificationId,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verId) {
        _verificationId = verId;
      },
    );
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Ensure Firestore user document exists
      final userRef = FirebaseFirestore.instance
          .collection('User')
          .doc(userCredential.user!.uid);
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        await userRef.set({
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'phone': userCredential.user!.phoneNumber ?? '',
          'role': 'driver', // default role
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      } else {
        // await testBackendConnection();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Wrapper()),
        );
      }

      final userProvider = Provider.of<UserDoc>(context, listen: false);
      await userProvider.fetchUser();

      // Navigate to profile (or wrapper will automatically handle it)
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => const Wrapper()),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 130, bottom: 80),
      alignment: Alignment.center,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _buildLoginText(),
              const SizedBox(height: 3),
              Text(
                "We will text you the verification code",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                ),
              ),
              SizedBox(height: 45),
              _buildPhoneField("Phone number", _phoneController),
              SizedBox(height: 45),
              TextButton(
                onPressed: verifyPhoneNumber,
                style: TextButton.styleFrom(
                  minimumSize: const Size(300, 45),
                  backgroundColor: const Color.fromRGBO(59, 120, 195, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Login with phone number',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (!isKeyboardOpen) // Only show when keyboard is closed
            Column(
              children: [
                Text(
                  'or',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w300,
                    fontSize: 13,
                    color: const Color.fromARGB(255, 165, 165, 165),
                  ),
                ),
                SizedBox(height: 20),
                _buildGoogleButton(),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "By signing up, i agree to ",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                          color: Color.fromRGBO(0, 0, 0, 1),
                        ),
                      ),
                      TextSpan(
                        text: "terms and conditions",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                          color: Color(0xFF004991),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLoginText() {
    return Container(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Login ",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 26,
                color: Color(0xFF004991),
              ),
            ),
            TextSpan(
              text: "with phone number",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color.fromRGBO(0, 0, 0, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField(String text, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 64, // slightly smaller
        child: TextField(
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w300,
            fontSize: 16,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                width: 0.3,
                color: Color.fromRGBO(79, 79, 79, 1),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                width: 1.2,
                color: Color.fromRGBO(79, 79, 79, 1),
              ),
            ),
            contentPadding: const EdgeInsets.only(top: 18, left: 0),
            hintText: text,
            hintStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w300,
              fontSize: 12,
              color: Color.fromRGBO(166, 166, 166, 1),
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            prefixIcon: CountryCodePicker(
              onChanged: (country) {
                setState(() {
                  _selectedCode = country.dialCode!;
                });
              },
              initialSelection: 'KH', // Cambodia
              favorite: ['+855', 'KH'], // show at top
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
            ),
          ),
          keyboardType: TextInputType.phone,
          controller: controller,
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: SizedBox(
        width: 300, // match button width
        child: TextButton(
          onPressed: () => signInWithGoogle(context), // FIXED: use closure
          style: TextButton.styleFrom(
            minimumSize: const Size(300, 45), // match login button
            backgroundColor: const Color.fromARGB(255, 233, 233, 233),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'icons/google.png',
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Sign in with Google',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
