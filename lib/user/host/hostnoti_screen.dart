import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/model/booking_model.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:curbshare/services/noti_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HostNotiScreen extends StatelessWidget {
  final NotiService _notiService = NotiService();
  double calculateOverstayFee(BookingModel booking) {
    final now = DateTime.now();
    final overstayMinutes = now.difference(booking.end).inMinutes;
    final hourlyRate =
        booking.budget; // assume your booking.budget = hourly rate
    final perMinuteRate = hourlyRate * 0.05; // 5% per minute
    return (overstayMinutes > 0 ? overstayMinutes * perMinuteRate : 0)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: StreamBuilder<List<BookingModel>>(
        stream: _notiService.hostBookingsLive(minutesWindow: 10),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No upcoming bookings."));
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final book = bookings[index];
              return _buildBookCard(context, book);
            },
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(
        "Notification",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: Color(0xFF004991),
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, BookingModel book) {
    final now = DateTime.now();
    final timeLeft = book.end.difference(now).inMinutes;
    final isOverstaying = now.isAfter(book.end) && book.checkout == null;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("ParkingLot")
          .doc(book.lotId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(); // Skip if lot not found
        }

        final lot = ParklotModel.fromDoc(snapshot.data!);

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timer,
                  color: isOverstaying
                      ? Colors.red
                      : Color.fromRGBO(0, 73, 145, 1),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),

              /// Lot Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 45,
                      width: 150,
                      child: Text(
                        lot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${DateFormat("dd MMM, h:mm a").format(book.start)} - ${DateFormat("dd MMM, h:mm a").format(book.end)}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              /// Right column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOverstaying
                        ? "Overstay: \$${calculateOverstayFee(book).toStringAsFixed(2)}"
                        : "Ends at: ${book.end.toLocal().toString().substring(11, 16)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF004991),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "$timeLeft min left",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF004991),
                    ),
                  ),
                  SizedBox(height: 4),
                  if (isOverstaying && !(book.overstayFeePaid ?? false))
                    GestureDetector(
                      onTap: () async {
                        final fee = calculateOverstayFee(book);
                        await FirebaseFirestore.instance
                            .collection('Booking')
                            .doc(book.id)
                            .update({
                          'overstayFeeAmount': fee,
                          'overstayFeePaid':
                              false, 
                        });
                        final message =
                            "Driver ID: ${book.driverId}\nBooking ID: ${book.id}\nVehicle: ${book.vehicleName ?? 'N/A'}\nOverstay Fee: \$${fee.toStringAsFixed(2)}";

                        final url = Uri.parse(
                            "https://t.me/share/url?url=CurbShare&text=${Uri.encodeComponent(message)}");

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open Telegram."),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Icon(
                        Icons.report,
                        color: Colors.red,
                        size: 24, // you can tweak this (default 24)
                      ),
                    )
                  else
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF004991),
                      ),
                    )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
