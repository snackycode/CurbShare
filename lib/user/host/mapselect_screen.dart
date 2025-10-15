import 'package:curbshare/services/location_service.dart';
import 'package:curbshare/services/place_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectScreen extends StatefulWidget {
  const MapSelectScreen({super.key});

  @override
  State<MapSelectScreen> createState() => _MapSelectScreenState();
}

class _MapSelectScreenState extends State<MapSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PlacesService _placesService = PlacesService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _selectedPosition;
  String _selectedPlace = "Selected Location";
  Set<Marker> _markers = {};

  // Services
  final LocationService _locationService = LocationService();

  void _selectPlace(Map<String, dynamic> prediction) async {
    try {
      // 1️⃣ Get LatLng from place ID
      final latLng =
          await _placesService.getPlaceDetails(prediction['place_id']);

      // 2️⃣ Update state: selected position, place, and search text
      setState(() {
        _selectedPosition = LatLng(latLng.latitude, latLng.longitude);
        _selectedPlace = prediction['description'];
        _searchController.text = prediction['description'];

        // Update existing marker if present, otherwise add a new one
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
          _markers.add(
            Marker(
              markerId: const MarkerId('selected'),
              position: _selectedPosition!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet),
              draggable: true,
              onDragEnd: (newPos) => setState(() => _selectedPosition = newPos),
              infoWindow: InfoWindow(title: _selectedPlace),
            ),
          );
        }
      });

      // 3️⃣ Animate camera to the new position
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 16),
      );
    } catch (e) {
      print("Error selecting place: $e");
    }
  }

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

  @override
  void initState() {
    super.initState();

    _init();
  }

  Future<void> _init() async {
    try {
      // 1️⃣ Get current position
      final pos = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = pos;
        _selectedPosition = LatLng(pos.latitude, pos.longitude);
        _selectedPlace = "Current Location";

// Selected (violet) marker
        _markers.add(
          Marker(
            markerId: const MarkerId('selected'),
            position: _selectedPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            draggable: true,
            onDragEnd: (newPos) => setState(() => _selectedPosition = newPos),
            infoWindow: InfoWindow(title: _selectedPlace),
          ),
        );
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition!, 16),
      );
    } catch (e) {
      print('Error initializing map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _buildBody(),
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

          const SizedBox(width: 12),

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
                    hintStyle: TextStyle(
                      color: Color.fromARGB(133, 0, 73, 145),
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color.fromARGB(133, 0, 73, 145),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Base layout: map + confirm button
        Column(
          children: [
            Expanded(child: _buildMap()), // Map takes available height
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildConfirmButton(), // Button pinned at bottom
            ),
          ],
        ),

        // Floating back button + search bar (on top)
        _buildFloatingAppBar(context),
      ],
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        GoogleMap(
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
          },
          onCameraMove: (position) {
            // Update only selected marker position if user drags map
            if (_selectedPosition != null) {
              final updatedMarkers = Set<Marker>.from(_markers);
              updatedMarkers.removeWhere((m) => m.markerId.value == 'selected');
              updatedMarkers.add(Marker(
                markerId: const MarkerId('selected'),
                position: position.target,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueViolet),
                draggable: true,
                onDragEnd: (newPos) => setState(() {
                  _selectedPosition = newPos;
                  _selectedPlace = "Selected Location";
                }),
                infoWindow: InfoWindow(title: _selectedPlace),
              ));

              setState(() {
                _selectedPosition = position.target;
                _selectedPlace = "Selected Location";
                _markers = updatedMarkers;
              });
            }
          },
        ),
        Positioned(
          right: 10, // adjust as needed
          bottom: 105, // adjust as needed
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
        )
      ],
    );
  }

  // Confirm button widget
  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color.fromRGBO(59, 120, 195, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          if (_selectedPosition != null) {
            final location = {
              "lat": _selectedPosition!.latitude,
              "lng": _selectedPosition!.longitude,
              "place": _selectedPlace,
            };
            print("Confirm pressed. Location data: $location");

            // 🔹 Pop this screen (Screen C) and send location back
            Navigator.pop(context, location);
          } else {
            // Optional: show a warning if no location is selected
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a location first.")),
            );
          }
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
