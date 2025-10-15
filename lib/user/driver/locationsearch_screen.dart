import 'package:curbshare/services/place_service.dart';
import 'package:curbshare/user/driver/googlemap_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class LocationSearchScreen extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onLocationConfirmed;
  const LocationSearchScreen({super.key, this.onLocationConfirmed});

  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final PlacesService _placesService = PlacesService();

  void _useCurrentLocation() async {
    // Await MapSearchScreen result
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapSearchScreen(
          useCurrentLocation: true,
        ),
      ),
    );

    // Send the result directly back to Screen A
    if (result != null) {
      Navigator.pop(context, result);
    }
  }

//  void _selectPlace(Map<String, dynamic> prediction) async {
//   try {
//     final latLng = await _placesService.getPlaceDetails(prediction['place_id']);

//     // Open MapSearchScreen with initial location and search query
//     final result = await Navigator.push<Map<String, dynamic>>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => MapSearchScreen(
//           latitude: latLng.latitude,
//           longitude: latLng.longitude,
//           searchQuery: prediction['description'],
//           onLocationConfirmed: (location) {
//             // Pop back to LocationSearchScreen (or Screen A)
//             Navigator.pop(context, location);
//           },
//         ),
//       ),
//     );

//     // This will be the confirmed location
//     if (result != null) {
//       Navigator.pop(context, result);
//     }
//   } catch (e) {
//     print("Error selecting place: $e");
//   }
// }

  void _selectPlace(Map<String, dynamic> prediction) async {
    try {
      final placeId = prediction['place_id'];
      print("Selected placeId: $placeId"); // debug
      final latLng = await _placesService.getPlaceDetails(placeId);
      print("LatLng: $latLng"); // debug

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapSearchScreen(
            latitude: latLng.latitude,
            longitude: latLng.longitude,
            searchQuery: prediction['description'],
            onLocationConfirmed: (location) {
              // Pop back to LocationSearchScreen (or Screen A)
              Navigator.pop(context, location);
            },
          ),
        ),
      );
    } catch (e) {
      print("Error selecting place: $e");
    }
  }

  // void _selectPlace(Map<String, dynamic> prediction) async {
  //   final latLng = await _placesService.getPlaceDetails(prediction['place_id']);
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => MapSearchScreen(
  //         latitude: latLng.latitude,
  //         longitude: latLng.longitude,
  //         searchQuery: prediction['description'],
  //         onLocationConfirmed: widget.onLocationConfirmed,
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TypeAheadField<Map<String, dynamic>>(
          textFieldConfiguration: TextFieldConfiguration(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Where would you like to park?",
              border: InputBorder.none,
            ),
          ),
          // suggestionsCallback: (pattern) async {
          //   if (pattern.isEmpty) return [];
          //   return await _placesService.getAutocomplete(pattern);
          // },
          suggestionsCallback: (pattern) async {
            print("User typed: $pattern"); // debug
            if (pattern.isEmpty) return [];
            final results = await _placesService.getAutocomplete(pattern);
            print("Autocomplete results: $results"); // debug
            return results;
          },
          itemBuilder: (context, prediction) {
            return ListTile(
              title: Text(prediction['description']),
            );
          },
          // onSuggestionSelected: _selectPlace,
          onSuggestionSelected: (prediction) {
            print("Suggestion tapped: $prediction"); // debug
            _selectPlace(prediction);
          },
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.my_location, color: Colors.pink),
            title: Text("Current location"),
            onTap: _useCurrentLocation,
          ),
        ],
      ),
    );
  }
}
