import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curbshare/services/payment_service.dart';
import 'package:curbshare/user/driver/lotdetail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:curbshare/services/location_service.dart';
import 'package:curbshare/services/place_service.dart';
import 'package:curbshare/model/parklot_model.dart';
import 'package:intl/intl.dart';

class MapFilterScreen extends StatefulWidget {
  final bool useCurrentLocation;
  final String? searchQuery;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? filterData;
  final void Function(Map<String, dynamic>)? onLocationConfirmed;

  const MapFilterScreen(
      {super.key,
      this.onLocationConfirmed,
      this.filterData,
      required this.useCurrentLocation,
      this.searchQuery,
      this.latitude,
      this.longitude});

  @override
  _MapFilterScreenState createState() => _MapFilterScreenState();
}

class _MapFilterScreenState extends State<MapFilterScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ScrollController _listScrollController = ScrollController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final PlacesService _placesService = PlacesService();
  final LocationService _locationService = LocationService();
  bool _showConfirmButton = false;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _selectedPosition;
  LatLng? _confirmedPosition;
  String _selectedPlace = "Selected Location";
  Set<Marker> _markers = {};
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<ParklotModel> _allLots = [];
  List<ParklotModel> _filteredLots = [];
  bool _isLoadingLots = true;

  late String _bookingType;
  late DateTime _startDate;
  late DateTime _endDate;
  // String _bookingType = "hourly"; // default value
  // DateTime _startDate = DateTime.now();
  // DateTime _endDate = DateTime.now().add(Duration(hours: 2));
  int _capacity = 1;
  bool? _echarge;

  RangeValues _priceRange = const RangeValues(0, 50);

  double radiusMeters = 2000;

  void _goToCurrentLocation() {
    if (_currentPosition == null || _mapController == null) return;

    final currentLatLng =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 16),
      ),
    );
  }

  // void _addOrUpdateMarker(LatLng pos) {
  //   final updatedMarkers = Set<Marker>.from(_markers);
  //   updatedMarkers.removeWhere((m) => m.markerId.value == 'selected');
  //   updatedMarkers.add(Marker(
  //     markerId: const MarkerId('selected'),
  //     position: pos,
  //     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
  //     draggable: true,
  //     onDragEnd: (newPos) => setState(() {
  //       _selectedPosition = newPos;
  //       _showConfirmButton = true;
  //     }),
  //     infoWindow: InfoWindow(title: _selectedPlace),
  //   ));

  //   setState(() {
  //     _selectedPosition = pos;
  //     _markers = updatedMarkers;
  //   });
  // }
  String _mapDialogBookingType(
      String previousType, DateTime start, DateTime? end) {
    switch (previousType) {
      case 'hour_day':
        if (end == null) return 'hourly';
        final actualEnd =
            end ?? start.add(const Duration(hours: 24)); // default > 24h
        final hours = actualEnd.difference(start).inMinutes / 60.0;

        return hours >= 24 ? 'daily' : 'hourly';
      case 'monthly':
        return 'monthly';
      default:
        return 'hourly';
    }
  }

  void _setBookingType(String type, StateSetter setState) {
    setState(() {
      _bookingType = type;
      // Update price range max based on booking type
      if (_bookingType == 'monthly') {
        _priceRange = RangeValues(
          _priceRange.start.clamp(0, 200),
          _priceRange.end.clamp(0, 200),
        );
      } else {
        _priceRange = RangeValues(
          _priceRange.start.clamp(0, 50),
          _priceRange.end.clamp(0, 50),
        );
      }
    });
    _applyFilters();
    print("Selected booking type: $_bookingType");
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            SizedBox(width: 50), // placeholder for alignment
                            Text(
                              'Filter',
                              style: TextStyle(
                                  color: Color(0xFF004991),
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Booking Type
                        const Text(
                          'Booking Type',
                          style: TextStyle(
                              color: Color(0xFF004991),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: ['hourly', 'daily', 'monthly'].map((type) {
                            return GestureDetector(
                              onTap: () => _setBookingType(type, setState),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        type[0].toUpperCase() +
                                            type.substring(1),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF004991),
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Transform.scale(
                                      scale: 0.9,
                                      child: Radio<String>(
                                        value: type,
                                        groupValue: _bookingType,
                                        onChanged: (val) =>
                                            _setBookingType(val!, setState),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        activeColor: const Color(0xFF004991),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 32),

                        if (_bookingType == 'monthly') ...[
                          _buildDateSelection(
                            context: context,
                            selectedDate: _startDate,
                            hintText: "Select Month Start",
                            onDateTimeChanged: (val) =>
                                setState(() => _startDate = val),
                          ),
                        ] else ...[
                          _buildDateSelection(
                            context: context,
                            selectedDate: _startDate,
                            hintText: "Enter After",
                            onDateTimeChanged: (val) =>
                                setState(() => _startDate = val),
                          ),
                          const SizedBox(height: 16),
                          _buildDateSelection(
                            context: context,
                            selectedDate: _endDate,
                            hintText: "Exit Before",
                            onDateTimeChanged: (val) =>
                                setState(() => _endDate = val),
                          ),
                        ],
                        const Divider(height: 32),

                        // Capacity Dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Capacity',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF004991),
                                )),
                            DropdownButton<int>(
                              value: _capacity == 0 ? 1 : _capacity,
                              items: List.generate(
                                  5,
                                  (index) => DropdownMenuItem(
                                        value: index + 1,
                                        child: Text('${index + 1}'),
                                      )),
                              onChanged: (val) =>
                                  setState(() => _capacity = val ?? 0),
                            ),
                          ],
                        ),

                        // E-Charge Dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('E-Charge',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF004991),
                                )),
                            DropdownButton<bool>(
                              value: _echarge,
                              hint: const Text("Any"),
                              items: const [
                                DropdownMenuItem(
                                    value: true, child: Text("Yes")),
                                DropdownMenuItem(
                                    value: false, child: Text("No")),
                              ],
                              onChanged: (val) =>
                                  setState(() => _echarge = val),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        // Price Range
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price Range',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF004991),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (_) {
                                // Determine max price based on booking type
                                final double maxPrice =
                                    _bookingType == 'monthly' ? 200.0 : 50.0;

                                // Ensure _priceRange.end is within max
                                if (_priceRange.end > maxPrice) {
                                  _priceRange = RangeValues(
                                      _priceRange.start.clamp(0.0, maxPrice),
                                      maxPrice);
                                }

                                return RangeSlider(
                                  values: _priceRange,
                                  min: 0,
                                  max: maxPrice,
                                  divisions:
                                      _bookingType == 'monthly' ? 30 : 15,
                                  activeColor: const Color(0xFF004991),
                                  inactiveColor: Colors.grey[300],
                                  labels: RangeLabels(
                                    "\$${_priceRange.start.toStringAsFixed(0)}",
                                    "\$${_priceRange.end.toStringAsFixed(0)}",
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      // Clamp values to avoid RangeSlider errors
                                      _priceRange = RangeValues(
                                        val.start.clamp(0.0, maxPrice),
                                        val.end.clamp(0.0, maxPrice),
                                      );
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),

                        // Distance slider
                        const Text(
                          'Distance',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF004991),
                          ),
                        ),
                        Slider(
                          value: radiusMeters,
                          min: 0,
                          max: 2000,
                          divisions: 20,
                          activeColor: const Color(0xFF004991),
                          label: '${radiusMeters.toInt()} m',
                          onChanged: (val) =>
                              setState(() => radiusMeters = val),
                        ),
                        const SizedBox(height: 32),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    foregroundColor: const Color(
                                        0xFF004991), // Apply button color
                                    side:
                                        const BorderSide(color: Colors.black12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    )),
                                onPressed: () {
                                  setState(() {
                                    _bookingType = 'hourly';
                                    _startDate = DateTime.now();
                                    _endDate = DateTime.now()
                                        .add(const Duration(hours: 1));
                                    _capacity = 0;
                                    _echarge = null;
                                    _priceRange = const RangeValues(0, 50);
                                    radiusMeters = 0;
                                  });
                                },
                                child: const Text('Clear all'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor:
                                      const Color(0xFF004991), // Text color
                                  foregroundColor:
                                      Colors.white, // Apply button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  side: const BorderSide(color: Colors.black12),
                                ),
                                onPressed: () {
                                  _applyFilters();
                                  Navigator.pop(context);
                                },
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _expandSheet() {
    _sheetController.animateTo(
      0.88, // expand to maxChildSize
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _updateSelectedMarker(LatLng pos) {
    final updatedMarkers = Set<Marker>.from(_markers);
    updatedMarkers.removeWhere((m) => m.markerId.value == 'selected');
    updatedMarkers.add(Marker(
      markerId: const MarkerId('selected'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      draggable: true,
      onDragEnd: (newPos) {
        setState(() {
          _selectedPosition = newPos;
          _showConfirmButton = true;
        });
      },
      infoWindow: InfoWindow(title: _selectedPlace),
    ));
    if (mounted) {
      setState(() {
        _markers = updatedMarkers;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Extract previous screen data safely
    // final previousType = widget.filterData?['type'] as String? ?? 'hour_day';
    // final previousStart =
    //     widget.filterData?['start'] as DateTime? ?? DateTime.now();
    // final previousEnd = widget.filterData?['end'] as DateTime?;

    // _fetchLots(
    //   previousType: previousType,
    //   previousStart: previousStart,
    //   previousEnd: previousEnd,
    // );
    _init();
  }

  Future<void> _init() async {
    try {
      // 1️⃣ Get current position
      final pos = await _locationService.getCurrentPosition();
      setState(() => _currentPosition = pos);
      final previousType = widget.filterData?['type'] as String? ?? 'hour_day';
      final previousStart =
          widget.filterData?['start'] as DateTime? ?? DateTime.now();
      final previousEnd = widget.filterData?['end'] as DateTime?;

      _bookingType =
          _mapDialogBookingType(previousType, previousStart, previousEnd);
      _startDate = previousStart;
      _endDate = previousEnd ??
          (_bookingType == 'monthly'
              ? _startDate.add(const Duration(days: 30))
              : _startDate.add(const Duration(hours: 2)));

      await _fetchLots(
        previousType: previousType,
        previousStart: previousStart,
        previousEnd: previousEnd,
      );

      // 2️⃣ Fetch all lots from Firestore (no filtering)
      // final allLots = await _locationService.fetchAllLots();
      // print("Total lots fetched: ${allLots.length}");
      // for (var lot in allLots) {
      //   print(" - ${lot.name} @ ${lot.lat},${lot.lng}");
      // }
      if (widget.latitude != null && widget.longitude != null) {
        _selectedPosition = LatLng(widget.latitude!, widget.longitude!);
        _selectedPlace = widget.searchQuery ?? "Selected Location";
        _searchController.text = _selectedPlace;
      } else {
        _selectedPosition = LatLng(pos.latitude, pos.longitude);
        _selectedPlace = "Current Location";
        _searchController.text = _selectedPlace;
      }

      // 3️⃣ Build markers for all lots
      final markers = _filteredLots.map((lot) {
        final price = _locationService.calculatePrice(
          lot: lot,
          bookingType: _bookingType,
          start: _startDate,
          end: _endDate,
        );
        return Marker(
          markerId: MarkerId(lot.id),
          position: LatLng(lot.lat, lot.lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
              title: lot.name, snippet: '\$${price.toStringAsFixed(2)}'),
          onTap: () => _onMarkerTap(lot),
        );
      }).toSet();

      // 4️⃣ Add selected position marker (your location or searched)
      if (_selectedPosition == null) {
        _selectedPosition = LatLng(pos.latitude, pos.longitude);
        _selectedPlace = "Current Location";
        _searchController.text = _selectedPlace;
      }
      markers.add(Marker(
        markerId: const MarkerId('selected'),
        position: _selectedPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        draggable: true,
        onDragEnd: (newPos) => setState(() => _selectedPosition = newPos),
        infoWindow: InfoWindow(title: _selectedPlace),
      ));

      // 5️⃣ Animate camera to selected position
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 14),
      );

      // 6️⃣ Update state
      setState(() => _markers = markers);
    } catch (e, stack) {
      print('Error initializing map: $e\n$stack');
    }
  }

  // Future<void> _fetchLots() async {
  //   final lots = await _locationService.fetchAllLots();
  //   setState(() {
  //     _allLots = lots;
  //     _filteredLots = lots; // default: no filter applied
  //     _isLoadingLots = false;
  //   });
  // }
  Future<void> _fetchLots({
    required String previousType,
    required DateTime previousStart,
    DateTime? previousEnd,
  }) async {
    try {
      // Map previous booking type to new screen options
      final bookingType =
          _mapDialogBookingType(previousType, previousStart, previousEnd);

      // Determine start and end dates
      final start = previousStart;
      final end = previousEnd ??
          (bookingType == 'monthly'
              ? start.add(const Duration(days: 30))
              : start.add(const Duration(hours: 2)));

      // Fetch lots from service
      final lots = await _locationService.fetchingLots(
        bookingType: bookingType,
        start: start,
        end: end,
      );

      // final lots = await _locationService.fetchAllLots();

      // Filter out lots where the rate for selected booking type is null or 0
      final validLots = lots.where((lot) {
        switch (bookingType) {
          case 'hourly':
            return lot.hourlyRate > 0;
          case 'daily':
            return lot.dailyRate > 0;
          case 'monthly':
            return lot.monthlyRate > 0;
          default:
            return false;
        }
      }).toList();

      setState(() {
        _bookingType = bookingType;
        _startDate = start;
        _endDate = end;
        _allLots = validLots;
        _filteredLots = validLots;
        _isLoadingLots = false;
      });
    } catch (e, stack) {
      print("Error fetching lots: $e\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch lots.")),
      );
    }
  }

  Future<void> _applyFilters() async {
    try {
      final bookingType =
          _mapDialogBookingType(_bookingType, _startDate, _endDate);
      print("Booking type from dialog: $_bookingType");
      print("Mapped booking type: $bookingType");
      // Step 0: Fetch all lots
      final allLots = await _locationService.fetchAllLots();
      print("Total lots fetched: ${allLots.length}");
      for (var lot in allLots) {
        print(" - ${lot.name}");
      }

      final filteredLots = await _locationService.getFilteredLots(
        start: _startDate ?? DateTime.now(),
        end: _endDate ?? DateTime.now().add(const Duration(hours: 1)),
        userPos: _selectedPosition!,
        minCapacity: _capacity,
        priceRange: _priceRange,
        radiusMeters: radiusMeters,
        bookingType: bookingType,
        echarge: _echarge,
        allLots: _allLots, // pass the already-fetched valid lots
      );

      // Step 6: Update markers
      final markers = filteredLots.map((lot) {
        final price = _locationService.calculatePrice(
          lot: lot,
          bookingType: bookingType,
          start: _startDate,
          end: _endDate,
        );

        return Marker(
          markerId: MarkerId(lot.id),
          position: LatLng(lot.lat, lot.lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: lot.name,
            snippet: '\$${price.toStringAsFixed(2)}',
          ),
          onTap: () => _onMarkerTap(lot),
        );
      }).toSet();

      // Add selected marker
      if (_selectedPosition != null) {
        markers.add(Marker(
          markerId: const MarkerId('selected'),
          position: _selectedPosition!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          draggable: true,
          onDragEnd: (newPos) => setState(() => _selectedPosition = newPos),
          infoWindow: InfoWindow(title: _selectedPlace),
        ));
      }

      setState(() {
        _filteredLots = filteredLots;
        _markers = markers;
      });
    } catch (e, stack) {
      print("Error in _applyFilters: $e\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching filtered lots.")),
      );
    }
  }

  void _onMarkerTap(ParklotModel lot) {
    // showModalBottomSheet(
    //   context: context,
    //   builder: (_) => ParkingBottomSheet(lot: lot),
    //   isScrollControlled: true,
    // );
    final index = _filteredLots.indexWhere((l) => l.id == lot.id);

    if (index != -1) {
      // Animate the carousel to the corresponding index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carouselController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    } else {
      // Debug: lot not found
      print('Tapped lot not found in filtered list: ${lot.name}');
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    try {
      final latLng =
          await _placesService.getPlaceDetails(prediction['place_id']);
      setState(() {
        _selectedPosition = LatLng(latLng.latitude, latLng.longitude);
        _selectedPlace = prediction['description'];
        _searchController.text = prediction['description'];

        bool markerExists = false;
        _markers = _markers.map((m) {
          if (m.markerId.value == 'selected') {
            markerExists = true;
            return m.copyWith(
              positionParam: _selectedPosition,
              infoWindowParam: InfoWindow(title: _selectedPlace),
              iconParam: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet),
            );
          }
          return m;
        }).toSet();

        if (!markerExists) {
          _markers.add(Marker(
            markerId: const MarkerId('selected'),
            position: _selectedPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            draggable: true,
            onDragEnd: (newPos) => setState(() => _selectedPosition = newPos),
            infoWindow: InfoWindow(title: _selectedPlace),
          ));
        }
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 16),
      );
    } catch (e) {
      print("Error selecting place: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: _buildAppBar(),
        extendBodyBehindAppBar: true,
        body: _buildBody());
  }

  // Widget _buildBody() {
  //   if (_currentPosition == null) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //   if (_filteredLots.isEmpty) {
  //     return const Center(child: Text("No parking lots found"));
  //   }

  //   return Stack(children: [
  //     // Base layout: map + confirm button
  //     Column(
  //       children: [
  //         Expanded(child: _buildMap()), // Map takes available height
  //         // Padding(
  //         //   padding: const EdgeInsets.all(16.0),
  //         // child: _buildCarousel(
  //         //   _filteredLots,
  //         //   GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
  //         //     _mapDialogBookingType(_bookingType), // or hourly/monthly
  //         //   ),
  //         // ),
  //         // Floating carousel at the bottom
  //         // Positioned(
  //         //   left: 0,
  //         //   right: 0,
  //         //   bottom: 16, // distance from bottom of screen
  //         //   child: SizedBox(
  //         //     height: 190, // same height as your carousel
  //         //     child: _buildCarousel(
  //         //       _filteredLots,
  //         //       GeoPoint(
  //         //           _currentPosition!.latitude, _currentPosition!.longitude),
  //         //       _mapDialogBookingType(_bookingType), // booking type
  //         //     ),
  //         //   ),
  //         // ),
  //       ],
  //     ),
  //     _buildCarousel(
  //       _filteredLots,
  //       GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
  //       _mapDialogBookingType(_bookingType), // booking type
  //     ),
  //     // Floating back button + search bar (on top)
  //     _buildFloatingAppBar(context),
  //   ]);
  // }

  Widget _buildBody() {
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Show snackbar if no lots
    if (_filteredLots.isEmpty) {
      // Use a post-frame callback to avoid calling ScaffoldMessenger during build
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text("No parking lots found"),
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      // });

      // Return only the map (no carousel or sheet)
      return Stack(
        children: [
          // Full-screen map
          _buildMap(),

          // Floating back button + search bar
          _buildFloatingAppBar(context),
        ],
      );
    }

    return Stack(
      children: [
        _buildMap(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 70,
          child: SizedBox(
            height: 190,
            child: _buildCarousel(
              _filteredLots,
              GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
              _bookingType,
            ),
          ),
        ),
        _buildFloatingAppBar(context),

        // Put the **button first** so it appears behind the sheet
        Align(
          alignment: Alignment(0, 0.31),
          child: ElevatedButton(
            onPressed: _expandSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 7, 108, 209),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.list, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "List",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Drag sheet **last**, so it covers the button when expanded
        _buildDragSheet(
          _filteredLots,
          GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
          _bookingType,
          controller: _sheetController,
        ),
      ],
    );
  }

  Widget _buildFloatingAppBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: [
          // Floating Back Button
          Container(
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
              boxShadow: [
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

          const SizedBox(width: 8),

          // Floating Search Bar with TypeAheadField
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFEEEEEE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(2, 3),
                  ),
                ],
              ),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Where to park?",
                    hintStyle:
                        TextStyle(color: Color.fromARGB(133, 0, 73, 145)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search,
                        color: Color.fromARGB(133, 0, 73, 145)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return [];
                  return await _placesService.getAutocomplete(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(suggestion['description']),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _selectPlace(suggestion);
                },
                noItemsFoundBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No locations found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Filter Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Color(0xFF004991)),
              onPressed: () => _showFilterDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Stack(
      children: [
        GoogleMap(
          key: const ValueKey("map"), //make sure delete this if code error
          initialCameraPosition: CameraPosition(
            target: _selectedPosition ??
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            if (_selectedPosition != null) {
              _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_selectedPosition!, 16));
            } else {
              _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude),
                  14));
            }
            if (_markers.isEmpty && _selectedPosition != null) {
              _markers.add(Marker(
                markerId: const MarkerId('selected'),
                position: _selectedPosition!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueViolet),
                draggable: true,
                onDragEnd: (newPos) =>
                    setState(() => _selectedPosition = newPos),
                infoWindow: InfoWindow(title: _selectedPlace),
              ));
            }
          },
          onCameraIdle: () {
            // if (_selectedPosition != null) {
            //   _addOrUpdateMarker(_selectedPosition!);
            // }
            if (_selectedPosition != null) {
              _updateSelectedMarker(
                  _selectedPosition!); //make sure to delete this if not working and uncomment out the below
              // final updatedMarkers = Set<Marker>.from(_markers);
              // updatedMarkers.removeWhere((m) => m.markerId.value == 'selected');
              // updatedMarkers.add(Marker(
              //   markerId: const MarkerId('selected'),
              //   position: _selectedPosition!,
              //   icon: BitmapDescriptor.defaultMarkerWithHue(
              //       BitmapDescriptor.hueViolet),
              //   draggable: true,
              //   onDragEnd: (newPos) => setState(() {
              //     _selectedPosition = newPos;
              //     _showConfirmButton = true;
              //   }),
              //   infoWindow: InfoWindow(title: _selectedPlace),
              // ));
              // setState(() => _markers = updatedMarkers);
            }
          },
        ),
        Positioned(
          right: 10, // adjust as needed
          bottom: 265, // adjust as needed
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _goToCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location,
                  // AssetImage('icons/searchicon.png'),
                  size: 30,
                  color: Color(0xFF004991),
                ),
              ),
            ),
          ),
        ),
        if (_showConfirmButton)
          Positioned(
            right: 10, // adjust as needed
            bottom: 315, // adjust as needed
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  setState(() {
                    _confirmedPosition = _selectedPosition ??
                        (_currentPosition != null
                            ? LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude)
                            : null);
                    _showConfirmButton = false;
                    if (_confirmedPosition != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Location confirmed!")),
                      );
                      print(
                          "Confirmed position: ${_confirmedPosition!.latitude}, ${_confirmedPosition!.longitude}");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No location selected.")),
                      );
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    // AssetImage('icons/searchicon.png'),
                    size: 30,
                    color: Color(0xFF004991),
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }

  // Helper for date picker
  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateChanged,
  }) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      controller: TextEditingController(
          text:
              "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}"),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onDateChanged(picked);
      },
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
              color: Color(0xFF004991),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(
    List<ParklotModel> lots,
    GeoPoint selectedPosition,
    String bookingType,
  ) {
    return CarouselSlider.builder(
      carouselController: _carouselController,
      options: CarouselOptions(
        height: 190,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        viewportFraction: 1,
      ),
      itemCount: lots.length,
      itemBuilder: (context, index, realIndex) {
        final lot = lots[index];

        // Calculate distance
        double distance = _locationService.calculateDistanceKm(
            selectedPosition.latitude,
            selectedPosition.longitude,
            lot.location.latitude,
            lot.location.longitude);

        String priceText;
        switch (bookingType.toLowerCase()) {
          case 'hourly':
            priceText = "\$${lot.hourlyRate.toStringAsFixed(2) ?? '0.00'} / h";
            break;
          case 'daily':
            priceText = "\$${lot.dailyRate.toStringAsFixed(2) ?? '0.00'} / d";
            break;
          case 'monthly':
            priceText = "\$${lot.monthlyRate.toStringAsFixed(2) ?? '0.00'} / m";
            break;
          default:
            priceText = "\$${lot.hourlyRate.toStringAsFixed(2) ?? '0.00'} / h";
        }
        return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LotDetailScreen(
                            lot: lot,
                            startDate: _startDate,
                            endDate: _endDate,
                            bookingType: _bookingType,
                            selectedPosition: selectedPosition,
                          )));
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              color: Colors.white, // ensure card background is white
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              clipBehavior:
                  Clip.antiAlias, // ensures rounded corners work with image
              child: Row(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16)),
                    child: SizedBox(
                      height: double.infinity,
                      width: 100,
                      child: _buildFirebaseImageFromBase64(lot.img),
                    ),
                  ),

                  // Info section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lot.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF004991),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          if (lot.availableFrom != null &&
                              lot.closeBefore != null)
                            Text(
                              "Available: ",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: Color.fromRGBO(59, 120, 195, 0.642),
                              ),
                            ),
                          Text(
                            "${dateFormat.format(lot.availableFrom!)} - "
                            "${dateFormat.format(lot.closeBefore!)}",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: Color.fromRGBO(59, 120, 195, 0.642),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Capacity: ${lot.capacity - lot.occupied}/${lot.capacity}, "
                            "EV-Charge: ${lot.echarge == true ? 'Yes' : 'No'}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color.fromRGBO(59, 120, 195, 0.642),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Distance: ${distance.toStringAsFixed(1)} km",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Color.fromRGBO(59, 120, 195, 0.642),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Price Text
                                  Text(
                                    priceText,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 7, 108, 209),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Book Now Button
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final amount =
                                            _locationService.calculatePrice(
                                          lot: lot,
                                          bookingType: _bookingType,
                                          start: _startDate,
                                          end: _endDate,
                                        );

                                        await PaymentService.startBookingAndPay(
                                          context: context,
                                          lotId: lot.id,
                                          hostId: lot.hostId,
                                          start: _startDate,
                                          end: _endDate!,
                                          bookingType: _bookingType,
                                          amount: amount,
                                        );

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text("Booking successful!")),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text("Error: $e")),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color.fromARGB(
                                          255,
                                          7,
                                          108,
                                          209), // outlined style with white bg
                                      side: const BorderSide(
                                          color: Colors.white), // green border
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 5),
                                    ),
                                    child: const Text(
                                      "Book",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // match border
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }

  Widget _buildDragSheet(
    List<ParklotModel> lots,
    GeoPoint selectedPosition,
    String bookingType, {
    required DraggableScrollableController controller,
  }) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.075, // visible small strip
      minChildSize: 0.075, // never hidden
      maxChildSize: 0.9, // expand to almost full screen
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Header section
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _expandSheet, // expand when tapped
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(131, 0, 73, 145),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(
                              "${lots.length} Parking Lots Near You",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF004991),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // List of lots
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lot = lots[index];
                    if (lot == null) return const SizedBox();

                    // Calculate distance
                    double distance = _locationService.calculateDistanceKm(
                      selectedPosition.latitude,
                      selectedPosition.longitude,
                      lot.location.latitude,
                      lot.location.longitude,
                    );

                    // Format price
                    String priceText;
                    switch (bookingType.toLowerCase()) {
                      case 'hourly':
                        priceText =
                            "\$${lot.hourlyRate.toStringAsFixed(2) ?? '0.00'} / h";
                        break;
                      case 'daily':
                        priceText =
                            "\$${lot.dailyRate.toStringAsFixed(2) ?? '0.00'} / d";
                        break;
                      case 'monthly':
                        priceText =
                            "\$${lot.monthlyRate.toStringAsFixed(2) ?? '0.00'} / m";
                        break;
                      default:
                        priceText =
                            "\$${lot.hourlyRate.toStringAsFixed(2) ?? '0.00'} / h";
                    }

                    // Your card widget
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LotDetailScreen(
                                      lot: lot,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                      bookingType: _bookingType,
                                      selectedPosition: selectedPosition,
                                    )));
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 8),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 150,
                              child: _buildFirebaseImageFromBase64(lot.img),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (lot.availableFrom != null &&
                                      lot.closeBefore != null) ...[
                                    Text(
                                      "Available: ${dateFormat.format(lot.availableFrom!)} - "
                                      "${dateFormat.format(lot.closeBefore!)}",
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color.fromRGBO(59, 120, 195, 1),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lot.name,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF004991),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_walk,
                                            size: 16, color: Color(0xFF004991)),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${distance.toStringAsFixed(1)} km",
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF004991),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.local_parking,
                                            size: 16, color: Color(0xFF004991)),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${lot.capacity - lot.occupied}/${lot.capacity}",
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
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
                                          lot.echarge ? "Yes" : "No",
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF004991),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          priceText,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromARGB(
                                                255, 7, 108, 209),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              final amount = _locationService
                                                  .calculatePrice(
                                                lot: lot,
                                                bookingType: _bookingType,
                                                start: _startDate,
                                                end: _endDate,
                                              );

                                              await PaymentService
                                                  .startBookingAndPay(
                                                context: context,
                                                lotId: lot.id,
                                                hostId: lot.hostId,
                                                start: _startDate,
                                                end: _endDate!,
                                                bookingType: _bookingType,
                                                amount: amount,
                                              );

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        "Booking successful!")),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text("Error: $e")),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 7, 108, 209),
                                            side: const BorderSide(
                                                color: Colors.white),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 5),
                                          ),
                                          child: const Text(
                                            "Book",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: lots.length,
                ),
              ),
            ],
          ),
        );
      },
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
