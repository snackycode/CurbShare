
import 'package:curbshare/user/driver/locationsearch_screen.dart';
import 'package:curbshare/user/driver/mapfilter_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int initialLabelIndex = 0;
  final DateTime _selectedDateTime = DateTime.now();
  DateTime? start;
  DateTime? end;
  Map<String, dynamic>? _selectedLocation;
  void _openLocationSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result; // {"lat": ..., "lng": ..., "place": ...}
      });
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
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: const Text(
          "CurbShare",
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w600,
            fontSize: 26,
            color: Color(0xFF004991),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        color: Colors.white,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  _buildTimeSwitch(),
                  SizedBox(height: 55),
                  _buildWhereInput(),
                  SizedBox(height: 20),
                  if (initialLabelIndex == 0) ...[
                    _buildDateSelection(
                      context: context,
                      selectedDate: start,
                      hintText: "Enter After",
                      onDateTimeChanged: (val) => setState(() => start = val),
                    ),
                    SizedBox(height: 20),
                    _buildDateSelection(
                      context: context,
                      selectedDate: end,
                      hintText: "Exit Before",
                      onDateTimeChanged: (val) => setState(() => end = val),
                    ),
                  ] else ...[
                    // Monthly → show only one date picker
                    _buildDateSelection(
                      context: context,
                      selectedDate: start,
                      hintText: "Monthly Parking Start",
                      onDateTimeChanged: (val) => setState(() {
                        start = val;
                        // Automatically set end = start + 30 days
                        end = start!.add(const Duration(days: 30));
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildConfirmButton(),
          SizedBox(height: 80),
        ]));
  }

  Widget _buildWhereInput() {
    return GestureDetector(
        onTap: (_openLocationSearch),
        // {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (_) => LocationSearchScreen(
        //               onLocationConfirmed: (location) {
        //                 setState(() {
        //                   _selectedLocation = location;
        //                 });
        //               },
        //             )),
        //   );
        // },
        child: AbsorbPointer(
          // makes TextFormField read-only
          child: TextFormField(
            controller: TextEditingController(
                text: _selectedLocation != null
                    ? _selectedLocation!['place']
                    : ""),
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

  Widget _buildTimeSwitch() {
    return Align(
      alignment: Alignment.center,
      child: ToggleSwitch(
        customTextStyles: const [
          TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 16, // smaller font
          )
        ],
        minWidth: 125, // much smaller width
        minHeight: 43, // much smaller height
        cornerRadius: 12.0,
        activeBgColor: const [Color.fromRGBO(59, 120, 195, 1)],
        activeFgColor: Colors.white,
        inactiveBgColor: Colors.white,
        inactiveFgColor: const Color.fromRGBO(59, 120, 195, 1),
        initialLabelIndex: initialLabelIndex,
        totalSwitches: 2,
        labels: const ['Hour/Day', 'Monthly'],
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

  Widget _buildConfirmButton() {
    return SizedBox(
      width: 223,
      height: 45,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color.fromRGBO(59, 120, 195, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          if (_selectedLocation == null) {
            // Optionally show a warning if no location selected
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a location.")),
            );
            return;
          }
          print('_selectedLocation: $_selectedLocation');
          String bookingType = initialLabelIndex == 0 ? "hour_day" : "monthly";
          print("Booking type for debug: $bookingType");
          final filterData = {
            "location":
                _selectedLocation, // {"lat":..., "lng":..., "place":...}
            "start": start,
            "end": initialLabelIndex == 0 ? end : null, // only Hour/Day has end
            "type": bookingType,
          };

          // Navigate to FilterScreen and pass filterData
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapFilterScreen(
                useCurrentLocation: false,
                latitude: _selectedLocation!['lat'],
                longitude: _selectedLocation!['lng'],
                searchQuery: _selectedLocation!['place'],
                filterData: filterData,
              ),
            ),
          );
        },
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
    );
  }
}
