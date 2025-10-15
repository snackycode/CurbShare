import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/booking_model.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:curbshare/user/host/editbooking_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

class HostLotDetailScreen extends StatefulWidget {
  final ParklotModel lot;
  final BookingModel? booking;
  const HostLotDetailScreen({
    super.key,
    required this.lot,
    this.booking,
  });

  @override
  State<HostLotDetailScreen> createState() => _HostLotDetailScreenState();
}

class _HostLotDetailScreenState extends State<HostLotDetailScreen> {
  late ParklotModel currentLot;
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _openGoogleMap() async {
    final lat = widget.lot.location.latitude;
    final lng = widget.lot.location.longitude;
    final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showQrDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      barrierDismissible: true, // allow tap outside to close
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                type == "checkin" ? "Check-in QR" : "Check-out QR",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004991),
                ),
              ),
              const SizedBox(height: 20),

              // QR Code container with subtle shadow
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: PrettyQrView.data(
                  data: jsonEncode({'lotId': currentLot.id, 'type': type}),
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            .doc(currentLot.id)
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
    currentLot = widget.lot;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          // Collapsing image header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 119, 187, 255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004991),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 255, 255, 255),
                      Color.fromARGB(255, 119, 187, 255),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF004991)),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        //   final updatedLot = await Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (_) => EditBookingScreen(lot: currentLot),
                        //     ),
                        //   );
                        //   if (updatedLot != null) {
                        //     setState(() {
                        //       currentLot = updatedLot;
                        //     });
                        //   }
                        //   break;
                        // case 'delete':
                        //   // Call your delete function
                        //   _deleteLot(context);
                        //   break;
                        if (widget.booking == null) {
                          final updatedLot = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditBookingScreen(lot: currentLot),
                            ),
                          );
                          if (updatedLot != null) {
                            setState(() {
                              currentLot = updatedLot;
                            });
                          }
                        }
                        break;
                      case 'delete':
                        if (widget.booking == null) {
                          _deleteLot(context);
                        }
                        break;
                      case 'checkin_qr':
                        _showQrDialog(context, "checkin");
                        break;
                      case 'checkout_qr':
                        _showQrDialog(context, "checkout");
                        break;
                    }
                  },
                  // itemBuilder: (context) => [

                  //   const PopupMenuItem(
                  //     value: 'edit',
                  //     child: Text('Edit'),
                  //   ),
                  //   const PopupMenuItem(
                  //     value: 'delete',
                  //     child: Text('Delete'),
                  //   ),
                  //   const PopupMenuItem(
                  //     value: 'checkin_qr',
                  //     child: Text('Check-in QR'),
                  //   ),
                  //   const PopupMenuItem(
                  //     value: 'checkout_qr',
                  //     child: Text('Check-out QR'),
                  //   ),
                  // ],
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> items = [];

                    // Only add Edit/Delete if no booking
                    if (widget.booking == null) {
                      items.addAll([
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ]);
                    }

                    // Always show QR options
                    items.addAll([
                      const PopupMenuItem(
                          value: 'checkin_qr', child: Text('Check-in QR')),
                      const PopupMenuItem(
                          value: 'checkout_qr', child: Text('Check-out QR')),
                    ]);

                    return items;
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildFirebaseImageFromBase64(currentLot.img),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLot.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004991),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (widget.booking != null) ...[
                        Image.asset(
                          'icons/plate.png',
                          width: 16,
                          height: 16,
                          color: const Color(0xFF004991),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.booking!.vehicleName ?? " ",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF004991),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.local_parking,
                          size: 16, color: Color(0xFF004991)),
                      const SizedBox(width: 4),
                      Text(
                        "${currentLot.capacity - currentLot.occupied}/${currentLot.capacity}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF004991),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.ev_station,
                          size: 16, color: Color(0xFF004991)),
                      const SizedBox(width: 4),
                      Text(
                        currentLot.echarge ? "Yes" : "No",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF004991),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 25),
                  // Availability
                  Text(
                    "Available: ${currentLot.availableFrom != null ? dateFormat.format(currentLot.availableFrom!) : "--"} "
                    "- ${currentLot.closeBefore != null ? dateFormat.format(currentLot.closeBefore!) : "--"}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(59, 120, 195, 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  widget.booking != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.radio_button_off,
                                      size: 18, color: Color(0xFF004991)),
                                  const SizedBox(width: 8),
                                  const Text("Check-in",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF004991))),
                                  const Spacer(),
                                  Text(
                                    dateFormat
                                        .format(widget.booking!.start),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.radio_button_on,
                                      size: 18, color: Color(0xFF004991)),
                                  const SizedBox(width: 8),
                                  const Text("Check-out",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF004991))),
                                  const Spacer(),
                                  Text(
                                    dateFormat.format(widget.booking!.end),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Text(
                                "Hourly: \$${currentLot.hourlyRate.toStringAsFixed(2)}/h",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color.fromRGBO(59, 120, 195, 0.642),
                                )),
                            const Spacer(),
                            Text(
                                "Daily: \$${currentLot.dailyRate.toStringAsFixed(2)}/d",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color.fromRGBO(59, 120, 195, 0.642),
                                )),
                            const Spacer(),
                            Text(
                                "Monthly: \$${currentLot.monthlyRate.toStringAsFixed(2)}/m",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color.fromRGBO(59, 120, 195, 0.642),
                                )),
                          ],
                        ),

                  const Divider(height: 25),
                  const Text(
                    "Parking Location:",
                    style: TextStyle(
                      color: Color.fromRGBO(59, 120, 195, 1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Map preview
                  GestureDetector(
                    onTap: _openGoogleMap,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(currentLot.location.latitude,
                              currentLot.location.longitude),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(currentLot.id),
                            position: LatLng(currentLot.location.latitude,
                                currentLot.location.longitude),
                          )
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        scrollGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  ReadMoreText(
                    currentLot.desc,
                    trimLines: 5, // show 5 lines initially
                    colorClickableText: const Color(0xFF004991),
                    trimMode: TrimMode.Line,
                    trimCollapsedText: '...Read more',
                    trimExpandedText: ' Read less',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    moreStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004991),
                    ),
                    lessStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004991),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 255, 119, 119),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
        onPressed: () => _deleteLot(context),
      ),
    );
  }

  Widget _buildFirebaseImageFromBase64(String? base64String) {
    if (base64String == null) {
      // fallback
      return Icon(Icons.image, size: 40, color: Colors.white);
    }

    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
