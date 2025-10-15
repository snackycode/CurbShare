import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:curbshare/login/auth_gate.dart';
import 'package:curbshare/main.dart';
import 'package:curbshare/model/user_model.dart';
import 'package:curbshare/payment/stripeonboarding_screen.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:curbshare/user/driver/profile_screen.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialCountryCode;
  final String? initialPhone;

  const SignupScreen({
    super.key,
    this.initialEmail,
    this.initialPhone,
    this.initialCountryCode,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCode = "+855";
  int initialLabelIndex = 0;
  final _formKey = GlobalKey<FormState>();

  // Future<void> createStripeAccount() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     throw Exception('User not logged in');
  //   }

  //   // Get fresh ID token
  //   final idToken = await user.getIdToken(true);

  //   final dio = Dio();
  //   final url =
  //       'https://us-central1-curbshare-22cs17.cloudfunctions.net/createStripeAccount';

  //   try {
  //     final response = await dio.post(
  //       url,
  //       data: {}, // empty payload, or add any additional data if needed
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer $idToken',
  //           'Content-Type': 'application/json',
  //         },
  //         validateStatus: (status) => true, // allows inspecting any status
  //       ),
  //     );

  //     if (response.statusCode == 200) {
  //       print('Stripe Account ID: ${response.data['accountId']}');
  //     } else {
  //       print('Error: ${response.statusCode}, ${response.data}');
  //     }
  //   } catch (e) {
  //     print('Dio request failed: $e');
  //   }
  // }

  // Future<String?> createStripeAccountLink() async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     final idToken = await user!.getIdToken(true);
  //     final dio = Dio();
  //     final response = await dio.post(
  //       'https://us-central1-curbshare-22cs17.cloudfunctions.net/createAccountLink',
  //       options: Options(headers: {'Authorization': 'Bearer $idToken'}),
  //     );

  //     final url = response.data['url'] as String?;
  //     print('✅ Onboarding URL: $url');
  //     return url;
  //   } catch (e) {
  //     print('❌ Error creating onboarding link: $e');
  //     return null;
  //   }
  // }

  Future<void> topUpTestAccount(String role) async {
    final dio = Dio();
    final url =
        'https://us-central1-curbshare-22cs17.cloudfunctions.net/topUpTestAccounts';

    try {
      final response = await dio.post(
        url,
        data: {'role': role},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final clientSecret = response.data['clientSecret'];

      // Confirm payment using flutter_stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'My Marketplace',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // ✅ Update Firestore balance for the user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final amount = role == 'driver' ? 1000.0 : 100.0; // dollars
        await FirebaseFirestore.instance.collection('User').doc(user.uid).set({
          'balance': FieldValue.increment(amount),
          'role': role, // ensure Firestore only stores `role`
        }, SetOptions(merge: true));
        print('✅ Top-up successful for $role');
      }
    } catch (e) {
      print('Error topping up account: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialCountryCode ?? '+855';

    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
    _prefillUserData();
  }

  void _prefillUserData() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (user.email != null && user.email!.isNotEmpty) {
        // Signed in with Google
        _emailController.text = user.email!;
      }
      //  else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      //   // Signed in with Phone
      //   _phoneController.text = user.phoneNumber!;
      // }
      if (_phoneController.text.isEmpty && user.phoneNumber != null) {
        final phone = user.phoneNumber!; // e.g., +85512345678
        if (phone.startsWith('+')) {
          final countryCodeMatch = RegExp(r'^\+\d+').firstMatch(phone);
          if (countryCodeMatch != null) {
            _selectedCode = countryCodeMatch.group(0)!; // +855
            _phoneController.text =
                phone.replaceFirst(_selectedCode, ''); // 12345678
          } else {
            _phoneController.text = phone;
          }
        } else {
          _phoneController.text = phone;
        }
      }
    }
  }

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
      centerTitle: true,
      title: const Text(
        "Account",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: Color(0xFF004991),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    _buildInfoField("Your Name", _nameController),
                    SizedBox(height: 10),
                    _buildInfoField("Email", _emailController),
                    SizedBox(height: 10),
                    _buildPhoneField("Phone", _phoneController, _selectedCode),
                    SizedBox(height: 15),
                    _buildRoleSwitch(),
                  ],
                ),
              ),
            ),
            if (!isKeyboardOpen) _buildConfirmButton(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String text, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w300,
          fontSize: 12,
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
          contentPadding: const EdgeInsets.only(top: 12, left: 14, bottom: 12),
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
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$text cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField(String text, TextEditingController controller,
      String initialCountryCode) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: SizedBox(
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w300,
            fontSize: 14,
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
            contentPadding:
                const EdgeInsets.only(top: 12, left: 14, bottom: 12),
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
              initialSelection: initialCountryCode,
              favorite: ['+855', 'KH'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$text cannot be empty';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildRoleSwitch() {
    return Align(
      alignment: Alignment.centerRight,
      child: ToggleSwitch(
        customTextStyles: const [
          TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 10, // smaller font
          )
        ],
        minWidth: 70.0, // much smaller width
        minHeight: 26, // much smaller height
        cornerRadius: 12.0,
        activeBgColor: const [Color.fromRGBO(59, 120, 195, 1)],
        activeFgColor: Colors.white,
        inactiveBgColor: Colors.white,
        inactiveFgColor: const Color.fromRGBO(59, 120, 195, 1),
        initialLabelIndex: initialLabelIndex,
        totalSwitches: 2,
        labels: const ['Driver', 'Host'],
        radiusStyle: true,
        onToggle: (index) {
          setState(() {
            initialLabelIndex = index!;
          });
          print('switched to: $index');
        },
      ),
    );
  }


  Widget _buildConfirmButton({VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed ??
          () async {
            if (!_formKey.currentState!.validate()) return;

            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error: No user logged in")),
              );
              return;
            }

            try {
              // 🔑 Ensure fresh Firebase ID token
              await user.getIdToken(true);
              await Future.delayed(const Duration(milliseconds: 50));

              final role = initialLabelIndex == 0 ? 'driver' : 'host';
              // Get FCM token
              final token = await FirebaseMessaging.instance.getToken();
              // Use pre-existing Stripe account IDs
              final stripeAccountId = role == 'host'
                  ? 'acct_1SDQ0w3iz3feVfLe'
                  : 'acct_1SDQFN3iz3yx2gl6';

              // Mark user as onboarded in Firestore
              await FirebaseFirestore.instance
                  .collection('User')
                  .doc(user.uid)
                  .update({
                'role': role,
                'stripeOnboarded': true,
                'stripeAccountId': stripeAccountId,
                'fcmToken': token,
              });
              // await topUpTestAccount(role);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Account setup complete!")),
              );
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Wrapper()),
                );
              }
            } catch (e, st) {
              print("❌ Error in confirm button: $e\n$st");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error setting up account: $e")),
              );
            }
          },
      style: TextButton.styleFrom(
        minimumSize: const Size(223, 45),
        backgroundColor: const Color.fromRGBO(59, 120, 195, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: const Text(
        'Confirm',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
