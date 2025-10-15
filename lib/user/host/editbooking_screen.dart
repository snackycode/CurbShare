import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/helper/imageCompressor.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:curbshare/user/host/mapselect_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class EditBookingScreen extends StatefulWidget {
  final ParklotModel lot;
  const EditBookingScreen({super.key, required this.lot});

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _capacityController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _monthlyRateController = TextEditingController();
  final TextEditingController _whereController = TextEditingController();

  DateTime? _availableFrom;
  DateTime? _closeBefore;
  bool _echarge = false;

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imgBase64;
  Map<String, dynamic>? _selectedLocation;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ needs READ_MEDIA_IMAGES
      if (await Permission.photos.request().isGranted) {
        return true;
      }
      // Fallback for older Android versions
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    }
    return false;
  }

  Future<void> uploadImageToFirebase(
      String base64Image, String fileName) async {
    try {
      await FirebaseFirestore.instance.collection('images').doc(fileName).set({
        'image': base64Image,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      print("Image uploaded to Firebase!");
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _pickImage() async {
    bool permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      print("Permission denied. Cannot pick image.");
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return; // user cancelled

      File imageFile = File(pickedFile.path);

      // Compress image
      Uint8List? compressedBytes =
          await ImageCompressor().compressImage(imageFile);

      if (compressedBytes == null) {
        print("Image compression failed.");
        return;
      }

      // Convert to Base64
      String base64Image = base64Encode(compressedBytes);

      // Optionally save compressed file locally
      File? compressedFile = await ImageCompressor()
          .readCompressedFile(compressedBytes, pickedFile.name);

      setState(() {
        _imageFile = compressedFile;
        _imgBase64 = base64Image; // immediately display
      });

      print("Image picked, compressed, and converted to Base64!");

      // TODO: upload base64Image to Firebase if needed
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _deleteLot(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Parking Lot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to delete this parking lot?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('ParkingLot')
            .doc(widget.lot.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parking lot deleted successfully')),
        );

        Navigator.pop(context); // go back after deletion
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting lot: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final lot = widget.lot;

    if (lot != null) {
      _nameController.text = lot.name;
      _descController.text = lot.desc;
      _capacityController.text = lot.capacity.toString();
      _hourlyRateController.text = lot.hourlyRate?.toString() ?? "";
      _dailyRateController.text = lot.dailyRate?.toString() ?? "";
      _monthlyRateController.text = lot.monthlyRate?.toString() ?? "";
      _availableFrom = lot.availableFrom;
      _closeBefore = lot.closeBefore;
      _echarge = lot.echarge;
      _imgBase64 = lot.img;
      _selectedLocation = {
        "lat": lot.location.latitude,
        "lng": lot.location.longitude,
      };
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location.')),
        );
        return;
      }

      final updatedLot = ParklotModel(
        id: widget.lot.id,
        hostId: widget.lot.hostId,
        img: _imgBase64,
        name: _nameController.text,
        desc: _descController.text,
        location: GeoPoint(
          _selectedLocation!['lat'],
          _selectedLocation!['lng'],
        ),
        capacity: int.tryParse(_capacityController.text) ?? 0,
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0,
        dailyRate: double.tryParse(_dailyRateController.text) ?? 0,
        monthlyRate: double.tryParse(_monthlyRateController.text) ?? 0,
        availableFrom: _availableFrom,
        closeBefore: _closeBefore,
        echarge: _echarge,
        occupied: widget.lot.occupied,
        createdAt: widget.lot.createdAt,
      );

      try {
        await FirebaseFirestore.instance
            .collection('ParkingLot')
            .doc(widget.lot.id)
            .update(updatedLot.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parklot successfully updated!')),
        );

        Navigator.pop(context, updatedLot);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating parklot: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildImgPreview(),
                const SizedBox(height: 20),
                _buildNameImg(),
                const SizedBox(height: 20),
                _buildWhereInput(),
                const SizedBox(height: 20),
                _buildDateSelection(
                  context: context,
                  selectedDate: _availableFrom,
                  hintText: "Available From",
                  onDateTimeChanged: (date) {
                    setState(() => _availableFrom = date);
                  },
                ),
                const SizedBox(height: 20),
                _buildDateSelection(
                  context: context,
                  selectedDate: _closeBefore,
                  hintText: "Close Before",
                  onDateTimeChanged: (date) {
                    setState(() => _closeBefore = date);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildRateBox(
                        controller: _hourlyRateController,
                        label: "Hourly",
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildRateBox(
                        controller: _dailyRateController,
                        label: "Daily",
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildRateBox(
                        controller: _monthlyRateController,
                        label: "Monthly",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDescriptionBox(controller: _descController),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildEchargeSwitch()),
                    const SizedBox(width: 55),
                    SizedBox(width: 115, child: _buildCapacity()),
                  ],
                ),
                const SizedBox(height: 60),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF004991)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Edit Parking Lot',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF004991),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildImgPreview() {
    return GestureDetector(
      onTap: _pickImage, // tap to pick a new image
      child: Container(
        width: double.infinity,
        height: 225,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: _imgBase64 == null
            ? const Center(
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.grey,
                  size: 40,
                ),
              )
            : Image.memory(
                base64Decode(_imgBase64!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 225,
              ),
      ),
    );
  }

  Widget _buildNameImg() {
    return TextFormField(
      controller: _nameController,
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
        contentPadding: const EdgeInsets.only(top: 12, left: 14, bottom: 12),
        hintText: "Name",
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w300,
          fontSize: 13,
          color: Color.fromRGBO(166, 166, 166, 1),
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.camera_alt,
            color: Color.fromARGB(135, 0, 73, 145),
            size: 25,
          ),
          onPressed: _pickImage,
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
    );
  }

  Widget _buildWhereInput() {
    return GestureDetector(
        onTap: () async {
          // Push the map screen and wait for result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapSelectScreen()),
          );

          if (result != null) {
            print("Selected location: $result");
            setState(() {
              _selectedLocation = result;
              _whereController.text = result['place'] ?? "";
            });
          }
        },
        child: AbsorbPointer(
          // makes TextFormField read-only
          child: TextFormField(
            controller: _whereController,
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
              contentPadding:
                  const EdgeInsets.only(top: 12, left: 14, bottom: 12),
              hintText: "Where are you going?",
              hintStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w300,
                fontSize: 13,
                color: Color.fromRGBO(166, 166, 166, 1),
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              suffixIcon: const Icon(Icons.search,
                  color: Color.fromARGB(135, 0, 73, 145)),
            ),
          ),
        ));
  }

  Widget _buildRateBox({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w300,
        fontSize: 14,
        color: Colors.black,
      ),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: label, // use label as hint
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w300,
          fontSize: 13,
          color: Color.fromRGBO(166, 166, 166, 1),
        ),
        contentPadding: const EdgeInsets.only(top: 12, left: 14, bottom: 12),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
        ),
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
      ),
    );
  }

  Widget _buildDescriptionBox({
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 5, // makes it taller like a square box
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w300,
        fontSize: 14,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: "Description",
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w300,
          fontSize: 13,
          color: Color.fromRGBO(166, 166, 166, 1),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildCapacity() {
    final List<int> capacities =
        List.generate(20, (i) => i + 1); // 1 → 20 options

    return DropdownButtonFormField<int>(
      value: int.tryParse(_capacityController.text),
      items: capacities
          .map((c) => DropdownMenuItem<int>(
                value: c,
                child: Text(
                  c.toString(),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          _capacityController.text = val.toString();
        }
      },
      decoration: InputDecoration(
        hintText: "Capacity",
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w300,
          fontSize: 13,
          color: Color.fromRGBO(166, 166, 166, 1),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Color.fromARGB(135, 0, 73, 145),
      ),
    );
  }

  Widget _buildEchargeSwitch() {
    return SwitchListTile(
      title: const Text(
        'E-Charge: ',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),

      value: _echarge,
      activeColor: const Color.fromRGBO(59, 120, 195, 1), // active thumb color
      inactiveThumbColor: Colors.grey.shade400,
      inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255),
      onChanged: (val) => setState(() => _echarge = val),
      dense: true, // makes it a bit more compact
      contentPadding: EdgeInsets.zero, // remove left/right padding
    );
  }

  Widget _buildDateSelection({
    required BuildContext context,
    required DateTime? selectedDate,
    required String hintText,
    required ValueChanged<DateTime> onDateTimeChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        DateTime now = DateTime.now();
        DateTime tempPickedDate = selectedDate ?? now;
        bool isValid =
            tempPickedDate.isAfter(now) || tempPickedDate.isAtSameMomentAs(now);

        DateTime? picked = await showModalBottomSheet<DateTime>(
          context: context,
          builder: (_) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  height: 400,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Expanded(
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.dateAndTime,
                          initialDateTime: selectedDate ?? now,
                          use24hFormat: false,
                          onDateTimeChanged: (val) {
                            setState(() {
                              tempPickedDate = val;
                              isValid =
                                  val.isAfter(now) || val.isAtSameMomentAs(now);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: SizedBox(
                          width: 223,
                          height: 45,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: isValid
                                  ? const Color.fromRGBO(59, 120, 195, 1)
                                  : Colors.grey, // grey if invalid
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: isValid
                                ? () {
                                    Navigator.of(context).pop(tempPickedDate);
                                  }
                                : null, // disable when invalid
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );

        if (picked != null) {
          onDateTimeChanged(picked); // Update parent state
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            width: 0.3,
            color: const Color.fromRGBO(79, 79, 79, 1),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate == null
                  ? hintText
                  : "${selectedDate.toLocal()}".split('.')[0],
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: selectedDate == null ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: Color.fromARGB(135, 0, 73, 145),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Delete button
        SizedBox(
          width: 150,
          height: 45,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _deleteLot(context),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Save / Submit button
        SizedBox(
          width: 150,
          height: 45,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromRGBO(59, 120, 195, 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _submit(),
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
        ),
      ],
    );
  }
}
