import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/booking_model.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:curbshare/services/location_service.dart';
import 'package:curbshare/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel book;

  const BookingDetailScreen({super.key, required this.book});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingModel currentBook;
  ParklotModel? lot;
  final _locationService = LocationService();
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    currentBook = widget.book;
    _fetchLot();
  }

  Future<void> _fetchLot() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ParkingLot')
          .doc(currentBook.lotId)
          .get();

      if (doc.exists) {
        setState(() {
          lot = ParklotModel.fromDoc(doc);
        });
      } else {
        print("Lot not found for ID: ${currentBook.lotId}");
      }
    } catch (e) {
      print("Error fetching lot: $e");
    }
  }

  Future<void> _openGoogleMap() async {
    final lat = lot!.location.latitude;
    final lng = lot!.location.longitude;
    final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = currentBook.end.difference(currentBook.start);

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
                icon: const Icon(Icons.arrow_back, color: Color(0xFF004991)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: lot != null
                  ? _buildFirebaseImageFromBase64(lot!.img)
                  : const ColoredBox(color: Colors.grey), // placeholder bg
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lot Name
                  Text(
                    lot?.name ?? "Loading...",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004991),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Image.asset(
                        'icons/plate.png',
                        width: 16,
                        height: 16,
                        color: const Color(0xFF004991),
                      ),
                      const SizedBox(width: 4),
                      Text("${currentBook.vehicleName}"),
                      const SizedBox(width: 12),
                      const Icon(Icons.local_parking,
                          size: 16, color: Color(0xFF004991)),
                      const SizedBox(width: 4),
                      Text(lot != null
                          ? "${lot!.capacity - lot!.occupied}/${lot!.capacity}"
                          : "..."),
                      const SizedBox(width: 12),
                      const Icon(Icons.ev_station,
                          size: 16, color: Color(0xFF004991)),
                      const SizedBox(width: 4),
                      Text(lot != null ? (lot!.echarge ? "Yes" : "No") : "..."),
                    ],
                  ),

                  const Divider(height: 25),

                  // Availability
                  Text(
                    "Available: "
                    "${lot?.availableFrom != null ? dateFormat.format(lot!.availableFrom!) : '...'}"
                    " - "
                    "${lot?.closeBefore != null ? dateFormat.format(lot!.closeBefore!) : '...'}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(59, 120, 195, 0.642),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(
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
                                    fontSize: 14, color: Color(0xFF004991))),
                            const Spacer(),
                            Text(dateFormat.format(currentBook.start)),
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
                                    fontSize: 14, color: Color(0xFF004991))),
                            const Spacer(),
                            Text(dateFormat.format(currentBook.end)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Parking Type: ",
                          style: TextStyle(
                            color: Color.fromRGBO(59, 120, 195, 0.642),
                          )),
                      Text(
                        currentBook.reservationType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(59, 120, 195, 0.642),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currentBook.reservationType == "monthly"
                            ? "${duration.inDays}d"
                            : "${duration.inHours}h",
                        style: const TextStyle(color: Color(0xFF004991)),
                      ),
                    ],
                  ),

                  const Divider(height: 25),
                  const Text(
                    "Parking Location:",
                    style: TextStyle(
                      color: Color.fromRGBO(59, 120, 195, 0.642),
                    ),
                  ),

                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _openGoogleMap,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: lot != null
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(lot!.location.latitude,
                                    lot!.location.longitude),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(lot!.id),
                                  position: LatLng(lot!.location.latitude,
                                      lot!.location.longitude),
                                )
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              scrollGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                            )
                          : const ColoredBox(
                              color: Colors.black12,
                              child: Center(child: Text("Loading map...")),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  ReadMoreText(
                    lot?.desc ?? "Loading description...",
                    trimLines: 5,
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
                  const SizedBox(height: 22),
                  _buildReportLink(context, lot),
                  const SizedBox(height: 22),
                  _buildRebookButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildReportLink(BuildContext context, ParklotModel? lot) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final hostId = lot?.hostId ?? 'N/A';
          final lotId = lot?.id ?? 'N/A';
          final message = "Host ID: $hostId\nLot ID: $lotId";

          final url = Uri.parse(
            "https://t.me/share/url?url=https://curbshare.app&text=${Uri.encodeComponent(message)}",
          );

          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Could not open Telegram."),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: const Text(
          "Report an Issue",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xFF004991),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildRebookButton() {
    return Center(
      child: SizedBox(
        width: 200,
        height: 45,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromRGBO(59, 120, 195, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () async {
            if (lot == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Lot information not available.")),
              );
              return;
            }
            try {
              final newStart = DateTime.now();
              final newEnd = newStart.add(
                currentBook.reservationType == "monthly"
                    ? const Duration(days: 30)
                    : currentBook.reservationType == "daily"
                        ? const Duration(days: 1)
                        : const Duration(hours: 1),
              );
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              await PaymentService.startBookingAndPay(
                context: context,
                lotId: lot!.id,
                hostId: lot!.hostId,
                start: newStart,
                end: newEnd,
                bookingType: currentBook.reservationType,
                amount: currentBook.budget ?? 10.0, // fallback if missing
              );
              if (Navigator.canPop(context)) Navigator.pop(context);
            } catch (e) {
              if (Navigator.canPop(context)) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Booking failed: $e")),
              );
            }
            // Navigate to FilterScreen and pass filterData
          },
          child: const Text(
            'Rebook',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
