import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:curbshare/model/user_model.dart';
import 'package:curbshare/provider/userDoc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditScreen extends StatefulWidget {
  final UserModel user;
  const EditScreen({super.key, required this.user});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String _selectedCode = "+855";

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.name ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');

    final fullPhone = widget.user.phone ?? '+85512345678';

// default
    _selectedCode = '+855';
    String phoneWithoutCode = fullPhone;

// extract country code (+ followed by 1–3 digits)
    final match = RegExp(r'^\+\d{1,3}').firstMatch(fullPhone);
    if (match != null) {
      _selectedCode = match.group(0)!; // now +855
      phoneWithoutCode = fullPhone.substring(_selectedCode.length); // 12345678
    }

// initialize controller once
    _phoneController = TextEditingController()..text = phoneWithoutCode;

    print("🟢 Loaded full phone: $fullPhone");
    print("🟢 Selected code: $_selectedCode");
    print("🟢 Controller text: ${_phoneController.text}");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final updatedPhone = "$_selectedCode${_phoneController.text.trim()}";
    try {
      await FirebaseFirestore.instance
          .collection("User")
          .doc(user!.uid)
          .update({
        "name": _nameController.text.trim(),
        "phone": updatedPhone,
        "email": _emailController.text.trim(),
        "updateAt": FieldValue.serverTimestamp(),
      });
      final userProvider = Provider.of<UserDoc>(context, listen: false);
      await userProvider.fetchUser(); // refresh data from Firestore

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      Navigator.pop(context); // Go back after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
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
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFF004991),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Edit my profile",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: Color(0xFF004991),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text("Personal information"),
            SizedBox(height: 10),
            _buildInfoField("Your Name", _nameController),
            SizedBox(height: 10),
            _buildInfoField("Email", _emailController),
            SizedBox(height: 10),
            _buildPhoneField("Phone", _phoneController, _selectedCode),
            SizedBox(height: 15),
            const SizedBox(height: 20),
            _buildSaveProfileButton(),
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

  Widget _buildPhoneField(
    String hint,
    TextEditingController controller,
    String initialCountryCode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
            borderSide: BorderSide(width: 0.3, color: Color(0xFF4F4F4F)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(width: 1.2, color: Color(0xFF4F4F4F)),
          ),
          contentPadding: const EdgeInsets.only(top: 12, left: 14, bottom: 12),
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w300,
            fontSize: 12,
            color: Color(0xFFA6A6A6),
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          prefixIcon: SizedBox(
            width: 110, // make enough room for country picker
            child: CountryCodePicker(
              onChanged: (country) {
                setState(() {
                  _selectedCode = country.dialCode!;
                  // optionally prepend to controller if you want live update
                  // controller.text = controller.text;
                });
              },
              initialSelection: _selectedCode, // use the actual selected code
              favorite: ['+855', 'KH'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$hint cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveProfileButton({VoidCallback? onPressed}) {
    return Center(
      child: TextButton(
        onPressed: onPressed ?? _saveProfile, // default to _saveProfile
        style: TextButton.styleFrom(
          minimumSize: const Size(223, 45),
          backgroundColor: const Color.fromRGBO(59, 120, 195, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: const Text(
          'Save',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
